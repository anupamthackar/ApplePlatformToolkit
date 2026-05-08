import Foundation
import ToolkitCore
import ToolkitUtility
import ToolkitCrypto
import ToolkitCompression
import ToolkitFormatter
import ToolkitNetworking
import ToolkitAuth
import ToolkitUI
import ToolkitPlugins
import ToolkitAll

@main
struct PracticeProject {
    @MainActor
    static func main() async throws {
        print("Starting PracticeProject Examples...\n")
        
        // Run all module examples
        CoreExamples.run()
        UtilityExamples.run()
        await CryptoExamples.run()
        await CompressionExamples.run()
        FormatterExamples.run()
        await NetworkingExamples.run()
        await AuthExamples.run()
        UIExamples.run()
        PluginsExamples.run()
        
        print("PracticeProject Finished.")
    }
}
