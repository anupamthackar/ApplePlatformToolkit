import Foundation
import CryptoKit
import ToolkitCore

// MARK: - Crypto Manager Documentation

/**
 # CryptoManager
 
 The central entry point for the Toolkit's cryptographic services.
 It unifies encryption, hashing, HMAC, and key management into a high-level, strategy-based API.
 
 ## Features
 - **Authenticated Encryption**: AES-GCM and ChaChaPoly.
 - **Secure Hashing**: SHA256, SHA384, and SHA512 with incremental support.
 - **Authentication**: HMAC-SHA256 and HMAC-SHA512.
 - **Key Management**: Generation, derivation (HKDF), and secure memory wiping.
 - **Fluent API**: Builder patterns for complex operations.
 
 ## Usage
 ```swift
 let crypto = CryptoManager.shared
 
 // Simple Hashing
 let hash = crypto.hash(string: "hello").encodedHex
 
 // File Encryption
 let key = crypto.generateKey()
 try await crypto.encryptFile(at: sourceURL, to: targetURL, key: key)
 
 // Using the Builder
 let complexHash = crypto.hashBuilder()
     .algorithm(.sha512)
     .append(string: "part1")
     .append(string: "part2")
     .salt(mySalt)
     .build()
 ```
 */
public final class CryptoManager: @unchecked Sendable {

    // MARK: - Singleton

    /// The default global instance of the `CryptoManager`.
    public static let shared = CryptoManager()

    // MARK: - Dependencies

    /// The active configuration for crypto defaults.
    public let config: CryptoConfig
    private let keyManagement: KeyManagementStrategy
    private let lock = NSLock()

    // MARK: - Init

    /**
     Initializes a new CryptoManager with custom settings.
     - Parameters:
        - config: Default algorithms and sizes.
        - keyManagement: The storage and derivation backend.
     */
    public init(
        config: CryptoConfig = CryptoConfig(),
        keyManagement: KeyManagementStrategy = DefaultKeyManagementStrategy()
    ) {
        self.config = config
        self.keyManagement = keyManagement
    }

    // MARK: - Encryption

    /**
     Encrypts raw data using a specified or default algorithm.
     - Parameters:
        - data: The plaintext to encrypt.
        - algorithm: The encryption scheme to use.
        - key: The symmetric key. If nil, a new one is generated.
        - iv: The initialization vector. If nil, a random one is generated.
     - Returns: A `CryptoResult` containing the ciphertext and algorithm info.
     */
    public func encrypt(_ data: Data, using algorithm: EncryptionAlgorithm? = nil, key: Data? = nil, iv: Data? = nil) async throws -> CryptoResult {
        let algo = algorithm ?? config.defaultEncryptionAlgorithm
        let strategy = encryptionStrategy(for: algo)
        let effectiveKey = key ?? keyManagement.generateSymmetricKey(size: config.defaultKeySize)
        let encrypted = try strategy.encrypt(data, key: effectiveKey, iv: iv)
        return CryptoResult(data: encrypted, algorithm: "\(algo)")
    }

    /**
     Decrypts ciphertext.
     - Parameters:
        - data: The combined ciphertext (nonce + payload + tag).
        - algorithm: The algorithm used during encryption.
        - key: The symmetric key.
        - iv: Optional IV if not combined in the data.
     - Returns: A `CryptoResult` containing the plaintext.
     */
    public func decrypt(_ data: Data, using algorithm: EncryptionAlgorithm? = nil, key: Data, iv: Data? = nil) async throws -> CryptoResult {
        let algo = algorithm ?? config.defaultEncryptionAlgorithm
        let strategy = encryptionStrategy(for: algo)
        let decrypted = try strategy.decrypt(data, key: key, iv: iv)
        return CryptoResult(data: decrypted, algorithm: "\(algo)")
    }

    /**
     Encrypts a file from disk to a new location.
     */
    public func encryptFile(at source: URL, to destination: URL, key: Data) async throws {
        let data = try Data(contentsOf: source)
        let result = try await encrypt(data, key: key)
        try result.data.write(to: destination)
    }

    /**
     Decrypts a file from disk to a new location.
     */
    public func decryptFile(at source: URL, to destination: URL, key: Data) async throws {
        let data = try Data(contentsOf: source)
        let result = try await decrypt(data, key: key)
        try result.data.write(to: destination)
    }

    // MARK: - Hashing

    /**
     Computes a hash for raw data.
     */
    public func hash(_ data: Data, algorithm: CryptoHashAlgorithm? = nil) -> CryptoResult {
        let algo = algorithm ?? config.defaultHashAlgorithm
        let strategy = HashingStrategyFactory.make(algorithm: algo)
        let hashed = strategy.hash(data)
        return CryptoResult(data: hashed, algorithm: "\(algo)")
    }

    /**
     Computes a hash for a string.
     */
    public func hash(string: String, algorithm: CryptoHashAlgorithm? = nil) -> CryptoResult {
        let data = Data(string.utf8)
        return hash(data, algorithm: algorithm)
    }

    /**
     Quick verification of a data hash.
     */
    public func verifyHash(_ data: Data, expectedHex: String, algorithm: CryptoHashAlgorithm? = nil) -> Bool {
        let algo = algorithm ?? config.defaultHashAlgorithm
        return HashingStrategyFactory.make(algorithm: algo).verify(data, against: expectedHex)
    }

    /**
     Returns an incremental hasher for large stream processing.
     */
    public func incrementalHasher() -> IncrementalHasher {
        return IncrementalHasher()
    }

    // MARK: - HMAC

    /**
     Signs data using HMAC-SHA256.
     */
    public func sign(_ data: Data, key: Data) -> CryptoResult {
        let strategy = HMACSHA256Strategy()
        let sig = strategy.sign(data, key: key)
        return CryptoResult(data: sig, algorithm: "HMAC-SHA256")
    }

    /**
     Verifies an HMAC signature using timing-attack safe comparison.
     */
    public func verifySignature(_ data: Data, signature: Data, key: Data) -> Bool {
        HMACSHA256Strategy().verify(data, signature: signature, key: key)
    }

    // MARK: - Key Management

    /// Generates a new random symmetric key.
    public func generateKey(size: CryptoKeySize? = nil) -> Data {
        keyManagement.generateSymmetricKey(size: size ?? config.defaultKeySize)
    }

    /// Derives a key from a password using PBKDF2.
    public func deriveKey(from password: String, salt: Data? = nil) -> Data {
        let effectiveSalt = salt ?? config.defaultSalt
        return keyManagement.deriveKey(
            from: password,
            salt: effectiveSalt,
            iterations: config.pbkdf2Iterations,
            keySize: config.defaultKeySize
        )
    }

    /// Stores a key in the key store.
    public func storeKey(_ key: Data, identifier: String) throws {
        try keyManagement.store(key: key, identifier: identifier)
    }

    /// Retrieves a stored key.
    public func retrieveKey(identifier: String) throws -> Data {
        try keyManagement.retrieve(identifier: identifier)
    }

    /// Rotates (replaces) an existing key.
    public func rotateKey(identifier: String) throws -> Data {
        try keyManagement.rotate(identifier: identifier)
    }

    /// Securely wipes key data from memory.
    public func wipeKey(_ key: inout Data) {
        keyManagement.wipe(&key)
    }

    // MARK: - Security Utilities

    /// Generates cryptographically secure random bytes.
    public func secureRandomBytes(count: Int) -> Data {
        SecureRandom.bytes(count: count)
    }

    /// Constant-time comparison to prevent timing attacks.
    public func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return lhs.withUnsafeBytes { (lhsBuf: UnsafeRawBufferPointer) in
            rhs.withUnsafeBytes { (rhsBuf: UnsafeRawBufferPointer) in
                var diff: UInt8 = 0
                for i in 0..<lhsBuf.count { diff |= lhsBuf[i] ^ rhsBuf[i] }
                return diff == 0
            }
        }
    }

    // MARK: - Builder

    /// Creates a fluent HashBuilder for complex hashing operations.
    public func hashBuilder() -> HashBuilder {
        return HashBuilder(config: config)
    }

    // MARK: - Private

    private func encryptionStrategy(for algorithm: EncryptionAlgorithm) -> EncryptionStrategy {
        switch algorithm {
        case .aesGcm:     return AESGCMStrategy()
        case .chachaPoly: return ChaChaPolyStrategy()
        case .mock:       return MockEncryptionStrategy()
        }
    }
}

// MARK: - CryptoConfig

/**
 Configuration for default cryptographic behavior.
 */
public struct CryptoConfig: Sendable {
    public var defaultEncryptionAlgorithm: EncryptionAlgorithm = .aesGcm
    public var defaultHashAlgorithm: CryptoHashAlgorithm = .sha256
    public var defaultKeySize: CryptoKeySize = .bits256
    public var pbkdf2Iterations: Int = 100_000
    public var defaultSalt: Data = SecureRandom.bytes(count: 32)
    public var outputEncoding: OutputEncoding = .base64

    public enum OutputEncoding: Sendable { case hex, base64, raw }

    public init() {}
}

/**
 Supported symmetric encryption algorithms.
 */
public enum EncryptionAlgorithm: Sendable {
    case aesGcm, chachaPoly, mock
}

// MARK: - HashBuilder (Fluent API)

/**
 # HashBuilder
 
 A fluent interface for building hash payloads.
 
 ## Usage
 ```swift
 let result = crypto.hashBuilder()
     .algorithm(.sha256)
     .append(string: "user-")
     .append(data: userID)
     .salt(sessionSalt)
     .build()
 ```
 */
public final class HashBuilder: @unchecked Sendable {
    private var data = Data()
    private var algorithm: CryptoHashAlgorithm = .sha256
    private var salt: Data?
    private let config: CryptoConfig

    public init(config: CryptoConfig) { self.config = config }

    /// Sets the algorithm for this builder.
    public func algorithm(_ algo: CryptoHashAlgorithm) -> Self { self.algorithm = algo; return self }
    /// Appends a string to the payload.
    public func append(string: String) -> Self { data.append(Data(string.utf8)); return self }
    /// Appends raw data to the payload.
    public func append(data: Data) -> Self { self.data.append(data); return self }
    /// Appends a salt to the payload.
    public func salt(_ s: Data) -> Self { self.salt = s; return self }

    /// Computes the final hash.
    public func build() -> CryptoResult {
        var payload = data
        if let salt { payload.append(salt) }
        let strategy = HashingStrategyFactory.make(algorithm: algorithm)
        return CryptoResult(data: strategy.hash(payload), algorithm: "\(algorithm)")
    }
}
