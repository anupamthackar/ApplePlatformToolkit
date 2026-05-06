import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)

core_src = """import Foundation
import Combine

// MARK: - Error Handling System

public enum ErrorCategory {
    case network, auth, crypto, system, validation, unknown
}

public protocol ToolkitErrorProtocol: Error {
    var category: ErrorCategory { get }
    var code: Int { get }
    var message: String { get }
    var underlyingError: Error? { get }
    var retryHint: Bool { get }
}

public struct ToolkitError: ToolkitErrorProtocol {
    public let category: ErrorCategory
    public let code: Int
    public let message: String
    public let underlyingError: Error?
    public let retryHint: Bool
    
    public init(category: ErrorCategory, code: Int = -1, message: String, underlyingError: Error? = nil, retryHint: Bool = false) {
        self.category = category
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
        self.retryHint = retryHint
    }
}

// MARK: - Logging System

public enum LogLevel: Int {
    case debug, info, warning, error, critical
}

public protocol LoggerProtocol: Sendable {
    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int)
    func addMetadata(_ key: String, value: String)
}

public actor DefaultLogger: LoggerProtocol {
    public static let shared = DefaultLogger()
    private var metadata: [String: String] = [:]
    private var logDestinations: [LogDestination] = [ConsoleLogDestination()]
    
    public init() {}
    
    public func addMetadata(_ key: String, value: String) {
        metadata[key] = value
    }
    
    public func addDestination(_ dest: LogDestination) {
        logDestinations.append(dest)
    }
    
    public nonisolated func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        Task {
            await self.internalLog(message, level: level, file: file, function: function, line: line)
        }
    }
    
    private func internalLog(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        let metaString = metadata.map { "\\($0.key)=\\($0.value)" }.joined(separator: ", ")
        let formatted = "[\\(level)] \\(URL(fileURLWithPath: file).lastPathComponent):\\(line) - \\(message) | \\(metaString)"
        for dest in logDestinations {
            dest.write(formatted)
        }
    }
}

public protocol LogDestination: Sendable {
    func write(_ message: String)
}

public struct ConsoleLogDestination: LogDestination {
    public init() {}
    public func write(_ message: String) { print(message) }
}

/// Legacy synchronous logger facade to maintain compatibility with existing modules
public class Logger: LoggerProtocol {
    public nonisolated(unsafe) static let shared = Logger()
    private let asyncLogger = DefaultLogger.shared
    public init() {}
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        asyncLogger.log(message, level: level, file: file, function: function, line: line)
    }
    public func addMetadata(_ key: String, value: String) {
        Task { await asyncLogger.addMetadata(key, value: value) }
    }
}

// MARK: - Dependency Injection System

public enum DependencyScope {
    case singleton, transient, scoped
}

public protocol DependencyResolver: Sendable {
    func resolve<T>(_ type: T.Type, name: String?) -> T?
}

public extension DependencyResolver {
    func resolve<T>(_ type: T.Type) -> T? { return resolve(type, name: nil) }
}

public class DependencyContainer: DependencyResolver, @unchecked Sendable {
    public nonisolated(unsafe) static let shared = DependencyContainer()
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var scopes: [String: DependencyScope] = [:]
    private let queue = DispatchQueue(label: "com.toolkit.di", attributes: .concurrent)
    
    public init() {}
    
    public func register<T>(_ type: T.Type, name: String? = nil, scope: DependencyScope = .singleton, factory: @escaping () -> T) {
        let key = "\\(String(describing: type))_\\(name ?? "default")"
        queue.async(flags: .barrier) {
            self.factories[key] = factory
            self.scopes[key] = scope
        }
    }
    
    public func resolve<T>(_ type: T.Type, name: String? = nil) -> T? {
        let key = "\\(String(describing: type))_\\(name ?? "default")"
        return queue.sync {
            let scope = self.scopes[key] ?? .transient
            if scope == .singleton {
                if let instance = self.singletons[key] as? T { return instance }
                if let factory = self.factories[key], let instance = factory() as? T {
                    self.singletons[key] = instance
                    return instance
                }
            } else {
                return self.factories[key]?() as? T
            }
            return nil
        }
    }
    
    public func override<T>(_ type: T.Type, name: String? = nil, instance: T) {
        let key = "\\(String(describing: type))_\\(name ?? "default")"
        queue.async(flags: .barrier) {
            self.singletons[key] = instance
            self.scopes[key] = .singleton
        }
    }
    
    public func clear() {
        queue.async(flags: .barrier) {
            self.factories.removeAll()
            self.singletons.removeAll()
            self.scopes.removeAll()
        }
    }
}

@propertyWrapper
public struct Inject<T> {
    private var component: T?
    private let name: String?
    
    public init(name: String? = nil) {
        self.name = name
    }
    
    public var wrappedValue: T {
        mutating get {
            if let c = component { return c }
            guard let resolved = DependencyContainer.shared.resolve(T.self, name: name) else {
                fatalError("Dependency \\(T.self) not registered")
            }
            component = resolved
            return resolved
        }
    }
}

// MARK: - Configuration System

public enum Environment { case dev, staging, prod }

public class ConfigManager: @unchecked Sendable {
    public nonisolated(unsafe) static let shared = ConfigManager()
    
    private var config: [String: Any] = [:]
    public var environment: Environment = .prod
    
    public init() {}
    
    public func load(dictionary: [String: Any]) {
        self.config.merge(dictionary) { _, new in new }
    }
    
    public func getValue<T>(_ key: String, defaultValue: T) -> T {
        return config[key] as? T ?? defaultValue
    }
    
    public func isFeatureEnabled(_ key: String) -> Bool {
        return getValue(key, defaultValue: false)
    }
}

// MARK: - Concurrency & Task Management

public actor TaskManager {
    public static let shared = TaskManager()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    public init() {}
    
    public func execute(priority: TaskPriority? = nil, operation: @escaping () async throws -> Void) -> UUID {
        let id = UUID()
        let task = Task(priority: priority) {
            do {
                try await operation()
            } catch {
                Logger.shared.log("Task \\(id) failed: \\(error)", level: .error, file: #file, function: #function, line: #line)
            }
            await self.removeTask(id)
        }
        activeTasks[id] = task
        return id
    }
    
    public func cancelTask(_ id: UUID) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }
    
    private func removeTask(_ id: UUID) {
        activeTasks.removeValue(forKey: id)
    }
}

// MARK: - Event & Lifecycle System

public protocol LifecycleObserver: Sendable {
    func onAppStart()
    func onAppStop()
    func onBackground()
    func onForeground()
}

public actor LifecycleManager {
    public static let shared = LifecycleManager()
    private var observers: [LifecycleObserver] = []
    
    public init() {}
    
    public func register(_ observer: LifecycleObserver) {
        observers.append(observer)
    }
    
    public func broadcastStart() { observers.forEach { $0.onAppStart() } }
    public func broadcastStop() { observers.forEach { $0.onAppStop() } }
    public func broadcastBackground() { observers.forEach { $0.onBackground() } }
    public func broadcastForeground() { observers.forEach { $0.onForeground() } }
}

public struct CoreEvent {
    public let name: String
    public let payload: Any
}

public class CoreEventBus: @unchecked Sendable {
    public nonisolated(unsafe) static let shared = CoreEventBus()
    private let subject = PassthroughSubject<CoreEvent, Never>()
    
    public init() {}
    
    public func publish(name: String, payload: Any = ()) {
        subject.send(CoreEvent(name: name, payload: payload))
    }
    
    public func subscribe(name: String) -> AnyPublisher<CoreEvent, Never> {
        return subject.filter { $0.name == name }.eraseToAnyPublisher()
    }
}

// MARK: - Metrics & Monitoring

public actor MetricsManager {
    public static let shared = MetricsManager()
    private var metrics: [String: [Double]] = [:]
    
    public init() {}
    
    public func recordMetric(name: String, value: Double) {
        var current = metrics[name] ?? []
        current.append(value)
        metrics[name] = current
    }
    
    public func average(for name: String) -> Double {
        let current = metrics[name] ?? []
        guard !current.isEmpty else { return 0 }
        return current.reduce(0, +) / Double(current.count)
    }
}

// MARK: - Plugin Infrastructure Support

public protocol PluginProtocol: Sendable {
    var id: String { get }
    func onLoad()
    func onExecute()
    func onUnload()
}

open class BaseManager {
    public var plugins: [PluginProtocol] = []
    
    public init() {}
    
    public func register(plugin: PluginProtocol) {
        plugins.append(plugin)
        plugin.onLoad()
    }
    
    public func executePlugins() {
        plugins.forEach { $0.onExecute() }
    }
}
"""
write_file("Sources/ToolkitCore/CoreSDK.swift", core_src)

core_tests = """import XCTest
@testable import ToolkitCore

final class CoreTests: XCTestCase {
    func testDependencyInjection() {
        let container = DependencyContainer.shared
        container.clear()
        
        container.register(String.self, name: "API_KEY", scope: .singleton) {
            return "secret_key"
        }
        
        let resolved = container.resolve(String.self, name: "API_KEY")
        XCTAssertEqual(resolved, "secret_key")
        
        container.override(String.self, name: "API_KEY", instance: "mock_key")
        XCTAssertEqual(container.resolve(String.self, name: "API_KEY"), "mock_key")
    }
    
    func testConfigManager() {
        let config = ConfigManager.shared
        config.load(dictionary: ["feature_x": true, "timeout": 30])
        
        XCTAssertTrue(config.isFeatureEnabled("feature_x"))
        XCTAssertEqual(config.getValue("timeout", defaultValue: 0), 30)
    }
    
    func testTaskManager() async {
        let manager = TaskManager.shared
        let exp = expectation(description: "Task executed")
        
        _ = await manager.execute {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func testMetricsManager() async {
        let metrics = MetricsManager.shared
        await metrics.recordMetric(name: "latency", value: 100)
        await metrics.recordMetric(name: "latency", value: 200)
        
        let avg = await metrics.average(for: "latency")
        XCTAssertEqual(avg, 150)
    }
    
    func testErrorHandling() {
        let error = ToolkitError(category: .network, code: 404, message: "Not Found", retryHint: true)
        XCTAssertEqual(error.category, .network)
        XCTAssertTrue(error.retryHint)
    }
}
"""
write_file("Tests/ToolkitCoreTests/CoreTests.swift", core_tests)

print("CoreSDK updated successfully")
