import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var biometricAuth = BiometricAuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var isSignUp = false
    @State private var showPassword = false
    @State private var showPhoneVerification = false
    @State private var enableBiometric = false
    @State private var showBiometricPrompt = false
    @State private var showPasswordReset = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 12) {
                        Image("taxed-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)

                        Text(isSignUp ? "auth.signup.title".localized : "auth.login.title".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(isSignUp ? "auth.signup.subtitle".localized : "auth.login.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                // Quick Login Options
                VStack(spacing: 16) {
                    // Face ID / Touch ID Button (only for login with saved credentials)
                    if !isSignUp && biometricAuth.isBiometricEnabled() {
                        Button(action: {
                            Task {
                                let success = await biometricAuth.performQuickLogin(authService: authService)
                                if !success {
                                    authService.errorMessage = biometricAuth.errorMessage
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: biometricAuth.biometricIcon)
                                    .font(.title3)
                                    .foregroundColor(.white)

                                Text(biometricAuth.biometricType == .faceID ? "auth.faceid.signin".localized : "auth.touchid.signin".localized)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(AppConstants.UI.cornerRadius)
                            .shadow(color: Color.taxedPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }

                    // Apple Sign-In Button (for both sign in and sign up)
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            authService.handleSignInWithAppleRequest(request)
                        },
                        onCompletion: { result in
                            Task {
                                await authService.handleSignInWithAppleCompletion(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }

                // Divider with "or"
                HStack {
                    VStack { Divider() }
                    Text("auth.divider.or".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }
                .padding(.vertical, 16)

                // Email/Password Form
                VStack(spacing: 16) {
                    if isSignUp {
                        CustomTextField(
                            text: $name,
                            placeholder: "auth.name.placeholder".localized,
                            icon: "person.fill"
                        )
                        .autocapitalization(.words)
                        .textContentType(.name)

                        // Phone Number Field
                        Button {
                            showPhoneVerification = true
                        } label: {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                if phoneNumber.isEmpty {
                                    Text("auth.phone.placeholder".localized)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(phoneNumber)
                                        .foregroundColor(.primary)
                                }

                                Spacer()

                                if !phoneNumber.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(AppConstants.UI.cornerRadius)
                        }
                    }

                    CustomTextField(
                        text: $email,
                        placeholder: "auth.email.placeholder".localized,
                        icon: "envelope.fill"
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(isSignUp ? .username : .emailAddress)

                    CustomSecureField(
                        text: $password,
                        placeholder: "auth.password.placeholder".localized,
                        showPassword: $showPassword
                    )
                    .textContentType(isSignUp ? .newPassword : .password)

                    // Forgot Password Button (only for login)
                    if !isSignUp {
                        Button(action: {
                            showPasswordReset = true
                        }) {
                            Text("auth.forgot_password".localized)
                                .font(.subheadline)
                                .foregroundColor(.taxedPrimary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.top, -8)
                    }
                }

                // Error Message
                if let errorMessage = authService.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AppConstants.UI.cornerRadius)
                }

                // Sign In/Up Button
                Button(action: {
                    Task {
                        await performAuthentication()
                    }
                }) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text(isSignUp ? "auth.signup.button".localized : "auth.login.button".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Color.taxedPrimary : Color.gray)
                .cornerRadius(AppConstants.UI.cornerRadius)
                .disabled(authService.isLoading || !isFormValid)

                // Password Requirements (only for sign up)
                if isSignUp {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.password.requirements".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        PasswordRequirementRow(
                            text: String(format: "auth.password.min_length".localized, AppConstants.Validation.minimumPasswordLength),
                            isMet: password.count >= AppConstants.Validation.minimumPasswordLength
                        )
                        PasswordRequirementRow(
                            text: "auth.password.letters_numbers".localized,
                            isMet: password.range(of: "[A-Za-z]", options: .regularExpression) != nil &&
                                   password.range(of: "[0-9]", options: .regularExpression) != nil
                        )
                    }
                    .padding(.horizontal, 4)
                }

                // Biometric Enable Option (only for login)
                if !isSignUp && biometricAuth.canEvaluatePolicy && !biometricAuth.isBiometricEnabled() {
                    HStack {
                        Toggle(isOn: $enableBiometric) {
                            HStack(spacing: 12) {
                                Image(systemName: biometricAuth.biometricIcon)
                                    .foregroundColor(.taxedPrimary)
                                VStack(alignment: .leading) {
                                    Text("auth.biometric.enable".localized)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                    Text(String(format: "auth.biometric.description".localized, biometricAuth.biometricName))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .taxedPrimary))
                    }
                    .padding()
                    .background(Color.taxedPrimary.opacity(0.05))
                    .cornerRadius(AppConstants.UI.cornerRadius)
                }

                // Toggle Sign In/Up
                HStack {
                    Text(isSignUp ? "auth.toggle.login".localized : "auth.toggle.signup".localized)
                        .foregroundColor(.secondary)
                    Text(isSignUp ? "auth.toggle.login.button".localized : "auth.toggle.signup.button".localized)
                        .foregroundColor(.taxedPrimary)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isSignUp.toggle()
                        authService.errorMessage = nil
                        email = ""
                        password = ""
                        name = ""
                        phoneNumber = ""
                    }
                }
                .padding(.top, 8)

                // Add bottom padding instead of Spacer
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 24)
            .frame(minHeight: geometry.size.height)
        }
        .sheet(isPresented: $showPhoneVerification) {
            PhoneVerificationView(
                isPresented: $showPhoneVerification,
                verifiedPhoneNumber: $phoneNumber
            )
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
                .environmentObject(authService)
        }
        .alert("auth.biometric.setup.title".localized, isPresented: $showBiometricPrompt) {
            Button("auth.biometric.setup.enable".localized) {
                biometricAuth.saveBiometricCredentials(email: email, password: password)
            }
            Button("auth.biometric.setup.later".localized, role: .cancel) { }
        } message: {
            Text(String(format: "auth.biometric.setup.message".localized, biometricAuth.biometricName))
        }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && !phoneNumber.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    // MARK: - Actions

    private func performAuthentication() async {
        // Clear error message
        authService.errorMessage = nil

        if isSignUp {
            await authService.signUp(email: email, password: password, name: name, phone: phoneNumber)
            // After successful sign up, prompt for biometric setup
            if authService.isAuthenticated && biometricAuth.canEvaluatePolicy {
                showBiometricPrompt = true
            }
        } else {
            await authService.signIn(email: email, password: password)
            // After successful login, save credentials for biometric if enabled
            if authService.isAuthenticated && enableBiometric {
                biometricAuth.saveBiometricCredentials(email: email, password: password)
            }
        }
    }
}

// MARK: - Custom TextField

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .taxedPrimary : .secondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .focused($isFocused)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                        .stroke(isFocused ? Color.taxedPrimary : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Custom SecureField

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(isFocused ? .taxedPrimary : .secondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            if showPassword {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            }

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPassword.toggle()
                }
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isFocused ? .taxedPrimary : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                        .stroke(isFocused ? Color.taxedPrimary : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Password Requirement Row

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .secondary)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
}
