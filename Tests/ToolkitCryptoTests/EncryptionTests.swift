import XCTest
@testable import ToolkitCrypto

final class EncryptionTests: XCTestCase {

    var manager: CryptoManager!

    override func setUp() {
        super.setUp()
        manager = CryptoManager(config: CryptoConfig())
    }

    // MARK: - AES-GCM

    func testAESGCMRoundTrip() async throws {
        let plaintext = Data("Hello, AES-GCM!".utf8)
        let key = manager.generateKey(size: .bits256)
        let encrypted = try await manager.encrypt(plaintext, using: .aesGcm, key: key)
        let decrypted = try await manager.decrypt(encrypted.data, using: .aesGcm, key: key)
        XCTAssertEqual(decrypted.data, plaintext)
    }

    func testAESGCMDifferentNoncesProduceDifferentCiphertext() async throws {
        let plaintext = Data("Hello".utf8)
        let key = manager.generateKey()
        let enc1 = try await manager.encrypt(plaintext, key: key)
        let enc2 = try await manager.encrypt(plaintext, key: key)
        XCTAssertNotEqual(enc1.data, enc2.data) // nonces differ → ciphertexts differ
    }

    // MARK: - ChaCha20-Poly1305

    func testChaChaPolyRoundTrip() async throws {
        let plaintext = Data("Hello, ChaCha!".utf8)
        let key = manager.generateKey()
        let encrypted = try await manager.encrypt(plaintext, using: .chachaPoly, key: key)
        let decrypted = try await manager.decrypt(encrypted.data, using: .chachaPoly, key: key)
        XCTAssertEqual(decrypted.data, plaintext)
    }

    // MARK: - Mock

    func testMockRoundTrip() async throws {
        let plaintext = Data("test".utf8)
        let key = manager.generateKey()
        let encrypted = try await manager.encrypt(plaintext, using: .mock, key: key)
        let decrypted = try await manager.decrypt(encrypted.data, using: .mock, key: key)
        XCTAssertEqual(decrypted.data, plaintext)
    }

    // MARK: - Wrong Key

    func testDecryptionWithWrongKeyFails() async {
        let plaintext = Data("Secret".utf8)
        let key = manager.generateKey()
        let wrongKey = manager.generateKey()
        do {
            let encrypted = try await manager.encrypt(plaintext, key: key)
            _ = try await manager.decrypt(encrypted.data, key: wrongKey)
            XCTFail("Decryption with wrong key should throw")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Empty Data

    func testEmptyDataEncryption() async throws {
        let key = manager.generateKey()
        let encrypted = try await manager.encrypt(Data(), key: key)
        let decrypted = try await manager.decrypt(encrypted.data, key: key)
        XCTAssertEqual(decrypted.data, Data())
    }

    // MARK: - File Encryption

    func testFileEncryptionRoundTrip() async throws {
        let tmp = FileManager.default.temporaryDirectory
        let source = tmp.appendingPathComponent("test_plain.txt")
        let encrypted = tmp.appendingPathComponent("test_enc.bin")
        let decrypted = tmp.appendingPathComponent("test_dec.txt")

        try Data("File content".utf8).write(to: source)
        let key = manager.generateKey()
        try await manager.encryptFile(at: source, to: encrypted, key: key)
        try await manager.decryptFile(at: encrypted, to: decrypted, key: key)

        let result = try Data(contentsOf: decrypted)
        XCTAssertEqual(result, Data("File content".utf8))
    }
}
