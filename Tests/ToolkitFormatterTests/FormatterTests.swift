import XCTest
@testable import ToolkitFormatter

final class FormatterTests: XCTestCase {

    let manager = FormatterManager()

    // MARK: - Date

    func testRelativeDateFormattingRecent() {
        let date = Date().addingTimeInterval(-120)
        let result = manager.formatRelativeDate(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testISO8601Format() {
        let date = Date(timeIntervalSince1970: 0)
        let result = DateFormatterEngine().formatISO8601(date)
        XCTAssertTrue(result.contains("1970"))
    }

    func testCustomDateFormat() {
        let engine = DateFormatterEngine().customFormat("yyyy")
        let result = engine.format(Date())
        XCTAssertTrue(result.count == 4)
    }

    func testDateParsing() {
        let engine = DateFormatterEngine()
        let parsed = engine.parse("2024-01-15")
        XCTAssertNotNil(parsed)
    }

    func testWeekdayName() {
        let engine = DateFormatterEngine()
        let knownSunday = Date(timeIntervalSince1970: 0) // 1970-01-01 was a Thursday
        let weekday = engine.weekday(of: knownSunday)
        XCTAssertFalse(weekday.isEmpty)
    }

    // MARK: - Currency

    func testUSDFormatting() {
        let result = manager.formatCurrency(1234.56, code: "USD")
        XCTAssertTrue(result.contains("1"))
    }

    func testAbbreviatedNumber() {
        XCTAssertEqual(manager.abbreviateNumber(1_500_000), "1.5M")
        XCTAssertEqual(manager.abbreviateNumber(2_000), "2.0K")
        XCTAssertEqual(manager.abbreviateNumber(500), "500")
    }

    func testPercentageFormatting() {
        let result = CurrencyFormatterEngine().formatPercentage(0.75)
        XCTAssertTrue(result.contains("75"))
    }

    // MARK: - String

    func testTitleCase() {
        let engine = StringFormatterEngine()
        XCTAssertEqual(engine.titleCase("hello world"), "Hello World")
    }

    func testSlugGeneration() {
        let engine = StringFormatterEngine()
        let result = engine.slug("Hello World & More!")
        XCTAssertEqual(result, "hello-world--more")
    }

    func testCamelCase() {
        let engine = StringFormatterEngine()
        XCTAssertEqual(engine.camelCase("hello-world-test"), "helloWorldTest")
    }

    func testEmailMasking() {
        let engine = StringFormatterEngine()
        let masked = engine.maskEmail("user@example.com")
        XCTAssertTrue(masked.contains("@"))
        XCTAssertTrue(masked.contains("*"))
    }

    func testPhoneMasking() {
        let engine = StringFormatterEngine()
        let masked = engine.maskPhone("1234567890")
        XCTAssertTrue(masked.hasSuffix("7890"))
    }

    func testCreditCardMasking() {
        let engine = StringFormatterEngine()
        let masked = engine.maskCreditCard("4111111111111111")
        XCTAssertTrue(masked.hasSuffix("1111"))
        XCTAssertTrue(masked.contains("*"))
    }

    func testTruncation() {
        let engine = StringFormatterEngine()
        let truncated = engine.truncate("Hello, World!", length: 8)
        XCTAssertEqual(truncated.count, 8)
    }

    func testHTMLStripping() {
        let engine = StringFormatterEngine()
        XCTAssertEqual(engine.stripHTML("<p>Hello</p>"), "Hello")
    }

    func testBase64RoundTrip() {
        let engine = StringFormatterEngine()
        let encoded = engine.base64Encode("Hello")
        let decoded = engine.base64Decode(encoded)
        XCTAssertEqual(decoded, "Hello")
    }

    // MARK: - File Size

    func testFileSizeFormatting() {
        XCTAssertEqual(manager.formatFileSize(1024), "1.02 kB")
        XCTAssertEqual(manager.formatFileSize(1_048_576), "1.05 MB")
    }

    func testBinaryFileSizeFormatting() {
        let engine = DataFormatterEngine(config: {
            var c = DataFormatterConfig(); c.unitStyle = .binary; return c
        }())
        XCTAssertEqual(engine.formatFileSize(1024), "1.00 KiB")
    }

    // MARK: - Duration

    func testDurationSeconds() {
        XCTAssertEqual(manager.formatDuration(45), "45s")
        XCTAssertEqual(manager.formatDuration(90), "1m 30s")
        XCTAssertEqual(manager.formatDuration(3661), "1h 1m 1s")
    }

    // MARK: - Phone

    func testUSPhoneFormatting() {
        XCTAssertEqual(manager.formatPhone("8005551234", region: "US"), "(800) 555-1234")
    }

    func testINPhoneFormatting() {
        XCTAssertEqual(manager.formatPhone("9876543210", region: "IN"), "+91 98765 43210")
    }

    // MARK: - Pipeline

    func testStringPipeline() {
        let result = StringFormattingPipeline()
            .trim()
            .lowercase()
            .replace("hello", with: "hi")
            .execute("  Hello World  ")
        XCTAssertEqual(result, "hi world")
    }

    func testPipelineTruncate() {
        let result = StringFormattingPipeline()
            .truncate(length: 5)
            .execute("Hello, World!")
        XCTAssertEqual(result, "Hell…")
    }

    // MARK: - Hex

    func testHexEncoding() {
        let engine = DataFormatterEngine()
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(engine.hexEncode(data), "deadbeef")
    }

    func testHexDecoding() {
        let engine = DataFormatterEngine()
        let decoded = engine.hexDecode("deadbeef")
        XCTAssertEqual(decoded, Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }
}
