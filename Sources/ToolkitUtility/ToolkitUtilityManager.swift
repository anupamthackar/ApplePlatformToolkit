import Foundation
import Combine
import ToolkitCore

// MARK: - Utility Manager Documentation

/**
 # ToolkitUtilityManager
 
 The central entry point for all utility-related features in the Apple Platform Toolkit.
 This manager provides access to connectivity monitoring, device information, formatting services,
 data validation, and Apple Watch integration.
 
 ## Usage
 ```swift
 // Access shared instance
 let utility = ToolkitUtilityManager.shared
 
 // Check reachability
 if utility.connectivity.isReachable() {
     print("Connected to \(utility.connectivity.currentConnectionType())")
 }
 
 // Get device snapshot
 let snapshot = utility.device.snapshot()
 print("Running on \(snapshot.model) with \(snapshot.osVersion)")
 
 // Validate email
 let isValid = utility.validator.isEmail("user@example.com")
 ```
 */
public final class ToolkitUtilityManager: BaseManager, @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// Shared singleton instance for global access.
    public nonisolated(unsafe) static let shared = ToolkitUtilityManager()
    
    // MARK: - Dependencies
    
    /// The active configuration for the utility manager.
    public let config: UtilityConfig
    
    /// Interface for tracking device connectivity logic.
    public let connectivity: ConnectivityMonitor
    
    /// Interface for retrieving hardware and system state.
    public let device: DeviceInfoProvider
    
    /// Interface for managing Apple Watch data syncing.
    public let watch: WatchConnectivityManagerProtocol
    
    /// Interface for formatting dates, numbers, and strings.
    public let formatter: FormatterService
    
    /// Interface for data format validation and sanitization.
    public let validator: ValidatorService
    
    // MARK: - Init
    
    /**
     Initializes the manager with specific dependencies or defaults.
     - Parameter config: Configuration options for the utility layer.
     - Parameter connectivity: A monitor for network state updates.
     - Parameter device: A provider for hardware and OS details.
     - Parameter watch: A manager for companion Watch app communication.
     - Parameter formatter: A service for string and data formatting.
     - Parameter validator: A service for data validation rules.
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
 Configuration options for the `ToolkitUtilityManager`.
 Controls global behavior for monitoring and localization.
 */
public struct UtilityConfig: Sendable {
    /// The locale to use for global formatting defaults.
    public var locale: Locale = .current
    /// The timezone to use for time computations.
    public var timeZone: TimeZone = .current
    /// The currency region used in monetary formatting.
    public var currencyRegion: String = "US"
    
    /// Initializes a new UtilityConfig.
    public init() {}
}

/**
 Common device theme states.
 */
public enum DeviceTheme: Sendable {
    case light, dark, system
}
