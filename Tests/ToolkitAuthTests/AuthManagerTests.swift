import XCTest
@testable import ToolkitAuth

final class AuthManagerTests: XCTestCase {
    func testTokenManagement() {
        let manager = AuthManager()
        manager.setAccessToken("test_token")
        XCTAssertEqual(manager.getAccessToken(), "test_token")
    }
}
