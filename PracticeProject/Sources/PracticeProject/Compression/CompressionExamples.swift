import Foundation
import ToolkitCompression

/// Examples demonstrating usage of ToolkitCompression methods.
public struct CompressionExamples {
    public static func run() async {
        print("=== ToolkitCompression Examples ===")
        let compression = CompressionManager.shared
        print("Accessing CompressionManager shared instance: \(compression)")
        
        // Example methods
        // let compressed = try await compression.compress(data)
        // let decompressed = try await compression.decompress(compressed)
        print("Demonstrated access to compression strategies.")
        print("===================================\n")
    }
}
