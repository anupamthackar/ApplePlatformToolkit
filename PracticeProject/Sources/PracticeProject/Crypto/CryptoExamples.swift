import Foundation
import ToolkitCrypto

/// Examples demonstrating usage of ToolkitCrypto methods.
public struct CryptoExamples {
    public static func run() async {
        print("=== ToolkitCrypto Examples ===")
        let crypto = CryptoManager.shared
        
        do {
            // 1. Generate Key
            let key = crypto.generateKey()
            print("Generated encryption key of size: \(key.count) bytes")
            
            // 2. Encrypt Data
            let plainText = "Hello from ToolkitCrypto".data(using: .utf8)!
            let encrypted = try await crypto.encrypt(plainText, key: key)
            print("Encrypted data size: \(encrypted.data.count) bytes")
            
            // 3. Decrypt Data
            let decrypted = try await crypto.decrypt(encrypted.data, key: key)
            if let decryptedString = String(data: decrypted.data, encoding: .utf8) {
                print("Decrypted string: \(decryptedString)")
            }
            
            // 4. Hashing
            let hashResult = crypto.hash(string: "SecretPassword123")
            print("Hash hex string: \(hashResult.encodedHex)")
            
            // 5. Verification
            let isValid = crypto.verifyHash("SecretPassword123".data(using: .utf8)!, expectedHex: hashResult.encodedHex)
            print("Hash verification passed: \(isValid)")
            
            // 6. Key Derivation
            let derivedKey = crypto.deriveKey(from: "MySecurePassword")
            print("Derived key size: \(derivedKey.count) bytes")
            
            // 7. Secure Random
            let randomBytes = crypto.secureRandomBytes(count: 16)
            print("Secure random bytes: \(randomBytes.count)")
            
        } catch {
            print("ToolkitCrypto Error: \(error)")
        }
        print("==============================\n")
    }
}
