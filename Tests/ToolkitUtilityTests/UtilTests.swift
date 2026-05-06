import XCTest
@testable import ToolkitUtility

final class UtilTests: XCTestCase {
    func testManager() {
        let manager = ToolkitUtilityManager.shared
        XCTAssertEqual(manager.config.currencyRegion, "US")
        XCTAssertEqual(manager.connectivity.currentConnectionType(), .wifi)
    }
}
