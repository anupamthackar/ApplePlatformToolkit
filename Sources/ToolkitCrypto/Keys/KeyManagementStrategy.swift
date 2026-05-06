import Foundation
import CryptoKit
import Security

// MARK: - Key Management Documentation

/**
 # KeyManagementStrategy
 
 A protocol for managing the lifecycle of cryptographic keys, including generation,
 derivation, storage, and secure deletion.
 
 ## Usage
 ```swift
 let keyManager = DefaultKeyManagementStrategy()
 
 // Generate a new key
 let key = keyManager.generateSymmetricKey(size: .bits256)
 
 // Store securely
 try keyManager.store(key: key, identifier: "primary-key")
 
 // Derive from password
 let salt = Data(repeating: 0x05, count: 16)
 let derived = keyManager.deriveKey(from: "p@ssword", salt: salt, iterations: 10000, keySize: .bits256)
 ```
 */
public protocol KeyManagementStrategy: Sendable {
    /**
     Generates a cryptographically secure symmetric key.
     - Parameter size: The desired bit length of the key.
     - Returns: The raw key as `Data`.
     */
    func generateSymmetricKey(size: CryptoKeySize) -> Data
    
    /**
     Derives a key from a password and salt using HKDF.
     - Parameters:
        - password: The source password string.
        - salt: A random salt value.
        - iterations: The complexity factor.
        - keySize: The output key size.
     - Returns: The derived key data.
     */
    func deriveKey(from password: String, salt: Data, iterations: Int, keySize: CryptoKeySize) -> Data
    
    /**
     Securely stores a key under a unique identifier.
     - Parameters:
        - key: The key data to store.
        - identifier: A unique string to reference the key later.
     - Throws: If storage fails (e.g., Keychain error).
     */
    func store(key: Data, identifier: String) throws
    
    /**
     Retrieves a previously stored key.
     - Parameter identifier: The unique identifier used during storage.
     - Returns: The raw key data.
     - Throws: `CryptoError.keyNotFound` if not found.
     */
    func retrieve(identifier: String) throws -> Data
    
    /**
     Deletes a key from storage.
     - Parameter identifier: The unique identifier.
     - Throws: If deletion fails.
     */
    func delete(identifier: String) throws
    
    /**
     Generates and stores a new key over an existing identifier.
     - Parameter identifier: The identifier to rotate.
     - Returns: The newly generated key data.
     - Throws: If rotation fails.
     */
    func rotate(identifier: String) throws -> Data
    
    /**
     Overwrites data in memory with zeros to prevent sensitive data recovery.
     - Parameter data: The data to wipe.
     */
    func wipe(_ data: inout Data)
}

/**
 Supported symmetric key sizes in bits.
 */
public enum CryptoKeySize: Int, Sendable {
    case bits128 = 16
    case bits192 = 24
    case bits256 = 32
}

/**
 Options for where keys are persisted.
 */
public enum KeyStorageBackend: Sendable {
    /// Stored in volatile memory (erased on app exit).
    case memory
    /// Stored in the system Keychain (persistent).
    case keychain
    /// Managed within the hardware Secure Enclave (highest security).
    case secureEnclave
}

// MARK: - Default Implementation

/**
 A memory-based implementation of `KeyManagementStrategy`.
 Suitable for ephemeral sessions or unit testing.
 */
public final class DefaultKeyManagementStrategy: KeyManagementStrategy, @unchecked Sendable {

    private var memoryStore: [String: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public func generateSymmetricKey(size: CryptoKeySize) -> Data {
        let key = SymmetricKey(size: .init(bitCount: size.rawValue * 8))
        return key.withUnsafeBytes { Data($0) }
    }

    public func deriveKey(from password: String, salt: Data, iterations: Int, keySize: CryptoKeySize) -> Data {
        guard let passwordData = password.data(using: .utf8) else { return Data() }
        // Use HKDF (RFC 5869) for key derivation — pure CryptoKit, no CommonCrypto needed.
        let inputKey = SymmetricKey(data: passwordData)
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("toolkit-kdf".utf8),
            outputByteCount: keySize.rawValue
        )
        return derived.withUnsafeBytes { Data($0) }
    }

    public func store(key: Data, identifier: String) throws {
        lock.lock(); defer { lock.unlock() }
        memoryStore[identifier] = key
    }

    public func retrieve(identifier: String) throws -> Data {
        lock.lock(); defer { lock.unlock() }
        guard let key = memoryStore[identifier] else {
            throw CryptoError.keyNotFound(identifier)
        }
        return key
    }

    public func delete(identifier: String) throws {
        lock.lock(); defer { lock.unlock() }
        memoryStore.removeValue(forKey: identifier)
    }

    public func rotate(identifier: String) throws -> Data {
        let newKey = generateSymmetricKey(size: .bits256)
        try store(key: newKey, identifier: identifier)
        return newKey
    }

    public func wipe(_ data: inout Data) {
        data.resetBytes(in: 0..<data.count)
        data = Data()
    }
}

// MARK: - Secure Random

/**
 Utilities for generating cryptographically secure random values.
 Uses system-level entropy sources (`SecRandomCopyBytes`).
 */
public struct SecureRandom {
    /**
     Generates a block of random bytes.
     - Parameter count: Number of bytes to generate.
     - Returns: Random `Data`.
     */
    public static func bytes(count: Int) -> Data {
        var bytes = Data(count: count)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) }
        return bytes
    }

    /**
     Generates a random boolean.
     */
    public static func bool() -> Bool { bytes(count: 1).first.map { $0 % 2 == 0 } ?? false }
}
