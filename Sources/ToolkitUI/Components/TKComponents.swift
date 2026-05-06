import SwiftUI

// MARK: - TKButton

public struct TKButtonConfig {
    public var title: String = "Button"
    public var style: Style = .primary
    public var isLoading: Bool = false
    public var isDisabled: Bool = false
    public var icon: String? = nil
    public var cornerRadius: CGFloat = 12

    public enum Style { case primary, secondary, destructive, ghost }
    public init(title: String) { self.title = title }
}

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
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(labelColor)
            .cornerRadius(config.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .strokeBorder(borderColor, lineWidth: config.style == .ghost ? 1.5 : 0)
            )
            .opacity(config.isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(TKScaleButtonStyle())
        .disabled(config.isDisabled || config.isLoading)
    }

    private var backgroundColor: Color {
        switch config.style {
        case .primary:     return theme.primaryColor
        case .secondary:   return theme.secondaryColor
        case .destructive: return theme.errorColor
        case .ghost:       return Color.clear
        }
    }

    private var labelColor: Color {
        switch config.style {
        case .ghost: return theme.primaryColor
        default:     return .white
        }
    }

    private var borderColor: Color {
        config.style == .ghost ? theme.primaryColor : Color.clear
    }
}

// MARK: - Scale Button Style

struct TKScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - TKTextField

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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? theme.primaryColor : theme.textSecondary)
                        .frame(width: 20)
                }

                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: theme.bodySize))

                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            .onTapGesture { isFocused = true }

            if let error = errorMessage, !error.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(.system(size: theme.captionSize))
                .foregroundColor(theme.errorColor)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    private var borderColor: Color {
        if errorMessage != nil { return theme.errorColor }
        return isFocused ? theme.primaryColor : theme.surfaceColor
    }
}

// MARK: - TKCard

public struct TKCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    @Environment(\.tkTheme) private var theme

    public init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    public var body: some View {
        content
            .padding(padding)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#if DEBUG
struct TKComponentPreviews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TKButton(config: TKButtonConfig(title: "Primary Action")) {}
                .padding(.horizontal)

            TKCard {
                Text("Card Content")
                    .font(.body)
            }
            .padding(.horizontal)
        }
        .padding()
        .tkThemed()
    }
}
#endif
