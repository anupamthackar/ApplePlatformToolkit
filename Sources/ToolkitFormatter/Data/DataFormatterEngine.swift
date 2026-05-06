import Foundation

// MARK: - Data Formatter Engine Documentation

/**
 # DataFormatterEngine
 
 An engine for formatting binary data sizes, time durations, and structured formats like JSON.
 Supports both binary (MiB) and decimal (MB) byte count units.
 
 ## Usage
 ```swift
 let engine = DataFormatterEngine()
     .unitStyle(.binary)
     .precision(1)
 
 // File size
 let size = engine.formatFileSize(1048576) // "1.0 MB"
 
 // JSON formatting
 let pretty = engine.prettyPrintJSON(rawJSONData)
 
 // Hex encoding
 let hex = engine.hexEncode(myData)
 ```
 */
public final class DataFormatterEngine: @unchecked Sendable {

    private var config: DataFormatterConfig

    /**
     Initializes a new engine with optional configuration.
     - Parameter config: The initial configuration for the engine.
     */
    public init(config: DataFormatterConfig = DataFormatterConfig()) {
        self.config = config
    }

    // MARK: - Builder Fluent API

    /// Sets the number of decimal places for file size formatting.
    public func precision(_ p: Int) -> Self { config.precision = p; return self }
    
    /// Sets the calculation unit style (.binary for 1024, .decimal for 1000).
    public func unitStyle(_ s: DataFormatterConfig.UnitStyle) -> Self { config.unitStyle = s; return self }

    // MARK: - File Size Operations

    /**
     Formats a byte count into a human-readable size string.
     - Parameter bytes: The number of bytes.
     - Returns: A localized size string (e.g., "1.2 MB").
     */
    public func formatFileSize(_ bytes: Int64) -> String {
        let divisor: Double = config.unitStyle == .binary ? 1024.0 : 1000.0
        let units = config.unitStyle == .binary ? ["B", "KiB", "MiB", "GiB", "TiB"] : ["B", "kB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var index = 0
        while value >= divisor && index < units.count - 1 {
            value /= divisor
            index += 1
        }
        return String(format: "%.\(config.precision)f \(units[index])", value)
    }

    // MARK: - Duration Operations

    /**
     Formats a time interval into a human-readable duration string.
     */
    public func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 { return "\(hours)h \(minutes)m \(seconds)s" }
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }

    // MARK: - Serialization Utilities

    /**
     Takes raw JSON data and returns a pretty-printed string.
     */
    public func prettyPrintJSON(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: pretty, encoding: .utf8)
    }

    // MARK: - Encoding

    /// Encodes data into a lowercase hexadecimal string.
    public func hexEncode(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    /// Decodes a hexadecimal string back into `Data`.
    public func hexDecode(_ hex: String) -> Data? {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}

/**
 Configuration options for `DataFormatterEngine`.
 */
public struct DataFormatterConfig: Sendable {
    public var unitStyle: UnitStyle = .decimal
    public var precision: Int = 2
    public var prettyPrint: Bool = true

    public enum UnitStyle: Sendable { case binary, decimal }
    public init() {}
}

// MARK: - Phone Formatter Engine Documentation

/**
 # PhoneFormatterEngine
 
 An engine for formatting phone numbers according to regional standards.
 
 ## Usage
 ```swift
 let engine = PhoneFormatterEngine().region("US")
 let formatted = engine.format("1234567890") // "(123) 456-7890"
 ```
 */
public final class PhoneFormatterEngine: @unchecked Sendable {
    private var config: PhoneFormatterConfig

    public init(config: PhoneFormatterConfig = PhoneFormatterConfig()) {
        self.config = config
    }

    /// Sets the target region for phone number rules.
    public func region(_ r: String) -> Self { config.region = r; return self }

    /**
     Formats a numeric string into a regional phone format.
     */
    public func format(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        switch config.region.uppercased() {
        case "US", "CA":
            guard digits.count == 10 else { return phone }
            return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        case "IN":
            guard digits.count == 10 else { return phone }
            return "+91 \(digits.prefix(5)) \(digits.suffix(5))"
        case "GB":
            guard digits.count >= 10 else { return phone }
            return "+44 \(digits.prefix(4)) \(digits.dropFirst(4).prefix(3)) \(digits.suffix(4))"
        default:
            return phone
        }
    }

    /**
     Normalizes a phone number to E.164 format.
     */
    public func normalize(_ phone: String) -> String {
        "+" + phone.filter { $0.isNumber }
    }
}

/**
 Configuration options for `PhoneFormatterEngine`.
 */
public struct PhoneFormatterConfig: Sendable {
    public var region: String = "US"
    public var includeCountryCode: Bool = true
    public init() {}
}
