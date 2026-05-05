import XCTest
@testable import ToolkitCrypto

final class HashingTests: XCTestCase {
    func testSHA256() {
        let manager = CryptoManager()
        let data = "hello".data(using: .utf8)!
        let hash = manager.sha256(data)
        XCTAssertEqual(hash.count, 64)
    }
}
