import Foundation
import Compression

// MARK: - CompressionAlgorithm

/// Supported compression algorithms.
public enum CompressionAlgorithm: Sendable {
    case lzfse
    case lz4
    case zlib
    case lzma
}

// MARK: - CompressionLevel

public enum CompressionLevel: Sendable {
    case low, medium, high, max
}

// MARK: - CompressionError

public enum CompressionError: Error, LocalizedError, Sendable {
    case compressionFailed(String)
    case decompressionFailed(String)
    case invalidData
    case unsupportedAlgorithm
    case fileTooLarge(Int64)
    case checksumMismatch
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .compressionFailed(let r):  return "Compression failed: \(r)"
        case .decompressionFailed(let r): return "Decompression failed: \(r)"
        case .invalidData:               return "Input data is invalid or corrupted"
        case .unsupportedAlgorithm:      return "The selected algorithm is not supported"
        case .fileTooLarge(let size):    return "File too large: \(size) bytes"
        case .checksumMismatch:          return "Checksum verification failed"
        case .fileNotFound(let path):    return "File not found at \(path)"
        }
    }
}

// MARK: - CompressionResult

public struct CompressionResult: Sendable {
    public let data: Data
    public let originalSize: Int
    public let compressedSize: Int
    public let algorithm: CompressionAlgorithm
    public let durationSeconds: Double
    public var ratio: Double { originalSize > 0 ? Double(compressedSize) / Double(originalSize) : 0 }
    public var spaceSaved: Double { 1.0 - ratio }
}

// MARK: - CompressionConfig

public struct CompressionConfig: Sendable {
    public var algorithm: CompressionAlgorithm = .lzfse
    public var level: CompressionLevel = .medium
    public var chunkSize: Int = 65536  // 64KB
    public var verifyChecksum: Bool = true

    public init() {}
}
