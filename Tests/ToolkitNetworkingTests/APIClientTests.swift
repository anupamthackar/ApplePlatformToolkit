import XCTest
@testable import ToolkitNetworking

final class APIClientTests: XCTestCase {
    func testInit() {
        let client = APIClient()
        XCTAssertNotNil(client)
    }
}
