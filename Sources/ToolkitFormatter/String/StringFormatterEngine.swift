import Foundation

// MARK: - String Formatter Engine Documentation

/**
 # StringFormatterEngine
 
 A high-performance engine for string manipulation, case transformation, masking, and encoding.
 It provides utilities for common PII (Personally Identifiable Information) masking and clean casing.
 
 ## Usage
 ```swift
 let engine = StringFormatterEngine()
 
 // Case Transformation
 let snake = engine.snakeCase("HelloWorld") // "hello_world"
 let slug = engine.slug("My Awesome Post Title") // "my-awesome-post-title"
 
 // PII Masking
 let email = engine.maskEmail("john.doe@example.com") // "jo****@example.com"
 let card = engine.maskCreditCard("1234567812345678") // "************5678"
 
 // Truncation
 let text = engine.truncate("Long text string", length: 10) // "Long te…"
 ```
 */
public final class StringFormatterEngine: @unchecked Sendable {

    private var config: StringFormatterConfig

    /**
     Initializes a new engine with optional configuration.
     - Parameter config: The initial configuration for the engine.
     */
    public init(config: StringFormatterConfig = StringFormatterConfig()) {
        self.config = config
    }

    // MARK: - Builder Fluent API

    /// Sets the maximum length for global truncation defaults.
    public func maxLength(_ n: Int) -> Self { config.maxLength = n; return self }
    /// Sets the character used when truncating strings.
    public func truncationSuffix(_ s: String) -> Self { config.truncationSuffix = s; return self }
    /// Sets the character used for masking PII.
    public func maskCharacter(_ c: Character) -> Self { config.maskCharacter = c; return self }

    // MARK: - Case Transformations

    /// Converts string to all uppercase.
    public func uppercase(_ s: String) -> String { s.uppercased() }
    /// Converts string to all lowercase.
    public func lowercase(_ s: String) -> String { s.lowercased() }

    /// Converts string to Title Case (e.g., "hello world" -> "Hello World").
    public func titleCase(_ s: String) -> String {
        s.split(separator: " ").map { word -> String in
            guard let first = word.first else { return String(word) }
            return first.uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    /// Converts string to camelCase (e.g., "hello world" -> "helloWorld").
    public func camelCase(_ s: String) -> String {
        let words = s.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return words.enumerated().map { i, word in
            i == 0 ? word.lowercased() : word.capitalized
        }.joined()
    }

    /// Converts string to snake_case (e.g., "HelloWorld" -> "hello_world").
    public func snakeCase(_ s: String) -> String {
        s.unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) {
                return result.isEmpty ? String(scalar).lowercased() : result + "_" + String(scalar).lowercased()
            }
            return result + String(scalar)
        }
    }

    /// Converts string to a URL-friendly slug (e.g., "Title 123!" -> "title-123").
    public func slug(_ s: String) -> String {
        s.lowercased()
         .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
         .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
    }

    // MARK: - Masking (PII Protection)

    /**
     Masks an email address by hiding characters in the prefix.
     - Parameter email: The raw email address.
     - Returns: A masked email (e.g., "jo****@example.com").
     */
    public func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let prefix = email[email.startIndex..<atIndex]
        let domain = email[atIndex...]
        let masked = String(repeating: config.maskCharacter, count: max(0, prefix.count - 2))
        return String(prefix.prefix(2)) + masked + domain
    }

    /**
     Masks a phone number, keeping only the last few digits visible.
     */
    public func maskPhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count > 4 else { return phone }
        let tail = String(digits.suffix(config.visibleTailCount))
        let masked = String(repeating: config.maskCharacter, count: digits.count - config.visibleTailCount)
        return masked + tail
    }

    /**
     Masks a credit card number, keeping only the last 4 digits visible.
     */
    public func maskCreditCard(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        guard digits.count >= 4 else { return number }
        let tail = String(digits.suffix(4))
        let masked = String(repeating: config.maskCharacter, count: digits.count - 4)
        return masked + tail
    }

    // MARK: - Truncation

    /**
     Truncates a string to a specified length and appends a suffix.
     */
    public func truncate(_ s: String, length: Int? = nil) -> String {
        let limit = length ?? config.maxLength
        if s.count <= limit { return s }
        return String(s.prefix(limit - config.truncationSuffix.count)) + config.truncationSuffix
    }

    // MARK: - Utilities

    /// Removes whitespace and newlines from both ends.
    public func trim(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Replaces multiple spaces/tabs with a single space.
    public func normalizeWhitespace(_ s: String) -> String {
        s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    /// Removes all HTML tags from a string.
    public func stripHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Encoding

    /// Converts a string to its Base64 representation.
    public func base64Encode(_ s: String) -> String {
        s.data(using: .utf8)?.base64EncodedString() ?? s
    }

    /// Decodes a Base64 string back to UTF-8.
    public func base64Decode(_ s: String) -> String? {
        guard let data = Data(base64Encoded: s) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/**
 Configuration options for `StringFormatterEngine`.
 */
public struct StringFormatterConfig: Sendable {
    public var locale: Locale = .current
    public var maxLength: Int = Int.max
    public var truncationSuffix: String = "…"
    public var maskCharacter: Character = "*"
    public var visibleTailCount: Int = 4

    public init() {}
}
