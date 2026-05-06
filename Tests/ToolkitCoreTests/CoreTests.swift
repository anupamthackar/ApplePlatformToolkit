import XCTest
@testable import ToolkitCore

final class CoreTests: XCTestCase {
    func testDependencyInjection() {
        let container = DependencyContainer.shared
        container.clear()
        
        container.register(String.self, name: "API_KEY", scope: .singleton) {
            return "secret_key"
        }
        
        let resolved = container.resolve(String.self, name: "API_KEY")
        XCTAssertEqual(resolved, "secret_key")
        
        container.override(String.self, name: "API_KEY", instance: "mock_key")
        XCTAssertEqual(container.resolve(String.self, name: "API_KEY"), "mock_key")
    }
    
    func testConfigManager() {
        let config = ConfigManager.shared
        config.load(dictionary: ["feature_x": true, "timeout": 30])
        
        XCTAssertTrue(config.isFeatureEnabled("feature_x"))
        XCTAssertEqual(config.getValue("timeout", defaultValue: 0), 30)
    }
    
    func testTaskManager() async {
        let manager = TaskManager.shared
        let exp = expectation(description: "Task executed")
        
        _ = await manager.execute {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func testMetricsManager() async {
        let metrics = MetricsManager.shared
        await metrics.recordMetric(name: "latency", value: 100)
        await metrics.recordMetric(name: "latency", value: 200)
        
        let avg = await metrics.average(for: "latency")
        XCTAssertEqual(avg, 150)
    }
    
    func testErrorHandling() {
        let error = ToolkitError(category: .network, code: 404, message: "Not Found", retryHint: true)
        XCTAssertEqual(error.category, .network)
        XCTAssertTrue(error.retryHint)
    }
}
