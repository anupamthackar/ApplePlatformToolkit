import XCTest
import ToolkitCore
@testable import ToolkitUI

final class UITests: XCTestCase {
    @MainActor
    func testConfig() {
        let ui = ToolkitUI.shared
        var config = UIConfig()
        config.animationsEnabled = false
        ui.configure(config)
        XCTAssertFalse(ui.uiConfig.animationsEnabled)
    }
}
