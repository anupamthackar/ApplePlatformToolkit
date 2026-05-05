import SwiftUI
import ToolkitCore
import ToolkitAuth

public struct ToolkitUI {
    public static func configure() {
        Logger.shared.log("ToolkitUI configured")
    }
}

public struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    public init() {}
    
    public var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Login") {
                // Perform login
                AuthManager.shared.setAccessToken("sample_token")
            }
            .padding()
        }
    }
}
