import Foundation
import Combine
import ToolkitCore

// MARK: - Utility Manager Documentation

/**
 # ToolkitUtilityManager
 
 The central entry point for all utility-related features in the Apple Platform Toolkit.
 This manager provides high-level access to device-specific features, connectivity monitoring, 
 formatting, and validation services.
 
 ## Features
 - **Connectivity**: Real-time network reachability and connection type tracking.
 - **Device Info**: Deep insights into hardware, battery, thermal state, and OS details.
 - **Watch Integration**: Simplified communication with companion Apple Watch apps.
 - **Formatting**: Extensible pipeline for dates, numbers, and strings.
 - **Validation**: Robust rules for emails, URLs, and custom data formats.
 
 ## Usage
 ```swift
 let utility = ToolkitUtilityManager.shared
 
 // Check if the internet is reachable
 if utility.connectivity.isReachable() {
     print("Connected via \(utility.connectivity.currentConnectionType())")
 }
 
 // Get a snapshot of device health
 let snapshot = utility.device.snapshot()
 print("Battery Level: \(snapshot.batteryLevel)%")
 ```
 */
public final class ToolkitUtilityManager: BaseManager, @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// Shared singleton instance for global access to utility services.
    public nonisolated(unsafe) static let shared = ToolkitUtilityManager()
    
    // MARK: - Dependencies
    
    /// The active configuration for the utility manager, defining locales and regions.
    public let config: UtilityConfig
    
    /// The service responsible for monitoring network reachability and quality.
    public let connectivity: ConnectivityMonitor
    
    /// The service responsible for providing hardware specifications and system state.
    public let device: DeviceInfoProvider
    
    /// The service managing data synchronization and messaging with an Apple Watch.
    public let watch: WatchConnectivityManagerProtocol
    
    /// The service for complex data and string formatting using standardized pipelines.
    public let formatter: FormatterService
    
    /// The service for validating data formats and sanitizing user input.
    public let validator: ValidatorService
    
    // MARK: - Init
    
    /**
     Initializes the manager with specific dependencies or defaults.
     
     - Parameters:
        - config: Configuration options for the utility layer. Defaults to `UtilityConfig()`.
        - connectivity: A custom monitor for network state.
        - device: A custom provider for hardware details.
        - watch: A custom manager for Apple Watch communication.
        - formatter: A custom formatting service.
        - validator: A custom validation service.
     */
    public init(
        config: UtilityConfig = UtilityConfig(),
        connectivity: ConnectivityMonitor? = nil,
        device: DeviceInfoProvider? = nil,
        watch: WatchConnectivityManagerProtocol? = nil,
        formatter: FormatterService? = nil,
        validator: ValidatorService? = nil
    ) {
        self.config = config
        self.connectivity = connectivity ?? DefaultConnectivityMonitor(config: ConnectivityConfig())
        self.device = device ?? DefaultDeviceInfoProvider(config: DeviceConfig())
        self.watch = watch ?? DefaultWatchConnectivityManager(config: WatchConfig())
        self.formatter = formatter ?? DefaultFormatterService(config: FormattingConfig())
        self.validator = validator ?? DefaultValidatorService(config: ValidationConfig())
        super.init()
    }
}

// MARK: - Configuration

/**
 # UtilityConfig
 
 Configuration options for the `ToolkitUtilityManager`, controlling global localization and region settings.
 */
public struct UtilityConfig: Sendable {
    /// The locale used for global formatting defaults (e.g., date and number formats).
    public var locale: Locale = .current
    /// The time zone used for time-based computations across modules.
    public var timeZone: TimeZone = .current
    /// The currency region used in monetary formatting operations.
    public var currencyRegion: String = "US"
    
    /// Initializes a default configuration instance.
    public init() {}
}

/// Represents the visual theme of the device interface.
public enum DeviceTheme: Sendable {
    /// Standard light mode appearance.
    case light
    /// High-contrast dark mode appearance.
    case dark
    /// Appearance that follows the system-wide settings.
    case system
}

// MARK: - Toolkit Extension

public extension Toolkit {
    /// Global access point for the ToolkitUtility module.
    static var utility: ToolkitUtilityManager { ToolkitUtilityManager.shared }
}
