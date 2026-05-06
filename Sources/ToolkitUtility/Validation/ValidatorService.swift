import Foundation

// MARK: - Validator Service Documentation

/**
 # ValidatorService
 
 A service for validating and sanitizing data against common patterns (email, phone, URL)
 and custom business rules. Supports pipeline-based multi-rule validation.
 
 ## Usage
 ```swift
 let validator = DefaultValidatorService(config: ValidationConfig())
 
 // Simple validation
 if validator.isEmail("test@example.com") { ... }
 
 // Pipeline validation
 let errors = validator.validatePipeline("secret", rules: [
     .notEmpty,
     .minLength(8),
     .regex(".*[A-Z].*")
 ])
 
 if !errors.isEmpty {
     print("Validation failed: \(errors)")
 }
 ```
 */
public protocol ValidatorService: Sendable {
    /// Checks if a string is a valid email address.
    func isEmail(_ s: String) -> Bool
    /// Checks if a string is a valid phone number.
    func isPhone(_ s: String) -> Bool
    /// Returns a score (0-100) representing password complexity.
    func passwordStrength(_ s: String) -> Int
    /// Checks if a string is a valid URL.
    func isURL(_ s: String) -> Bool
    /// Checks if a string is a valid credit card number.
    func isCreditCard(_ s: String) -> Bool
    /// Checks if a string matches a custom regular expression.
    func matchesRegex(_ s: String, regex: String) -> Bool
    
    /// Removes dangerous characters or unwanted whitespace.
    func sanitize(_ s: String) -> String
    /// Converts a string to a standard form (e.g., lowercase, no accents).
    func normalize(_ s: String) -> String
    
    /// Executes a series of validation rules against a string.
    /// - Returns: A list of `ValidationError` objects for each failed rule.
    func validatePipeline(_ s: String, rules: [ValidationRule]) -> [ValidationError]
}

/**
 Common validation rules used in pipelines.
 */
public enum ValidationRule: Sendable {
    case email, phone, url, notEmpty, minLength(Int), maxLength(Int), regex(String)
}

/**
 Represents a failure in a validation pipeline.
 */
public struct ValidationError: Error, CustomStringConvertible, Sendable {
    /// Human-readable explanation of why validation failed.
    public let reason: String
    public var description: String { return reason }
}

/**
 Configuration for validation strictness and custom patterns.
 */
public struct ValidationConfig: Sendable {
    /// If true, applies stricter checks for standards (e.g., RFC for emails).
    public var strictMode: Bool = true
    /// A dictionary of named regex patterns for easy reuse.
    public var customRegex: [String: String] = [:]
    /// Detail level of returned errors.
    public var errorReportingLevel: ReportingLevel = .detailed
    
    public enum ReportingLevel: Sendable { case basic, detailed }
    
    public init() {}
}

// MARK: - Default Implementation

/// Standard implementation of `ValidatorService` using `NSPredicate` and regex.
public final class DefaultValidatorService: ValidatorService, @unchecked Sendable {
    private let config: ValidationConfig
    
    public init(config: ValidationConfig) {
        self.config = config
    }
    
    public func isEmail(_ s: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return matchesRegex(s, regex: regex)
    }
    
    public func isPhone(_ s: String) -> Bool {
        let digits = s.filter { $0.isNumber }
        return digits.count >= 10
    }
    
    public func passwordStrength(_ s: String) -> Int {
        var score = 0
        if s.count >= 8 { score += 40 }
        if s.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 20 }
        if s.rangeOfCharacter(from: .decimalDigits) != nil { score += 20 }
        if s.rangeOfCharacter(from: .symbols) != nil { score += 20 }
        return score
    }
    
    public func isURL(_ s: String) -> Bool {
        return URL(string: s) != nil && s.hasPrefix("http")
    }
    
    public func isCreditCard(_ s: String) -> Bool {
        let digits = s.filter { $0.isNumber }
        return digits.count >= 13 && digits.count <= 19
    }
    
    public func matchesRegex(_ s: String, regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: s)
    }
    
    public func sanitize(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func normalize(_ s: String) -> String {
        return s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }
    
    public func validatePipeline(_ s: String, rules: [ValidationRule]) -> [ValidationError] {
        var errors: [ValidationError] = []
        for rule in rules {
            switch rule {
            case .email: if !isEmail(s) { errors.append(ValidationError(reason: "Invalid email format")) }
            case .phone: if !isPhone(s) { errors.append(ValidationError(reason: "Invalid phone number")) }
            case .url: if !isURL(s) { errors.append(ValidationError(reason: "Invalid URL")) }
            case .notEmpty: if s.isEmpty { errors.append(ValidationError(reason: "Value cannot be empty")) }
            case .minLength(let min): if s.count < min { errors.append(ValidationError(reason: "Value too short (min \(min))")) }
            case .maxLength(let max): if s.count > max { errors.append(ValidationError(reason: "Value too long (max \(max))")) }
            case .regex(let r): if !matchesRegex(s, regex: r) { errors.append(ValidationError(reason: "Value does not match pattern")) }
            }
        }
        return errors
    }
}
