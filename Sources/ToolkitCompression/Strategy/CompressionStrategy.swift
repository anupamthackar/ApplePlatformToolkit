import Foundation
import Compression

// MARK: - Compression Strategy Documentation

/**
 # CompressionStrategy
 
 A protocol defining the interface for swappable compression algorithm implementations.
 Supports standard compression and decompression operations.
 
 ## Usage
 ```swift
 let strategy = AppleCompressionStrategy(algorithm: .lzfse)
 let data = Data("Compress me".utf8)
 
 // Compress
 let compressed = try strategy.compress(data)
 
 // Decompress (requires knowing the original size)
 let original = try strategy.decompress(compressed, originalSize: data.count)
 ```
 */
public protocol CompressionStrategy: Sendable {
    /// The algorithm implemented by this strategy.
    var algorithm: CompressionAlgorithm { get }
    
    /**
     Compresses the input data.
     - Parameter data: The raw data to compress.
     - Returns: The compressed data.
     - Throws: `CompressionError` if compression fails.
     */
    func compress(_ data: Data) throws -> Data
    
    /**
     Decompresses the input data back to its original state.
     - Parameters:
        - data: The compressed data.
        - originalSize: The size of the data before it was compressed.
     - Returns: The decompressed plaintext data.
     - Throws: `CompressionError` if decompression fails.
     */
    func decompress(_ data: Data, originalSize: Int) throws -> Data
}

// MARK: - Apple Compression Framework Strategy

/**
 Implementation of `CompressionStrategy` using Apple's native `Compression` framework.
 Leverages hardware acceleration where available.
 
 ## Supported Algorithms
 - **LZFSE**: Apple's recommended algorithm. High compression, low power.
 - **LZ4**: High speed, lower compression ratio.
 - **ZLIB**: Standard DEFLATE compatibility.
 - **LZMA**: Highest compression ratio, high memory/CPU cost.
 */
public struct AppleCompressionStrategy: CompressionStrategy {
    public let algorithm: CompressionAlgorithm
    private let filter: compression_algorithm

    public init(algorithm: CompressionAlgorithm) {
        self.algorithm = algorithm
        switch algorithm {
        case .lzfse: self.filter = COMPRESSION_LZFSE
        case .lz4:   self.filter = COMPRESSION_LZ4
        case .zlib:  self.filter = COMPRESSION_ZLIB
        case .lzma:  self.filter = COMPRESSION_LZMA
        }
    }

    public func compress(_ data: Data) throws -> Data {
        guard !data.isEmpty else { throw CompressionError.invalidData }
        // Estimate destination capacity. AEAD and metadata may add overhead.
        let destCapacity = data.count + 1024
        var destBuffer = [UInt8](repeating: 0, count: destCapacity)
        let resultSize = data.withUnsafeBytes { srcBytes -> Int in
            guard let srcPtr = srcBytes.baseAddress else { return 0 }
            return compression_encode_buffer(
                &destBuffer, destCapacity,
                srcPtr.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil, filter
            )
        }
        guard resultSize > 0 else { throw CompressionError.compressionFailed("compression_encode_buffer returned 0") }
        return Data(destBuffer.prefix(resultSize))
    }

    public func decompress(_ data: Data, originalSize: Int) throws -> Data {
        guard !data.isEmpty else { throw CompressionError.invalidData }
        var destBuffer = [UInt8](repeating: 0, count: originalSize)
        let resultSize = data.withUnsafeBytes { srcBytes -> Int in
            guard let srcPtr = srcBytes.baseAddress else { return 0 }
            return compression_decode_buffer(
                &destBuffer, originalSize,
                srcPtr.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil, filter
            )
        }
        guard resultSize > 0 else { throw CompressionError.decompressionFailed("compression_decode_buffer returned 0") }
        return Data(destBuffer.prefix(resultSize))
    }
}

// MARK: - Mock Strategy (Testing)

/**
 A pass-through compression strategy for unit testing.
 Returns data as-is without any actual compression.
 */
public struct MockCompressionStrategy: CompressionStrategy {
    public let algorithm: CompressionAlgorithm = .lzfse
    public init() {}
    public func compress(_ data: Data) throws -> Data { data }
    public func decompress(_ data: Data, originalSize: Int) throws -> Data { data }
}
