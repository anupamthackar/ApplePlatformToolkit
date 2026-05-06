import SwiftUI
import ToolkitCore

// MARK: - ToolkitUI Facade Documentation

/**
 # ToolkitUI
 
 The primary entry point for all User Interface services within the Toolkit SDK.
 It provides unified access to themes, toasts, global state, and ready-to-use views.
 
 ## Usage
 ```swift
 // Configure the UI layer
 Toolkit.ui.configure(UIConfig(animationsEnabled: true))
 
 // Show a global success notification
 Toolkit.ui.showSuccess("Saved Changes!")
 
 // Create a pre-built login view
 let loginView = Toolkit.ui.makeLoginView {
     print("User logged in!")
 }
 ```
 */
@MainActor
public final class ToolkitUI: Sendable {

    // MARK: - Singleton

    /// Shared global instance for UI management.
    public static let shared = ToolkitUI()

    // MARK: - Sub-managers

    /// The manager for active design tokens and theme switching.
    public let theme: ThemeManager
    /// The manager for displaying global HUD/Toast notifications.
    public let toast: ToastManager
    /// The container for cross-view state sharing.
    public let globalState: GlobalStateContainer

    // MARK: - Config

    /// Current global UI behavior settings.
    public private(set) var uiConfig: UIConfig

    // MARK: - Init

    /**
     Initializes the UI facade with specific sub-managers.
     */
    public init(
        uiConfig: UIConfig = UIConfig(),
        theme: ThemeManager = .shared,
        toast: ToastManager = .shared,
        globalState: GlobalStateContainer = .shared
    ) {
        self.uiConfig = uiConfig
        self.theme = theme
        self.toast = toast
        self.globalState = globalState
    }

    // MARK: - Configuration

    /**
     Updates the global UI configuration and optionally applies a new theme.
     */
    public func configure(_ config: UIConfig) {
        self.uiConfig = config
        if let themeConfig = config.themeConfig {
            theme.apply(themeConfig)
        }
    }

    // MARK: - Toast Shortcuts

    /**
     Displays a success toast notification at the top/bottom of the screen.
     */
    @MainActor
    public func showSuccess(_ message: String, duration: Double = 3.0) {
        toast.show(ToastConfig(message: message, style: .success, duration: duration))
    }

    /**
     Displays an error toast notification.
     */
    @MainActor
    public func showError(_ message: String, duration: Double = 4.0) {
        toast.show(ToastConfig(message: message, style: .error, duration: duration))
    }

    /**
     Displays an informational toast notification.
     */
    @MainActor
    public func showInfo(_ message: String) {
        toast.show(ToastConfig(message: message, style: .info))
    }

    // MARK: - View Factories

    /**
     Creates a fully configured `TKLoginView` integrated with the `ToolkitAuth` layer.
     - Parameters:
        - config: Optional configuration for titles, icons, etc.
        - onSuccess: Closure executed after a successful authentication.
     - Returns: A themed SwiftUI view.
     */
    @MainActor
    public func makeLoginView(config: LoginViewModel.Config = LoginViewModel.Config(), onSuccess: (() -> Void)? = nil) -> some View {
        TKLoginView(config: config, onSuccess: onSuccess)
            .tkThemed(theme)
    }
}

// MARK: - UIConfig Documentation

/**
 # UIConfig
 
 Configuration options that control the behavioral aspects of the ToolkitUI layer.
 */
public struct UIConfig: Sendable {
    /// An optional custom theme to apply during configuration.
    public var themeConfig: ThemeConfig? = nil
    /// Whether to show standard transitions and animations.
    public var animationsEnabled: Bool = true
    /// The text displayed in the global loading overlay.
    public var defaultLoadingMessage: String = "Loading…"
    /// If true, failed views will show a "Retry" button where applicable.
    public var errorRetryEnabled: Bool = true

    public init() {}
}

// MARK: - Toolkit Namespace

/**
 The primary SDK namespace. Use `Toolkit.ui` to access all user interface services.
 */
public extension Toolkit {
    /// Global access point for the ToolkitUI module.
    @MainActor
    static var ui: ToolkitUI { ToolkitUI.shared }
}
