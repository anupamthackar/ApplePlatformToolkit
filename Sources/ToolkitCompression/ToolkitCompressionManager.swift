import Foundation
import ToolkitCore

// MARK: - Compression Manager Documentation

/**
 # CompressionManager
 
 The primary entry point for high-performance data compression services.
 It supports in-memory compression, file-based batch processing, and chunked streaming.
 
 ## Features
 - **Multi-Algorithm**: Support for LZFSE, LZ4, ZLIB, and LZMA via strategy pattern.
 - **Batch Processing**: Parallel compression of multiple datasets using Swift Concurrency.
 - **Streaming**: AsyncStream-based chunked processing for massive files without memory spikes.
 - **Integrity**: Built-in CRC32 checksums for data verification.
 - **Fluent Builder**: Easy configuration through `CompressionBuilder`.
 
 ## Usage
 ```swift
 let manager = CompressionBuilder()
     .algorithm(.lzfse)
     .chunkSize(128_000)
     .build()
 
 // In-memory
 let result = try await manager.compress(myData)
 
 // File
 try await manager.compressFile(at: source, to: dest)
 
 // Parallel batch
 let results = try await manager.batchCompress([d1, d2, d3])
 ```
 */
public final class CompressionManager: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared global instance with default LZFSE settings.
    public static let shared = CompressionManager()

    // MARK: - Dependencies

    /// Current algorithm and performance settings.
    public let config: CompressionConfig
    private let strategy: CompressionStrategy
    private let logger: LoggerProtocol?

    // MARK: - Init

    /**
     Initializes a manager with specific dependencies.
     - Parameters:
        - config: Algorithm and performance options.
        - strategy: A custom strategy implementation (defaults to `AppleCompressionStrategy`).
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
     Compresses a block of data synchronously (but within an async context).
     - Parameter data: The raw input bytes.
     - Returns: A `CompressionResult` with metadata and compressed bytes.
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
     Decompresses a block of data.
     - Parameters:
        - data: The compressed bytes.
        - originalSize: The expected size of the output data (required by system algorithms).
     - Returns: A `CompressionResult` with metadata and decompressed bytes.
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
     Reads a file from disk, compresses it, and writes the result to a new file.
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
     Reads a compressed file, decompresses it, and writes the result to a new file.
     */
    public func decompressFile(at source: URL, to destination: URL, originalSize: Int) async throws -> CompressionResult {
        let data = try Data(contentsOf: source)
        let result = try await decompress(data, originalSize: originalSize)
        try result.data.write(to: destination)
        return result
    }

    // MARK: - Batch Compression

    /**
     Compresses multiple items concurrently using a `TaskGroup`.
     - Parameter items: An array of `Data` objects to process.
     - Returns: An array of `CompressionResult` objects.
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
     Creates a stateful streaming session for large data sets.
     */
    public func streamingSession() -> StreamingCompressionSession {
        StreamingCompressionSession(strategy: strategy, chunkSize: config.chunkSize)
    }

    // MARK: - Checksum / Integrity

    /**
     Calculates a CRC32 checksum for the given data.
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
     Verifies if the data matches an expected checksum.
     */
    public func verifyIntegrity(data: Data, expectedChecksum: UInt32) -> Bool {
        return checksum(data) == expectedChecksum
    }

    // MARK: - Metrics

    /**
     Returns a formatted summary of the compression performance.
     */
    public func formatRatio(_ result: CompressionResult) -> String {
        String(format: "%.1f%% smaller (%.2fx ratio)", result.spaceSaved * 100, 1.0 / max(result.ratio, 0.01))
    }
}

// MARK: - CompressionBuilder

/**
 A fluent builder for creating customized `CompressionManager` instances.
 */
public final class CompressionBuilder {
    private var algorithm: CompressionAlgorithm = .lzfse
    private var level: CompressionLevel = .medium
    private var chunkSize: Int = 65536
    private var verifyChecksum: Bool = true
    private var customStrategy: CompressionStrategy?

    public init() {}

    /// Sets the algorithm to use (e.g., .lz4, .zlib).
    public func algorithm(_ algo: CompressionAlgorithm) -> Self { self.algorithm = algo; return self }
    /// Sets the performance/compression ratio trade-off level.
    public func level(_ level: CompressionLevel) -> Self { self.level = level; return self }
    /// Sets the chunk size for streaming and file operations.
    public func chunkSize(_ size: Int) -> Self { self.chunkSize = size; return self }
    /// Enables automatic CRC32 verification.
    public func verifyChecksum(_ verify: Bool) -> Self { self.verifyChecksum = verify; return self }
    /// Injects a custom strategy implementation.
    public func customStrategy(_ strategy: CompressionStrategy) -> Self { self.customStrategy = strategy; return self }

    /// Finalizes the configuration and returns a manager.
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
