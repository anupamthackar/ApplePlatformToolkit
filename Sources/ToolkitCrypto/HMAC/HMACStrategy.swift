import Foundation
import CryptoKit

// MARK: - HMAC Strategy Documentation

/**
 # HMACStrategy
 
 A protocol defining the interface for Hash-based Message Authentication Codes (HMAC).
 Use this to ensure message authenticity and integrity using a shared secret key.
 
 ## Usage
 ```swift
 let strategy = HMACSHA256Strategy()
 let key = Data(repeating: 0x01, count: 32)
 let message = Data("Authentic Message".utf8)
 
 // Generate signature
 let signature = strategy.sign(message, key: key)
 
 // Verify signature
 let isValid = strategy.verify(message, signature: signature, key: key)
 ```
 */
public protocol HMACStrategy: Sendable {
    /**
     Computes the HMAC signature for the provided data using a secret key.
     - Parameters:
        - data: The message data to sign.
        - key: The shared secret key.
     - Returns: The raw binary signature as `Data`.
     */
    func sign(_ data: Data, key: Data) -> Data
    
    /**
     Verifies if a signature is valid for the given data and secret key.
     Uses constant-time comparison to prevent timing attacks.
     - Parameters:
        - data: The message data that was signed.
        - signature: The signature to verify.
        - key: The shared secret key.
     - Returns: `true` if the signature is valid, otherwise `false`.
     */
    func verify(_ data: Data, signature: Data, key: Data) -> Bool
    
    /**
     Computes the HMAC signature and returns it as a hexadecimal string.
     - Parameters:
        - data: The message data to sign.
        - key: The shared secret key.
     - Returns: The lowercase hexadecimal signature string.
     */
    func signHex(_ data: Data, key: Data) -> String
}

// MARK: - HMAC-SHA256

/**
 HMAC implementation using the SHA256 hashing algorithm.
 Provides 256 bits of authentication security.
 */
public struct HMACSHA256Strategy: HMACStrategy {
    public init() {}

    public func sign(_ data: Data, key: Data) -> Data {
        let symKey = SymmetricKey(data: key)
        var hmac = HMAC<SHA256>(key: symKey)
        hmac.update(data: data)
        return Data(hmac.finalize())
    }

    public func verify(_ data: Data, signature: Data, key: Data) -> Bool {
        let expected = sign(data, key: key)
        // Constant-time comparison to prevent timing attacks
        guard expected.count == signature.count else { return false }
        return expected.withUnsafeBytes { (expBuf: UnsafeRawBufferPointer) in
            signature.withUnsafeBytes { (sigBuf: UnsafeRawBufferPointer) in
                var diff: UInt8 = 0
                for i in 0..<expBuf.count {
                    diff |= expBuf[i] ^ sigBuf[i]
                }
                return diff == 0
            }
        }
    }

    public func signHex(_ data: Data, key: Data) -> String {
        sign(data, key: key).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - HMAC-SHA512

/**
 HMAC implementation using the SHA512 hashing algorithm.
 Provides 512 bits of authentication security.
 */
public struct HMACSHA512Strategy: HMACStrategy {
    public init() {}

    public func sign(_ data: Data, key: Data) -> Data {
        let symKey = SymmetricKey(data: key)
        var hmac = HMAC<SHA512>(key: symKey)
        hmac.update(data: data)
        return Data(hmac.finalize())
    }

    public func verify(_ data: Data, signature: Data, key: Data) -> Bool {
        let expected = sign(data, key: key)
        // Constant-time comparison to prevent timing attacks
        guard expected.count == signature.count else { return false }
        return expected.withUnsafeBytes { (expBuf: UnsafeRawBufferPointer) in
            signature.withUnsafeBytes { (sigBuf: UnsafeRawBufferPointer) in
                var diff: UInt8 = 0
                for i in 0..<expBuf.count { diff |= expBuf[i] ^ sigBuf[i] }
                return diff == 0
            }
        }
    }

    public func signHex(_ data: Data, key: Data) -> String {
        sign(data, key: key).map { String(format: "%02x", $0) }.joined()
    }
}
