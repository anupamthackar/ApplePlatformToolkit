import Foundation

// MARK: - RequestBuilder

/// Fluent builder for constructing type-safe URLRequests.
public final class RequestBuilder: @unchecked Sendable {

    private var urlString: String = ""
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var queryItems: [URLQueryItem] = []
    private var body: Data?
    private var timeout: TimeInterval = 30.0
    private var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    private var baseURL: String?

    public init(baseURL: String? = nil) {
        self.baseURL = baseURL
    }

    // MARK: - Fluent Methods

    @discardableResult
    public func path(_ path: String) -> Self {
        let base = baseURL ?? ""
        self.urlString = base + path
        return self
    }

    @discardableResult
    public func url(_ urlString: String) -> Self { self.urlString = urlString; return self }

    @discardableResult
    public func method(_ method: HTTPMethod) -> Self { self.method = method; return self }

    @discardableResult
    public func header(_ key: String, _ value: String) -> Self { headers[key] = value; return self }

    @discardableResult
    public func headers(_ h: [String: String]) -> Self { h.forEach { headers[$0.key] = $0.value }; return self }

    @discardableResult
    public func query(_ key: String, _ value: String) -> Self {
        queryItems.append(URLQueryItem(name: key, value: value)); return self
    }

    @discardableResult
    public func queryParameters(_ params: [String: String]) -> Self {
        params.forEach { queryItems.append(URLQueryItem(name: $0.key, value: $0.value)) }
        return self
    }

    @discardableResult
    public func body(_ data: Data) -> Self { self.body = data; return self }

    @discardableResult
    public func jsonBody<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) -> Self {
        self.body = try? encoder.encode(object)
        self.headers["Content-Type"] = "application/json"
        return self
    }

    @discardableResult
    public func timeout(_ interval: TimeInterval) -> Self { self.timeout = interval; return self }

    // MARK: - Build

    public func build() throws -> URLRequest {
        var components = URLComponents(string: urlString)
        if !queryItems.isEmpty {
            var existing = components?.queryItems ?? []
            existing.append(contentsOf: queryItems)
            components?.queryItems = existing
        }
        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL(urlString)
        }
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = timeout
        request.cachePolicy = cachePolicy
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
