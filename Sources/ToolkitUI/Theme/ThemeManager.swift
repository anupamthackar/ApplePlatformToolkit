import Foundation
import SwiftUI
import Combine

// MARK: - Theme Documentation

/**
 # ThemeConfig
 
 A collection of design tokens including colors, typography, spacing, and animation settings.
 Use this to define the visual brand of your application.
 
 ## Usage
 ```swift
 var myTheme = ThemeConfig()
 myTheme.primaryColor = .blue
 myTheme.cornerRadius = 20
 ```
 */
public struct ThemeConfig: Sendable {
    // MARK: - Colors
    public var primaryColor: Color = Color(red: 0.33, green: 0.42, blue: 0.98)
    public var secondaryColor: Color = Color(red: 0.98, green: 0.56, blue: 0.23)
    public var backgroundColor: Color = .white
    public var surfaceColor: Color = Color(white: 0.95)
    public var errorColor: Color = Color.red
    public var successColor: Color = Color.green
    public var warningColor: Color = Color.orange
    public var textPrimary: Color = .black
    public var textSecondary: Color = .gray

    // MARK: - Typography
    public var fontFamily: String = "SF Pro Display"
    public var headingSize: CGFloat = 28
    public var subheadingSize: CGFloat = 20
    public var bodySize: CGFloat = 16
    public var captionSize: CGFloat = 12

    // MARK: - Spacing
    public var cornerRadius: CGFloat = 12
    public var smallPadding: CGFloat = 8
    public var defaultPadding: CGFloat = 16
    public var largePadding: CGFloat = 24

    // MARK: - Animation
    public var animationDuration: Double = 0.25
    public var springResponse: Double = 0.4
    public var springDamping: Double = 0.8

    // MARK: - Mode
    public var colorScheme: ColorScheme?

    public init() {}
}

// MARK: - Theme Manager Documentation

/**
 # ThemeManager
 
 An observable object that manages the active `ThemeConfig`.
 It allows for runtime theme switching (e.g., Light vs Dark mode) and propagates
 changes down the SwiftUI view hierarchy via environment values.
 
 ## Usage
 ```swift
 // In your App entry point
 ContentView()
     .tkThemed(ThemeManager.shared)
 
 // Anywhere in your code
 ThemeManager.shared.applyDarkMode()
 ```
 */
@MainActor
public final class ThemeManager: ObservableObject, Sendable {
    /// Global shared instance.
    public static let shared = ThemeManager()

    /// The currently active design tokens.
    @Published public var current: ThemeConfig = ThemeConfig()

    public init() {}

    /**
     Applies a new theme configuration with an optional animation.
     */
    public func apply(_ theme: ThemeConfig) {
        withAnimation(.easeInOut(duration: theme.animationDuration)) {
            current = theme
        }
    }

    /**
     Short-cut to apply a predefined high-contrast Dark Mode theme.
     */
    public func applyDarkMode() {
        var dark = ThemeConfig()
        dark.backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.08)
        dark.surfaceColor = Color(red: 0.12, green: 0.12, blue: 0.16)
        dark.textPrimary = .white
        dark.textSecondary = Color(white: 0.7)
        dark.colorScheme = .dark
        apply(dark)
    }

    /**
     Short-cut to reset to the standard Light Mode theme.
     */
    public func applyLightMode() {
        var light = ThemeConfig()
        light.colorScheme = .light
        apply(light)
    }
}

// MARK: - SwiftUI Integration

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemeConfig()
}

public extension EnvironmentValues {
    /// Access the toolkit theme design tokens from any SwiftUI view.
    var tkTheme: ThemeConfig {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct TKThemeModifier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    func body(content: Content) -> some View {
        content
            .environment(\.tkTheme, themeManager.current)
            .preferredColorScheme(themeManager.current.colorScheme)
    }
}

public extension View {
    /**
     Injects the `ThemeManager` into the view hierarchy.
     All toolkit components will automatically adapt to the manager's state.
     */
    func tkThemed(_ manager: ThemeManager = .shared) -> some View {
        modifier(TKThemeModifier(themeManager: manager))
    }
}
