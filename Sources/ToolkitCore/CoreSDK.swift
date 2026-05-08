import Foundation
import Combine

/// The main namespace for the Apple Platform Toolkit.
public enum Toolkit {}

// MARK: - Error Handling

/**
 # ToolkitError
 
 A standardized error structure used across all modules of the SDK.
 It provides category-based grouping, numeric codes, and user-friendly messages for consistent error handling.
 */
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

public protocol ToolkitErrorProtocol: Error, Sendable {
    var category: ErrorCategory { get }
    var code: Int { get }
    var message: String { get }
    var underlyingError: Error? { get }
    var retryHint: Bool { get }
}

public enum ErrorCategory: Sendable {
    case network, auth, crypto, system, validation, unknown
}

// MARK: - Logging System

/**
 # Logger
 
 A thread-safe, high-performance logging system that supports multiple destinations and rich metadata.
 */
public final class Logger: LoggerProtocol, @unchecked Sendable {
    public static let shared = Logger()
    private let asyncLogger = DefaultLogger.shared
    public init() {}
    
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        asyncLogger.log(message, level: level, file: file, function: function, line: line)
    }
    
    public func addMetadata(_ key: String, value: String) {
        asyncLogger.addMetadata(key, value: value)
    }
}

public protocol LoggerProtocol: Sendable {
    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int)
    func addMetadata(_ key: String, value: String)
}

public enum LogLevel: Int, Sendable {
    case debug, info, warning, error, critical
}

// MARK: - Dependency Injection

/**
 # DependencyContainer
 
 A lightweight, thread-safe dependency injection container.
 */
public final class DependencyContainer: DependencyResolver, @unchecked Sendable {
    public static let shared = DependencyContainer()
    private var factories: [String: @Sendable () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var scopes: [String: DependencyScope] = [:]
    private let queue = DispatchQueue(label: "com.toolkit.di", attributes: .concurrent)
    public init() {}
    
    public func register<T>(_ type: T.Type, name: String? = nil, scope: DependencyScope = .singleton, factory: @escaping @Sendable () -> T) {
        let key = "\(String(describing: type))_\(name ?? "default")"
        queue.async(flags: .barrier) {
            self.factories[key] = factory
            self.scopes[key] = scope
        }
    }
    
    public func resolve<T>(_ type: T.Type, name: String? = nil) -> T? {
        let key = "\(String(describing: type))_\(name ?? "default")"
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

    public func override<T: Sendable>(_ type: T.Type, name: String? = nil, instance: T) {
        let key = "\(String(describing: type))_\(name ?? "default")"
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

/**
 # Inject
 
 A property wrapper for seamless dependency injection.
 */
@propertyWrapper
public struct Inject<T> {
    private var component: T?
    private let name: String?
    public init(name: String? = nil) { self.name = name }
    public var wrappedValue: T {
        mutating get {
            if let c = component { return c }
            guard let resolved = DependencyContainer.shared.resolve(T.self, name: name) else {
                fatalError("Dependency \(T.self) not registered")
            }
            component = resolved
            return resolved
        }
    }
}

public protocol DependencyResolver: Sendable {
    func resolve<T>(_ type: T.Type, name: String?) -> T?
}

public enum DependencyScope: Sendable {
    case singleton, transient, scoped
}

// MARK: - Task Management

/**
 # TaskManager
 
 An actor-based manager for executing, tracking, and cancelling asynchronous background tasks.
 */
public actor TaskManager {
    public static let shared = TaskManager()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    public init() {}
    public func execute(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Void) -> UUID {
        let id = UUID()
        let task = Task(priority: priority) {
            do {
                try await operation()
            } catch {
                Logger.shared.log("Task \(id) failed: \(error)", level: .error)
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
    private func removeTask(_ id: UUID) { activeTasks.removeValue(forKey: id) }
}

// MARK: - Lifecycle Management

public actor LifecycleManager {
    public static let shared = LifecycleManager()
    private var observers: [LifecycleObserver] = []
    public init() {}
    public func register(_ observer: LifecycleObserver) { observers.append(observer) }
    public func broadcastStart() { observers.forEach { $0.onAppStart() } }
    public func broadcastStop() { observers.forEach { $0.onAppStop() } }
    public func broadcastBackground() { observers.forEach { $0.onBackground() } }
    public func broadcastForeground() { observers.forEach { $0.onForeground() } }
}

// MARK: - Configuration System

public enum ToolkitEnvironment: Sendable { 
    case dev, staging, prod 
}

public final class ConfigManager: @unchecked Sendable {
    public static let shared = ConfigManager()
    private var config: [String: Any] = [:]
    public var environment: ToolkitEnvironment = .prod
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

public protocol LifecycleObserver: Sendable {
    func onAppStart()
    func onAppStop()
    func onBackground()
    func onForeground()
}

// MARK: - Internal Infrastructure

public final class DefaultLogger: LoggerProtocol, @unchecked Sendable {
    public static let shared = DefaultLogger()
    private var metadata: [String: String] = [:]
    private var logDestinations: [LogDestination] = [ConsoleLogDestination()]
    private let queue = DispatchQueue(label: "com.toolkit.logger", attributes: .concurrent)
    public init() {}
    public func addMetadata(_ key: String, value: String) {
        queue.async(flags: .barrier) { self.metadata[key] = value }
    }
    public func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        queue.async {
            let metaString = self.metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            let formatted = "[\(level)] \(URL(fileURLWithPath: file).lastPathComponent):\(line) - \(message) | \(metaString)"
            for dest in self.logDestinations { dest.write(formatted) }
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

public protocol PluginProtocol: Sendable {
    var id: String { get }
    func onLoad()
    func onExecute()
    func onUnload()
}

open class BaseManager: @unchecked Sendable {
    public var plugins: [PluginProtocol] = []
    public init() {}
    public func register(plugin: PluginProtocol) {
        plugins.append(plugin)
        plugin.onLoad()
    }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitCore module.
    static var core: CoreAccess { CoreAccess() }
}

/**
 # CoreAccess
 
 Provides unified, professional access to core foundation services.
 */
public struct CoreAccess: Sendable {
    /// Access the global logging system.
    public var logger: Logger { Logger.shared }
    /// Access the dependency injection container.
    public var dependencyContainer: DependencyContainer { DependencyContainer.shared }
    /// Access the asynchronous task manager.
    public var taskManager: TaskManager { TaskManager.shared }
    /// Access the application lifecycle events.
    public var lifecycleManager: LifecycleManager { LifecycleManager.shared }
    /// Access global configuration and feature flags.
    public var config: ConfigManager { ConfigManager.shared }
    /// Access performance metrics and monitoring.
    public var metrics: MetricsManager { MetricsManager.shared }
}
