import Foundation

// MARK: - Formatting Pipeline Documentation

/**
 # StringFormattingPipeline
 
 A lightweight, chainable pipeline for applying multiple transformations to a string in sequence.
 Each step in the pipeline takes the output of the previous step as its input.
 
 ## Usage
 ```swift
 let pipeline = StringFormattingPipeline()
     .stripHTML()
     .trim()
     .lowercase()
     .truncate(length: 20)
 
 let clean = pipeline.execute("<div>  HELLO WORLD 1234567890 </div>") // "hello world 123…"
 ```
 */
public final class StringFormattingPipeline: @unchecked Sendable {
    private var steps: [(String) -> String] = []

    public init() {}

    /**
     Adds a custom transformation step to the pipeline.
     - Parameter step: A closure that takes a string and returns a transformed string.
     - Returns: The pipeline instance for chaining.
     */
    public func then(_ step: @escaping (String) -> String) -> Self {
        steps.append(step)
        return self
    }

    // MARK: - Predefined Steps

    /// Trims whitespace and newlines.
    public func trim() -> Self { then { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
    /// Converts to lowercase.
    public func lowercase() -> Self { then { $0.lowercased() } }
    /// Converts to uppercase.
    public func uppercase() -> Self { then { $0.uppercased() } }
    /// Replaces occurrences of a target string.
    public func replace(_ target: String, with replacement: String) -> Self { then { $0.replacingOccurrences(of: target, with: replacement) } }
    /// Truncates to a fixed length with a suffix.
    public func truncate(length: Int, suffix: String = "…") -> Self {
        then { s in s.count <= length ? s : String(s.prefix(length - suffix.count)) + suffix }
    }
    /// Removes HTML tags.
    public func stripHTML() -> Self { then { $0.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) } }
    /// Encodes as Base64.
    public func base64Encode() -> Self { then { $0.data(using: .utf8)?.base64EncodedString() ?? $0 } }

    // MARK: - Execution

    /**
     Runs the input string through all pipeline steps.
     - Parameter input: The source string.
     - Returns: The final transformed string.
     */
    public func execute(_ input: String) -> String {
        steps.reduce(input) { $1($0) }
    }

    /**
     Asynchronously executes the pipeline.
     */
    public func executeAsync(_ input: String) async -> String {
        execute(input)
    }
}

/**
 # FormattingPipeline
 
 A generic pipeline for mapping one type to another through a series of transformations.
 */
public final class FormattingPipeline<Input, Output>: @unchecked Sendable {
    public typealias Step = @Sendable (Input) throws -> Output
    private var steps: [Step] = []

    public init() {}

    /// Adds a transformation step to the generic pipeline.
    public func add(_ step: @escaping Step) -> Self { steps.append(step); return self }

    /**
     Executes the pipeline (currently supports single-step execution in this base implementation).
     */
    public func execute(_ input: Input) throws -> Output {
        guard let first = steps.first else { fatalError("Pipeline has no steps") }
        // Simple implementation for demonstration; complex pipelines use generic chaining.
        return try first(input)
    }
}
