import Foundation

public enum LogLevel: Int, Sendable {
    case debug, info, warning, error
}

public protocol LoggerProtocol: Sendable {
    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int)
}

public final class Logger: LoggerProtocol, @unchecked Sendable {
    public static let shared = Logger()
    private let lock = NSLock()
    
    public init() {}
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        lock.lock()
        defer { lock.unlock() }
        print("[\(level)] \((file as NSString).lastPathComponent):\(line) - \(message)")
    }
}

public protocol ErrorMapping: Sendable {
    var mappedError: Error { get }
}

public enum ToolkitError: Error, ErrorMapping, Sendable {
    case unknown
    case notFound
    case invalidConfiguration
    
    public var mappedError: Error { self }
}

public protocol DependencyResolver: Sendable {
    func resolve<T>(_ type: T.Type) -> T?
}

public final class DependencyContainer: DependencyResolver, @unchecked Sendable {
    public static let shared = DependencyContainer()
    private var dependencies: [String: Any] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func register<T>(_ type: T.Type, dependency: Any) {
        lock.lock()
        defer { lock.unlock() }
        dependencies[String(describing: type)] = dependency
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return dependencies[String(describing: type)] as? T
    }
}

public final class ConfigurationManager: @unchecked Sendable {
    public static let shared = ConfigurationManager()
    private var config: [String: String] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func set(_ value: String, forKey key: String) { 
        lock.lock()
        defer { lock.unlock() }
        config[key] = value 
    }
    public func get(_ key: String) -> String? { 
        lock.lock()
        defer { lock.unlock() }
        return config[key] 
    }
}
