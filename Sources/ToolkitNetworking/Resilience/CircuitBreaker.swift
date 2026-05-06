import Foundation

// MARK: - Circuit Breaker Documentation

/**
 # CircuitBreaker
 
 A resilience pattern that prevents an application from repeatedly trying to execute
 an operation that is likely to fail. It "opens" after a threshold of failures is reached,
 and periodically allows a single test request in "half-open" state.
 
 ## Usage
 ```swift
 let breaker = CircuitBreaker()
 breaker.failureThreshold = 3
 breaker.resetTimeout = 10.0
 
 if breaker.canExecute() {
     do {
         try await makeNetworkCall()
         breaker.recordSuccess()
     } catch {
         breaker.recordFailure()
     }
 } else {
     print("Request blocked: Circuit is OPEN")
 }
 ```
 */
public final class CircuitBreaker: @unchecked Sendable {

    /// The possible operational states of the circuit.
    public enum State: Sendable {
        /// System is healthy, allowing all requests.
        case closed
        /// System is failing, blocking all requests.
        case open
        /// System is recovering, allowing a test request.
        case halfOpen
    }

    /// Number of consecutive failures allowed before opening the circuit.
    public var failureThreshold: Int = 5
    /// How long the circuit stays open before transitioning to half-open.
    public var resetTimeout: TimeInterval = 60.0

    private var state: State = .closed
    private var failureCount: Int = 0
    private var lastOpenedAt: Date?
    private let lock = NSLock()

    public init() {}

    /**
     Checks if the operation is permitted to proceed.
     - Returns: `true` if closed or half-open, `false` if open and timeout not reached.
     */
    public func canExecute() -> Bool {
        lock.lock(); defer { lock.unlock() }
        switch state {
        case .closed: return true
        case .open:
            guard let openedAt = lastOpenedAt,
                  Date().timeIntervalSince(openedAt) >= resetTimeout else { return false }
            state = .halfOpen
            return true
        case .halfOpen: return true
        }
    }

    /**
     Call this after a successful operation to reset the failure counter.
     */
    public func recordSuccess() {
        lock.lock(); defer { lock.unlock() }
        failureCount = 0
        state = .closed
    }

    /**
     Call this after a failed operation to increment the failure counter.
     */
    public func recordFailure() {
        lock.lock(); defer { lock.unlock() }
        failureCount += 1
        if failureCount >= failureThreshold {
            state = .open
            lastOpenedAt = Date()
        }
    }

    /// Resets the circuit to its initial closed state.
    public func reset() {
        lock.lock(); defer { lock.unlock() }
        failureCount = 0
        state = .closed
        lastOpenedAt = nil
    }

    /// The current state of the circuit breaker.
    public var currentState: State {
        lock.lock(); defer { lock.unlock() }
        return state
    }
}

// MARK: - Network Cache Documentation

/**
 # NetworkCache
 
 A thread-safe in-memory cache with TTL (Time To Live) support for network responses.
 
 ## Usage
 ```swift
 NetworkCache.shared.set(key: "profile_data", data: rawData, ttl: 3600)
 
 if let cached = NetworkCache.shared.get(key: "profile_data") {
     // Use cached data
 }
 ```
 */
public final class NetworkCache: @unchecked Sendable {
    
    /// A single entry in the cache.
    public struct CacheEntry: Sendable {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval
        /// Whether the entry has exceeded its lifespan.
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > ttl }
    }

    private var store: [String: CacheEntry] = [:]
    private let lock = NSLock()
    /// Shared singleton for global caching.
    public static let shared = NetworkCache()

    public init() {}

    /**
     Stores data in the cache.
     - Parameters:
        - key: Unique identifier for the data.
        - data: The binary payload.
        - ttl: Lifespan in seconds (default 5 minutes).
     */
    public func set(key: String, data: Data, ttl: TimeInterval = 300) {
        lock.lock(); defer { lock.unlock() }
        store[key] = CacheEntry(data: data, timestamp: Date(), ttl: ttl)
    }

    /**
     Retrieves data from the cache if it hasn't expired.
     */
    public func get(key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = store[key], !entry.isExpired else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    /// Removes a specific item from the cache.
    public func invalidate(key: String) {
        lock.lock(); defer { lock.unlock() }
        store.removeValue(forKey: key)
    }

    /// Wipes all items from the cache.
    public func clear() {
        lock.lock(); defer { lock.unlock() }
        store.removeAll()
    }
}
