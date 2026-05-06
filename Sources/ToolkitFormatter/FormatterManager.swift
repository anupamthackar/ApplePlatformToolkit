import Foundation
import ToolkitCore

// MARK: - Formatter Manager Documentation

/**
 # FormatterManager
 
 The central facade for all formatting services in the Toolkit.
 It provides access to specialized engines for dates, currencies, strings, binary data, and phone numbers.
 
 ## Usage
 ```swift
 let formatter = FormatterManager.shared
 
 // Quick format
 let str = formatter.formatCurrency(100.50, code: "USD")
 
 // Access specialized engines
 let dateStr = formatter.date.formatISO8601(Date())
 
 // Create a custom pipeline
 let pipeline = formatter.pipeline()
     .trim()
     .uppercase()
     .truncate(length: 10)
 ```
 */
public final class FormatterManager: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared global instance of the `FormatterManager`.
    public static let shared = FormatterManager()

    // MARK: - Engines

    /// The engine responsible for date and time formatting.
    public let date: DateFormatterEngine
    /// The engine responsible for currency, percentage, and numeric formatting.
    public let currency: CurrencyFormatterEngine
    /// The engine responsible for case transforms, masking, and string utilities.
    public let string: StringFormatterEngine
    /// The engine responsible for file size, duration, and JSON formatting.
    public let data: DataFormatterEngine
    /// The engine responsible for regional phone number formatting.
    public let phone: PhoneFormatterEngine

    // MARK: - Init

    /**
     Initializes a manager with custom engines. Supports Dependency Injection.
     */
    public init(
        date: DateFormatterEngine = DateFormatterEngine(),
        currency: CurrencyFormatterEngine = CurrencyFormatterEngine(),
        string: StringFormatterEngine = StringFormatterEngine(),
        data: DataFormatterEngine = DataFormatterEngine(),
        phone: PhoneFormatterEngine = PhoneFormatterEngine()
    ) {
        self.date = date
        self.currency = currency
        self.string = string
        self.data = data
        self.phone = phone
    }

    // MARK: - Factory Methods

    /**
     Returns a configurable date formatter engine instance.
     */
    public func dateEngine(configure: (DateFormatterEngine) -> Void = { _ in }) -> DateFormatterEngine {
        let engine = DateFormatterEngine()
        configure(engine)
        return engine
    }

    /**
     Returns a configurable currency formatter engine instance.
     */
    public func currencyEngine(configure: (CurrencyFormatterEngine) -> Void = { _ in }) -> CurrencyFormatterEngine {
        let engine = CurrencyFormatterEngine()
        configure(engine)
        return engine
    }

    /**
     Returns a new string formatting pipeline.
     */
    public func pipeline() -> StringFormattingPipeline {
        StringFormattingPipeline()
    }

    // MARK: - Convenience Shortcuts

    /// Formats a date with a specified style.
    public func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        self.date.style(style).format(date)
    }

    /// Formats a date relatively (e.g., "1 hour ago").
    public func formatRelativeDate(_ date: Date) -> String {
        self.date.formatRelative(date)
    }

    /// Formats a double as a currency string.
    public func formatCurrency(_ value: Double, code: String = "USD") -> String {
        self.currency.currencyCode(code).format(value)
    }

    /// Formats a byte count as a readable size (e.g., "1.2 MB").
    public func formatFileSize(_ bytes: Int64) -> String {
        self.data.formatFileSize(bytes)
    }

    /// Formats a time interval as a duration (e.g., "1h 30m").
    public func formatDuration(_ seconds: TimeInterval) -> String {
        self.data.formatDuration(seconds)
    }

    /// Formats a phone number for a specific region.
    public func formatPhone(_ phone: String, region: String = "US") -> String {
        self.phone.region(region).format(phone)
    }

    /// Converts a large number to an abbreviated form (e.g., 1000 -> "1K").
    public func abbreviateNumber(_ value: Double) -> String {
        self.currency.formatAbbreviated(value)
    }
}

// MARK: - Toolkit Namespace Extension

/**
 Extension to the global `Toolkit` namespace to expose formatting services.
 */
public extension Toolkit {
    static var formatter: FormatterManager { FormatterManager.shared }
}
