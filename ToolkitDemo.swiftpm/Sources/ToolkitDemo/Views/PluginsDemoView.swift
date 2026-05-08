import SwiftUI
import ToolkitPlugins
import ToolkitCore
import ToolkitUI

@MainActor
struct PluginsDemoView: View {
    @State private var events: [String] = []
    @State private var pluginCount = 0
    @State private var customEventName = "user_clicked_demo"
    @State private var customPayload = "Sample Data"
    
    var body: some View {
        List {
            Section("Plugin Management") {
                LabeledContent("Registered Plugins", value: "\(pluginCount)")
                TKButton(config: TKButtonConfig(title: "Register Standard Plugins")) {
                    registerPlugins()
                }
            }
            
            Section("Event Bus (Pub/Sub)") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Event Name", text: $customEventName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Payload Content", text: $customPayload)
                        .textFieldStyle(.roundedBorder)
                    
                    TKButton(config: TKButtonConfig(title: "Publish Custom Event", style: .secondary)) {
                        Task {
                            await EventBus.shared.publish(TypedEvent(name: customEventName, payload: ["content": customPayload, "time": Date().description]))
                        }
                    }
                }
                .padding(.vertical, 8)
                
                ForEach(events, id: \.self) { event in
                    Text(event)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Plugins & Events")
        .tkThemed()
        .onAppear {
            setupSubscription()
            refreshStats()
        }
    }
    
    private func setupSubscription() {
        EventBus.shared.subscribe(event: "user_clicked_demo") { event in
            await MainActor.run {
                events.insert("Received: \(event.name) at \(event.payload["time"] as? String ?? "")", at: 0)
            }
        }
    }
    
    private func registerPlugins() {
        do {
            try PluginManager.shared.register(LoggingPlugin())
            try PluginManager.shared.register(AnalyticsPlugin())
            Toolkit.ui.showSuccess("Plugins Registered")
            refreshStats()
        } catch {
            Toolkit.ui.showError("Registration failed")
        }
    }
    
    private func refreshStats() {
        // Mocking refresh as internal state isn't fully exposed in public API for simplicity
        pluginCount = 2 
    }
}
