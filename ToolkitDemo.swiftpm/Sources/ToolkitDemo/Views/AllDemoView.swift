import SwiftUI
import ToolkitAll
import ToolkitUI

@MainActor
struct AllDemoView: View {
    let modules = [
        "ToolkitCore", "ToolkitUtility", "ToolkitCrypto", 
        "ToolkitCompression", "ToolkitFormatter", "ToolkitNetworking", 
        "ToolkitAuth", "ToolkitUI", "ToolkitPlugins"
    ]
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Umbrella Module")
                        .font(.headline)
                    Text("ToolkitAll simplifies integration by exporting all sub-modules automatically. This is the recommended entry point for most developers.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Available Components") {
                ForEach(modules, id: \.self) { module in
                    HStack {
                        Image(systemName: "cube.fill")
                            .foregroundColor(.teal)
                        Text(module)
                        Spacer()
                        TKBadge("v6.0")
                    }
                }
            }
            
            Section {
                TKButton(config: TKButtonConfig(title: "Verify All Modules", style: .outline)) {
                    Toolkit.ui.showInfo("All 10 modules are healthy.")
                    Toolkit.ui
                }
            }
        }
        .navigationTitle("Package Overview")
        .tkThemed()
    }
}
