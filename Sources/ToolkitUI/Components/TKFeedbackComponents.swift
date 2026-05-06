import SwiftUI
import Combine

// MARK: - Toast Configuration

public struct ToastConfig: Sendable {
    public var message: String
    public var style: Style = .info
    public var duration: Double = 3.0
    public var position: Position = .bottom

    public enum Style: Sendable { case success, error, warning, info }
    public enum Position: Sendable { case top, bottom }

    public init(message: String, style: Style = .info, duration: Double = 3.0) {
        self.message = message
        self.style = style
        self.duration = duration
    }
}

// MARK: - Toast Manager

@MainActor
public final class ToastManager: ObservableObject, Sendable {
    public static let shared = ToastManager()

    @Published public var current: ToastConfig? = nil
    private var hideTask: Task<Void, Never>?

    public init() {}

    public func show(_ config: ToastConfig) {
        current = config
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(config.duration * 1_000_000_000))
            if !Task.isCancelled { self.current = nil }
        }
    }

    public func dismiss() { hideTask?.cancel(); current = nil }
}

// MARK: - Toast View

public struct TKToast: View {
    let config: ToastConfig
    @Environment(\.tkTheme) private var theme

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 18, weight: .semibold))
            Text(config.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(iconColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    private var iconName: String {
        switch config.style {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch config.style {
        case .success: return .green
        case .error:   return .red
        case .warning: return .orange
        case .info:    return .blue
        }
    }
}

// MARK: - Toast Container Modifier

public struct TKToastContainerModifier: ViewModifier {
    @ObservedObject var manager: ToastManager

    public func body(content: Content) -> some View {
        ZStack {
            content
            if let toast = manager.current {
                VStack {
                    if toast.position == .top { Spacer(minLength: 0) }
                    TKToast(config: toast)
                        .transition(.move(edge: toast.position == .top ? .top : .bottom).combined(with: .opacity))
                    if toast.position == .bottom { Spacer(minLength: 0) }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.current?.message)
                .padding(.bottom, toast.position == .bottom ? 40 : 0)
                .padding(.top, toast.position == .top ? 60 : 0)
            }
        }
    }
}

public extension View {
    func tkToastContainer(manager: ToastManager = .shared) -> some View {
        modifier(TKToastContainerModifier(manager: manager))
    }
}

// MARK: - Skeleton Loader

public struct TKSkeletonView: View {
    @State private var isAnimating = false
    private let width: CGFloat
    private let height: CGFloat
    private let cornerRadius: CGFloat

    public init(width: CGFloat = .infinity, height: CGFloat = 16, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width == .infinity ? nil : width, height: height)
            .offset(x: isAnimating ? 300 : -300)
            .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
            .clipped()
    }
}

// MARK: - Loading Overlay

public struct TKLoadingOverlay: View {
    let message: String
    @Environment(\.tkTheme) private var theme

    public init(message: String = "Loading…") {
        self.message = message
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryColor))
                    .scaleEffect(1.4)
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)
            }
            .padding(28)
            .background(.regularMaterial)
            .cornerRadius(18)
        }
    }
}

// MARK: - Network Status Banner

public struct TKNetworkBanner: View {
    let isOnline: Bool
    @Environment(\.tkTheme) private var theme

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isOnline ? "wifi" : "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            Text(isOnline ? "Back Online" : "No Internet Connection")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isOnline ? theme.successColor : theme.errorColor)
        .foregroundColor(.white)
    }
}

// MARK: - Progress Bar

public struct TKProgressBar: View {
    let progress: Double
    var tint: Color? = nil
    @Environment(\.tkTheme) private var theme

    public init(progress: Double, tint: Color? = nil) {
        self.progress = min(max(progress, 0), 1)
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2))
                Capsule()
                    .fill(tint ?? theme.primaryColor)
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 6)
    }
}
