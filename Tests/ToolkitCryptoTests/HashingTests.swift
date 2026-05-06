import XCTest
@testable import ToolkitCrypto

final class HashingTests: XCTestCase {

    var manager: CryptoManager!

    override func setUp() {
        super.setUp()
        manager = CryptoManager()
    }

    func testSHA256Consistency() {
        let data = Data("Hello".utf8)
        let r1 = manager.hash(data, algorithm: .sha256)
        let r2 = manager.hash(data, algorithm: .sha256)
        XCTAssertEqual(r1.encodedHex, r2.encodedHex)
    }

    func testSHA256KnownValue() {
        let data = Data("hello".utf8)
        let result = manager.hash(data, algorithm: .sha256)
        XCTAssertEqual(result.encodedHex, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }

    func testSHA384Produces48Bytes() {
        let data = Data("test".utf8)
        let result = manager.hash(data, algorithm: .sha384)
        XCTAssertEqual(result.data.count, 48)
    }

    func testSHA512Produces64Bytes() {
        let data = Data("test".utf8)
        let result = manager.hash(data, algorithm: .sha512)
        XCTAssertEqual(result.data.count, 64)
    }

    func testHashVerification() {
        let data = Data("verify me".utf8)
        let result = manager.hash(data, algorithm: .sha256)
        XCTAssertTrue(manager.verifyHash(data, expectedHex: result.encodedHex))
        XCTAssertFalse(manager.verifyHash(Data("wrong".utf8), expectedHex: result.encodedHex))
    }

    func testIncrementalHasher() {
        let full = Data("Hello, World!".utf8)
        let fullHash = manager.hash(full, algorithm: .sha256).encodedHex

        let incremental = manager.incrementalHasher()
        incremental.update(with: Data("Hello, ".utf8))
        incremental.update(with: Data("World!".utf8))
        let incrementalHash = incremental.finalize()

        XCTAssertEqual(fullHash, incrementalHash)
    }

    func testHashBuilder() {
        let result = manager.hashBuilder()
            .algorithm(.sha256)
            .append(string: "hello")
            .salt(Data("salty".utf8))
            .build()
        XCTAssertFalse(result.encodedHex.isEmpty)
    }

    func testHMACSignAndVerify() {
        let data = Data("message".utf8)
        let key = manager.generateKey()
        let sig = manager.sign(data, key: key)
        XCTAssertTrue(manager.verifySignature(data, signature: sig.data, key: key))
    }

    func testHMACWrongKeyFails() {
        let data = Data("message".utf8)
        let key = manager.generateKey()
        let wrongKey = manager.generateKey()
        let sig = manager.sign(data, key: key)
        XCTAssertFalse(manager.verifySignature(data, signature: sig.data, key: wrongKey))
    }

    func testConstantTimeComparison() {
        let a = Data("same".utf8)
        let b = Data("same".utf8)
        let c = Data("diff".utf8)
        XCTAssertTrue(manager.constantTimeEqual(a, b))
        XCTAssertFalse(manager.constantTimeEqual(a, c))
    }
}
