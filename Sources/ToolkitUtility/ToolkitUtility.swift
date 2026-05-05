import Foundation

public struct TKNamespace<Base> {
    public let base: Base
    public init(_ base: Base) { self.base = base }
}

public protocol TKCompatible {
    associatedtype TKBase
    var tk: TKNamespace<TKBase> { get }
}

extension TKCompatible {
    public var tk: TKNamespace<Self> { return TKNamespace(self) }
}

extension String: TKCompatible {}
extension String {
    public var tk: TKNamespace<String> { return TKNamespace(self) }
}

extension TKNamespace where Base == String {
    public var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: base)
    }
}

extension Date: TKCompatible {}
extension TKNamespace where Base == Date {
    public func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: base)
    }
}

extension Data: TKCompatible {}
extension TKNamespace where Base == Data {
    public var hexString: String {
        return base.map { String(format: "%02hhx", $0) }.joined()
    }
}

public class Formatters {
    public static func currencyFormatter(locale: Locale = .current) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter
    }
}
