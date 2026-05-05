import Foundation
import ToolkitCore

public protocol PluginProtocol: Sendable {
    var id: String { get }
    func onLoad()
    func onExecute()
    func onUnload()
}

public final class PluginRegistry: @unchecked Sendable {
    public static let shared = PluginRegistry()
    private var plugins: [String: PluginProtocol] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func register(_ plugin: PluginProtocol) {
        lock.lock()
        plugins[plugin.id] = plugin
        lock.unlock()
        plugin.onLoad()
    }
    
    public func unregister(id: String) {
        lock.lock()
        let plugin = plugins.removeValue(forKey: id)
        lock.unlock()
        plugin?.onUnload()
    }
    
    public func executeAll() {
        lock.lock()
        let currentPlugins = plugins.values
        lock.unlock()
        currentPlugins.forEach { $0.onExecute() }
    }
}
