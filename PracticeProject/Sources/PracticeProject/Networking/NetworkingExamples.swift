import Foundation
import ToolkitNetworking

/// Examples demonstrating usage of ToolkitNetworking methods.
public struct NetworkingExamples {
    public static func run() async {
        print("=== ToolkitNetworking Examples ===")
        let network = APIClient.shared
        print("Accessing APIClient shared instance: \(network)")
        
        // Example building a request
        // let request = RequestBuilder(url: URL(string: "https://api.example.com")!).build()
        // let response = try await network.execute(request)
        
        print("Demonstrated networking setup, ready for requests.")
        print("==================================\n")
    }
}
