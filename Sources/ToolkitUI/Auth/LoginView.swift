import SwiftUI
import Combine

// MARK: - Login ViewModel

@MainActor
public final class LoginViewModel: TKViewModel {

    // MARK: - State
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var emailError: String? = nil
    @Published public var passwordError: String? = nil
    @Published public var isAuthenticated: Bool = false

    // MARK: - Config
    public struct Config {
        public var enableBiometric: Bool = false
        public var enableOTP: Bool = false
        public var enableSocialLogin: Bool = false
        public var minimumPasswordLength: Int = 8
        public init() {}
    }

    private let config: Config
    private var cancellables = Set<AnyCancellable>()

    public init(config: Config = Config()) {
        self.config = config
        super.init()
        setupLiveValidation()
    }

    // MARK: - Live Validation

    private func setupLiveValidation() {
        $email
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.emailError = value.isEmpty ? nil : (value.contains("@") ? nil : "Please enter a valid email")
            }
            .store(in: &cancellables)

        $password
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                if value.isEmpty { self.passwordError = nil; return }
                self.passwordError = value.count < self.config.minimumPasswordLength
                    ? "Password must be at least \(self.config.minimumPasswordLength) characters"
                    : nil
            }
            .store(in: &cancellables)
    }

    // MARK: - Validation

    public func validate() -> Bool {
        var valid = true
        if email.isEmpty || !email.contains("@") {
            emailError = "Enter a valid email address"
            valid = false
        }
        if password.count < config.minimumPasswordLength {
            passwordError = "Password must be at least \(config.minimumPasswordLength) characters"
            valid = false
        }
        return valid
    }

    // MARK: - Login

    public func login() {
        guard validate() else { return }
        run {
            try await Task.sleep(nanoseconds: 1_500_000_000) // Simulated auth delay
            self.isAuthenticated = true
            self.successMessage = "Welcome back!"
        }
    }

    public func forgotPassword() {
        run {
            try await Task.sleep(nanoseconds: 800_000_000)
            self.successMessage = "Password reset email sent"
        }
    }

    public func loginWithBiometric() {
        run {
            // LAContext integration hook
            try await Task.sleep(nanoseconds: 500_000_000)
            self.isAuthenticated = true
        }
    }
}

// MARK: - Login View

public struct TKLoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.tkTheme) private var theme
    @State private var animateIn = false

    public var onSuccess: (() -> Void)?
    public var onForgotPassword: (() -> Void)?

    public init(config: LoginViewModel.Config = LoginViewModel.Config(), onSuccess: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: LoginViewModel(config: config))
        self.onSuccess = onSuccess
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    Text("Welcome Back")
                        .font(.system(size: theme.headingSize, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Text("Sign in to continue")
                        .font(.system(size: theme.bodySize))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 40)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateIn)

                // Form
                VStack(spacing: 14) {
                    TKTextField(
                        text: $viewModel.email,
                        placeholder: "Email address",
                        icon: "envelope",
                        errorMessage: viewModel.emailError
                    )

                    TKTextField(
                        text: $viewModel.password,
                        placeholder: "Password",
                        icon: "lock",
                        errorMessage: viewModel.passwordError,
                        isSecure: true
                    )
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateIn)

                // Error
                if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(theme.errorColor)
                    .padding(10)
                    .background(theme.errorColor.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                }

                // Actions
                VStack(spacing: 12) {
                    TKButton(config: {
                        var c = TKButtonConfig(title: "Sign In")
                        c.isLoading = viewModel.isLoading
                        c.icon = "arrow.right.circle.fill"
                        return c
                    }()) { viewModel.login() }

                    Button("Forgot password?") { viewModel.forgotPassword() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryColor)
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateIn)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, theme.defaultPadding)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .onAppear { animateIn = true }
        .onChange(of: viewModel.isAuthenticated) { authenticated in
            if authenticated { onSuccess?() }
        }
    }
}

#if DEBUG
struct TKLoginView_Previews: PreviewProvider {
    static var previews: some View {
        TKLoginView()
            .tkThemed()
    }
}
#endif
