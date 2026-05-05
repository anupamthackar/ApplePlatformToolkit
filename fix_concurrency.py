import os

def write_file(path, content):
    with open(path, 'w') as f:
        f.write(content)

# 1. ToolkitCore
core_src = """import Foundation

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
        print("[\(level)] \\((file as NSString).lastPathComponent):\\(line) - \\(message)")
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
"""
write_file("Sources/ToolkitCore/ToolkitCore.swift", core_src)

# 3. ToolkitCrypto
crypto_src = """import Foundation
import CryptoKit
import ToolkitCore

public final class CryptoManager: @unchecked Sendable {
    public static let shared = CryptoManager()
    
    public init() {}
    
    public func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public func generateRandomKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    public func encryptAES(data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw ToolkitError.unknown
        }
        return combined
    }
    
    public func decryptAES(data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
"""
write_file("Sources/ToolkitCrypto/ToolkitCrypto.swift", crypto_src)

# 5. ToolkitNetworking
net_src = """import Foundation
import Alamofire
import ToolkitCore

public protocol NetworkInterceptor: Sendable {
    func adapt(_ request: URLRequest) -> URLRequest
}

public final class APIClient: @unchecked Sendable {
    public static let shared = APIClient()
    
    private let session: Session
    private var _interceptors: [NetworkInterceptor] = []
    private let lock = NSLock()
    
    public var interceptors: [NetworkInterceptor] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _interceptors
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _interceptors = newValue
        }
    }
    
    public init(session: Session = .default) {
        self.session = session
    }
    
    public func request<T: Decodable>(_ url: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        var req = try URLRequest(url: url, method: method, headers: headers)
        if let params = parameters {
            req = try JSONEncoding.default.encode(req, with: params)
        }
        
        let currentInterceptors = self.interceptors
        for interceptor in currentInterceptors {
            req = interceptor.adapt(req)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(req).validate().responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
"""
write_file("Sources/ToolkitNetworking/ToolkitNetworking.swift", net_src)

# 6. ToolkitAuth
auth_src = """import Foundation
import ToolkitCore
import ToolkitNetworking
import ToolkitCrypto

public final class AuthManager: NetworkInterceptor, @unchecked Sendable {
    public static let shared = AuthManager()
    
    private var accessToken: String?
    private let lock = NSLock()
    
    public init() {}
    
    public func setAccessToken(_ token: String) {
        lock.lock()
        defer { lock.unlock() }
        self.accessToken = token
    }
    
    public func getAccessToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return accessToken
    }
    
    public func adapt(_ request: URLRequest) -> URLRequest {
        var req = request
        lock.lock()
        let token = accessToken
        lock.unlock()
        if let token = token {
            req.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}
"""
write_file("Sources/ToolkitAuth/ToolkitAuth.swift", auth_src)

# 8. ToolkitPlugins
plug_src = """import Foundation
import ToolkitCore

public protocol PluginProtocol: Sendable {
    var id: String { get }
    func onLoad()
    func onExecute()
    func onUnload()
}

public final class PluginRegistry: @unchecked Sendable {
    public static let shared = PluginRegistry()
    private var plugins: [String: PluginProtocol] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func register(_ plugin: PluginProtocol) {
        lock.lock()
        plugins[plugin.id] = plugin
        lock.unlock()
        plugin.onLoad()
    }
    
    public func unregister(id: String) {
        lock.lock()
        let plugin = plugins.removeValue(forKey: id)
        lock.unlock()
        plugin?.onUnload()
    }
    
    public func executeAll() {
        lock.lock()
        let currentPlugins = plugins.values
        lock.unlock()
        currentPlugins.forEach { $0.onExecute() }
    }
}
"""
write_file("Sources/ToolkitPlugins/ToolkitPlugins.swift", plug_src)

print("Updated concurrency fixes!")
