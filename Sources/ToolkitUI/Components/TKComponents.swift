import SwiftUI

// MARK: - TKButton

/**
 # TKButtonConfig
 
 Configuration object for `TKButton`. Allows full control over title, style, state, and icon.
 */
public struct TKButtonConfig: Sendable {
    public var title: String = "Button"
    public var style: Style = .primary
    public var isLoading: Bool = false
    public var isDisabled: Bool = false
    public var icon: String? = nil
    public var cornerRadius: CGFloat? = nil

    public enum Style: Sendable { case primary, secondary, destructive, ghost, outline }
    public init(title: String, style: Style = .primary) {
        self.title = title
        self.style = style
    }
}

/**
 # TKButton
 
 A highly customizable button component that adapts to the current theme.
 Supports loading states, icons, and multiple visual styles.
 */
public struct TKButton: View {
    private let config: TKButtonConfig
    private let action: () -> Void
    @Environment(\.tkTheme) private var theme

    public init(config: TKButtonConfig, action: @escaping () -> Void) {
        self.config = config
        self.action = action
    }

    public var body: some View {
        Button(action: { if !config.isDisabled && !config.isLoading { action() } }) {
            HStack(spacing: 8) {
                if config.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: labelColor))
                        .scaleEffect(0.85)
                }
                if let icon = config.icon {
                    Image(systemName: icon).font(.system(size: 16, weight: .medium))
                }
                Text(config.title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, theme.defaultPadding)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(backgroundView)
            .foregroundColor(labelColor)
            .cornerRadius(config.cornerRadius ?? theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: config.cornerRadius ?? theme.cornerRadius)
                    .strokeBorder(borderColor, lineWidth: theme.borderWidth)
            )
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            .opacity(config.isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(TKScaleButtonStyle(springResponse: theme.springResponse, dampingFraction: theme.springDamping))
        .disabled(config.isDisabled || config.isLoading)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch config.style {
        case .primary:     theme.primaryGradient
        case .secondary:   theme.secondaryColor
        case .destructive: theme.errorColor
        case .ghost, .outline: Color.clear
        }
    }

    private var labelColor: Color {
        switch config.style {
        case .ghost, .outline: return theme.primaryColor
        case .secondary:       return theme.textPrimary
        default:               return .white
        }
    }

    private var borderColor: Color {
        switch config.style {
        case .outline: return theme.primaryColor
        default:       return Color.clear
        }
    }
    
    private var shadowColor: Color {
        config.style == .primary ? theme.primaryColor.opacity(0.15) : Color.clear
    }
}

// MARK: - TKScaleButtonStyle

struct TKScaleButtonStyle: ButtonStyle {
    let springResponse: Double
    let dampingFraction: Double
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: springResponse, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

// MARK: - TKTextField

/**
 # TKTextField
 
 A standardized text input component with support for icons, security (password), and validation error messages.
 */
public struct TKTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let icon: String?
    private let errorMessage: String?
    private let isSecure: Bool
    @Environment(\.tkTheme) private var theme
    @State private var isFocused = false
    @State private var showPassword = false

    public init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        errorMessage: String? = nil,
        isSecure: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.errorMessage = errorMessage
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? theme.primaryColor : theme.textSecondary)
                        .font(.system(size: 16))
                        .frame(width: 20)
                }

                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)

                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(theme.textSecondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 1.5 : theme.borderWidth)
                    .animation(.easeInOut(duration: theme.animationDuration), value: isFocused)
            )
            .onTapGesture { withAnimation { isFocused = true } }

            if let error = errorMessage, !error.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(theme.captionFont)
                .foregroundColor(theme.errorColor)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: theme.animationDuration), value: errorMessage)
    }

    private var borderColor: Color {
        if errorMessage != nil { return theme.errorColor }
        return isFocused ? theme.primaryColor : theme.borderColor
    }
}

// MARK: - TKCard

/**
 # TKCard
 
 A container component with standardized padding, corner radius, and shadow.
 */
public struct TKCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat?
    @Environment(\.tkTheme) private var theme

    public init(padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    public var body: some View {
        content
            .padding(padding ?? theme.defaultPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cardCornerRadius)
            .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, x: theme.cardShadowOffset.x, y: theme.cardShadowOffset.y)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .strokeBorder(theme.borderColor.opacity(0.5), lineWidth: theme.borderWidth)
            )
    }
}

// MARK: - TKSectionHeader

/**
 # TKSectionHeader
 
 A simple header component for grouping sections within a view.
 */
public struct TKSectionHeader: View {
    private let title: String
    @Environment(\.tkTheme) private var theme

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(theme.textTertiary)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - TKBadge

/**
 # TKBadge
 
 A small status indicator or count badge.
 */
public struct TKBadge: View {
    private let text: String
    private let color: Color
    @Environment(\.tkTheme) private var theme

    public init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color ?? .blue
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.gradient)
            .clipShape(Capsule())
    }
}
