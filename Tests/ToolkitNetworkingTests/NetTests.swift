import XCTest
@testable import ToolkitNetworking

final class NetTests: XCTestCase {
    func testBuilder() throws {
        let req = try RequestBuilder()
            .url("https://apple.com")
            .method(.post)
            .header("A", "B")
            .timeout(10.0)
            .build()
            
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.url?.absoluteString, "https://apple.com")
        XCTAssertEqual(req.value(forHTTPHeaderField: "A"), "B")
        XCTAssertEqual(req.timeoutInterval, 10.0)
    }
}
