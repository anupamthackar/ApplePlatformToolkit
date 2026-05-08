import Foundation
import Alamofire
import ToolkitCore

// MARK: - API Client Protocol

/**
 # APIClientProtocol
 
 A protocol-oriented interface for the Networking layer.
 This allows for easy mocking in unit tests and interchangeable implementations.
 
 ## Conformance
 - `APIClient`: The production implementation.
 - `MockAPIClient`: The testing implementation.
 */
public protocol APIClientProtocol: Sendable {
    /**
     Executes a request and decodes the response into a specified model.
     
     - Parameters:
        - request: The configured `URLRequest`.
        - decoding: The `Decodable` type to parse into.
     - Returns: A `NetworkResponse` containing the model and metadata.
     - Throws: `NetworkError` if connection, decoding, or circuit breaker fails.
     
     ## Example
     ```swift
     let user = try await client.execute(request, decoding: User.self)
     ```
     */
    func execute<T: Decodable & Sendable>(_ request: URLRequest, decoding: T.Type) async throws -> NetworkResponse<T>
    
    /**
     Executes a request and returns the raw binary response and status code.
     
     - Parameter request: The configured `URLRequest`.
     - Returns: A tuple containing the response `Data` and the HTTP status code.
     - Throws: `NetworkError` if the request fails.
     */
    func executeRaw(_ request: URLRequest) async throws -> (Data, Int)
    
    /**
     Downloads a file from a remote URL to a local destination.
     
     - Parameters:
        - url: The source URL of the file.
        - destination: The local file system URL where the file should be saved.
     - Throws: `Error` if the download or file move fails.
     */
    func download(from url: URL, to destination: URL) async throws
    
    /**
     Uploads binary data to a remote endpoint.
     
     - Parameters:
        - data: The binary data to upload.
        - request: The configured `URLRequest`.
     - Returns: A `NetworkResponse` containing the response body as `Data`.
     - Throws: `Error` if the upload fails.
     */
    func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data>
}

// MARK: - API Client

/**
 # APIClient
 
 The primary networking client for the Apple Platform Toolkit.
 Built on top of `URLSession` with enterprise-grade features:
 
 - **Interceptors**: Chainable request modification (e.g., Auth, Logging).
 - **Circuit Breaker**: Automatic protection against failing endpoints.
 - **Retry Policy**: Configurable exponential backoff and jitter.
 - **Caching**: In-memory and disk caching support.
 - **Swift Concurrency**: 100% async/await native.
 
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

    /// The active network configuration including timeout, cache policy, and retry settings.
    public let config: NetworkConfig
    
    /// The chain of interceptors that process every request before it is sent.
    public private(set) var interceptors: [NetworkInterceptor]
    
    /// The circuit breaker monitoring endpoint health to prevent cascading failures.
    public let circuitBreaker: CircuitBreaker
    
    private let cache: NetworkCache
    private let decoder: JSONDecoder

    // MARK: - Init

    /**
     Initializes a new APIClient with custom configuration and components.
     
     - Parameters:
        - config: Global networking settings. Defaults to `NetworkConfig()`.
        - interceptors: Custom interceptors to add to the chain.
        - circuitBreaker: A circuit breaker instance. Defaults to a new instance.
        - cache: A caching engine. Defaults to the shared cache.
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

    /// Dynamically appends a new interceptor to the end of the execution chain.
    /// - Parameter interceptor: The interceptor to add.
    public func addInterceptor(_ interceptor: NetworkInterceptor) {
        interceptors.append(interceptor)
    }

    // MARK: - Execution (Decodable)

    /// Executes a request and decodes the response into a specified model.
    /// - Parameters:
    ///   - request: The `URLRequest` to execute.
    ///   - decoding: The type of the model to decode.
    /// - Returns: A parsed `NetworkResponse`.
    /// - Throws: `NetworkError` if the operation fails.
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

    /// Executes a request and returns the raw binary response.
    /// - Parameter request: The `URLRequest` to execute.
    /// - Returns: A tuple with the data and HTTP status code.
    /// - Throws: `NetworkError` if the operation fails.
    public func executeRaw(_ request: URLRequest) async throws -> (Data, Int) {
        guard circuitBreaker.canExecute() else { throw NetworkError.circuitOpen }
        var adapted = request
        for interceptor in interceptors { try await interceptor.adapt(&adapted) }
        let (data, response) = try await executeWithRetry(adapted)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (data, code)
    }

    // MARK: - Download/Upload

    /// Downloads a file to a specific local path.
    /// - Parameters:
    ///   - url: Remote file URL.
    ///   - destination: Local path to save the file.
    /// - Throws: `Error` if the download or move fails.
    public func download(from url: URL, to destination: URL) async throws {
        let (tmpURL, _) = try await URLSession.shared.download(from: url)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tmpURL, to: destination)
    }

    /// Uploads data to a specific endpoint.
    /// - Parameters:
    ///   - data: Binary data to upload.
    ///   - request: The `URLRequest` target.
    /// - Returns: A response containing the server's reply data.
    /// - Throws: `Error` if the upload fails.
    public func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data> {
        let start = Date()
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        let latency = Date().timeIntervalSince(start)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        return NetworkResponse(value: responseData, statusCode: code, headers: [:], latency: latency, requestURL: request.url?.absoluteString ?? "")
    }

    // MARK: - Cache Control

    /// Wipes all entries from the in-memory networking cache.
    public func clearCache() { cache.clear() }
    
    /// Invalidates a specific URL from the cache.
    /// - Parameter url: The URL key to remove.
    public func invalidateCache(for url: String) { cache.invalidate(key: url) }

    // MARK: - Private

    private func executeWithRetry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error = NetworkError.cancelled
        for attempt in 0..<max(1, config.retryPolicy.maxAttempts) {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
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

// MARK: - Mock API Client

/**
 # MockAPIClient
 
 A robust mock implementation of `APIClientProtocol` for use in unit tests.
 Allows for stubbing data, status codes, and simulating network failures.
 */
public final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    /// The data to return for successful requests.
    public var stubbedData: Data = Data()
    /// The HTTP status code to return. Defaults to 200.
    public var stubbedStatusCode: Int = 200
    /// Whether the next request should throw an error.
    public var shouldThrow: Bool = false
    /// The error to throw if `shouldThrow` is true.
    public var thrownError: Error = NetworkError.noConnection

    /// Initializes the mock client.
    public init() {}

    /// Mocks a decodable request.
    public func execute<T: Decodable & Sendable>(_ request: URLRequest, decoding: T.Type) async throws -> NetworkResponse<T> {
        if shouldThrow { throw thrownError }
        let value = try JSONDecoder().decode(T.self, from: stubbedData)
        return NetworkResponse(value: value, statusCode: stubbedStatusCode, headers: [:], latency: 0.01, requestURL: request.url?.absoluteString ?? "")
    }

    /// Mocks a raw data request.
    public func executeRaw(_ request: URLRequest) async throws -> (Data, Int) {
        if shouldThrow { throw thrownError }
        return (stubbedData, stubbedStatusCode)
    }

    /// Mocks a file download.
    public func download(from url: URL, to destination: URL) async throws {}
    
    /// Mocks a data upload.
    public func upload(data: Data, to request: URLRequest) async throws -> NetworkResponse<Data> {
        NetworkResponse(value: data, statusCode: 200, headers: [:], latency: 0, requestURL: "")
    }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitNetworking module.
    static var networking: APIClient { APIClient.shared }
}
