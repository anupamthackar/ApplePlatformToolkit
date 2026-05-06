import Foundation
import Alamofire
import ToolkitCore

// MARK: - Network Config Documentation

/**
 # NetworkConfig
 
 A comprehensive configuration object for the `ToolkitNetworkingManager`.
 Controls base URLs, timeouts, caching strategies, retry logic, and security settings.
 
 ## Usage
 ```swift
 var config = NetworkConfig()
 config.baseURL = "https://api.example.com"
 config.timeoutInterval = 15.0
 config.retryPolicy.maxAttempts = 5
 config.cachePolicy = .memoryAndDisk
 ```
 */
public struct NetworkConfig: Sendable {
    /// The base URL prepended to all relative request paths.
    public var baseURL: String = ""
    /// Standard HTTP headers included in every request (e.g., User-Agent).
    public var defaultHeaders: [String: String] = [:]
    /// Global timeout for requests in seconds.
    public var timeoutInterval: TimeInterval = 30.0
    /// The strategy used for caching responses.
    public var cachePolicy: NetworkCachePolicy = .memoryAndDisk
    /// Configuration for automatic request retries on failure.
    public var retryPolicy: RetryPolicy = RetryPolicy()
    /// Whether to log request/response details to the console.
    public var loggingEnabled: Bool = true
    /// SSL pinning and security validation settings.
    public var securityConfig: SecurityConfig = SecurityConfig()
    /// The key decoding strategy for JSON responses.
    public var decoderStrategy: DecoderStrategy = .default
    /// Maximum number of active requests allowed at once.
    public var maxConcurrentRequests: Int = 10

    /// Strategy for mapping JSON keys to Swift properties.
    public enum DecoderStrategy: Sendable {
        /// Uses keys exactly as they appear in JSON.
        case `default`
        /// Automatically maps snake_case JSON keys to camelCase Swift properties.
        case snakeCase
        /// Uses a custom provided decoder.
        case custom
    }

    public init() {}
}

// MARK: - RetryPolicy

/**
 # RetryPolicy
 
 Defines how and when the networking layer should automatically retry failed requests.
 */
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts before throwing an error.
    public var maxAttempts: Int = 3
    /// The initial delay before the first retry.
    public var baseDelay: TimeInterval = 0.5
    /// The algorithm used to calculate subsequent delays.
    public var strategy: RetryStrategy = .exponential
    /// HTTP status codes that trigger a retry attempt.
    public var retryableCodes: Set<Int> = [408, 429, 500, 502, 503, 504]

    /// Backoff algorithms for timing retries.
    public enum RetryStrategy: Sendable {
        /// Uses the same delay for every attempt.
        case fixed
        /// Doubles the delay after each failure.
        case exponential
        /// Adds a random variation to avoid "thundering herd" problems.
        case jitter
    }

    public init() {}

    /**
     Calculates the wait time for a specific attempt number.
     */
    public func delay(for attempt: Int) -> TimeInterval {
        switch strategy {
        case .fixed: return baseDelay
        case .exponential: return baseDelay * pow(2.0, Double(attempt))
        case .jitter: return baseDelay * pow(2.0, Double(attempt)) + Double.random(in: 0...0.3)
        }
    }
}

// MARK: - SecurityConfig

/**
 # SecurityConfig
 
 Manages SSL pinning and certificate validation rules.
 */
public struct SecurityConfig: Sendable {
    /// List of DER-encoded certificate data for SSL pinning.
    public var pinnedCertificateData: [Data] = []
    /// If true, validates the server's certificate chain.
    public var validateSSL: Bool = true
    /// If true, allows connections to servers with self-signed certificates (debug only).
    public var allowSelfSignedCertificates: Bool = false

    public init() {}
}

// MARK: - NetworkCachePolicy

/**
 Supported caching strategies for the networking layer.
 */
public enum NetworkCachePolicy: Sendable {
    /// No caching performed.
    case ignore
    /// Cached only in volatile memory.
    case memoryOnly
    /// Cached only on persistent disk.
    case diskOnly
    /// Cached both in memory and on disk.
    case memoryAndDisk
    /// Always attempts to use cache first, then falls back to network.
    case offlineFirst
}
