import Foundation
import ToolkitCore

// MARK: - Streaming Compression Documentation

/**
 # StreamingCompressionSession
 
 A high-level session manager for performing chunked compression on large files or data streams.
 Supports pausing, resuming, and progress tracking via `AsyncStream`.
 
 ## Usage
 ```swift
 let session = StreamingCompressionSession(strategy: myStrategy)
 
 // Start streaming compression
 let stream = session.compress(fileAt: bigFileURL)
 
 Task {
     for await chunk in stream {
         // Upload or write chunk to disk
         print("Processed: \(Int(session.progress * 100))%")
     }
 }
 
 // Lifecycle control
 session.pause()
 session.resume()
 session.cancel()
 ```
 */
public final class StreamingCompressionSession: @unchecked Sendable {

    /// The lifecycle states of a compression session.
    public enum State: Sendable {
        /// Session created but not started.
        case idle
        /// Actively processing data.
        case running
        /// Temporarily halted by user.
        case paused
        /// Terminated before completion.
        case cancelled
        /// Successfully finished processing all data.
        case completed
    }

    /// The current operational state of the session.
    public private(set) var state: State = .idle
    /// The number of raw (uncompressed) bytes processed so far.
    public private(set) var processedBytes: Int64 = 0
    /// The total size of the source data.
    public private(set) var totalBytes: Int64 = 0

    private let strategy: CompressionStrategy
    private let chunkSize: Int
    private var continuation: AsyncStream<Data>.Continuation?
    private var task: Task<Void, Never>?
    private let lock = NSLock()

    /**
     Initializes a new streaming session.
     - Parameters:
        - strategy: The algorithm strategy to use for each chunk.
        - chunkSize: The size of each uncompressed data block (default 64KB).
     */
    public init(strategy: CompressionStrategy, chunkSize: Int = 65536) {
        self.strategy = strategy
        self.chunkSize = chunkSize
    }

    // MARK: - Stream Execution

    /**
     Begins compressing a file and returns a stream of compressed chunks.
     - Parameter url: The file system URL of the source file.
     - Returns: An `AsyncStream` emitting compressed `Data` blocks.
     */
    public func compress(fileAt url: URL) -> AsyncStream<Data> {
        AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.continuation = continuation
            self.state = .running

            self.task = Task {
                do {
                    let data = try Data(contentsOf: url)
                    self.totalBytes = Int64(data.count)
                    var offset = 0
                    while offset < data.count {
                        if self.state == .cancelled { continuation.finish(); return }
                        
                        // Wait if paused
                        while self.state == .paused {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            if self.state == .cancelled { continuation.finish(); return }
                        }
                        
                        let end = min(offset + self.chunkSize, data.count)
                        let chunk = data[offset..<end]
                        let compressed = try self.strategy.compress(Data(chunk))
                        
                        continuation.yield(compressed)
                        
                        self.processedBytes += Int64(chunk.count)
                        offset = end
                    }
                    self.state = .completed
                    continuation.finish()
                } catch {
                    self.state = .completed
                    continuation.finish()
                }
            }
        }
    }

    /// Pauses the current operation.
    public func pause()  { lock.lock(); defer { lock.unlock() }; state = .paused }
    
    /// Resumes a paused operation.
    public func resume() { lock.lock(); defer { lock.unlock() }; state = .running }
    
    /// Cancels the operation and cleans up resources.
    public func cancel() { lock.lock(); defer { lock.unlock() }; state = .cancelled; task?.cancel() }

    /// A value from 0.0 to 1.0 representing the session progress.
    public var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(processedBytes) / Double(totalBytes)
    }
}
