import Foundation
import CryptoKit

// MARK: - Encryption Strategy Documentation

/**
 # EncryptionStrategy
 
 A protocol defining the interface for symmetric encryption algorithms.
 Implementations use modern, authenticated encryption schemes (AEAD) by default.
 
 ## Usage
 ```swift
 let strategy = AESGCMStrategy()
 let key = Data(repeating: 0x01, count: 32)
 let secret = Data("Secret Message".utf8)
 
 // Encrypt
 let ciphertext = try strategy.encrypt(secret, key: key, iv: nil)
 
 // Decrypt
 let plaintext = try strategy.decrypt(ciphertext, key: key, iv: nil)
 ```
 */
public protocol EncryptionStrategy: Sendable {
    /**
     Encrypts the provided data using the specified key.
     - Parameters:
        - data: The plaintext data to encrypt.
        - key: The raw symmetric key (e.g., 256-bit).
        - iv: An optional initialization vector or nonce. If nil, a random one is generated.
     - Returns: The encrypted ciphertext (combined with nonce/tag for AEAD).
     - Throws: `CryptoError` if encryption fails.
     */
    func encrypt(_ data: Data, key: Data, iv: Data?) throws -> Data
    
    /**
     Decrypts the provided ciphertext using the specified key.
     - Parameters:
        - data: The ciphertext (combined format).
        - key: The raw symmetric key.
        - iv: An optional initialization vector or nonce if not part of the ciphertext.
     - Returns: The decrypted plaintext data.
     - Throws: `CryptoError` if decryption fails or authentication fails.
     */
    func decrypt(_ data: Data, key: Data, iv: Data?) throws -> Data
}

// MARK: - AES-GCM Strategy

/**
 Authenticated encryption using AES-GCM (Galois/Counter Mode).
 AES-GCM provides both confidentiality and data integrity.
 
 ## Standards
 - Key Size: 128, 192, or 256 bits (256 recommended).
 - Nonce Size: 96 bits (12 bytes).
 - Tag Size: 128 bits (16 bytes).
 */
public struct AESGCMStrategy: EncryptionStrategy {
    public init() {}

    public func encrypt(_ data: Data, key: Data, iv: Data?) throws -> Data {
        let symKey = SymmetricKey(data: key)
        let nonce: AES.GCM.Nonce = try {
            if let iv, iv.count == 12 {
                return try AES.GCM.Nonce(data: iv)
            }
            return AES.GCM.Nonce()
        }()
        let sealedBox = try AES.GCM.seal(data, using: symKey, nonce: nonce)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed("AES-GCM combined box is nil")
        }
        return combined
    }

    public func decrypt(_ data: Data, key: Data, iv: Data?) throws -> Data {
        let symKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symKey)
    }
}

// MARK: - ChaCha20-Poly1305 Strategy

/**
 Authenticated encryption using the ChaCha20 stream cipher and Poly1305 MAC.
 ChaChaPoly is often faster than AES in software on non-AES-NI hardware (e.g., older mobile chips).
 
 ## Standards
 - RFC 8439 compliant.
 - Key Size: 256 bits.
 - Nonce Size: 96 bits.
 */
public struct ChaChaPolyStrategy: EncryptionStrategy {
    public init() {}

    public func encrypt(_ data: Data, key: Data, iv: Data?) throws -> Data {
        let symKey = SymmetricKey(data: key)
        let nonce: ChaChaPoly.Nonce = try {
            if let iv, iv.count == 12 {
                return try ChaChaPoly.Nonce(data: iv)
            }
            return ChaChaPoly.Nonce()
        }()
        let sealed = try ChaChaPoly.seal(data, using: symKey, nonce: nonce)
        return sealed.combined
    }

    public func decrypt(_ data: Data, key: Data, iv: Data?) throws -> Data {
        let symKey = SymmetricKey(data: key)
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealedBox, using: symKey)
    }
}

// MARK: - Mock Strategy (Testing)

/**
 A pass-through encryption strategy for unit-testing purposes.
 Returns input data unchanged.
 */
public struct MockEncryptionStrategy: EncryptionStrategy {
    public init() {}
    public func encrypt(_ data: Data, key: Data, iv: Data?) throws -> Data { data }
    public func decrypt(_ data: Data, key: Data, iv: Data?) throws -> Data { data }
}
