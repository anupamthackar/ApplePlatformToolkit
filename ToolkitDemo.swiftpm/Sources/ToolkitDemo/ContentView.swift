import SwiftUI
import ToolkitAll

@MainActor
struct ContentView: View {
    let sections = [
        SectionItem(name: "Crypto", icon: "lock.shield", color: .blue, destination: AnyView(CryptoDemoView())),
        SectionItem(name: "Networking", icon: "network", color: .green, destination: AnyView(NetworkingDemoView())),
        SectionItem(name: "Auth", icon: "person.badge.key", color: .purple, destination: AnyView(AuthDemoView())),
        SectionItem(name: "UI Components", icon: "square.grid.2x2", color: .orange, destination: AnyView(UIDemoView())),
        SectionItem(name: "Utility", icon: "wrench.and.screwdriver", color: .gray, destination: AnyView(UtilityDemoView()))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(sections) { section in
                            NavigationLink(destination: section.destination) {
                                SectionCard(section: section)
                            }
                        }
                    }
                    .padding()
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .background(Color.dashboardBackground.ignoresSafeArea())
        }
    }
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toolkit Sections")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Comprehensive toolkit scenario testing")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 40)
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
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(section.color.gradient)
                .cornerRadius(16)
                .shadow(color: section.color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text(section.name)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension Color {
    static var dashboardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    static var cardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
