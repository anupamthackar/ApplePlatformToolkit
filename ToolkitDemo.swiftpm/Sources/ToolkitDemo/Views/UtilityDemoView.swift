import SwiftUI
import ToolkitCore

@MainActor
struct UtilityDemoView: View {
    @State private var selectedScenario: UtilityScenario = .logging
    
    var body: some View {
        List {
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(UtilityScenario.allCases, id: \.self) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            
            switch selectedScenario {
            case .logging:
                LoggingSection()
            case .di:
                DISection()
            case .config:
                ConfigSection()
            case .metrics:
                MetricsSection()
            }
        }
        .navigationTitle("Utility Section")
    }
}

enum UtilityScenario: String, CaseIterable {
    case logging = "Logs"
    case di = "DI"
    case config = "Config"
    case metrics = "Metrics"
}

// MARK: - Logging
struct LoggingSection: View {
    @State private var logMessage = "Test Log Message"
    @State private var selectedLevel: LogLevel = .info
    
    var body: some View {
        Section("Logger System") {
            TextField("Message", text: $logMessage)
            Picker("Level", selection: $selectedLevel) {
                Text("Debug").tag(LogLevel.debug)
                Text("Info").tag(LogLevel.info)
                Text("Warning").tag(LogLevel.warning)
                Text("Error").tag(LogLevel.error)
            }
            
            Button("Write to Log") {
                Logger.shared.log(logMessage, level: selectedLevel)
            }
            
            Button("Add Metadata (UserID)") {
                Logger.shared.addMetadata("user_id", value: "user_99")
            }
        }
        
        Section("Console Output") {
            Text("Open Xcode Console to see output in real-time.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Dependency Injection
struct DISection: View {
    @State private var resolvedValue = "Not Resolved"
    
    var body: some View {
        Section("Dependency Container") {
            Button("Register MockService") {
                DependencyContainer.shared.register(String.self, name: "API_KEY") { "SECRET_12345" }
            }
            
            Button("Resolve API_KEY") {
                resolvedValue = DependencyContainer.shared.resolve(String.self, name: "API_KEY") ?? "Not Found"
            }
            
            Text("Resolved: \(resolvedValue)")
                .bold()
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Config
struct ConfigSection: View {
    @State private var featureKey = "experimental_feature"
    @State private var isEnabled = false
    
    var body: some View {
        Section("Configuration Manager") {
            LabeledContent("Environment", value: "\(ConfigManager.shared.environment)")
            
            Toggle("Experimental Feature", isOn: $isEnabled)
                .onChange(of: isEnabled) { newValue in
                    ConfigManager.shared.load(dictionary: [featureKey: newValue])
                }
            
            Button("Check via Manager") {
                let status = ConfigManager.shared.isFeatureEnabled(featureKey)
                print("Feature Status: \(status)")
            }
        }
    }
}

// MARK: - Metrics
struct MetricsSection: View {
    @State private var metricValue: Double = 0
    @State private var average: Double = 0
    
    var body: some View {
        Section("Metrics & Monitoring") {
            Slider(value: $metricValue, in: 0...100)
            Button("Record Performance Metric") {
                Task {
                    await MetricsManager.shared.recordMetric(name: "api_latency", value: metricValue)
                    average = await MetricsManager.shared.average(for: "api_latency")
                }
            }
            
            LabeledContent("Current Average", value: String(format: "%.2f ms", average))
        }
    }
}
