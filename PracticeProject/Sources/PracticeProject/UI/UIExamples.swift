import Foundation
import ToolkitUI

/// Examples demonstrating usage of ToolkitUI methods.
public struct UIExamples {
    @MainActor
    public static func run() {
        print("=== ToolkitUI Examples ===")
        let theme = ThemeManager.shared
        print("Accessing ThemeManager shared instance: \(theme)")
        
        // Example usage of navigator or state
        print("UI components like TKNavigator, StateManagement, LoginView are ready to be used in SwiftUI views.")
        print("==========================\n")
    }
}
