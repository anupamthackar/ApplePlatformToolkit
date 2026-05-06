import XCTest
@testable import ToolkitCompression

final class CompressionTests: XCTestCase {

    var manager: CompressionManager!

    override func setUp() {
        super.setUp()
        manager = CompressionManager()
    }

    // MARK: - Basic Round Trips

    func testLZFSERoundTrip() async throws {
        let manager = CompressionBuilder().algorithm(.lzfse).build()
        let original = Data("Hello, world! This is a test string for LZFSE compression.".utf8)
        let compressed = try await manager.compress(original)
        let decompressed = try await manager.decompress(compressed.data, originalSize: original.count)
        XCTAssertEqual(decompressed.data, original)
    }

    func testZlibRoundTrip() async throws {
        let manager = CompressionBuilder().algorithm(.zlib).build()
        let data = Data(repeating: 65, count: 1000) // 1000 'A' bytes
        let compressed = try await manager.compress(data)
        let decompressed = try await manager.decompress(compressed.data, originalSize: data.count)
        XCTAssertEqual(decompressed.data, data)
    }

    func testLZ4RoundTrip() async throws {
        let manager = CompressionBuilder().algorithm(.lz4).build()
        let data = Data("LZ4 round trip test data".utf8)
        let compressed = try await manager.compress(data)
        let decompressed = try await manager.decompress(compressed.data, originalSize: data.count)
        XCTAssertEqual(decompressed.data, data)
    }

    // MARK: - Metadata

    func testCompressionResultMetadata() async throws {
        let data = Data(repeating: 66, count: 5000)
        let result = try await manager.compress(data)
        XCTAssertEqual(result.originalSize, data.count)
        XCTAssertGreaterThan(result.compressedSize, 0)
        XCTAssertGreaterThan(result.durationSeconds, 0)
        XCTAssertGreaterThan(result.spaceSaved, 0) // repetitive data compresses well
    }

    // MARK: - File Compression

    func testFileCompressionRoundTrip() async throws {
        let tmp = FileManager.default.temporaryDirectory
        let source = tmp.appendingPathComponent("compress_test.txt")
        let dest = tmp.appendingPathComponent("compress_test.bin")
        let restored = tmp.appendingPathComponent("compress_restored.txt")

        let content = Data(String(repeating: "ABCDE", count: 200).utf8)
        try content.write(to: source)

        let result = try await manager.compressFile(at: source, to: dest)
        _ = try await manager.decompressFile(at: dest, to: restored, originalSize: result.originalSize)

        let restoredData = try Data(contentsOf: restored)
        XCTAssertEqual(restoredData, content)
    }

    // MARK: - Batch Compression

    func testBatchCompression() async throws {
        let items = (0..<5).map { Data("Item \($0) data payload".utf8) }
        let results = try await manager.batchCompress(items)
        XCTAssertEqual(results.count, 5)
    }

    // MARK: - Checksum

    func testChecksumConsistency() {
        let data = Data("Checksum test".utf8)
        let c1 = manager.checksum(data)
        let c2 = manager.checksum(data)
        XCTAssertEqual(c1, c2)
    }

    func testIntegrityVerification() {
        let data = Data("Integrity check".utf8)
        let expected = manager.checksum(data)
        XCTAssertTrue(manager.verifyIntegrity(data: data, expectedChecksum: expected))
        XCTAssertFalse(manager.verifyIntegrity(data: Data("tampered".utf8), expectedChecksum: expected))
    }

    // MARK: - Mock Strategy

    func testMockStrategyPassthrough() async throws {
        let manager = CompressionManager(strategy: MockCompressionStrategy())
        let data = Data("test".utf8)
        let result = try await manager.compress(data)
        XCTAssertEqual(result.data, data)
    }

    // MARK: - Streaming Session

    func testStreamingSessionCancelNotCrash() {
        let session = manager.streamingSession()
        session.cancel()
        XCTAssertEqual(session.progress, 0)
    }
}
