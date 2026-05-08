import SwiftUI
import ToolkitAuth

@MainActor
struct AuthDemoView: View {
    @ObservedObject private var auth = ToolkitAuthManager.shared
    @State private var email = "demo@example.com"
    @State private var code = ""
    @State private var isLoading = false
    
    var body: some View {
        List {
            Section("Session Status") {
                HStack {
                    Circle()
                        .fill(auth.state == .authenticated ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(stateText)
                        .bold()
                }
                
                TextField("User Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                
                if auth.state == .authenticated {
                    LabeledContent("Token", value: auth.session.currentToken() ?? "None")
                    Button("Logout", role: .destructive) {
                        logout()
                    }
                }
            }
            
            if auth.state != .authenticated {
                Section("Authentication Flow") {
                    Button {
                        authenticate(method: .oauth2)
                    } label: {
                        Label("Login with OAuth2", systemImage: "safari")
                    }
                    
                    Button {
                        authenticate(method: .biometric)
                    } label: {
                        Label("Login with FaceID", systemImage: "faceid")
                    }
                }
            }
            
            Section("Security & Account") {
                NavigationLink("Multi-Factor Auth (MFA)") {
                    MFAScreen()
                }
                
                Button("Password Reset") {
                    Task { try? await auth.requestPasswordReset(email: email) }
                }
                
                Button("Fetch User Profile") {
                    Task {
                        let profile = try? await auth.fetchUserProfile()
                        print("Profile: \(profile ?? [:])")
                    }
                }
            }
        }
        .navigationTitle("Auth Section")
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
        }
    }
    
    var stateText: String {
        switch auth.state {
        case .unauthenticated: return "Unauthenticated"
        case .authenticating: return "Authenticating..."
        case .authenticated: return "Authenticated"
        case .expired: return "Session Expired"
        }
    }
    
    func authenticate(method: AuthMethod) {
        isLoading = true
        Task {
            do {
                try await auth.authenticate(method: method)
            } catch {
                print("Auth Error: \(error)")
            }
            isLoading = false
        }
    }
    
    func logout() {
        Task {
            try? await auth.logout()
        }
    }
}

struct MFAScreen: View {
    @State private var code = ""
    @State private var qrPayload = ""
    
    var body: some View {
        Form {
            Section("MFA Setup") {
                Button("Setup New MFA") {
                    Task {
                        qrPayload = try await ToolkitAuthManager.shared.setupMFA()
                    }
                }
                if !qrPayload.isEmpty {
                    Text("QR Payload: \(qrPayload)")
                        .font(.caption)
                }
            }
            
            Section("Verification") {
                TextField("6-Digit Code", text: $code)
                Button("Verify Code") {
                    Task {
                        let success = try await ToolkitAuthManager.shared.verifyMFA(code: code)
                        print("MFA Success: \(success)")
                    }
                }
            }
        }
        .navigationTitle("MFA Management")
    }
}
