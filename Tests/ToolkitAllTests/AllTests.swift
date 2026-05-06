import XCTest
import ToolkitCore
import ToolkitNetworking
import ToolkitUtility
import ToolkitAuth
import ToolkitUI

final class AllTests: XCTestCase {
    @MainActor
    func testIntegration() {
        XCTAssertNotNil(ToolkitUtilityManager.shared)
        XCTAssertNotNil(APIClient.shared)
        XCTAssertNotNil(ToolkitAuthManager.shared)
        XCTAssertNotNil(ToolkitUI.shared)
    }
}
