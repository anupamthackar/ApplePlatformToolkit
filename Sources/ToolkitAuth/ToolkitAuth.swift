import Foundation
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
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}
