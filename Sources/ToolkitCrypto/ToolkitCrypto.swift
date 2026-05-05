import Foundation
import CryptoKit
import ToolkitCore

public final class CryptoManager: @unchecked Sendable {
    public static let shared = CryptoManager()
    
    public init() {}
    
    public func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public func generateRandomKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    public func encryptAES(data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw ToolkitError.unknown
        }
        return combined
    }
    
    public func decryptAES(data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
