import SwiftUI
import ToolkitCore
import ToolkitUI

@MainActor
struct CoreDemoView: View {
    @State private var logs: [String] = []
    @State private var customLog = "System check: Normal"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TKCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TKSectionHeader("Infrastructure Logging")
                        
                        TextField("Enter custom log message", text: $customLog)
                            .textFieldStyle(.roundedBorder)
                        
                        TKButton(config: TKButtonConfig(title: "Log Info Message")) {
                            Toolkit.core.logger.log(customLog, level: .info)
                            logs.insert("Log: '\(customLog)' sent", at: 0)
                        }
                        
                        TKButton(config: TKButtonConfig(title: "Log Critical Error", style: .destructive)) {
                            Toolkit.core.logger.log("CRITICAL: \(customLog)", level: .critical)
                            logs.insert("Log: Critical failure reported", at: 0)
                        }
                    }
                }
                
                TKCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TKSectionHeader("Dependency Injection")
                        Text("Resolved Service: \(resolvedService)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !logs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        TKSectionHeader("Local Session Logs")
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .font(.system(.caption, design: .monospaced))
                                .padding(6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Core Infrastructure")
        .tkThemed()
    }
    
    private var resolvedService: String {
        // Simple DI demonstration
        return "CoreService-v1.0"
    }
}
