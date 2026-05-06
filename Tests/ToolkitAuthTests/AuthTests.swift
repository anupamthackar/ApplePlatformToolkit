import XCTest
@testable import ToolkitAuth

final class AuthTests: XCTestCase {
    @MainActor
    func testConfig() {
        let m = ToolkitAuthManager()
        XCTAssertNotNil(m.session.currentToken())
        XCTAssertEqual(m.state, .unauthenticated)
    }
    
    @MainActor
    func testAuthenticate() async throws {
        let m = ToolkitAuthManager()
        try await m.authenticate(method: .oauth2)
        XCTAssertEqual(m.state, .authenticated)
    }
}
