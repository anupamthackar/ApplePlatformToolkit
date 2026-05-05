import XCTest
@testable import ToolkitCore

final class DependencyContainerTests: XCTestCase {
    func testDependencyRegistration() {
        let container = DependencyContainer()
        let config = ConfigurationManager()
        container.register(ConfigurationManager.self, dependency: config)
        let resolved = container.resolve(ConfigurationManager.self)
        XCTAssertNotNil(resolved)
    }
}
