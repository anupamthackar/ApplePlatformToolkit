import Foundation

// MARK: - CryptoError

/// Typed errors from the ToolkitCrypto module.
public enum CryptoError: Error, Sendable, LocalizedError {
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidKey(String)
    case keyNotFound(String)
    case hashingFailed(String)
    case hmacFailed(String)
    case invalidInputSize
    case unsupportedAlgorithm

    public var errorDescription: String? {
        switch self {
        case .encryptionFailed(let r): return "Encryption failed: \(r)"
        case .decryptionFailed(let r): return "Decryption failed: \(r)"
        case .invalidKey(let r):       return "Invalid key: \(r)"
        case .keyNotFound(let id):     return "Key not found: \(id)"
        case .hashingFailed(let r):    return "Hashing failed: \(r)"
        case .hmacFailed(let r):       return "HMAC failed: \(r)"
        case .invalidInputSize:        return "Input data has an invalid size"
        case .unsupportedAlgorithm:    return "Algorithm is not supported"
        }
    }
}

// MARK: - CryptoResult

/// Strongly-typed result for crypto operations, pairing output with metadata.
public struct CryptoResult: Sendable {
    public let data: Data
    public let algorithm: String
    public let timestamp: Date
    public let encodedHex: String
    public let encodedBase64: String

    public init(data: Data, algorithm: String) {
        self.data = data
        self.algorithm = algorithm
        self.timestamp = Date()
        self.encodedHex = data.map { String(format: "%02x", $0) }.joined()
        self.encodedBase64 = data.base64EncodedString()
    }
}
