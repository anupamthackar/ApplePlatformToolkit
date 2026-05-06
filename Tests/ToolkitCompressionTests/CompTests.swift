import XCTest
@testable import ToolkitCompression

final class CompTests: XCTestCase {
    func testCompression() async throws {
        let manager = CompressionBuilder()
            .algorithm(.lzfse)
            .build()
            
        let data = Data("Hello World!".repeating(count: 100).utf8)
        
        let compressed = try await manager.compress(data)
        XCTAssertLessThan(compressed.data.count, data.count)
        
        let decompressed = try await manager.decompress(compressed.data, originalSize: data.count)
        XCTAssertEqual(data, decompressed.data)
    }
    
    func testChecksum() {
        let manager = CompressionManager.shared
        let data = Data("abc".utf8)
        let sum = manager.checksum(data)
        XCTAssertTrue(manager.verifyIntegrity(data: data, expectedChecksum: sum))
    }
}

extension String {
    func repeating(count: Int) -> String {
        return Array(repeating: self, count: count).joined()
    }
}
