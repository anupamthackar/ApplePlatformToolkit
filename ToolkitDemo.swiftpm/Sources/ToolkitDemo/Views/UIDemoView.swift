import SwiftUI
import ToolkitUI

@MainActor
struct UIDemoView: View {
    @State private var selectedScenario: UIScenario = .components
    
    var body: some View {
        List {
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(UIScenario.allCases, id: \.self) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            
            switch selectedScenario {
            case .components:
                BasicComponentsSection()
            case .feedback:
                FeedbackSection()
            case .theme:
                ThemeSection()
            }
        }
        .navigationTitle("UI Section")
        .tkThemed() // Apply Toolkit Theme
    }
}

enum UIScenario: String, CaseIterable {
    case components = "Basics"
    case feedback = "Feedback"
    case theme = "Theming"
}

// MARK: - Basic Components
struct BasicComponentsSection: View {
    @State private var text = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        Section("Input & Buttons") {
            TKTextField(
                text: $text,
                placeholder: "Enter something...",
                icon: "pencil.line"
            )
            
            TKTextField(
                text: $password,
                placeholder: "Enter password...",
                icon: "lock",
                isSecure: true
            )
            
            TKButton(config: TKButtonConfig(title: "Primary Button")) {
                print("Primary Clicked")
            }
            
            TKButton(config: {
                var config = TKButtonConfig(title: "Secondary Loading")
                config.style = .secondary
                config.isLoading = isLoading
                return config
            }()) {
                isLoading = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    isLoading = false
                }
            }
            
            TKButton(config: {
                var config = TKButtonConfig(title: "Destructive Action")
                config.style = .destructive
                return config
            }()) {
                print("Destructive Clicked")
            }
        }
        
        Section("Layout") {
            TKCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TKCard Component")
                        .font(.headline)
                    Text("This is a reusable card component with standardized shadow and corner radius.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Feedback
struct FeedbackSection: View {
    var body: some View {
        Section("Indicators") {
            HStack {
                Text("Success")
                Spacer()
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
            HStack {
                Text("Warning")
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            }
            HStack {
                Text("Error")
                Spacer()
                Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
            }
        }
    }
}

// MARK: - Theme
struct ThemeSection: View {
    @Environment(\.tkTheme) var theme
    
    var body: some View {
        Section("Active Design System") {
            ColorCircle(color: theme.primaryColor, name: "Primary")
            ColorCircle(color: theme.secondaryColor, name: "Secondary")
            ColorCircle(color: theme.surfaceColor, name: "Surface")
            ColorCircle(color: theme.errorColor, name: "Error")
            
            LabeledContent("Corner Radius", value: "\(theme.cornerRadius)pt")
            LabeledContent("Body Size", value: "\(theme.bodySize)pt")
        }
    }
}

struct ColorCircle: View {
    let color: Color
    let name: String
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            Text(name)
            Spacer()
            Text(color.description).font(.system(.caption, design: .monospaced)).foregroundColor(.secondary)
        }
    }
}
