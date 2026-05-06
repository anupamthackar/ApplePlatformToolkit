import Foundation

// MARK: - Network Interceptor Documentation

/**
 # NetworkInterceptor
 
 A protocol for objects that can modify outgoing `URLRequest`s and decide whether failed
 requests should be retried. Interceptors are executed in a chain.
 
 ## Usage
 ```swift
 struct MyInterceptor: NetworkInterceptor {
     func adapt(_ request: inout URLRequest) async throws {
         request.setValue("my-value", forHTTPHeaderField: "X-My-Header")
     }
     
     func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool {
         return attempt < 2 // Retry once
     }
 }
 ```
 */
public protocol NetworkInterceptor: Sendable {
    /**
     Modifies the outgoing request before it is sent to the network.
     - Parameter request: The request to adapt.
     - Throws: If adaptation fails (e.g., token expired and can't refresh).
     */
    func adapt(_ request: inout URLRequest) async throws
    
    /**
     Called when a request fails to determine if it should be tried again.
     - Parameters:
        - request: The original request.
        - response: The HTTP response if one was received.
        - error: The error that occurred.
        - attempt: The current attempt number (0-indexed).
     - Returns: `true` to retry the request, `false` to propagate the error.
     */
    func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool
}

// MARK: - Auth Token Interceptor

/**
 Automatically injects an Authorization Bearer token into every outgoing request.
 */
public struct AuthTokenInterceptor: NetworkInterceptor {
    private let tokenProvider: @Sendable () -> String?

    /**
     Initializes the interceptor with a closure that returns the current token.
     */
    public init(tokenProvider: @escaping @Sendable () -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func adapt(_ request: inout URLRequest) async throws {
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    public func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool {
        return false
    }
}

// MARK: - Logging Interceptor

/**
 Logs basic request and response metadata for debugging purposes.
 */
public struct LoggingInterceptor: NetworkInterceptor {
    public init() {}

    public func adapt(_ request: inout URLRequest) async throws {
        print("[ToolkitNetworking] → \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")")
    }

    public func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool {
        print("[ToolkitNetworking] ← Error: \(error.localizedDescription) (attempt \(attempt))")
        return false
    }
}

// MARK: - Default Headers Interceptor

/**
 Injects a static dictionary of headers into every request.
 Won't overwrite headers already set on the request.
 */
public struct DefaultHeadersInterceptor: NetworkInterceptor {
    private let headers: [String: String]

    public init(headers: [String: String]) {
        self.headers = headers
    }

    public func adapt(_ request: inout URLRequest) async throws {
        for (key, value) in headers where request.value(forHTTPHeaderField: key) == nil {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    public func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool {
        return false
    }
}

// MARK: - Retry Interceptor

/**
 Evaluates retry logic based on the provided `RetryPolicy`.
 */
public struct RetryInterceptor: NetworkInterceptor {
    private let policy: RetryPolicy

    public init(policy: RetryPolicy) { self.policy = policy }

    public func adapt(_ request: inout URLRequest) async throws {}

    public func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, attempt: Int) -> Bool {
        guard attempt < policy.maxAttempts else { return false }
        if let httpResponse = response {
            return policy.retryableCodes.contains(httpResponse.statusCode)
        }
        return true // Network-level errors (timeout, no connection) usually deserve a retry
    }
}
