import XCTest
@testable import ToolkitUtility

final class StringExtensionTests: XCTestCase {
    func testEmailValidation() {
        XCTAssertTrue("test@example.com".tk.isValidEmail)
        XCTAssertFalse("invalid-email".tk.isValidEmail)
    }
}
