import Foundation

public struct TKProxy<Base> {
    public let base: Base
    public init(_ base: Base) { self.base = base }
}

public protocol TKCompatible {
    associatedtype TKCompatibleType
    var tk: TKCompatibleType { get }
    static var tk: TKCompatibleType.Type { get }
}

public extension TKCompatible {
    var tk: TKProxy<Self> { return TKProxy(self) }
    static var tk: TKProxy<Self>.Type { return TKProxy<Self>.self }
}

// Enable .tk on common foundation types
extension String: TKCompatible {}
extension Date: TKCompatible {}
extension Double: TKCompatible {}
extension Int: TKCompatible {}
