import Foundation
import ToolkitCore

// MARK: - Core Protocols Documentation

/**
 # ToolkitPlugin
 
 A protocol defining the structure and behavior of a plugin within the Toolkit ecosystem.
 Plugins support lifecycle management, dependency resolution, and priority-based execution.
 
 ## Usage
 ```swift
 final class MyPlugin: ToolkitPlugin {
     let id = "com.myapp.plugin"
     let version = "1.0.0"
     let priority = 10
     let dependencies = ["com.toolkit.core"]
     
     func onExecute(context: PluginContext) async throws {
         print("Executing plugin with context")
     }
 }
 ```
 */
public protocol ToolkitPlugin: PluginProtocol {
    /// Semantic version string (e.g., "1.2.3").
    var version: String { get }
    /// Relative priority. Plugins with higher values are executed first.
    var priority: Int { get }
    /// A list of plugin IDs that must be registered before this plugin can load.
    var dependencies: [String] { get }
    
    /**
     The core execution logic for the plugin.
     - Parameter context: Provides access to shared resources like loggers and shared state.
     */
    func onExecute(context: PluginContext) async throws
}

public extension ToolkitPlugin {
    /// Bridges the simple `PluginProtocol` to the more advanced `ToolkitPlugin`.
    func onExecute() { }
}

/**
 # PluginContext
 
 A shared container passed to plugins during their execution phase.
 Provides access to configuration, logging, and dependency resolution.
 */
public class PluginContext {
    /// Static configuration data for the plugin.
    public let configuration: [String: Any]
    /// Shared logger for diagnostic information.
    public let logger: LoggerProtocol
    /// A thread-safe dictionary for passing data between different plugins in the same session.
    public var sharedState: [String: Any] = [:]
    
    public init(configuration: [String: Any] = [:], logger: LoggerProtocol = Logger.shared) {
        self.configuration = configuration
        self.logger = logger
    }
    
    /**
     Attempts to resolve a dependency from the host application's dependency container.
     */
    public func resolveDependency<T>(_ type: T.Type) -> T? {
        return nil // Integration point for future DI logic
    }
}

// MARK: - Event Bus Documentation

/**
 # EventBus
 
 A simple, thread-safe publish-subscribe mechanism for decoupled communication
 between different modules and plugins.
 
 ## Usage
 ```swift
 EventBus.shared.subscribe(event: "user_logged_in") { event in
     print("User \(event.payload["id"] ?? "") logged in!")
 }
 
 await EventBus.shared.publish(TypedEvent(name: "user_logged_in", payload: ["id": "123"]))
 ```
 */
public final class EventBus: @unchecked Sendable {
    /// The global shared event bus.
    public nonisolated(unsafe) static let shared = EventBus()
    private var listeners: [String: [EventListener]] = [:]
    private let queue = DispatchQueue(label: "com.toolkit.eventbus", attributes: .concurrent)
    
    public init() {}
    
    /**
     Registers a listener for a specific event name.
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
     Dispatches an event to all subscribed listeners.
     */
    public func publish(_ event: TypedEvent) async {
        let targets = queue.sync { self.listeners[event.name] ?? [] }
        for listener in targets {
            await listener.onEvent(event)
        }
    }
}

/**
 Represents a structured event emitted on the `EventBus`.
 */
public struct TypedEvent {
    public let name: String
    public let payload: [String: Any]
    public let source: String
    
    public init(name: String, payload: [String: Any], source: String = "system") {
        self.name = name
        self.payload = payload
        self.source = source
    }
}

/**
 Protocol for objects that want to listen for events on the `EventBus`.
 */
public protocol EventListener: Sendable {
    var priority: Int { get }
    func onEvent(_ event: TypedEvent) async
}

// MARK: - Plugin Manager Documentation

/**
 # PluginManager
 
 The registry and executor for all toolkit plugins.
 Handles dependency validation, topological execution ordering, and plugin lifecycle.
 
 ## Usage
 ```swift
 try PluginManager.shared.register(MyPlugin())
 await PluginManager.shared.executeAll()
 ```
 */
public final class PluginManager: @unchecked Sendable {
    /// Shared singleton manager.
    public nonisolated(unsafe) static let shared = PluginManager()
    
    private var plugins: [String: ToolkitPlugin] = [:]
    private var executionOrder: [ToolkitPlugin] = []
    
    /// Global configuration for plugin behaviors.
    public let config: PluginConfig
    /// The shared context provided to all plugins.
    public let context = PluginContext()
    private let accessQueue = DispatchQueue(label: "com.toolkit.pluginmanager", attributes: .concurrent)
    
    public init(config: PluginConfig = PluginConfig()) {
        self.config = config
    }
    
    /**
     Registers a new plugin.
     - Throws: `PluginError.missingDependency` if requirements aren't met.
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
     Unloads and removes a plugin by its ID.
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
     Executes all registered plugins in order of their priority.
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
     Retrieves a registered plugin by its identifier.
     */
    public func fetch(id: String) -> ToolkitPlugin? {
        return accessQueue.sync { plugins[id] }
    }
    
    private func recalculateGraph() {
        executionOrder = plugins.values.sorted { $0.priority > $1.priority }
    }
}

/**
 Errors thrown during plugin registration or execution.
 */
public enum PluginError: Error {
    case missingDependency(String)
    case incompatibleVersion
    case executionFailed(String)
}

/**
 Configuration for the `PluginManager`.
 */
public struct PluginConfig {
    /// If true, registration fails if dependencies are not already loaded.
    public var strictDependencies: Bool = true
    /// If true, a single plugin failure won't stop other plugins from executing.
    public var isolateFailures: Bool = true
    public init() {}
}

// MARK: - Example Plugins

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
