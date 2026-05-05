import Foundation
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
    
    public func request<T: Decodable & Sendable>(_ url: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
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
