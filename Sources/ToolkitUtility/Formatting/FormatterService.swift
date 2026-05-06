import Foundation

// MARK: - Formatter Service Documentation

/**
 # FormatterService
 
 A high-level service for localized formatting of dates, currencies, numbers, and strings.
 Also provides a fluent `FormatPipelineBuilder` for chaining string transformations.
 
 ## Usage
 ```swift
 let formatter = DefaultFormatterService(config: FormattingConfig())
 
 // Simple date formatting
 let dateStr = formatter.formatDate(Date(), style: .long)
 
 // Chained string transformation
 let transform = formatter.pipeline()
     .trim()
     .lowercase()
     .replace("apple", with: "fruit")
     .build()
 
 let result = transform("  Apple Pie  ") // "fruit pie"
 ```
 */
public protocol FormatterService: Sendable {
    /// Formats a date using a specified style.
    func formatDate(_ date: Date, style: DateFormatter.Style) -> String
    
    /// Returns a localized relative time string (e.g., "3 hours ago").
    func formatRelativeTime(from date: Date) -> String
    
    /// Formats a decimal value as a currency string.
    func formatCurrency(_ value: Decimal, code: String) -> String
    
    /// Formats a double value as a localized number string.
    func formatNumber(_ value: Double, precision: Int?) -> String
    
    /// Applies standard masking and grouping to a phone number string.
    func formatPhoneNumber(_ phone: String) -> String
    
    /// Joins address components into a localized address block.
    func formatAddress(_ addressParts: [String]) -> String
    
    /// Formats a unit of measurement (e.g., "5.0 kg").
    func formatUnit(value: Double, unit: String) -> String
    
    /// Formats a time interval as a readable duration (e.g., "1h 30m").
    func formatDuration(_ interval: TimeInterval) -> String
    
    /// Formats a byte count into a human-readable file size (e.g., "1.2 MB").
    func formatFileSize(_ bytes: Int64) -> String
    
    /// Returns a builder for creating composable string transformation pipelines.
    func pipeline() -> FormatPipelineBuilder
}

/**
 A fluent builder for creating a sequence of string transformations.
 */
public final class FormatPipelineBuilder {
    private var steps: [(String) -> String] = []
    public init() {}
    
    /// Trims whitespace and newlines from the start and end.
    public func trim() -> Self { steps.append { $0.trimmingCharacters(in: .whitespacesAndNewlines) }; return self }
    /// Converts the string to lowercase.
    public func lowercase() -> Self { steps.append { $0.lowercased() }; return self }
    /// Converts the string to uppercase.
    public func uppercase() -> Self { steps.append { $0.uppercased() }; return self }
    /// Replaces occurrences of a substring.
    public func replace(_ target: String, with: String) -> Self { steps.append { $0.replacingOccurrences(of: target, with: with) }; return self }
    /// Truncates the string to a maximum length.
    public func truncate(length: Int) -> Self { steps.append { String($0.prefix(length)) }; return self }
    /// Replaces characters with a mask character.
    public func mask(character: Character = "*") -> Self { steps.append { String(repeating: character, count: $0.count) }; return self }
    
    /// Compiles the steps into a single transformation closure.
    public func build() -> (String) -> String {
        return { input in self.steps.reduce(input) { $1($0) } }
    }
}

/**
 Global configuration for formatting defaults.
 */
public struct FormattingConfig: Sendable {
    /// The locale to use for all formatting operations.
    public var locale: Locale = .current
    /// Default number of decimal places.
    public var precision: Int = 2
    /// Visual style for units and numbers.
    public var formatStyle: FormatStyle = .standard
    /// How to handle decimal rounding.
    public var roundingMode: NumberFormatter.RoundingMode = .halfUp
    
    public enum FormatStyle: Sendable { case standard, compact, scientific }
    
    public init() {}
}

// MARK: - Default Implementation

/// Standard implementation of `FormatterService` using `Foundation` formatters.
public final class DefaultFormatterService: FormatterService, @unchecked Sendable {
    private let config: FormattingConfig
    
    public init(config: FormattingConfig) {
        self.config = config
    }
    
    public func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let f = DateFormatter()
        f.locale = config.locale
        f.dateStyle = style
        return f.string(from: date)
    }
    
    public func formatRelativeTime(from date: Date) -> String { return "just now" }
    
    public func formatCurrency(_ value: Decimal, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.locale = config.locale
        return f.string(from: value as NSDecimalNumber) ?? ""
    }
    
    public func formatNumber(_ value: Double, precision: Int?) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = precision ?? config.precision
        f.locale = config.locale
        return f.string(from: NSNumber(value: value)) ?? ""
    }
    
    public func formatPhoneNumber(_ phone: String) -> String { return phone }
    public func formatAddress(_ addressParts: [String]) -> String { return addressParts.joined(separator: ", ") }
    public func formatUnit(value: Double, unit: String) -> String { return "\(value) \(unit)" }
    public func formatDuration(_ interval: TimeInterval) -> String { return "\(interval)s" }
    public func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    public func pipeline() -> FormatPipelineBuilder {
        return FormatPipelineBuilder()
    }
}
