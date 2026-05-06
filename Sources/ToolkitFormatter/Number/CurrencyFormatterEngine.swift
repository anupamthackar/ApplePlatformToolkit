import Foundation

// MARK: - Currency Formatter Engine Documentation

/**
 # CurrencyFormatterEngine
 
 A high-level engine for formatting numbers as currencies, percentages, and scientific notation.
 It supports localized output, precision control, and abbreviated notation (K, M, B).
 
 ## Usage
 ```swift
 let engine = CurrencyFormatterEngine()
     .currencyCode("EUR")
     .locale(Locale(identifier: "de_DE"))
 
 // Format currency
 let str = engine.format(1234.56) // "1.234,56 €"
 
 // Abbreviated number
 let big = engine.formatAbbreviated(1_500_000) // "1.5M"
 
 // Percentage
 let percent = engine.formatPercentage(0.85) // "85%"
 ```
 */
public final class CurrencyFormatterEngine: @unchecked Sendable {

    private var config: CurrencyFormatterConfig

    /**
     Initializes a new engine with optional configuration.
     - Parameter config: The initial configuration for the engine.
     */
    public init(config: CurrencyFormatterConfig = CurrencyFormatterConfig()) {
        self.config = config
    }

    // MARK: - Builder Fluent API

    /// Sets the currency code (e.g., "USD", "EUR", "JPY").
    public func currencyCode(_ code: String) -> Self { config.currencyCode = code; return self }
    
    /// Sets the locale for localized formatting.
    public func locale(_ l: Locale) -> Self { config.locale = l; return self }
    
    /// Sets the number of decimal places.
    public func precision(_ p: Int) -> Self { config.precision = p; return self }
    
    /// Sets the rounding mode for decimals.
    public func roundingMode(_ m: NumberFormatter.RoundingMode) -> Self { config.roundingMode = m; return self }

    // MARK: - Format Operations

    /**
     Formats a double value as a currency string.
     - Parameter value: The numeric value to format.
     - Returns: A localized currency string.
     */
    public func format(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = config.currencyCode
        f.locale = config.locale
        f.minimumFractionDigits = config.precision
        f.maximumFractionDigits = config.precision
        f.roundingMode = config.roundingMode
        f.usesGroupingSeparator = config.groupingSeparator
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /**
     Formats a `Decimal` value as a currency string.
     */
    public func formatDecimal(_ value: Decimal) -> String {
        format(NSDecimalNumber(decimal: value).doubleValue)
    }

    /**
     Formats a double as a percentage string (e.g., 0.5 -> "50%").
     */
    public func formatPercentage(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.locale = config.locale
        f.maximumFractionDigits = config.precision
        return f.string(from: NSNumber(value: value)) ?? "\(value)%"
    }

    /**
     Formats a double in scientific notation (e.g., "1.23E4").
     */
    public func formatScientific(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .scientific
        f.locale = config.locale
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /**
     Formats large numbers into abbreviated strings (K for thousands, M for millions, B for billions).
     */
    public func formatAbbreviated(_ value: Double) -> String {
        switch abs(value) {
        case 1_000_000_000...: return String(format: "%.1fB", value / 1_000_000_000)
        case 1_000_000...:     return String(format: "%.1fM", value / 1_000_000)
        case 1_000...:         return String(format: "%.1fK", value / 1_000)
        default:               return String(format: "%.0f", value)
        }
    }

    /**
     Formats a double as a standard localized decimal number.
     */
    public func formatNumber(_ value: Double, precision: Int? = nil) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = config.locale
        f.minimumFractionDigits = precision ?? config.precision
        f.maximumFractionDigits = precision ?? config.precision
        f.usesGroupingSeparator = config.groupingSeparator
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

/**
 Configuration options for `CurrencyFormatterEngine`.
 */
public struct CurrencyFormatterConfig: Sendable {
    public var currencyCode: String = "USD"
    public var locale: Locale = .current
    public var precision: Int = 2
    public var roundingMode: NumberFormatter.RoundingMode = .halfEven
    public var groupingSeparator: Bool = true

    public init() {}
}
