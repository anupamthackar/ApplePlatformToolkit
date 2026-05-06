import Foundation
import Combine
public enum Toolkit {}

// MARK: - Error Handling Documentation

/**
 # ToolkitError
 
 A standardized error structure for the entire SDK.
 Provides category-based grouping, numeric codes, and user-friendly messages.
 
 ## Usage
 ```swift
 throw ToolkitError(category: .network, code: 404, message: "Resource not found")
 ```
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

// MARK: - Logging System Documentation

/**
 # Logger
 
 A thread-safe, multi-destination logging system.
 Supports levels, metadata, and asynchronous writing to console or remote targets.
 
 ## Usage
 ```swift
 Logger.shared.addMetadata("session_id", value: "xyz-123")
 Logger.shared.log("User logged in", level: .info)
 ```
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

// MARK: - Dependency Injection Documentation

/**
 # DependencyContainer
 
 A simple, thread-safe DI container supporting singletons and transient instances.
 
 ## Usage
 ```swift
 // Register
 DependencyContainer.shared.register(MyService.self) { MyServiceImpl() }
 
 // Resolve
 let service = DependencyContainer.shared.resolve(MyService.self)
 
 // Property Wrapper
 @Inject var service: MyService
 ```
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

// MARK: - Task Management Documentation

/**
 # TaskManager
 
 An actor-based manager for tracking and cancelling background tasks.
 
 ## Usage
 ```swift
 let taskID = await TaskManager.shared.execute {
     try await someLongRunningOperation()
 }
 
 await TaskManager.shared.cancelTask(taskID)
 ```
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

// MARK: - Lifecycle Documentation

/**
 # LifecycleManager
 
 Notifies registered observers about application lifecycle changes.
 */
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

public enum Environment: Sendable { case dev, staging, prod }

public final class ConfigManager: @unchecked Sendable {
    public static let shared = ConfigManager()
    
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

// MARK: - Internal Infrastucture

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

public protocol LogDestination: Sendable { func write(_ message: String) }
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
