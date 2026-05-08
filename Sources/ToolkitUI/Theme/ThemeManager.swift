import Foundation
import SwiftUI
import Combine

// MARK: - Theme Documentation

/**
 # ThemeConfig
 
 A collection of design tokens including colors, typography, spacing, and animation settings.
 Use this to define the visual brand of your application.
 */
public struct ThemeConfig: Sendable {
    // MARK: - Colors
    public var primaryColor: Color = Color.blue
    public var secondaryColor: Color = Color.secondary
    
    // Adaptive Backgrounds
    public var backgroundColor: Color = {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }()
    
    public var surfaceColor: Color = {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()
    
    public var errorColor: Color = .red
    public var successColor: Color = .green
    public var warningColor: Color = .orange
    
    // Adaptive Text
    public var textPrimary: Color = .primary
    public var textSecondary: Color = .secondary
    public var textTertiary: Color = .secondary.opacity(0.7)
    public var borderColor: Color = Color.gray.opacity(0.2)

    // MARK: - Gradients
    public var primaryGradient: LinearGradient {
        LinearGradient(colors: [primaryColor, primaryColor.opacity(0.85)], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Typography
    public var fontFamily: String = "SF Pro"
    public var titleFont: Font = .system(size: 28, weight: .bold, design: .rounded)
    public var headlineFont: Font = .system(size: 17, weight: .semibold, design: .default)
    public var bodyFont: Font = .system(size: 15, weight: .regular, design: .default)
    public var captionFont: Font = .system(size: 12, weight: .medium, design: .default)

    // MARK: - Spacing & Shape
    public var cornerRadius: CGFloat = 12
    public var cardCornerRadius: CGFloat = 16
    public var smallPadding: CGFloat = 8
    public var defaultPadding: CGFloat = 16
    public var largePadding: CGFloat = 24
    public var borderWidth: CGFloat = 0.5

    // MARK: - Shadows
    public var cardShadowColor: Color = Color.black.opacity(0.04)
    public var cardShadowRadius: CGFloat = 10
    public var cardShadowOffset: CGPoint = CGPoint(x: 0, y: 4)

    // MARK: - Animation
    public var animationDuration: Double = 0.3
    public var springResponse: Double = 0.35
    public var springDamping: Double = 0.85

    // MARK: - Mode
    public var colorScheme: ColorScheme?

    public init() {}
}

// MARK: - Theme Manager Documentation

@MainActor
public final class ThemeManager: ObservableObject, Sendable {
    public static let shared = ThemeManager()
    @Published public var current: ThemeConfig = ThemeConfig()
    public init() {}

    public func apply(_ theme: ThemeConfig) {
        withAnimation(.easeInOut(duration: theme.animationDuration)) {
            current = theme
        }
    }

    public func applyDarkMode() {
        var dark = ThemeConfig()
        dark.colorScheme = .dark
        apply(dark)
    }

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
    func tkThemed(_ manager: ThemeManager = .shared) -> some View {
        modifier(TKThemeModifier(themeManager: manager))
    }
}
