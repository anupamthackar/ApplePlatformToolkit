import Foundation
import Alamofire
import ToolkitCore

// MARK: - API Client Protocol Documentation

/**
 # APIClientProtocol
 
 A protocol-oriented interface for the Networking layer.
 This allows for easy mocking in unit tests and interchangeable implementations.
 */
public protocol APIClientProtocol: Sendable {
    /**
     Executes a request and decodes the response into a specified model.
     - Parameters:
        - request: The configured `URLRequest`.
        - decoding: The `Decodable` type to parse into.
     - Returns: A `NetworkResponse` containing the model and metadata.
     - Throws: `NetworkError` if connection, decoding, or circuit breaker fails.
     */
    func execute<T: Decodable & Sendable>(_ request: URLRequest, decoding: T.Type) async throws -> NetworkResponse<T>
    
    /**
     Executes a request and returns the raw binary response.
     */
    func executeRaw(_ request: URLRequest) async throws -> (Data, Int)
    
    /**
     Downloads a file from a remote URL to a local destination.
     */
    func download(from url: URL, to destination: URL) async throws
    
    /**
     Uploads binary data to a remote endpoint.
     */
    func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data>
}

// MARK: - API Client Documentation

/**
 # APIClient
 
 The primary networking client for the Apple Platform Toolkit.
 Built on top of `URLSession` with features like:
 - **Interceptors**: Chainable request modification and retry logic.
 - **Circuit Breaker**: Automatic short-circuiting of failing hosts.
 - **Caching**: In-memory and disk caching with TTL.
 - **Swift Concurrency**: Fully async/await native.
 
 ## Usage
 ```swift
 let client = APIClient.shared
 let request = RequestBuilder(url: "https://api.example.com/v1/users")
     .method(.get)
     .build()
 
 let response = try await client.execute(request, decoding: User.self)
 print("Got user: \(response.value.name)")
 ```
 */
public final class APIClient: APIClientProtocol, @unchecked Sendable {

    // MARK: - Singleton

    /// The shared global networking client.
    public static let shared = APIClient()

    // MARK: - Dependencies

    /// The active network configuration.
    public let config: NetworkConfig
    /// The chain of interceptors that process every request.
    public private(set) var interceptors: [NetworkInterceptor]
    /// The circuit breaker monitoring endpoint health.
    public let circuitBreaker: CircuitBreaker
    private let cache: NetworkCache
    private let decoder: JSONDecoder

    // MARK: - Init

    /**
     Initializes a new APIClient.
     - Parameters:
        - config: Global networking settings.
        - interceptors: Custom interceptors to add to the chain.
        - circuitBreaker: A circuit breaker instance.
        - cache: A caching engine.
     */
    public init(
        config: NetworkConfig = NetworkConfig(),
        interceptors: [NetworkInterceptor] = [],
        circuitBreaker: CircuitBreaker = CircuitBreaker(),
        cache: NetworkCache = .shared
    ) {
        self.config = config
        self.circuitBreaker = circuitBreaker
        self.cache = cache

        // Build default interceptor chain
        var allInterceptors = [NetworkInterceptor]()
        if config.loggingEnabled { allInterceptors.append(LoggingInterceptor()) }
        allInterceptors.append(DefaultHeadersInterceptor(headers: config.defaultHeaders))
        allInterceptors.append(RetryInterceptor(policy: config.retryPolicy))
        allInterceptors.append(contentsOf: interceptors)
        self.interceptors = allInterceptors

        // Configure Decoder
        let dec = JSONDecoder()
        if config.decoderStrategy == .snakeCase {
            dec.keyDecodingStrategy = .convertFromSnakeCase
        }
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Management

    /// Dynamically appends a new interceptor to the end of the chain.
    public func addInterceptor(_ interceptor: NetworkInterceptor) {
        interceptors.append(interceptor)
    }

    // MARK: - Execution (Decodable)

    public func execute<T: Decodable & Sendable>(_ request: URLRequest, decoding: T.Type) async throws -> NetworkResponse<T> {
        guard circuitBreaker.canExecute() else { throw NetworkError.circuitOpen }

        var adaptedRequest = request
        for interceptor in interceptors {
            try await interceptor.adapt(&adaptedRequest)
        }

        // Check cache
        let cacheKey = request.url?.absoluteString ?? UUID().uuidString
        if config.cachePolicy != .ignore {
            if let cachedData = cache.get(key: cacheKey) {
                let value = try decoder.decode(T.self, from: cachedData)
                return NetworkResponse(value: value, statusCode: 200, headers: [:], latency: 0, requestURL: cacheKey)
            }
        }

        let start = Date()
        do {
            let (data, response) = try await executeWithRetry(adaptedRequest)
            let latency = Date().timeIntervalSince(start)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 200
            let headers = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]
            
            circuitBreaker.recordSuccess()

            // Cache successful responses
            if config.cachePolicy != .ignore && statusCode >= 200 && statusCode < 300 {
                cache.set(key: cacheKey, data: data)
            }

            guard let decoded = try? decoder.decode(T.self, from: data) else {
                throw NetworkError.decodingFailed("Failed to decode \(T.self)")
            }
            return NetworkResponse(value: decoded, statusCode: statusCode, headers: headers, latency: latency, requestURL: cacheKey)
        } catch {
            circuitBreaker.recordFailure()
            throw NetworkError.underlying(error)
        }
    }

    // MARK: - Execution (Raw Data)

    public func executeRaw(_ request: URLRequest) async throws -> (Data, Int) {
        guard circuitBreaker.canExecute() else { throw NetworkError.circuitOpen }
        var adapted = request
        for interceptor in interceptors { try await interceptor.adapt(&adapted) }
        let (data, response) = try await executeWithRetry(adapted)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (data, code)
    }

    // MARK: - Download/Upload

    public func download(from url: URL, to destination: URL) async throws {
        let (tmpURL, _) = try await URLSession.shared.download(from: url)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tmpURL, to: destination)
    }

    public func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data> {
        let start = Date()
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        let latency = Date().timeIntervalSince(start)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        return NetworkResponse(value: responseData, statusCode: code, headers: [:], latency: latency, requestURL: request.url?.absoluteString ?? "")
    }

    // MARK: - Cache Control

    /// Wipes the entire in-memory cache.
    public func clearCache() { cache.clear() }
    
    /// Invalidates a specific URL from the cache.
    public func invalidateCache(for url: String) { cache.invalidate(key: url) }

    // MARK: - Private

    private func executeWithRetry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error = NetworkError.cancelled
        for attempt in 0..<max(1, config.retryPolicy.maxAttempts) {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 200
                
                // Evaluate interceptors for retry on specific status codes
                let shouldRetry = interceptors.contains { $0.shouldRetry(request: request, response: response as? HTTPURLResponse, error: NetworkError.cancelled, attempt: attempt) }
                
                if shouldRetry {
                    let delay = config.retryPolicy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                return (data, response)
            } catch {
                lastError = error
                let shouldRetry = interceptors.contains { $0.shouldRetry(request: request, response: nil, error: error, attempt: attempt) }
                if !shouldRetry { break }
                let delay = config.retryPolicy.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        throw lastError
    }
}

// MARK: - Mock API Client Documentation

/**
 A mock implementation of `APIClientProtocol` for use in unit tests.
 */
public final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    public var stubbedData: Data = Data()
    public var stubbedStatusCode: Int = 200
    public var shouldThrow: Bool = false
    public var thrownError: Error = NetworkError.noConnection

    public init() {}

    public func execute<T: Decodable & Sendable>(_ request: URLRequest, decoding: T.Type) async throws -> NetworkResponse<T> {
        if shouldThrow { throw thrownError }
        let value = try JSONDecoder().decode(T.self, from: stubbedData)
        return NetworkResponse(value: value, statusCode: stubbedStatusCode, headers: [:], latency: 0.01, requestURL: request.url?.absoluteString ?? "")
    }

    public func executeRaw(_ request: URLRequest) async throws -> (Data, Int) {
        if shouldThrow { throw thrownError }
        return (stubbedData, stubbedStatusCode)
    }

    public func download(from url: URL, to destination: URL) async throws {}
    public func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data> {
        NetworkResponse(value: data, statusCode: 200, headers: [:], latency: 0, requestURL: "")
    }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitNetworking module.
    static var networking: APIClient { APIClient.shared }
}
