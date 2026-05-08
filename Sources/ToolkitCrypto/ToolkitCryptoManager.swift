import Foundation
import CryptoKit
import ToolkitCore

// MARK: - Crypto Manager Documentation

/**
 # CryptoManager
 
 The central entry point for the Toolkit's cryptographic services.
 It unifies encryption, hashing, HMAC, and key management into a high-level, strategy-based API.
 
 ## Features
 - **Authenticated Encryption**: Support for AES-GCM and ChaChaPoly.
 - **Secure Hashing**: SHA256, SHA384, and SHA512 with incremental support.
 - **Message Authentication**: HMAC-SHA256 and HMAC-SHA512 implementations.
 - **Key Management**: Generation, PBKDF2 derivation, and secure memory wiping.
 - **Fluent API**: Builder patterns for complex, multi-stage hashing operations.
 
 ## Usage
 ```swift
 let crypto = CryptoManager.shared
 
 // Simple Hashing
 let hash = crypto.hash(string: "hello").encodedHex
 
 // File Encryption
 let key = crypto.generateKey()
 try await crypto.encryptFile(at: sourceURL, to: targetURL, key: key)
 ```
 */
public final class CryptoManager: @unchecked Sendable {

    // MARK: - Singleton

    /// The default global instance of the `CryptoManager`.
    public static let shared = CryptoManager()

    // MARK: - Dependencies

    /// The active configuration for crypto defaults like algorithms and salt.
    public let config: CryptoConfig
    
    private let keyManagement: KeyManagementStrategy
    private let lock = NSLock()

    // MARK: - Init

    /**
     Initializes a new CryptoManager with custom settings.
     
     - Parameters:
        - config: Default algorithms and key sizes. Defaults to `CryptoConfig()`.
        - keyManagement: The storage and derivation backend. Defaults to `DefaultKeyManagementStrategy()`.
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
        - data: The plaintext data to encrypt.
        - algorithm: The encryption scheme to use. Defaults to the configured default.
        - key: The symmetric key. If nil, a new one is generated automatically.
        - iv: The initialization vector. If nil, a random one is generated.
     - Returns: A `CryptoResult` containing the ciphertext and algorithm information.
     - Throws: `ToolkitError` if encryption fails.
     */
    public func encrypt(_ data: Data, using algorithm: EncryptionAlgorithm? = nil, key: Data? = nil, iv: Data? = nil) async throws -> CryptoResult {
        let algo = algorithm ?? config.defaultEncryptionAlgorithm
        let strategy = encryptionStrategy(for: algo)
        let effectiveKey = key ?? keyManagement.generateSymmetricKey(size: config.defaultKeySize)
        let encrypted = try strategy.encrypt(data, key: effectiveKey, iv: iv)
        return CryptoResult(data: encrypted, algorithm: "\(algo)")
    }

    /**
     Decrypts ciphertext using a specified or default algorithm.
     
     - Parameters:
        - data: The combined ciphertext (usually nonce + payload + tag).
        - algorithm: The algorithm used during encryption.
        - key: The symmetric key used for encryption.
        - iv: Optional IV if it is not already embedded in the data.
     - Returns: A `CryptoResult` containing the decrypted plaintext.
     - Throws: `ToolkitError` if decryption or authentication fails.
     */
    public func decrypt(_ data: Data, using algorithm: EncryptionAlgorithm? = nil, key: Data, iv: Data? = nil) async throws -> CryptoResult {
        let algo = algorithm ?? config.defaultEncryptionAlgorithm
        let strategy = encryptionStrategy(for: algo)
        let decrypted = try strategy.decrypt(data, key: key, iv: iv)
        return CryptoResult(data: decrypted, algorithm: "\(algo)")
    }

    /**
     Encrypts a file from disk and saves the result to a new location.
     
     - Parameters:
        - source: The URL of the plaintext file.
        - destination: The target URL for the encrypted file.
        - key: The symmetric key to use.
     - Throws: `Error` if file I/O or encryption fails.
     */
    public func encryptFile(at source: URL, to destination: URL, key: Data) async throws {
        let data = try Data(contentsOf: source)
        let result = try await encrypt(data, key: key)
        try result.data.write(to: destination)
    }

    /**
     Decrypts a file from disk and saves the result to a new location.
     
     - Parameters:
        - source: The URL of the encrypted file.
        - destination: The target URL for the decrypted file.
        - key: The symmetric key to use.
     - Throws: `Error` if file I/O or decryption fails.
     */
    public func decryptFile(at source: URL, to destination: URL, key: Data) async throws {
        let data = try Data(contentsOf: source)
        let result = try await decrypt(data, key: key)
        try result.data.write(to: destination)
    }

    // MARK: - Hashing

    /**
     Computes a cryptographic hash for raw data.
     
     - Parameters:
        - data: The input data to hash.
        - algorithm: The hash algorithm to use (e.g., SHA256).
     - Returns: A `CryptoResult` containing the hash digest.
     */
    public func hash(_ data: Data, algorithm: CryptoHashAlgorithm? = nil) -> CryptoResult {
        let algo = algorithm ?? config.defaultHashAlgorithm
        let strategy = HashingStrategyFactory.make(algorithm: algo)
        let hashed = strategy.hash(data)
        return CryptoResult(data: hashed, algorithm: "\(algo)")
    }

    /**
     Computes a cryptographic hash for a string.
     
     - Parameters:
        - string: The input string to hash.
        - algorithm: The hash algorithm to use.
     - Returns: A `CryptoResult` containing the hash digest.
     */
    public func hash(string: String, algorithm: CryptoHashAlgorithm? = nil) -> CryptoResult {
        let data = Data(string.utf8)
        return hash(data, algorithm: algorithm)
    }

    /**
     Verifies if the hash of the provided data matches an expected hex string.
     
     - Parameters:
        - data: The data to verify.
        - expectedHex: The expected hash digest in hexadecimal format.
        - algorithm: The algorithm to use for hashing.
     - Returns: `true` if the hashes match.
     */
    public func verifyHash(_ data: Data, expectedHex: String, algorithm: CryptoHashAlgorithm? = nil) -> Bool {
        let algo = algorithm ?? config.defaultHashAlgorithm
        return HashingStrategyFactory.make(algorithm: algo).verify(data, against: expectedHex)
    }

    /**
     Returns an incremental hasher for processing large streams of data.
     - Returns: A new `IncrementalHasher` instance.
     */
    public func incrementalHasher() -> IncrementalHasher {
        return IncrementalHasher()
    }

    // MARK: - HMAC

    /**
     Signs data using HMAC with the specified key.
     
     - Parameters:
        - data: The data to sign.
        - key: The secret key for signing.
     - Returns: A `CryptoResult` containing the HMAC signature.
     */
    public func sign(_ data: Data, key: Data) -> CryptoResult {
        let strategy = HMACSHA256Strategy()
        let sig = strategy.sign(data, key: key)
        return CryptoResult(data: sig, algorithm: "HMAC-SHA256")
    }

    /**
     Verifies an HMAC signature using timing-attack safe comparison.
     
     - Parameters:
        - data: The original data.
        - signature: The signature to verify.
        - key: The secret key used for signing.
     - Returns: `true` if the signature is valid.
     */
    public func verifySignature(_ data: Data, signature: Data, key: Data) -> Bool {
        HMACSHA256Strategy().verify(data, signature: signature, key: key)
    }

    // MARK: - Key Management

    /// Generates a new random symmetric key.
    /// - Parameter size: The desired key size. Defaults to the configured default (usually 256 bits).
    /// - Returns: Binary key data.
    public func generateKey(size: CryptoKeySize? = nil) -> Data {
        keyManagement.generateSymmetricKey(size: size ?? config.defaultKeySize)
    }

    /// Derives a cryptographic key from a password using PBKDF2.
    /// - Parameters:
    ///   - password: The user's password.
    ///   - salt: The salt to use. If nil, the default salt is used.
    /// - Returns: The derived key data.
    public func deriveKey(from password: String, salt: Data? = nil) -> Data {
        let effectiveSalt = salt ?? config.defaultSalt
        return keyManagement.deriveKey(
            from: password,
            salt: effectiveSalt,
            iterations: config.pbkdf2Iterations,
            keySize: config.defaultKeySize
        )
    }

    /// Persists a key in the secure system keystore (e.g., Keychain).
    /// - Parameters:
    ///   - key: The key data to store.
    ///   - identifier: A unique name for the key.
    /// - Throws: `ToolkitError` if storage fails.
    public func storeKey(_ key: Data, identifier: String) throws {
        try keyManagement.store(key: key, identifier: identifier)
    }

    /// Retrieves a previously stored key from the keystore.
    /// - Parameter identifier: The unique name used when storing the key.
    /// - Returns: The retrieved key data.
    /// - Throws: `ToolkitError` if the key is not found.
    public func retrieveKey(identifier: String) throws -> Data {
        try keyManagement.retrieve(identifier: identifier)
    }

    /// Rotates a key by generating a new one and updating the keystore.
    /// - Parameter identifier: The key identifier to rotate.
    /// - Returns: The new key data.
    /// - Throws: `ToolkitError` if rotation fails.
    public func rotateKey(identifier: String) throws -> Data {
        try keyManagement.rotate(identifier: identifier)
    }

    /// Securely wipes key data from memory by overwriting it with zeros.
    /// - Parameter key: The mutable data buffer to wipe.
    public func wipeKey(_ key: inout Data) {
        keyManagement.wipe(&key)
    }

    // MARK: - Security Utilities

    /// Generates cryptographically secure random bytes.
    /// - Parameter count: The number of bytes to generate.
    /// - Returns: Random binary data.
    public func secureRandomBytes(count: Int) -> Data {
        SecureRandom.bytes(count: count)
    }

    /// Performs a constant-time comparison of two Data buffers.
    /// This is used to prevent timing attacks when comparing sensitive info like hashes or signatures.
    /// - Parameters:
    ///   - lhs: First buffer.
    ///   - rhs: Second buffer.
    /// - Returns: `true` if buffers are identical.
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

    /// Creates a fluent HashBuilder for creating complex hashing pipelines.
    /// - Returns: A new `HashBuilder` instance.
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
 # CryptoConfig
 
 Global configuration for the `CryptoManager`, defining default algorithms, iteration counts, and encoding preferences.
 */
public struct CryptoConfig: Sendable {
    /// The default symmetric encryption algorithm. Defaults to `.aesGcm`.
    public var defaultEncryptionAlgorithm: EncryptionAlgorithm = .aesGcm
    /// The default hashing algorithm. Defaults to `.sha256`.
    public var defaultHashAlgorithm: CryptoHashAlgorithm = .sha256
    /// The default bit-size for generated keys. Defaults to 256 bits.
    public var defaultKeySize: CryptoKeySize = .bits256
    /// Number of iterations for PBKDF2 key derivation. Defaults to 100,000.
    public var pbkdf2Iterations: Int = 100_000
    /// The default salt used for derivation.
    public var defaultSalt: Data = SecureRandom.bytes(count: 32)
    /// Preferred output encoding for results.
    public var outputEncoding: OutputEncoding = .base64

    /// Supported encoding formats for cryptographic output.
    public enum OutputEncoding: Sendable { case hex, base64, raw }

    /// Initializes a default configuration.
    public init() {}
}

/// Supported symmetric encryption algorithms.
public enum EncryptionAlgorithm: Sendable {
    /// Advanced Encryption Standard with Galois/Counter Mode.
    case aesGcm
    /// ChaCha20 stream cipher with Poly1305 authenticator.
    case chachaPoly
    /// A mock algorithm for testing environments.
    case mock
}

// MARK: - HashBuilder (Fluent API)

/**
 # HashBuilder
 
 A fluent interface for building hash digests by appending multiple data segments.
 
 ## Usage
 ```swift
 let result = crypto.hashBuilder()
     .algorithm(.sha512)
     .append(string: "header:")
     .append(data: payload)
     .salt(sessionSalt)
     .build()
 ```
 */
public final class HashBuilder: @unchecked Sendable {
    private var data = Data()
    private var algorithm: CryptoHashAlgorithm = .sha256
    private var salt: Data?
    private let config: CryptoConfig

    /// Initializes the builder.
    public init(config: CryptoConfig) { self.config = config }

    /// Sets the algorithm for the final hash.
    /// - Parameter algo: The algorithm to use.
    /// - Returns: `Self` for chaining.
    public func algorithm(_ algo: CryptoHashAlgorithm) -> Self { self.algorithm = algo; return self }
    
    /// Appends a UTF-8 string to the hashing buffer.
    /// - Parameter string: The string to append.
    /// - Returns: `Self` for chaining.
    public func append(string: String) -> Self { data.append(Data(string.utf8)); return self }
    
    /// Appends raw binary data to the hashing buffer.
    /// - Parameter data: The data to append.
    /// - Returns: `Self` for chaining.
    public func append(data: Data) -> Self { self.data.append(data); return self }
    
    /// Appends a salt to the hashing buffer.
    /// - Parameter s: The salt data.
    /// - Returns: `Self` for chaining.
    public func salt(_ s: Data) -> Self { self.salt = s; return self }

    /// Computes and returns the final cryptographic hash digest.
    /// - Returns: A `CryptoResult` containing the digest.
    public func build() -> CryptoResult {
        var payload = data
        if let salt { payload.append(salt) }
        let strategy = HashingStrategyFactory.make(algorithm: algorithm)
        return CryptoResult(data: strategy.hash(payload), algorithm: "\(algorithm)")
    }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitCrypto module.
    static var crypto: CryptoManager { CryptoManager.shared }
}
