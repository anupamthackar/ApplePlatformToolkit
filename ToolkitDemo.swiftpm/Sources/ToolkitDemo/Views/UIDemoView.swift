import SwiftUI
import ToolkitUI
import ToolkitCore

@MainActor
struct UIDemoView: View {
    @State private var selectedScenario: UIScenario = .components
    @Environment(\.tkTheme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Custom Segmented Picker
                HStack(spacing: 0) {
                    ForEach(UIScenario.allCases, id: \.self) { scenario in
                        Button(action: { withAnimation(.spring()) { selectedScenario = scenario } }) {
                            Text(scenario.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedScenario == scenario ? theme.primaryColor : Color.clear)
                                .foregroundColor(selectedScenario == scenario ? .white : theme.textSecondary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(4)
                .background(theme.surfaceColor)
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(spacing: 32) {
                    switch selectedScenario {
                    case .components:
                        BasicComponentsSection()
                    case .feedback:
                        FeedbackSection()
                    case .theme:
                        ThemeSection()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("UI Framework")
        .background(theme.backgroundColor.ignoresSafeArea())
        .tkThemed()
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
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                TKSectionHeader("Input & Buttons")
                
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
                
                TKButton(config: TKButtonConfig(title: "Primary Action")) {
                    print("Primary Clicked")
                }
                
                TKButton(config: {
                    var config = TKButtonConfig(title: "Secondary Loading", style: .secondary)
                    config.isLoading = isLoading
                    return config
                }()) {
                    isLoading = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        isLoading = false
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                TKSectionHeader("Layout Containers")
                
                TKCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TKCard Surface")
                                .font(.headline)
                            Spacer()
                            TKBadge("Modern")
                        }
                        Text("This container adapts to light and dark modes while maintaining a premium glass-like depth.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Feedback
struct FeedbackSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TKSectionHeader("Status Indicators")
            
            TKCard {
                VStack(spacing: 16) {
                    StatusRow(title: "Success", icon: "checkmark.circle.fill", color: .green)
                    Divider()
                    StatusRow(title: "Warning", icon: "exclamationmark.triangle.fill", color: .orange)
                    Divider()
                    StatusRow(title: "Error", icon: "xmark.octagon.fill", color: .red)
                }
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}

// MARK: - Theme
struct ThemeSection: View {
    @Environment(\.tkTheme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TKSectionHeader("Active Design Tokens")
            
            TKCard {
                VStack(spacing: 12) {
                    ColorCircle(color: theme.primaryColor, name: "Primary")
                    ColorCircle(color: theme.surfaceColor, name: "Surface")
                    ColorCircle(color: theme.backgroundColor, name: "Background")
                    ColorCircle(color: theme.errorColor, name: "Error")
                }
            }
            
            TKSectionHeader("Live Customization")
            
            TKCard {
                VStack(spacing: 12) {
                    TKButton(config: TKButtonConfig(title: "Apple Modern (Blue)", style: .outline)) {
                        var config = ThemeConfig()
                        config.primaryColor = .blue
                        config.cornerRadius = 12
                        ThemeManager.shared.apply(config)
                    }
                    
                    TKButton(config: TKButtonConfig(title: "Vibrant Slate (Orange)", style: .outline)) {
                        var config = ThemeConfig()
                        config.primaryColor = .orange
                        config.cornerRadius = 24
                        ThemeManager.shared.apply(config)
                    }
                    
                    HStack(spacing: 12) {
                        TKButton(config: TKButtonConfig(title: "Dark Mode", style: .secondary)) {
                            ThemeManager.shared.applyDarkMode()
                        }
                        TKButton(config: TKButtonConfig(title: "Light Mode", style: .secondary)) {
                            ThemeManager.shared.applyLightMode()
                        }
                    }
                }
            }
        }
    }
}

struct ColorCircle: View {
    let color: Color
    let name: String
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            Text(name)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Text(color.description.prefix(10))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
