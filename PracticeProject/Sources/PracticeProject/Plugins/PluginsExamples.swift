import Foundation
import ToolkitPlugins

/// Examples demonstrating usage of ToolkitPlugins methods.
public struct PluginsExamples {
    public static func run() {
        print("=== ToolkitPlugins Examples ===")
        let plugins = PluginManager.shared
        print("Accessing PluginManager shared instance: \(plugins)")
        
        let bus = EventBus.shared
        print("Accessing EventBus shared instance: \(bus)")
        
        // Example usage
        // bus.subscribe(to: "UserLogin") { event in ... }
        // bus.publish(event: "UserLogin", payload: [...])
        
        print("Demonstrated plugin and event bus availability.")
        print("===============================\n")
    }
}
