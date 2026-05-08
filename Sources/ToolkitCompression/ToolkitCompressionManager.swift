import Foundation
import ToolkitCore

// MARK: - Compression Manager Documentation

/**
 # CompressionManager
 
 The primary entry point for high-performance data compression services within the toolkit.
 It supports a variety of system-level algorithms (LZFSE, LZ4, ZLIB, LZMA) and provides
 optimized workflows for in-memory, file-based, and streaming data.
 
 ## Features
 - **Multi-Algorithm**: Native support for Apple's `Compression` framework.
 - **Batch Processing**: Parallel compression of multiple data sets using `TaskGroup`.
 - **Streaming**: Chunked, memory-efficient processing for massive payloads.
 - **Integrity**: Built-in CRC32 checksum generation and verification.
 - **Fluent Builder**: Easy configuration using the `CompressionBuilder` pattern.
 
 ## Usage
 ```swift
 // 1. Configure via Builder
 let manager = CompressionBuilder()
     .algorithm(.lzfse)
     .chunkSize(128_000)
     .build()
 
 // 2. Compress in-memory
 let result = try await manager.compress(myData)
 print("Compression Ratio: \(manager.formatRatio(result))")
 
 // 3. Compress a file
 try await manager.compressFile(at: sourceURL, to: targetURL)
 ```
 */
public final class CompressionManager: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared global instance with default LZFSE settings for general use.
    public static let shared = CompressionManager()

    // MARK: - Dependencies

    /// The current configuration including algorithm, compression level, and chunk size.
    public let config: CompressionConfig
    
    private let strategy: CompressionStrategy
    private let logger: LoggerProtocol?

    // MARK: - Init

    /**
     Initializes a manager with specific dependencies and configuration.
     
     - Parameters:
        - config: Algorithm and performance options. Defaults to `CompressionConfig()`.
        - strategy: A custom strategy implementation. Defaults to `AppleCompressionStrategy`.
        - logger: Optional logging provider for lifecycle events.
     */
    public init(
        config: CompressionConfig = CompressionConfig(),
        strategy: CompressionStrategy? = nil,
        logger: LoggerProtocol? = nil
    ) {
        self.config = config
        self.strategy = strategy ?? AppleCompressionStrategy(algorithm: config.algorithm)
        self.logger = logger
    }

    // MARK: - In-Memory Compression

    /**
     Compresses a block of data asynchronously.
     
     - Parameter data: The raw input bytes to compress.
     - Returns: A `CompressionResult` containing the compressed bytes and performance metadata.
     - Throws: `CompressionError` if the operation fails.
     */
    public func compress(_ data: Data) async throws -> CompressionResult {
        let start = Date()
        logger?.log("Compressing \(data.count) bytes", level: .debug, file: #file, function: #function, line: #line)
        let compressed = try strategy.compress(data)
        let duration = Date().timeIntervalSince(start)
        return CompressionResult(
            data: compressed,
            originalSize: data.count,
            compressedSize: compressed.count,
            algorithm: config.algorithm,
            durationSeconds: duration
        )
    }

    /**
     Decompresses a block of data asynchronously.
     
     - Parameters:
        - data: The compressed bytes to decompress.
        - originalSize: The expected size of the resulting decompressed data.
     - Returns: A `CompressionResult` containing the decompressed bytes and metadata.
     - Throws: `CompressionError` if decompression fails.
     */
    public func decompress(_ data: Data, originalSize: Int) async throws -> CompressionResult {
        let start = Date()
        let decompressed = try strategy.decompress(data, originalSize: originalSize)
        let duration = Date().timeIntervalSince(start)
        return CompressionResult(
            data: decompressed,
            originalSize: data.count,
            compressedSize: decompressed.count,
            algorithm: config.algorithm,
            durationSeconds: duration
        )
    }

    // MARK: - File Compression

    /**
     Reads a file from disk, compresses it, and writes the output to a new location.
     
     - Parameters:
        - source: The URL of the source file.
        - destination: The target URL for the compressed output.
     - Returns: Performance metadata for the operation.
     - Throws: `Error` if file I/O or compression fails.
     */
    public func compressFile(at source: URL, to destination: URL) async throws -> CompressionResult {
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw CompressionError.fileNotFound(source.path)
        }
        let data = try Data(contentsOf: source)
        let result = try await compress(data)
        try result.data.write(to: destination)
        return result
    }

    /**
     Reads a compressed file from disk, decompresses it, and writes the output to a new location.
     
     - Parameters:
        - source: The URL of the compressed source file.
        - destination: The target URL for the decompressed output.
        - originalSize: The expected size of the final decompressed file.
     - Returns: Performance metadata for the operation.
     - Throws: `Error` if file I/O or decompression fails.
     */
    public func decompressFile(at source: URL, to destination: URL, originalSize: Int) async throws -> CompressionResult {
        let data = try Data(contentsOf: source)
        let result = try await decompress(data, originalSize: originalSize)
        try result.data.write(to: destination)
        return result
    }

    // MARK: - Batch Compression

    /**
     Compresses multiple data items concurrently using optimized parallel tasks.
     
     - Parameter items: An array of `Data` objects to process.
     - Returns: An array of `CompressionResult` objects, corresponding to the input items.
     - Throws: `CompressionError` if any single item fails to compress.
     */
    public func batchCompress(_ items: [Data]) async throws -> [CompressionResult] {
        try await withThrowingTaskGroup(of: CompressionResult.self) { group in
            for item in items {
                group.addTask { try await self.compress(item) }
            }
            var results: [CompressionResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    // MARK: - Streaming Session

    /**
     Creates a stateful streaming session for processing large datasets in chunks.
     
     - Returns: A new `StreamingCompressionSession` instance.
     */
    public func streamingSession() -> StreamingCompressionSession {
        StreamingCompressionSession(strategy: strategy, chunkSize: config.chunkSize)
    }

    // MARK: - Checksum / Integrity

    /**
     Calculates a CRC32 checksum for the given data.
     
     - Parameter data: The input data.
     - Returns: A 32-bit unsigned integer checksum.
     */
    public func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (0xEDB88320 * (crc & 1))
            }
        }
        return ~crc
    }

    /**
     Verifies if the data matches an expected CRC32 checksum.
     
     - Parameters:
        - data: The data to verify.
        - expectedChecksum: The checksum value to compare against.
     - Returns: `true` if the calculated checksum matches the expected value.
     */
    public func verifyIntegrity(data: Data, expectedChecksum: UInt32) -> Bool {
        return checksum(data) == expectedChecksum
    }

    // MARK: - Metrics

    /**
     Returns a human-readable summary of the compression performance (ratio and space saved).
     
     - Parameter result: The compression result to format.
     - Returns: A string like "45.0% smaller (2.22x ratio)".
     */
    public func formatRatio(_ result: CompressionResult) -> String {
        String(format: "%.1f%% smaller (%.2fx ratio)", result.spaceSaved * 100, 1.0 / max(result.ratio, 0.01))
    }
}

// MARK: - CompressionBuilder

/**
 # CompressionBuilder
 
 A fluent builder for creating and configuring customized `CompressionManager` instances.
 */
public final class CompressionBuilder {
    private var algorithm: CompressionAlgorithm = .lzfse
    private var level: CompressionLevel = .medium
    private var chunkSize: Int = 65536
    private var verifyChecksum: Bool = true
    private var customStrategy: CompressionStrategy?

    /// Initializes a new builder instance.
    public init() {}

    /// Sets the algorithm for the manager (e.g., `.lzfse`, `.zlib`).
    public func algorithm(_ algo: CompressionAlgorithm) -> Self { self.algorithm = algo; return self }
    
    /// Sets the compression effort level (speed vs. size ratio).
    public func level(_ level: CompressionLevel) -> Self { self.level = level; return self }
    
    /// Sets the chunk size for streaming and file operations in bytes.
    public func chunkSize(_ size: Int) -> Self { self.chunkSize = size; return self }
    
    /// Enables or disables automatic CRC32 verification.
    public func verifyChecksum(_ verify: Bool) -> Self { self.verifyChecksum = verify; return self }
    
    /// Injects a custom compression strategy implementation.
    public func customStrategy(_ strategy: CompressionStrategy) -> Self { self.customStrategy = strategy; return self }

    /// Finalizes the configuration and returns a configured `CompressionManager`.
    public func build() -> CompressionManager {
        var config = CompressionConfig()
        config.algorithm = algorithm
        config.level = level
        config.chunkSize = chunkSize
        config.verifyChecksum = verifyChecksum
        let strategy = customStrategy ?? AppleCompressionStrategy(algorithm: algorithm)
        return CompressionManager(config: config, strategy: strategy)
    }
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitCompression module.
    static var compression: CompressionManager { CompressionManager.shared }
}
