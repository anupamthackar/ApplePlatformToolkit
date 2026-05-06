import XCTest
@testable import ToolkitPlugins
@testable import ToolkitCore

final class AdvancedPluginTests: XCTestCase {
    func testPluginLifecycle() async throws {
        var config = PluginConfig()
        config.strictDependencies = false
        let manager = PluginManager(config: config)
        let logPlugin = LoggingPlugin()
        
        try manager.register(logPlugin)
        XCTAssertNotNil(manager.fetch(id: logPlugin.id))
        
        await manager.executeAll()
        
        manager.unregister(id: logPlugin.id)
        XCTAssertNil(manager.fetch(id: logPlugin.id))
    }
    
    func testDependencyResolution() {
        var config = PluginConfig()
        config.strictDependencies = true
        let manager = PluginManager(config: config)
        let analytics = AnalyticsPlugin() // Depends on logging
        
        XCTAssertThrowsError(try manager.register(analytics)) { error in
            guard case PluginError.missingDependency(let dep) = error else {
                XCTFail("Wrong error")
                return
            }
            XCTAssertEqual(dep, "com.toolkit.logging")
        }
    }
    
    func testEventBus() async {
        final class MockListener: EventListener, @unchecked Sendable {
            var priority: Int = 1
            var received = false
            func onEvent(_ event: TypedEvent) async {
                received = true
            }
        }
        
        let listener = MockListener()
        EventBus.shared.subscribe(event: "test_event", listener: listener)
        await EventBus.shared.publish(TypedEvent(name: "test_event", payload: [:]))
        
        XCTAssertTrue(listener.received)
    }
}
