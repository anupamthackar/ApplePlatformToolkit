import Foundation

// MARK: - String Extensions

public extension TKProxy where Base == String {
    /// Returns true if the string is a valid email.
    var isEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: base)
    }
    
    /// Returns true if the string is a valid URL.
    var isURL: Bool {
        return URL(string: base) != nil && base.hasPrefix("http")
    }
    
    /// Truncates the string to a specific length with an ellipsis.
    func truncate(to length: Int) -> String {
        guard base.count > length else { return base }
        return String(base.prefix(length)) + "…"
    }
    
    /// Converts the string to a slug format (lowercase, hyphenated).
    var slugified: String {
        return base.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

// MARK: - Date Extensions

public extension TKProxy where Base == Date {
    /// Returns a string representation in ISO8601 format.
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: base)
    }
    
    /// Returns true if the date is in the past.
    var isPast: Bool {
        return base < Date()
    }
    
    /// Returns true if the date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(base)
    }
}
