import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)

plugins_src = """import Foundation
import ToolkitCore

// MARK: - Core Protocols & Models

/// Extended plugin protocol meeting advanced architecture requirements.
public protocol ToolkitPlugin: PluginProtocol {
    /// Semantic version of the plugin.
    var version: String { get }
    /// Execution priority (higher executes first).
    var priority: Int { get }
    /// Array of plugin IDs that must be loaded before this one.
    var dependencies: [String] { get }
    
    /// Advanced execution with isolated context.
    func onExecute(context: PluginContext) async throws
}

public extension ToolkitPlugin {
    // Default implementation to bridge the legacy PluginProtocol
    func onExecute() { }
}

/// A sandbox/context provided to plugins during execution.
public class PluginContext {
    public let configuration: [String: Any]
    public let logger: LoggerProtocol
    public var sharedState: [String: Any] = [:]
    
    public init(configuration: [String: Any] = [:], logger: LoggerProtocol = Logger.shared) {
        self.configuration = configuration
        self.logger = logger
    }
    
    public func resolveDependency<T>(_ type: T.Type) -> T? {
        return nil // Hook to DI container
    }
}

// MARK: - Event Bus

public protocol EventListener {
    var priority: Int { get }
    func onEvent(_ event: TypedEvent) async
}

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

public class EventBus {
    public nonisolated(unsafe) static let shared = EventBus()
    private var listeners: [String: [EventListener]] = [:]
    private let queue = DispatchQueue(label: "com.toolkit.eventbus", attributes: .concurrent)
    
    public init() {}
    
    public func subscribe(event: String, listener: EventListener) {
        queue.async(flags: .barrier) {
            var current = self.listeners[event] ?? []
            current.append(listener)
            current.sort { $0.priority > $1.priority }
            self.listeners[event] = current
        }
    }
    
    public func publish(_ event: TypedEvent) async {
        let targets = queue.sync { self.listeners[event.name] ?? [] }
        for listener in targets {
            await listener.onEvent(event)
        }
    }
}

// MARK: - Plugin Registry

public enum PluginError: Error {
    case missingDependency(String)
    case incompatibleVersion
    case executionFailed(String)
}

public struct PluginConfig {
    public var strictDependencies: Bool = true
    public var isolateFailures: Bool = true
    public init() {}
}

public class PluginManager {
    public nonisolated(unsafe) static let shared = PluginManager()
    
    private var plugins: [String: ToolkitPlugin] = [:]
    private var executionOrder: [ToolkitPlugin] = []
    public let config: PluginConfig
    public let context = PluginContext()
    private let accessQueue = DispatchQueue(label: "com.toolkit.pluginmanager", attributes: .concurrent)
    
    public init(config: PluginConfig = PluginConfig()) {
        self.config = config
    }
    
    @discardableResult
    public func register(_ plugin: ToolkitPlugin) throws -> Bool {
        return try accessQueue.sync(flags: .barrier) {
            // Check dependencies
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
    
    public func unregister(id: String) {
        accessQueue.sync(flags: .barrier) {
            if let plugin = plugins[id] {
                plugin.onUnload()
                plugins.removeValue(forKey: id)
                recalculateGraph()
            }
        }
    }
    
    public func fetch(id: String) -> ToolkitPlugin? {
        return accessQueue.sync { plugins[id] }
    }
    
    private func recalculateGraph() {
        // Simplified topological/priority sort
        executionOrder = plugins.values.sorted { $0.priority > $1.priority }
    }
    
    public func executeAll() async {
        let targets = accessQueue.sync { executionOrder }
        for plugin in targets {
            do {
                try await plugin.onExecute(context: context)
            } catch {
                if !config.isolateFailures {
                    // Bubble up or handle locally
                    Logger.shared.log("Plugin \\(plugin.id) failed: \\(error)", level: .error, file: #file, function: #function, line: #line)
                }
            }
        }
    }
    
    // Hot-swapping
    public func swap(id: String, with newPlugin: ToolkitPlugin) throws {
        unregister(id: id)
        try register(newPlugin)
    }
}

// MARK: - Example Plugins

public class LoggingPlugin: ToolkitPlugin {
    public var id: String = "com.toolkit.logging"
    public var version: String = "1.0.0"
    public var priority: Int = 100
    public var dependencies: [String] = []
    
    public init() {}
    public func onLoad() { print("LoggingPlugin Loaded") }
    public func onUnload() { print("LoggingPlugin Unloaded") }
    public func onExecute(context: PluginContext) async throws {
        context.logger.log("LoggingPlugin executing", level: .info, file: #file, function: #function, line: #line)
    }
}

public class AnalyticsPlugin: ToolkitPlugin {
    public var id: String = "com.toolkit.analytics"
    public var version: String = "1.0.0"
    public var priority: Int = 90
    public var dependencies: [String] = ["com.toolkit.logging"]
    
    public init() {}
    public func onLoad() { }
    public func onUnload() { }
    public func onExecute(context: PluginContext) async throws {
        // Batch event tracking logic
    }
}

public class SecurityPlugin: ToolkitPlugin {
    public var id: String = "com.toolkit.security"
    public var version: String = "1.0.0"
    public var priority: Int = 1000
    public var dependencies: [String] = []
    
    public init() {}
    public func onLoad() { }
    public func onUnload() { }
    public func onExecute(context: PluginContext) async throws {
        // Threat detection and request signing hooks
    }
}

public class NetworkingPlugin: ToolkitPlugin {
    public var id: String = "com.toolkit.networking.plugin"
    public var version: String = "1.0.0"
    public var priority: Int = 50
    public var dependencies: [String] = ["com.toolkit.security"]
    
    public init() {}
    public func onLoad() { }
    public func onUnload() { }
    public func onExecute(context: PluginContext) async throws {
        // Intercept and transform requests
    }
}
"""
write_file("Sources/ToolkitPlugins/ToolkitPlugins.swift", plugins_src)

# Update Tests
tests_src = """import XCTest
@testable import ToolkitPlugins
@testable import ToolkitCore

final class AdvancedPluginTests: XCTestCase {
    func testPluginLifecycle() async throws {
        let manager = PluginManager(config: PluginConfig(strictDependencies: false))
        let logPlugin = LoggingPlugin()
        
        try manager.register(logPlugin)
        XCTAssertNotNil(manager.fetch(id: logPlugin.id))
        
        await manager.executeAll()
        
        manager.unregister(id: logPlugin.id)
        XCTAssertNil(manager.fetch(id: logPlugin.id))
    }
    
    func testDependencyResolution() {
        let manager = PluginManager(config: PluginConfig(strictDependencies: true))
        let analytics = AnalyticsPlugin() // Depends on logging
        
        XCTAssertThrowsError(try manager.register(analytics)) { error in
            guard case PluginError.missingDependency(let dep) = error else {
                XCTFail("Wrong error")
                return
            }
            XCTAssertEqual(dep, "com.toolkit.logging")
        }
    }
    
    func testEventBus() async {
        class MockListener: EventListener {
            var priority: Int = 1
            var received = false
            func onEvent(_ event: TypedEvent) async {
                received = true
            }
        }
        
        let listener = MockListener()
        EventBus.shared.subscribe(event: "test_event", listener: listener)
        await EventBus.shared.publish(TypedEvent(name: "test_event", payload: [:]))
        
        XCTAssertTrue(listener.received)
    }
}
"""
write_file("Tests/ToolkitPluginsTests/PluginTests.swift", tests_src)

print("Plugin system expanded.")
