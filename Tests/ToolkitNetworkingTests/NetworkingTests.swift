import XCTest
@testable import ToolkitNetworking

final class NetworkingTests: XCTestCase {

    // MARK: - RequestBuilder

    func testRequestBuilderSetsURL() throws {
        let request = try RequestBuilder(baseURL: "https://api.example.com")
            .path("/users")
            .method(.get)
            .query("limit", "10")
            .build()
        XCTAssertEqual(request.url?.host, "api.example.com")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.absoluteString.contains("limit=10") ?? false)
    }

    func testRequestBuilderJSONBody() throws {
        struct Payload: Codable { let name: String }
        let request = try RequestBuilder(baseURL: "https://api.example.com")
            .path("/create")
            .method(.post)
            .jsonBody(Payload(name: "test"))
            .build()
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testRequestBuilderHeaderInjection() throws {
        let request = try RequestBuilder()
            .url("https://example.com")
            .header("X-Custom-Header", "toolkit")
            .build()
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom-Header"), "toolkit")
    }

    func testRequestBuilderTimeout() throws {
        let request = try RequestBuilder()
            .url("https://example.com")
            .timeout(60)
            .build()
        XCTAssertEqual(request.timeoutInterval, 60)
    }

    func testInvalidURLThrows() {
        XCTAssertThrowsError(try RequestBuilder().url("not a url:::").build())
    }

    // MARK: - Circuit Breaker

    func testCircuitBreakerStartsClosed() {
        let cb = CircuitBreaker()
        XCTAssertTrue(cb.canExecute())
        XCTAssertEqual(cb.currentState, .closed)
    }

    func testCircuitBreakerOpensAfterThreshold() {
        let cb = CircuitBreaker()
        cb.failureThreshold = 3
        cb.recordFailure()
        cb.recordFailure()
        cb.recordFailure()
        XCTAssertFalse(cb.canExecute())
        XCTAssertEqual(cb.currentState, .open)
    }

    func testCircuitBreakerResetsOnSuccess() {
        let cb = CircuitBreaker()
        cb.failureThreshold = 2
        cb.recordFailure(); cb.recordFailure()
        XCTAssertFalse(cb.canExecute())
        cb.reset()
        XCTAssertTrue(cb.canExecute())
    }

    // MARK: - Network Cache

    func testNetworkCacheStoreAndRetrieve() {
        let cache = NetworkCache()
        let data = Data("cached".utf8)
        cache.set(key: "test-key", data: data, ttl: 60)
        XCTAssertEqual(cache.get(key: "test-key"), data)
    }

    func testNetworkCacheExpiry() {
        let cache = NetworkCache()
        cache.set(key: "expired-key", data: Data("x".utf8), ttl: 0)
        Thread.sleep(forTimeInterval: 0.01)
        XCTAssertNil(cache.get(key: "expired-key"))
    }

    func testNetworkCacheClear() {
        let cache = NetworkCache()
        cache.set(key: "k1", data: Data("a".utf8))
        cache.set(key: "k2", data: Data("b".utf8))
        cache.clear()
        XCTAssertNil(cache.get(key: "k1"))
        XCTAssertNil(cache.get(key: "k2"))
    }

    // MARK: - Retry Policy

    func testExponentialBackoffDelayIncreases() {
        var policy = RetryPolicy()
        policy.strategy = .exponential
        policy.baseDelay = 0.5
        XCTAssertLessThan(policy.delay(for: 0), policy.delay(for: 1))
        XCTAssertLessThan(policy.delay(for: 1), policy.delay(for: 2))
    }

    func testFixedDelayIsConstant() {
        var policy = RetryPolicy()
        policy.strategy = .fixed
        policy.baseDelay = 1.0
        XCTAssertEqual(policy.delay(for: 0), 1.0)
        XCTAssertEqual(policy.delay(for: 5), 1.0)
    }

    // MARK: - Mock APIClient

    func testMockAPIClientSuccess() async throws {
        struct User: Codable, Sendable { let id: Int; let name: String }
        let mock = MockAPIClient()
        mock.stubbedData = try JSONEncoder().encode(User(id: 1, name: "Alice"))
        let request = try RequestBuilder().url("https://example.com/user").build()
        let response = try await mock.execute(request, decoding: User.self)
        XCTAssertEqual(response.value.name, "Alice")
        XCTAssertEqual(response.statusCode, 200)
    }

    func testMockAPIClientThrowsWhenConfigured() async {
        let mock = MockAPIClient()
        mock.shouldThrow = true
        mock.thrownError = NetworkError.noConnection
        let request = try? RequestBuilder().url("https://example.com").build()
        do {
            _ = try await mock.executeRaw(request!)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Interceptors

    func testAuthInterceptorInjectsToken() async throws {
        let interceptor = AuthTokenInterceptor { return "my-token-123" }
        var request = try RequestBuilder().url("https://example.com").build()
        try await interceptor.adapt(&request)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-token-123")
    }

    func testDefaultHeadersInterceptor() async throws {
        let interceptor = DefaultHeadersInterceptor(headers: ["X-App-Version": "1.0"])
        var request = try RequestBuilder().url("https://example.com").build()
        try await interceptor.adapt(&request)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0")
    }
}
