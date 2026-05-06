import Foundation

// MARK: - Date Formatter Engine Documentation

/**
 # DateFormatterEngine
 
 A high-level engine for formatting and parsing dates.
 It provides a fluent builder API for configuration and supports ISO8601, relative time, and custom formats.
 
 ## Usage
 ```swift
 let engine = DateFormatterEngine()
     .style(.long, time: .short)
     .locale(Locale(identifier: "fr_FR"))
 
 // Format current date
 let str = engine.format(Date())
 
 // ISO8601
 let iso = engine.formatISO8601(Date())
 
 // Relative time
 let relative = engine.formatRelative(Date().addingTimeInterval(-3600)) // "1 hour ago"
 ```
 */
public final class DateFormatterEngine: @unchecked Sendable {

    private var config: DateFormatterConfig
    
    /**
     Initializes a new engine with optional configuration.
     - Parameter config: The initial configuration for the engine.
     */
    public init(config: DateFormatterConfig = DateFormatterConfig()) {
        self.config = config
    }

    // MARK: - Builder Fluent API

    /// Sets the locale for formatting (e.g., "en_US", "ja_JP").
    public func locale(_ locale: Locale) -> Self { config.locale = locale; return self }
    
    /// Sets the time zone for date computation.
    public func timeZone(_ tz: TimeZone) -> Self { config.timeZone = tz; return self }
    
    /// Sets the predefined date and time styles.
    public func style(_ date: DateFormatter.Style, time: DateFormatter.Style = .none) -> Self {
        config.dateStyle = date; config.timeStyle = time; return self
    }
    
    /// Sets a custom date format string (e.g., "yyyy-MM-dd HH:mm:ss").
    public func customFormat(_ format: String) -> Self { config.customFormat = format; return self }
    
    /// Forces 24-hour time regardless of locale.
    public func use24Hour(_ flag: Bool) -> Self { config.use24HourTime = flag; return self }

    // MARK: - Format Operations

    /**
     Formats a date into a string using the current configuration.
     - Parameter date: The date to format.
     - Returns: A localized date string.
     */
    public func format(_ date: Date) -> String {
        let f = DateFormatter()
        apply(f)
        return f.string(from: date)
    }

    /**
     Formats a date into an ISO8601 compliant string.
     */
    public func formatISO8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /**
     Formats a date into a localized relative string (e.g., "2 days ago", "demain").
     */
    public func formatRelative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = config.locale
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }

    /**
     Attempts to parse a string into a `Date` object using multiple fallback formats.
     - Parameters:
        - string: The date string to parse.
        - formats: A list of candidate date formats.
     - Returns: A `Date` object if parsing succeeds, otherwise `nil`.
     */
    public func parse(_ string: String, formats: [String] = ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd'T'HH:mm:ssZ"]) -> Date? {
        let f = DateFormatter()
        f.locale = config.locale
        f.timeZone = config.timeZone
        for format in formats {
            f.dateFormat = format
            if let date = f.date(from: string) { return date }
        }
        return nil
    }

    /**
     Returns the full name of the weekday for a given date.
     */
    public func weekday(of date: Date) -> String {
        let f = DateFormatter()
        f.locale = config.locale
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    /**
     Returns the name of the month for a given date.
     */
    public func monthName(of date: Date, abbreviated: Bool = false) -> String {
        let f = DateFormatter()
        f.locale = config.locale
        f.dateFormat = abbreviated ? "MMM" : "MMMM"
        return f.string(from: date)
    }

    // MARK: - Private

    private func apply(_ f: DateFormatter) {
        f.locale = config.locale
        f.timeZone = config.timeZone
        f.calendar = Calendar(identifier: config.calendarIdentifier)
        if let custom = config.customFormat {
            f.dateFormat = custom
        } else {
            f.dateStyle = config.dateStyle
            f.timeStyle = config.timeStyle
            if config.use24HourTime {
                f.setLocalizedDateFormatFromTemplate("HH:mm")
            }
        }
    }
}

/**
 Configuration options for `DateFormatterEngine`.
 */
public struct DateFormatterConfig: Sendable {
    public var locale: Locale = .current
    public var timeZone: TimeZone = .current
    public var dateStyle: DateFormatter.Style = .medium
    public var timeStyle: DateFormatter.Style = .short
    public var customFormat: String?
    public var calendarIdentifier: Calendar.Identifier = .gregorian
    public var use24HourTime: Bool = false

    public init() {}
}
