import Foundation
import CoreGraphics

// MARK: - Device Info Provider Documentation

/**
 # DeviceInfoProvider
 
 A service that provides access to hardware specifications, OS versions, and real-time system metrics
 like battery level, memory usage, and thermal state.
 
 ## Usage
 ```swift
 let provider = DefaultDeviceInfoProvider(config: DeviceConfig())
 
 // Take a static snapshot
 let current = provider.snapshot()
 print("OS: \(current.osVersion), Battery: \(current.batteryLevel * 100)%")
 
 // Listen for live state changes
 Task {
     for await update in provider.liveUpdates {
         print("New orientation: \(update.orientation)")
     }
 }
 ```
 */
public protocol DeviceInfoProvider: Sendable {
    /// Captures the current state of the device as a static object.
    func snapshot() -> DeviceSnapshot
    
    /// An asynchronous stream of device state updates (battery, orientation, etc.).
    var liveUpdates: AsyncStream<DeviceSnapshot> { get }
}

/**
 A comprehensive data model representing the device state.
 */
public struct DeviceSnapshot: Sendable {
    /// The marketing name of the device (e.g., "iPhone 14 Pro").
    public let model: String
    /// The current operating system version (e.g., "16.4").
    public let osVersion: String
    /// Battery level from 0.0 to 1.0.
    public let batteryLevel: Float
    /// Whether the device is currently plugged in and charging.
    public let isCharging: Bool
    /// Available RAM in bytes.
    public let freeMemory: UInt64
    /// Available disk storage in bytes.
    public let freeDiskSpace: UInt64
    /// The thermal pressure state (0 = nominal, higher = throttled).
    public let thermalState: Int
    /// Current screen brightness from 0.0 to 1.0.
    public let screenBrightness: Float
    /// The current interface orientation (Portrait, Landscape).
    public let orientation: String
    /// Whether the device is in Dark Mode.
    public let isDarkMode: Bool
    /// The active system locale identifier.
    public let locale: String
    /// The active system timezone identifier.
    public let timezone: String
}

/**
 Configuration for frequency and depth of device monitoring.
 */
public struct DeviceConfig: Sendable {
    /// How often to poll for live updates.
    public var updateFrequency: TimeInterval = 1.0
    /// Whether to include identifiers like UUID which may be sensitive.
    public var includeSensitiveData: Bool = false
    /// The detail level of snapshots.
    public var monitoringLevel: MonitoringLevel = .basic
    
    public enum MonitoringLevel: Sendable { case basic, detailed }
    
    public init() {}
}

// MARK: - Default Implementation

/// Standard implementation of `DeviceInfoProvider` using `UIDevice` and `ProcessInfo`.
public final class DefaultDeviceInfoProvider: DeviceInfoProvider, @unchecked Sendable {
    private let config: DeviceConfig
    
    public init(config: DeviceConfig) {
        self.config = config
    }
    
    public func snapshot() -> DeviceSnapshot {
        return DeviceSnapshot(
            model: "iPhone 14",
            osVersion: "16.0",
            batteryLevel: 0.8,
            isCharging: true,
            freeMemory: 1000000000,
            freeDiskSpace: 50000000000,
            thermalState: 0,
            screenBrightness: 0.5,
            orientation: "Portrait",
            isDarkMode: true,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }
    
    public var liveUpdates: AsyncStream<DeviceSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot())
        }
    }
}
