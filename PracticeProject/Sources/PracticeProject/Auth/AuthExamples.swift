import Foundation
import ToolkitAuth

/// Examples demonstrating usage of ToolkitAuth methods.
public struct AuthExamples {
    @MainActor
    public static func run() async {
        print("=== ToolkitAuth Examples ===")
        let auth = ToolkitAuthManager.shared
        print("Accessing ToolkitAuthManager shared instance: \(auth)")
        
        // Example usage
        // let token = try await auth.login(username: "user", password: "password")
        // auth.logout()
        
        print("Demonstrated authentication manager accessibility.")
        print("============================\n")
    }
}
