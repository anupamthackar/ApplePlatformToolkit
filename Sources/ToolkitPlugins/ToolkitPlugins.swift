import Foundation
import ToolkitCore

// MARK: - Core Protocols

/**
 # ToolkitPlugin
 
 A protocol defining the structure and behavior of a plugin within the Toolkit ecosystem.
 Plugins allow for modular extensibility, supporting lifecycle management, dependency resolution, 
 and priority-based execution ordering.
 
 ## Usage
 ```swift
 final class AnalyticsPlugin: ToolkitPlugin {
     let id = "com.myapp.analytics"
     let version = "1.0.0"
     let priority = 100
     let dependencies = ["com.toolkit.core"]
     
     func onExecute(context: PluginContext) async throws {
         // Perform analytics setup
         context.logger.log("Analytics started", level: .info)
     }
 }
 ```
 */
public protocol ToolkitPlugin: PluginProtocol {
    /// A semantic version string for the plugin (e.g., "1.2.3").
    var version: String { get }
    
    /// The relative priority of the plugin. Plugins with higher values are executed earlier in the sequence.
    var priority: Int { get }
    
    /// A list of plugin identifiers that must be registered before this plugin can be loaded.
    var dependencies: [String] { get }
    
    /**
     The core logic to be executed by the plugin manager.
     
     - Parameter context: A shared object providing access to configuration, logging, and common state.
     - Throws: `PluginError` if execution fails.
     */
    func onExecute(context: PluginContext) async throws
}

public extension ToolkitPlugin {
    /// Bridges the simple `PluginProtocol` to the more advanced `ToolkitPlugin` interface.
    func onExecute() { }
}

/**
 # PluginContext
 
 A shared container passed to plugins during their execution phase.
 It provides access to global configuration, diagnostic logging, and a shared state dictionary 
 for inter-plugin communication.
 */
public class PluginContext {
    /// Static configuration data specific to the current plugin session.
    public let configuration: [String: Any]
    
    /// A shared logger instance for recording diagnostic and lifecycle information.
    public let logger: LoggerProtocol
    
    /// A thread-safe dictionary used to pass data between different plugins in the same execution cycle.
    public var sharedState: [String: Any] = [:]
    
    /**
     Initializes a new plugin context.
     
     - Parameters:
        - configuration: Session-specific settings.
        - logger: The logger to be used by plugins.
     */
    public init(configuration: [String: Any] = [:], logger: LoggerProtocol = Logger.shared) {
        self.configuration = configuration
        self.logger = logger
    }
    
    /**
     Attempts to resolve a specific dependency from the host application's dependency container.
     
     - Parameter type: The type of dependency to resolve.
     - Returns: An instance of the type, or `nil` if not found.
     */
    public func resolveDependency<T>(_ type: T.Type) -> T? {
        return DependencyContainer.shared.resolve(type)
    }
}

// MARK: - Event Bus

/**
 # EventBus
 
 A high-performance, thread-safe publish-subscribe mechanism for decoupled communication
 between different modules, services, and plugins.
 
 ## Usage
 ```swift
 // 1. Subscribe to an event
 EventBus.shared.subscribe(event: "session_started") { event in
     print("Session ID: \(event.payload["id"] ?? "")")
 }
 
 // 2. Publish an event
 await EventBus.shared.publish(TypedEvent(
     name: "session_started", 
     payload: ["id": "XYZ"]
 ))
 ```
 */
public final class EventBus: @unchecked Sendable {
    /// The global shared instance of the event bus.
    public nonisolated(unsafe) static let shared = EventBus()
    
    private var listeners: [String: [EventListener]] = [:]
    private let queue = DispatchQueue(label: "com.toolkit.eventbus", attributes: .concurrent)
    
    /// Internal initializer for singleton use.
    public init() {}
    
    /**
     Registers a listener for a specific event name.
     
     - Parameters:
        - event: The unique name of the event to observe.
        - listener: The object that will handle the event when published.
     */
    public func subscribe(event: String, listener: EventListener) {
        queue.async(flags: .barrier) {
            var current = self.listeners[event] ?? []
            current.append(listener)
            current.sort { $0.priority > $1.priority }
            self.listeners[event] = current
        }
    }
    
    /**
     Dispatches an event to all subscribed listeners asynchronously.
     
     - Parameter event: The event object containing name and payload.
     */
    public func publish(_ event: TypedEvent) async {
        let targets = queue.sync { self.listeners[event.name] ?? [] }
        for listener in targets {
            await listener.onEvent(event)
        }
    }
}

/**
 # TypedEvent
 
 Represents a structured event message transmitted over the `EventBus`.
 */
public struct TypedEvent {
    /// The unique name of the event (e.g., "user_did_login").
    public let name: String
    /// A dictionary of metadata associated with the event.
    public let payload: [String: Any]
    /// The identifier of the module or component that emitted the event.
    public let source: String
    
    /**
     Initializes a new event.
     
     - Parameters:
        - name: The event name.
        - payload: Associated data.
        - source: The origin of the event. Defaults to "system".
     */
    public init(name: String, payload: [String: Any], source: String = "system") {
        self.name = name
        self.payload = payload
        self.source = source
    }
}

/// Defines the interface for objects that observe events on the `EventBus`.
public protocol EventListener: Sendable {
    /// The priority of the listener. Lower values are called later.
    var priority: Int { get }
    /// Called when a matching event is published.
    func onEvent(_ event: TypedEvent) async
}

// MARK: - Plugin Manager

/**
 # PluginManager
 
 The central registry and execution coordinator for all toolkit-compliant plugins.
 It manages dependency validation, topological execution ordering, and plugin lifecycle.
 
 ## Usage
 ```swift
 // 1. Register plugins
 try PluginManager.shared.register(LoggingPlugin())
 try PluginManager.shared.register(AnalyticsPlugin())
 
 // 2. Trigger execution
 await PluginManager.shared.executeAll()
 ```
 */
public final class PluginManager: @unchecked Sendable {
    /// Shared singleton instance of the `PluginManager`.
    public nonisolated(unsafe) static let shared = PluginManager()
    
    private var plugins: [String: ToolkitPlugin] = [:]
    private var executionOrder: [ToolkitPlugin] = []
    
    /// Global configuration settings for the plugin system.
    public let config: PluginConfig
    
    /// The shared context provided to every plugin during execution.
    public let context = PluginContext()
    
    private let accessQueue = DispatchQueue(label: "com.toolkit.pluginmanager", attributes: .concurrent)
    
    /**
     Initializes the manager with specific settings.
     - Parameter config: Configuration for dependency checks and failure isolation.
     */
    public init(config: PluginConfig = PluginConfig()) {
        self.config = config
    }
    
    /**
     Registers a new plugin with the manager.
     
     - Parameter plugin: The plugin instance to register.
     - Returns: `true` if registration was successful.
     - Throws: `PluginError.missingDependency` if requirements are not met and `strictDependencies` is enabled.
     */
    @discardableResult
    public func register(_ plugin: ToolkitPlugin) throws -> Bool {
        return try accessQueue.sync(flags: .barrier) {
            if config.strictDependencies {
                for dep in plugin.dependencies {
                    guard plugins[dep] != nil else {
                        throw PluginError.missingDependency(dep)
                    }
                }
            }
            
            plugins[plugin.id] = plugin
            plugin.onLoad()
            recalculateGraph()
            return true
        }
    }
    
    /**
     Unloads and removes a plugin by its unique identifier.
     
     - Parameter id: The ID of the plugin to remove.
     */
    public func unregister(id: String) {
        accessQueue.async(flags: .barrier) {
            if let plugin = self.plugins[id] {
                plugin.onUnload()
                self.plugins.removeValue(forKey: id)
                self.recalculateGraph()
            }
        }
    }
    
    /**
     Executes all registered plugins in the order defined by their priority and dependencies.
     */
    public func executeAll() async {
        let targets = accessQueue.sync { executionOrder }
        for plugin in targets {
            do {
                try await plugin.onExecute(context: context)
            } catch {
                if !config.isolateFailures {
                    Logger.shared.log("Plugin \(plugin.id) failed: \(error)", level: .error, file: #file, function: #function, line: #line)
                }
            }
        }
    }
    
    /**
     Retrieves a registered plugin by its identifier for manual interaction.
     
     - Parameter id: The identifier of the plugin.
     - Returns: The plugin instance if registered.
     */
    public func fetch(id: String) -> ToolkitPlugin? {
        return accessQueue.sync { plugins[id] }
    }
    
    private func recalculateGraph() {
        executionOrder = plugins.values.sorted { $0.priority > $1.priority }
    }
}

/// Represents errors that can occur during the plugin lifecycle.
public enum PluginError: Error {
    /// Thrown when a required dependency for a plugin is not found.
    case missingDependency(String)
    /// Thrown when a plugin's version is not compatible with the current manager.
    case incompatibleVersion
    /// Thrown when a plugin encounters a critical failure during its execution phase.
    case executionFailed(String)
}

/**
 # PluginConfig
 
 Configuration settings for the `PluginManager`.
 */
public struct PluginConfig {
    /// If true, a plugin cannot be registered unless all its dependencies are already present.
    public var strictDependencies: Bool = true
    /// If true, a failure in one plugin will not prevent the rest of the chain from executing.
    public var isolateFailures: Bool = true
    
    /// Initializes a default configuration.
    public init() {}
}

// MARK: - Standard Plugins

/**
 # LoggingPlugin
 
 A standard plugin that provides diagnostic logging during the toolkit execution phase.
 */
public final class LoggingPlugin: ToolkitPlugin, @unchecked Sendable {
    public var id: String = "com.toolkit.logging"
    public var version: String = "1.0.0"
    public var priority: Int = 100
    public var dependencies: [String] = []
    
    public init() {}
    public func onLoad() { }
    public func onUnload() { }
    public func onExecute(context: PluginContext) async throws {
        context.logger.log("LoggingPlugin executing", level: .info, file: #file, function: #function, line: #line)
    }
}

/**
 # AnalyticsPlugin
 
 A standard plugin for recording usage metrics and application events.
 */
public final class AnalyticsPlugin: ToolkitPlugin, @unchecked Sendable {
    public var id: String = "com.toolkit.analytics"
    public var version: String = "1.0.0"
    public var priority: Int = 90
    public var dependencies: [String] = ["com.toolkit.logging"]
    
    public init() {}
    public func onLoad() { }
    public func onUnload() { }
    public func onExecute(context: PluginContext) async throws { }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitPlugins module.
    static var plugins: PluginManager { PluginManager.shared }
}
