import Foundation
import Compression

public class CompressionManager {
    public init() {}
    
    public func compress(_ data: Data) -> Data? {
        let destinationBufferSize = data.count
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }
        
        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_encode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
        }
        
        if compressedSize == 0 { return nil }
        return Data(bytes: destinationBuffer, count: compressedSize)
    }
    
    public func decompress(_ data: Data) -> Data? {
        let destinationBufferSize = data.count * 4
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }
        
        let decompressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
        }
        
        if decompressedSize == 0 { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}
