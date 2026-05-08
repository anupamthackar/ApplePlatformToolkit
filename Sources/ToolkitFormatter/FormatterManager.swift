import Foundation
import ToolkitCore

// MARK: - Formatter Manager Documentation

/**
 # FormatterManager
 
 The central facade for all formatting services in the Apple Platform Toolkit.
 It provides access to specialized engines for dates, currencies, strings, binary data, and phone numbers,
 enabling a unified and highly configurable formatting layer for your application.
 
 ## Features
 - **Date Formatting**: ISO8601, relative time, and localized styles.
 - **Currency & Numbers**: Multi-currency support and large number abbreviation (e.g., 1K, 1M).
 - **Data Presentation**: Human-readable file sizes and time durations.
 - **String Pipelines**: Fluent, chainable transformations like masking and case conversion.
 - **Phone Numbers**: Regional formatting for international phone support.
 
 ## Usage
 ```swift
 let formatter = FormatterManager.shared
 
 // Format a currency
 let price = formatter.formatCurrency(29.99, code: "EUR")
 
 // Format a file size
 let size = formatter.formatFileSize(1024 * 1024 * 5) // "5 MB"
 
 // Create a custom string pipeline
 let cleanID = formatter.pipeline()
     .trim()
     .uppercase()
     .mask(pattern: "****")
     .execute("  abc-123  ")
 ```
 */
public final class FormatterManager: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared global instance of the `FormatterManager` for application-wide use.
    public static let shared = FormatterManager()

    // MARK: - Engines

    /// The engine responsible for date and time formatting (ISO8601, relative, etc.).
    public let date: DateFormatterEngine
    
    /// The engine responsible for currency, percentage, and numeric formatting.
    public let currency: CurrencyFormatterEngine
    
    /// The engine responsible for case transforms, masking, and general string utilities.
    public let string: StringFormatterEngine
    
    /// The engine responsible for file sizes, data durations, and raw data formatting.
    public let data: DataFormatterEngine
    
    /// The engine responsible for regional and international phone number formatting.
    public let phone: PhoneFormatterEngine

    // MARK: - Init

    /**
     Initializes a manager with custom engines. This supports Dependency Injection for testing.
     
     - Parameters:
        - date: A custom date engine.
        - currency: A custom currency engine.
        - string: A custom string engine.
        - data: A custom data engine.
        - phone: A custom phone engine.
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
     Returns a newly configured date formatter engine instance.
     
     - Parameter configure: A closure to customize the engine's behavior.
     - Returns: A configured `DateFormatterEngine`.
     */
    public func dateEngine(configure: (DateFormatterEngine) -> Void = { _ in }) -> DateFormatterEngine {
        let engine = DateFormatterEngine()
        configure(engine)
        return engine
    }

    /**
     Returns a newly configured currency formatter engine instance.
     
     - Parameter configure: A closure to customize the engine's behavior.
     - Returns: A configured `CurrencyFormatterEngine`.
     */
    public func currencyEngine(configure: (CurrencyFormatterEngine) -> Void = { _ in }) -> CurrencyFormatterEngine {
        let engine = CurrencyFormatterEngine()
        configure(engine)
        return engine
    }

    /**
     Returns a new, empty string formatting pipeline for chainable transformations.
     
     - Returns: A `StringFormattingPipeline` instance.
     */
    public func pipeline() -> StringFormattingPipeline {
        StringFormattingPipeline()
    }

    // MARK: - Convenience Shortcuts

    /**
     Formats a date with a specified standard style.
     
     - Parameters:
        - date: The date object to format.
        - style: The style to apply (e.g., `.short`, `.medium`, `.long`).
     - Returns: A localized date string.
     */
    public func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        self.date.style(style).format(date)
    }

    /**
     Formats a date relative to the current time (e.g., "3 hours ago", "yesterday").
     
     - Parameter date: The target date.
     - Returns: A relative time description.
     */
    public func formatRelativeDate(_ date: Date) -> String {
        self.date.formatRelative(date)
    }

    /**
     Formats a numeric value as a currency string with the specified currency code.
     
     - Parameters:
        - value: The amount to format.
        - code: The ISO currency code (e.g., "USD", "GBP").
     - Returns: A localized currency string.
     */
    public func formatCurrency(_ value: Double, code: String = "USD") -> String {
        self.currency.currencyCode(code).format(value)
    }

    /**
     Formats a byte count as a human-readable file size (e.g., "1.2 MB", "4 GB").
     
     - Parameter bytes: The number of bytes.
     - Returns: A formatted size string.
     */
    public func formatFileSize(_ bytes: Int64) -> String {
        self.data.formatFileSize(bytes)
    }

    /**
     Formats a time interval as a readable duration (e.g., "1h 30m", "45s").
     
     - Parameter seconds: The time interval in seconds.
     - Returns: A formatted duration string.
     */
    public func formatDuration(_ seconds: TimeInterval) -> String {
        self.data.formatDuration(seconds)
    }

    /**
     Formats a phone number string for a specific region.
     
     - Parameters:
        - phone: The raw phone number string.
        - region: The ISO region code (e.g., "US", "IN").
     - Returns: A formatted phone number.
     */
    public func formatPhone(_ phone: String, region: String = "US") -> String {
        self.phone.region(region).format(phone)
    }

    /**
     Converts a large number into a short abbreviated form (e.g., 1200 becomes "1.2K").
     
     - Parameter value: The number to abbreviate.
     - Returns: An abbreviated string.
     */
    public func abbreviateNumber(_ value: Double) -> String {
        self.currency.formatAbbreviated(value)
    }
}

// MARK: - Toolkit Namespace Extension

public extension Toolkit {
    /// Global access point for the ToolkitFormatter module.
    static var formatter: FormatterManager { FormatterManager.shared }
}
