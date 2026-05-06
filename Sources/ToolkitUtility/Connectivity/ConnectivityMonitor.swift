import Foundation
import Combine

// MARK: - Connectivity Monitor Documentation

/**
 # ConnectivityMonitor
 
 A protocol-oriented service for monitoring network reachability and connection types.
 Supports real-time updates via `AsyncStream` and manual overrides for testing.
 
 ## Usage
 ```swift
 let monitor = DefaultConnectivityMonitor(config: ConnectivityConfig())
 
 // Start listening
 monitor.startMonitoring()
 
 // Observe changes
 Task {
     for await state in monitor.updates {
         print("Network changed to: \(state.type)")
     }
 }
 
 // Immediate check
 if monitor.isReachable() {
     let type = monitor.currentConnectionType()
 }
 ```
 */
public protocol ConnectivityMonitor: Sendable {
    /// Starts the observation process.
    func startMonitoring()
    
    /// Stops the observation process and finishes the update stream.
    func stopMonitoring()
    
    /// An asynchronous stream of connectivity state changes.
    var updates: AsyncStream<ConnectivityState> { get }
    
    /// Returns the currently active network interface type.
    func currentConnectionType() -> NetworkType
    
    /// Returns whether the internet is currently reachable.
    func isReachable() -> Bool
    
    /// Provides an estimated quality score of the current connection.
    func networkSpeedEstimation() -> Double
    
    /// Indicates if the device is in an explicit offline mode.
    func isOfflineMode() -> Bool
    
    /// Indicates if Airplane Mode is active.
    func isAirplaneMode() -> Bool
    
    /// Returns the history of detected state changes.
    func networkChangeHistory() -> [ConnectivityState]
    
    /// Manually overrides the detected connection type (useful for testing).
    func setManualOverride(to type: NetworkType)
    
    /// Pings a host to determine latency.
    func ping() async -> TimeInterval
}

/**
 The types of network connections that can be detected or simulated.
 */
public enum NetworkType: Sendable, Equatable {
    case wifi
    case cellular2G
    case cellular3G
    case cellular4G
    case cellular5G
    case offline
    case unknown
    case manual(String)
}

/**
 A snapshot of the network state at a specific point in time.
 */
public struct ConnectivityState: Sendable {
    /// The detected network type.
    public let type: NetworkType
    /// Whether the internet is reachable.
    public let isReachable: Bool
    /// The estimated speed or quality.
    public let speed: Double
    /// The time this state was captured.
    public let timestamp: Date
}

/**
 Configuration options for the `ConnectivityMonitor`.
 */
public struct ConnectivityConfig: Sendable {
    /// Interval between passive checks.
    public var pollingInterval: TimeInterval = 1.0
    /// Delay before emitting a state change to avoid rapid flipping.
    public var debounceDuration: TimeInterval = 0.5
    /// The intensity of monitoring.
    public var monitoringMode: MonitoringMode = .passive
    
    public enum MonitoringMode: Sendable { case active, passive }
    
    public init() {}
}

// MARK: - Default Implementation

/// Standard implementation of `ConnectivityMonitor` using system reachability or stubs.
public final class DefaultConnectivityMonitor: ConnectivityMonitor, @unchecked Sendable {
    private let config: ConnectivityConfig
    private var history: [ConnectivityState] = []
    private var overrideType: NetworkType? = nil
    
    private var continuation: AsyncStream<ConnectivityState>.Continuation?
    private var _updates: AsyncStream<ConnectivityState>?
    
    public var updates: AsyncStream<ConnectivityState> {
        if let _updates = _updates { return _updates }
        let (stream, cont) = AsyncStream.makeStream(of: ConnectivityState.self)
        self.continuation = cont
        self._updates = stream
        return stream
    }
    
    public init(config: ConnectivityConfig) {
        self.config = config
    }
    
    public func startMonitoring() {
        emitUpdate()
    }
    
    public func stopMonitoring() {
        continuation?.finish()
    }
    
    public func currentConnectionType() -> NetworkType {
        return overrideType ?? .wifi
    }
    
    public func isReachable() -> Bool {
        return overrideType != .offline
    }
    
    public func networkSpeedEstimation() -> Double { return 100.0 }
    public func isOfflineMode() -> Bool { return currentConnectionType() == .offline }
    public func isAirplaneMode() -> Bool { return false }
    
    public func networkChangeHistory() -> [ConnectivityState] {
        return history
    }
    
    public func setManualOverride(to type: NetworkType) {
        self.overrideType = type
        emitUpdate()
    }
    
    public func ping() async -> TimeInterval {
        return 0.05
    }
    
    private func emitUpdate() {
        let state = ConnectivityState(
            type: currentConnectionType(),
            isReachable: isReachable(),
            speed: networkSpeedEstimation(),
            timestamp: Date()
        )
        history.append(state)
        continuation?.yield(state)
    }
}
