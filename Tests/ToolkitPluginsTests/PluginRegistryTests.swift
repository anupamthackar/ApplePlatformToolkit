import XCTest
@testable import ToolkitPlugins

final class MockPlugin: PluginProtocol, @unchecked Sendable {
    let id: String = "MockPlugin"
    var isLoaded = false
    func onLoad() { isLoaded = true }
    func onExecute() {}
    func onUnload() { isLoaded = false }
}

final class PluginRegistryTests: XCTestCase {
    func testPluginLifecycle() {
        let registry = PluginRegistry()
        let plugin = MockPlugin()
        registry.register(plugin)
        XCTAssertTrue(plugin.isLoaded)
        registry.unregister(id: plugin.id)
        XCTAssertFalse(plugin.isLoaded)
    }
}
