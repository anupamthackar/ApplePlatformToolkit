import SwiftUI
import ToolkitCore

// MARK: - ToolkitUI Facade Documentation

/**
 # ToolkitUI
 
 The primary entry point for all User Interface services within the Toolkit SDK.
 It provides unified access to modular themes, toast notifications, global state, 
 and ready-to-use professional SwiftUI views.
 
 ## Features
 - **Theme Management**: Dynamic switching between light, dark, and custom branding.
 - **Notifications**: Global HUD and toast system for async operation feedback.
 - **State Sharing**: Synchronized data flow across disparate views.
 - **Component Library**: Pre-built, enterprise-grade components like Login and Settings views.
 
 ## Usage
 ```swift
 // 1. Configure behavior
 Toolkit.ui.configure(UIConfig(animationsEnabled: true))
 
 // 2. Trigger a global notification
 Toolkit.ui.showSuccess("Document Saved")
 
 // 3. Instantiate a modular view
 let settingsView = Toolkit.ui.makeSettingsView()
 ```
 */
@MainActor
public final class ToolkitUI: Sendable {

    // MARK: - Singleton

    /// Shared global instance for centralized UI management.
    public static let shared = ToolkitUI()

    // MARK: - Sub-managers

    /// The manager responsible for active design tokens, fonts, and theme switching.
    public let theme: ThemeManager
    
    /// The manager for displaying global, non-blocking HUD and Toast notifications.
    public let toast: ToastManager
    
    /// The container for shared global state that needs to persist across view transitions.
    public let globalState: GlobalStateContainer

    // MARK: - Config

    /// Current global UI behavior settings (e.g., animations, retry logic).
    public private(set) var uiConfig: UIConfig

    // MARK: - Init

    /**
     Initializes the UI facade with specific sub-managers or defaults.
     
     - Parameters:
        - uiConfig: Global behavioral settings. Defaults to `UIConfig()`.
        - theme: A custom theme manager instance.
        - toast: A custom toast manager instance.
        - globalState: A custom global state container.
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
     Updates the global UI behavior and optionally applies a new visual theme.
     
     - Parameter config: The new configuration to apply.
     */
    public func configure(_ config: UIConfig) {
        self.uiConfig = config
        if let themeConfig = config.themeConfig {
            theme.apply(themeConfig)
        }
    }

    // MARK: - Toast Shortcuts

    /**
     Displays a success notification overlay.
     
     - Parameters:
        - message: The success message to display.
        - duration: How long the notification should stay on screen. Defaults to 3.0s.
     */
    @MainActor
    public func showSuccess(_ message: String, duration: Double = 3.0) {
        toast.show(ToastConfig(message: message, style: .success, duration: duration))
    }

    /**
     Displays an error notification overlay.
     
     - Parameters:
        - message: The error description.
        - duration: How long the notification should stay on screen. Defaults to 4.0s.
     */
    @MainActor
    public func showError(_ message: String, duration: Double = 4.0) {
        toast.show(ToastConfig(message: message, style: .error, duration: duration))
    }

    /**
     Displays an informational notification overlay.
     
     - Parameter message: The info message.
     */
    @MainActor
    public func showInfo(_ message: String) {
        toast.show(ToastConfig(message: message, style: .info))
    }

    // MARK: - View Factories

    /**
     Creates a fully configured `TKLoginView` integrated with the `ToolkitAuth` backend.
     
     - Parameters:
        - config: Visual and behavioral settings for the login screen.
        - onSuccess: A closure executed after the user successfully authenticates.
     - Returns: A fully-themed SwiftUI view ready for presentation.
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
 
 Configuration options that control behavioral and visual aspects of the ToolkitUI layer.
 */
public struct UIConfig: Sendable {
    /// An optional theme configuration to be applied globally upon initialization.
    public var themeConfig: ThemeConfig? = nil
    /// Whether to enable standard view transitions and micro-animations. Defaults to `true`.
    public var animationsEnabled: Bool = true
    /// The default text displayed during global loading states. Defaults to "Loading…".
    public var defaultLoadingMessage: String = "Loading…"
    /// If enabled, specific UI components will offer a "Retry" button upon failure. Defaults to `true`.
    public var errorRetryEnabled: Bool = true

    /// Initializes a default configuration instance.
    public init() {}
}

// MARK: - Toolkit Namespace

public extension Toolkit {
    /// Global access point for the ToolkitUI module services.
    @MainActor
    static var ui: ToolkitUI { ToolkitUI.shared }
}
