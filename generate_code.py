import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)

# 1. ToolkitCore
core_src = """import Foundation

public enum LogLevel: Int {
    case debug, info, warning, error
}

public protocol LoggerProtocol {
    func log(_ message: String, level: LogLevel, file: String, function: String, line: Int)
}

public class Logger: LoggerProtocol {
    public static let shared = Logger()
    public init() {}
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        print("[\(level)] \\((file as NSString).lastPathComponent):\\(line) - \\(message)")
    }
}

public protocol ErrorMapping {
    var mappedError: Error { get }
}

public enum ToolkitError: Error, ErrorMapping {
    case unknown
    case notFound
    case invalidConfiguration
    
    public var mappedError: Error { self }
}

public protocol DependencyResolver {
    func resolve<T>(_ type: T.Type) -> T?
}

public class DependencyContainer: DependencyResolver {
    public static let shared = DependencyContainer()
    private var dependencies: [String: Any] = [:]
    
    public init() {}
    
    public func register<T>(_ type: T.Type, dependency: Any) {
        dependencies[String(describing: type)] = dependency
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        return dependencies[String(describing: type)] as? T
    }
}

public class ConfigurationManager {
    public static let shared = ConfigurationManager()
    private var config: [String: String] = [:]
    
    public init() {}
    
    public func set(_ value: String, forKey key: String) { config[key] = value }
    public func get(_ key: String) -> String? { return config[key] }
}
"""
write_file("Sources/ToolkitCore/ToolkitCore.swift", core_src)

# 2. ToolkitUtility
util_src = """import Foundation

public struct TKNamespace<Base> {
    public let base: Base
    public init(_ base: Base) { self.base = base }
}

public protocol TKCompatible {
    associatedtype TKBase
    var tk: TKNamespace<TKBase> { get }
}

extension TKCompatible {
    public var tk: TKNamespace<Self> { return TKNamespace(self) }
}

extension String: TKCompatible {}
extension String {
    public var tk: TKNamespace<String> { return TKNamespace(self) }
}

extension TKNamespace where Base == String {
    public var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: base)
    }
}

extension Date: TKCompatible {}
extension TKNamespace where Base == Date {
    public func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: base)
    }
}

extension Data: TKCompatible {}
extension TKNamespace where Base == Data {
    public var hexString: String {
        return base.map { String(format: "%02hhx", $0) }.joined()
    }
}

public class Formatters {
    public static func currencyFormatter(locale: Locale = .current) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter
    }
}
"""
write_file("Sources/ToolkitUtility/ToolkitUtility.swift", util_src)

# 3. ToolkitCrypto
crypto_src = """import Foundation
import CryptoKit
import ToolkitCore

public class CryptoManager {
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

# 4. ToolkitCompression
comp_src = """import Foundation
import Compression

public class CompressionManager {
    public init() {}
    
    public func compress(_ data: Data) -> Data? {
        let destinationBufferSize = data.count
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }
        
        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_encode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
        }
        
        if compressedSize == 0 { return nil }
        return Data(bytes: destinationBuffer, count: compressedSize)
    }
    
    public func decompress(_ data: Data) -> Data? {
        let destinationBufferSize = data.count * 4
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }
        
        let decompressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
        }
        
        if decompressedSize == 0 { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}
"""
write_file("Sources/ToolkitCompression/ToolkitCompression.swift", comp_src)

# 5. ToolkitNetworking
net_src = """import Foundation
import Alamofire
import ToolkitCore

public protocol NetworkInterceptor {
    func adapt(_ request: URLRequest) -> URLRequest
}

public class APIClient {
    public static let shared = APIClient()
    
    private let session: Session
    public var interceptors: [NetworkInterceptor] = []
    
    public init(session: Session = .default) {
        self.session = session
    }
    
    public func request<T: Decodable>(_ url: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        var req = try URLRequest(url: url, method: method, headers: headers)
        if let params = parameters {
            req = try JSONEncoding.default.encode(req, with: params)
        }
        
        for interceptor in interceptors {
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

public class AuthManager: NetworkInterceptor {
    public static let shared = AuthManager()
    
    private var accessToken: String?
    
    public init() {}
    
    public func setAccessToken(_ token: String) {
        self.accessToken = token
    }
    
    public func getAccessToken() -> String? {
        return accessToken
    }
    
    public func adapt(_ request: URLRequest) -> URLRequest {
        var req = request
        if let token = accessToken {
            req.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}
"""
write_file("Sources/ToolkitAuth/ToolkitAuth.swift", auth_src)

# 7. ToolkitUI
ui_src = """import SwiftUI
import ToolkitCore
import ToolkitAuth

public struct ToolkitUI {
    public static func configure() {
        Logger.shared.log("ToolkitUI configured")
    }
}

public struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    public init() {}
    
    public var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Login") {
                // Perform login
                AuthManager.shared.setAccessToken("sample_token")
            }
            .padding()
        }
    }
}
"""
write_file("Sources/ToolkitUI/ToolkitUI.swift", ui_src)

# 8. ToolkitPlugins
plug_src = """import Foundation
import ToolkitCore

public protocol PluginProtocol {
    var id: String { get }
    func onLoad()
    func onExecute()
    func onUnload()
}

public class PluginRegistry {
    public static let shared = PluginRegistry()
    private var plugins: [String: PluginProtocol] = [:]
    
    public init() {}
    
    public func register(_ plugin: PluginProtocol) {
        plugins[plugin.id] = plugin
        plugin.onLoad()
    }
    
    public func unregister(id: String) {
        plugins[id]?.onUnload()
        plugins.removeValue(forKey: id)
    }
    
    public func executeAll() {
        plugins.values.forEach { $0.onExecute() }
    }
}
"""
write_file("Sources/ToolkitPlugins/ToolkitPlugins.swift", plug_src)

# 9. ToolkitAll
all_src = """@_exported import ToolkitCore
@_exported import ToolkitUtility
@_exported import ToolkitCrypto
@_exported import ToolkitCompression
@_exported import ToolkitNetworking
@_exported import ToolkitAuth
@_exported import ToolkitUI
@_exported import ToolkitPlugins
"""
write_file("Sources/ToolkitAll/ToolkitAll.swift", all_src)

# Tests
core_test = """import XCTest
@testable import ToolkitCore

final class DependencyContainerTests: XCTestCase {
    func testDependencyRegistration() {
        let container = DependencyContainer()
        let config = ConfigurationManager()
        container.register(ConfigurationManager.self, dependency: config)
        let resolved = container.resolve(ConfigurationManager.self)
        XCTAssertNotNil(resolved)
    }
}
"""
write_file("Tests/ToolkitCoreTests/DependencyContainerTests.swift", core_test)

util_test = """import XCTest
@testable import ToolkitUtility

final class StringExtensionTests: XCTestCase {
    func testEmailValidation() {
        XCTAssertTrue("test@example.com".tk.isValidEmail)
        XCTAssertFalse("invalid-email".tk.isValidEmail)
    }
}
"""
write_file("Tests/ToolkitUtilityTests/StringExtensionTests.swift", util_test)

crypto_test = """import XCTest
@testable import ToolkitCrypto

final class HashingTests: XCTestCase {
    func testSHA256() {
        let manager = CryptoManager()
        let data = "hello".data(using: .utf8)!
        let hash = manager.sha256(data)
        XCTAssertEqual(hash.count, 64)
    }
}
"""
write_file("Tests/ToolkitCryptoTests/HashingTests.swift", crypto_test)

net_test = """import XCTest
@testable import ToolkitNetworking

final class APIClientTests: XCTestCase {
    func testInit() {
        let client = APIClient()
        XCTAssertNotNil(client)
    }
}
"""
write_file("Tests/ToolkitNetworkingTests/APIClientTests.swift", net_test)

auth_test = """import XCTest
@testable import ToolkitAuth

final class AuthManagerTests: XCTestCase {
    func testTokenManagement() {
        let manager = AuthManager()
        manager.setAccessToken("test_token")
        XCTAssertEqual(manager.getAccessToken(), "test_token")
    }
}
"""
write_file("Tests/ToolkitAuthTests/AuthManagerTests.swift", auth_test)

ui_test = """import XCTest
@testable import ToolkitUI

final class ToolkitUITests: XCTestCase {
    func testUIConfig() {
        ToolkitUI.configure()
    }
}
"""
write_file("Tests/ToolkitUITests/ToolkitUITests.swift", ui_test)

plug_test = """import XCTest
@testable import ToolkitPlugins

class MockPlugin: PluginProtocol {
    var id: String = "MockPlugin"
    var isLoaded = false
    func onLoad() { isLoaded = true }
    func onExecute() {}
    func onUnload() { isLoaded = false }
}

final class PluginRegistryTests: XCTestCase {
    func testPluginLifecycle() {
        let registry = PluginRegistry()
        let plugin = MockPlugin()
        registry.register(plugin)
        XCTAssertTrue(plugin.isLoaded)
        registry.unregister(id: plugin.id)
        XCTAssertFalse(plugin.isLoaded)
    }
}
"""
write_file("Tests/ToolkitPluginsTests/PluginRegistryTests.swift", plug_test)

print("All files created successfully!")
