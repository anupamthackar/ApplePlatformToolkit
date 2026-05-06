import Foundation
import CryptoKit

// MARK: - Hashing Strategy Documentation

/**
 # HashingStrategy
 
 A protocol defining the interface for cryptographic hashing algorithms.
 Use this to generate digests for data integrity verification and secure identification.
 
 ## Usage
 ```swift
 let strategy = SHA256HashingStrategy()
 let data = Data("Hello World".utf8)
 
 // Get hex digest
 let hex = strategy.hashHex(data)
 print("SHA256: \(hex)")
 
 // Verify integrity
 let isValid = strategy.verify(data, against: hex)
 ```
 */
public protocol HashingStrategy: Sendable {
    /**
     Computes the raw binary hash digest of the input data.
     - Parameter data: The input data to hash.
     - Returns: The raw digest as `Data`.
     */
    func hash(_ data: Data) -> Data
    
    /**
     Computes the hash digest and returns it as a hexadecimal string.
     - Parameter data: The input data to hash.
     - Returns: The lowercase hexadecimal digest string.
     */
    func hashHex(_ data: Data) -> String
    
    /**
     Computes the hash digest and returns it as a Base64 encoded string.
     - Parameter data: The input data to hash.
     - Returns: The Base64 encoded digest string.
     */
    func hashBase64(_ data: Data) -> String
    
    /**
     Verifies if the hash of the input data matches an expected hexadecimal string.
     - Parameters:
        - data: The data to verify.
        - expectedHex: The expected hexadecimal digest.
     - Returns: `true` if the hashes match, otherwise `false`.
     */
    func verify(_ data: Data, against expectedHex: String) -> Bool
}

/**
 Supported cryptographic hashing algorithms.
 */
public enum CryptoHashAlgorithm: Sendable {
    /// Secure Hash Algorithm 2 (256-bit). Recommended for general use.
    case sha256
    /// Secure Hash Algorithm 2 (384-bit). Often used in top-secret applications.
    case sha384
    /// Secure Hash Algorithm 2 (512-bit). Most secure of the SHA-2 family.
    case sha512
}

// MARK: - SHA256 Strategy

/// Implementation of `HashingStrategy` using the SHA256 algorithm.
public struct SHA256HashingStrategy: HashingStrategy {
    public init() {}
    public func hash(_ data: Data) -> Data { Data(SHA256.hash(data: data)) }
    public func hashHex(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    public func hashBase64(_ data: Data) -> String { hash(data).base64EncodedString() }
    public func verify(_ data: Data, against expectedHex: String) -> Bool { hashHex(data) == expectedHex }
}

// MARK: - SHA384 Strategy

/// Implementation of `HashingStrategy` using the SHA384 algorithm.
public struct SHA384HashingStrategy: HashingStrategy {
    public init() {}
    public func hash(_ data: Data) -> Data { Data(SHA384.hash(data: data)) }
    public func hashHex(_ data: Data) -> String { SHA384.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    public func hashBase64(_ data: Data) -> String { hash(data).base64EncodedString() }
    public func verify(_ data: Data, against expectedHex: String) -> Bool { hashHex(data) == expectedHex }
}

// MARK: - SHA512 Strategy

/// Implementation of `HashingStrategy` using the SHA512 algorithm.
public struct SHA512HashingStrategy: HashingStrategy {
    public init() {}
    public func hash(_ data: Data) -> Data { Data(SHA512.hash(data: data)) }
    public func hashHex(_ data: Data) -> String { SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    public func hashBase64(_ data: Data) -> String { hash(data).base64EncodedString() }
    public func verify(_ data: Data, against expectedHex: String) -> Bool { hashHex(data) == expectedHex }
}

// MARK: - Incremental Hasher

/**
 # IncrementalHasher
 
 Supports streaming or chunked SHA256 hashing for large files or network streams.
 This avoids loading large amounts of data into memory at once.
 
 ## Usage
 ```swift
 let hasher = IncrementalHasher()
 hasher.update(with: chunk1)
 hasher.update(with: chunk2)
 let finalDigest = hasher.finalize()
 ```
 */
public final class IncrementalHasher: @unchecked Sendable {
    private var hasher = SHA256()

    public init() {}

    /// Updates the hash state with the provided chunk of data.
    public func update(with data: Data) {
        hasher.update(data: data)
    }

    /// Finalizes the hash state and returns the hexadecimal digest.
    public func finalize() -> String {
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Factory

/**
 A factory for creating `HashingStrategy` instances based on the algorithm type.
 */
public struct HashingStrategyFactory {
    public static func make(algorithm: CryptoHashAlgorithm) -> HashingStrategy {
        switch algorithm {
        case .sha256: return SHA256HashingStrategy()
        case .sha384: return SHA384HashingStrategy()
        case .sha512: return SHA512HashingStrategy()
        }
    }
}
