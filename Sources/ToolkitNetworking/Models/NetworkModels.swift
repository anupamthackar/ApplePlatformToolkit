import Foundation

// MARK: - NetworkError

public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL(String)
    case requestFailed(Int, Data?)
    case decodingFailed(String)
    case timeout
    case noConnection
    case circuitOpen
    case cancelled
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):        return "Invalid URL: \(url)"
        case .requestFailed(let code, _): return "Request failed with status \(code)"
        case .decodingFailed(let r):      return "Decoding failed: \(r)"
        case .timeout:                    return "Request timed out"
        case .noConnection:               return "No network connection"
        case .circuitOpen:                return "Circuit breaker is open"
        case .cancelled:                  return "Request was cancelled"
        case .underlying(let e):          return "Underlying error: \(e.localizedDescription)"
        }
    }
}

// MARK: - NetworkResponse

public struct NetworkResponse<T: Sendable>: Sendable {
    public let value: T
    public let statusCode: Int
    public let headers: [String: String]
    public let latency: TimeInterval
    public let requestURL: String
}

// MARK: - HTTPMethod

public enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE", patch = "PATCH", head = "HEAD"
}
