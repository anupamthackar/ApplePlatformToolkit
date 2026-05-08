import SwiftUI
import ToolkitAll

@MainActor
struct ContentView: View {
    let sections = [
        SectionItem(name: "Crypto", icon: "lock.shield", color: .blue, destination: AnyView(CryptoDemoView())),
        SectionItem(name: "Networking", icon: "network", color: .green, destination: AnyView(NetworkingDemoView())),
        SectionItem(name: "Auth", icon: "person.badge.key", color: .purple, destination: AnyView(AuthDemoView())),
        SectionItem(name: "UI Components", icon: "square.grid.2x2", color: .orange, destination: AnyView(UIDemoView())),
        SectionItem(name: "Utility", icon: "wrench.and.screwdriver", color: .gray, destination: AnyView(UtilityDemoView())),
        SectionItem(name: "Compression", icon: "arrow.down.right.and.arrow.up.left", color: .cyan, destination: AnyView(CompressionDemoView())),
        SectionItem(name: "Formatter", icon: "text.quote", color: .pink, destination: AnyView(FormatterDemoView())),
        SectionItem(name: "Plugins", icon: "puzzlepiece", color: .indigo, destination: AnyView(PluginsDemoView())),
        SectionItem(name: "Core", icon: "cpu", color: .red, destination: AnyView(CoreDemoView())),
        SectionItem(name: "ToolkitAll", icon: "cube.box", color: .teal, destination: AnyView(AllDemoView()))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerView
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                        ForEach(sections) { section in
                            NavigationLink(destination: section.destination) {
                                SectionCard(section: section)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 4) {
                        Text("Architecture Exploration Demo")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text("Optimized for 'My Mac' Destination")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .background(Color.dashboardBackground.ignoresSafeArea())
        }
    }
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Toolkit")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text("Sections")
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text("A comprehensive suite for enterprise Apple platform development.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 60)
    }
}

struct SectionItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let destination: AnyView
}

struct SectionCard: View {
    let section: SectionItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(section.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: section.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(section.color.gradient)
            }
            
            VStack(spacing: 4) {
                Text(section.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Module")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 15 : 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(section.color.opacity(isHovered ? 0.3 : 0.0), lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        #if os(macOS)
        .onHover { isHovered = $0 }
        #endif
    }
}

extension Color {
    static var dashboardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    static var cardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}
