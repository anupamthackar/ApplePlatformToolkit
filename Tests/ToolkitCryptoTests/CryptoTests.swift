import XCTest
@testable import ToolkitCrypto

final class CryptoTests: XCTestCase {
    func testHashing() {
        let crypto = CryptoManager.shared
        
        // Simple hash
        let result = crypto.hash(string: "abc", algorithm: .sha256)
        XCTAssertFalse(result.encodedHex.isEmpty)
        
        // Builder hash
        let builderResult = crypto.hashBuilder()
            .algorithm(.sha256)
            .append(string: "abc")
            .build()
            
        XCTAssertEqual(result.encodedHex, builderResult.encodedHex)
    }
    
    func testEncryption() async throws {
        let crypto = CryptoManager.shared
        let key = crypto.generateKey()
        let data = Data("Secret Message".utf8)
        
        let encrypted = try await crypto.encrypt(data, using: .aesGcm, key: key)
        XCTAssertNotEqual(data, encrypted.data)
        
        let decrypted = try await crypto.decrypt(encrypted.data, using: .aesGcm, key: key)
        XCTAssertEqual(data, decrypted.data)
    }
}
