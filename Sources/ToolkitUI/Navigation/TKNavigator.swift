import SwiftUI

// MARK: - Navigation Route Protocol

public protocol TKRoute: Hashable, Sendable {}

// MARK: - Navigator

/// Observable navigation stack controller.
@MainActor
public final class TKNavigator<Route: TKRoute>: ObservableObject {
    @Published public var path: NavigationPath = NavigationPath()
    @Published public var isPresenting: Bool = false
    @Published public var presentedSheet: Route? = nil

    public init() {}

    public func navigate(to route: Route) { path.append(route) }
    public func pop() { if !path.isEmpty { path.removeLast() } }
    public func popToRoot() { path.removeLast(path.count) }
    public func present(_ route: Route) { presentedSheet = route; isPresenting = true }
    public func dismiss() { isPresenting = false; presentedSheet = nil }

    public var canPop: Bool { !path.isEmpty }
    public var depth: Int { path.count }
}

// MARK: - Route Guard

/// Prevents navigation based on a condition (e.g., auth state).
public struct TKRouteGuard {
    private let condition: @Sendable () -> Bool
    private let redirect: () -> Void

    public init(condition: @escaping @Sendable () -> Bool, redirect: @escaping () -> Void) {
        self.condition = condition
        self.redirect = redirect
    }

    public func evaluate() -> Bool {
        if !condition() { redirect(); return false }
        return true
    }
}

// MARK: - Deep Link Handler

public final class TKDeepLinkHandler: @unchecked Sendable {
    public typealias Handler = @Sendable (URL) -> Bool
    private var handlers: [Handler] = []

    public init() {}

    public func register(_ handler: @escaping Handler) {
        handlers.append(handler)
    }

    @discardableResult
    public func handle(_ url: URL) -> Bool {
        handlers.contains { $0(url) }
    }
}
