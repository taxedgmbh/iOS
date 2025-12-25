//
//  AuthenticationView.swift
//  TaxedGmbH_IOS
//
//  User authentication view with enhanced accessibility and Apple HIG compliance
//  Features: Email/Password auth, Apple Sign In, Biometric authentication
//  Follows Apple Human Interface Guidelines for accessibility
//

import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var biometricAuth = BiometricAuthService()
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared

    // Form State
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
    @State private var pendingBiometricPassword = ""

    // Accessibility Focus States
    @AccessibilityFocusState private var emailFieldFocused: Bool
    @AccessibilityFocusState private var passwordFieldFocused: Bool
    @AccessibilityFocusState private var nameFieldFocused: Bool
    @AccessibilityFocusState private var phoneFieldFocused: Bool
    @AccessibilityFocusState private var submitButtonFocused: Bool

    // Accessibility Environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    // Validation States for Accessibility
    @State private var emailValidationError: String?
    @State private var passwordValidationError: String?
    @State private var nameValidationError: String?
    @State private var phoneValidationError: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: dynamicSpacing(24)) {
                    // Logo and Title with Accessibility
                    logoSection

                    // Quick Login Options with Accessibility
                    if !isSignUp {
                        quickLoginSection
                    }

                    // Divider with Accessibility
                    accessibleDivider

                    // Form Fields with Accessibility
                    formFieldsSection

                    // Action Buttons with Accessibility
                    actionButtonsSection

                    // Additional Options with Accessibility
                    additionalOptionsSection
                }
                .padding(.horizontal, dynamicSpacing(20))
                .padding(.vertical, dynamicSpacing(40))
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Authentication form")
        }
        .navigationBarHidden(true)
        .onAppear {
            setupAccessibilityFocus()
            announceScreenContext()
        }
        .accessibilityOptimized()
        .sheet(isPresented: $showBiometricPrompt) {
            BiometricPromptSheet(
                biometricType: biometricAuth.biometricType,
                onEnable: {
                    enableBiometricLogin()
                },
                onSkip: {
                    pendingBiometricPassword = ""
                }
            )
        }
    }

    // MARK: - Biometric Setup

    private func enableBiometricLogin() {
        guard let userEmail = authService.user?.email, !pendingBiometricPassword.isEmpty else {
            pendingBiometricPassword = ""
            return
        }
        biometricAuth.saveBiometricCredentials(email: userEmail, password: pendingBiometricPassword)
        pendingBiometricPassword = ""
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: dynamicSpacing(12)) {
            // Logo with Accessibility
            Image("taxed-logo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: dynamicLogoSize(),
                    height: dynamicLogoSize()
                )
                .cornerRadius(20)
                .accessibleImage(label: "TaxedGmbH Application Logo")
                .accessibilityHidden(false)

            // Title with Dynamic Type
            Text(isSignUp ? "auth.signup.title".localized : "auth.login.title".localized)
                .font(dynamicFont(.largeTitle))
                .fontWeight(accessibilityManager.isBoldTextEnabled ? .heavy : .bold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            // Subtitle with Dynamic Type
            Text(isSignUp ? "auth.signup.subtitle".localized : "auth.login.subtitle".localized)
                .font(dynamicFont(.subheadline))
                .foregroundColor(accessibleSecondaryColor())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isStaticText)
        }
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(1000)
    }

    // MARK: - Quick Login Section

    private var quickLoginSection: some View {
        VStack(spacing: dynamicSpacing(16)) {
            // Biometric Authentication with Accessibility
            if biometricAuth.isBiometricEnabled() {
                biometricLoginButton
            }

            // Google Sign-In with Accessibility
            googleSignInButton

            // Apple Sign-In with Accessibility
            appleSignInButton
        }
        .accessibilitySortPriority(900)
    }

    private var biometricLoginButton: some View {
        Button(action: performBiometricLogin) {
            HStack(spacing: dynamicSpacing(12)) {
                Image(systemName: biometricAuth.biometricIcon)
                    .font(dynamicFont(.title3))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)

                Text(biometricAuth.biometricType == .faceID ?
                     "auth.faceid.signin".localized :
                     "auth.touchid.signin".localized)
                    .font(dynamicFont(.headline))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: accessibilityManager.minimumTouchTargetSize.height)
            .background(accessibleGradient())
            .cornerRadius(AppConstants.UI.cornerRadius)
            .overlay(
                showButtonShapes ?
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(Color.white, lineWidth: 2) : nil
            )
        }
        .accessibleButton(
            label: biometricAuth.biometricType == .faceID ?
                   "Sign in with Face ID" :
                   "Sign in with Touch ID",
            hint: "Authenticate using biometric authentication"
        )
        .accessibilityIdentifier("biometric_login_button")
    }

    private var googleSignInButton: some View {
        Button(action: performGoogleSignIn) {
            HStack(spacing: dynamicSpacing(12)) {
                Image(systemName: "g.circle.fill")
                    .font(dynamicFont(.title3))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)

                Text("auth.google.signin".localized)
                    .font(dynamicFont(.headline))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: accessibilityManager.minimumTouchTargetSize.height)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.22, green: 0.45, blue: 0.82)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppConstants.UI.cornerRadius)
            .overlay(
                showButtonShapes ?
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(Color.white, lineWidth: 2) : nil
            )
        }
        .accessibleButton(
            label: "auth.google.signin.label".localized,
            hint: "auth.google.signin.hint".localized
        )
        .accessibilityIdentifier("google_signin_button")
    }

    private var appleSignInButton: some View {
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
        .signInWithAppleButtonStyle(colorSchemeContrast == .increased ? .whiteOutline : .black)
        .frame(height: 50) // Apple HIG recommended height: 44-50pt
        .cornerRadius(AppConstants.UI.cornerRadius)
        .accessibilityLabel("auth.apple.signin.label".localized)
        .accessibilityHint("auth.apple.signin.hint".localized)
        .accessibilityIdentifier("apple_signin_button")
    }

    // MARK: - Divider Section

    private var accessibleDivider: some View {
        HStack(spacing: dynamicSpacing(8)) {
            VStack { Divider() }
                .accessibilityHidden(true)

            Text("auth.divider.or".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(accessibleSecondaryColor())
                .accessibilityLabel("auth.divider.or".localized)

            VStack { Divider() }
                .accessibilityHidden(true)
        }
        .accessibilitySortPriority(800)
    }

    // MARK: - Form Fields Section

    private var formFieldsSection: some View {
        VStack(spacing: dynamicSpacing(16)) {
            // Name Field (Sign Up only)
            if isSignUp {
                nameField
            }

            // Email Field
            emailField

            // Password Field
            passwordField

            // Phone Field (Sign Up only)
            if isSignUp {
                phoneField
            }
        }
        .accessibilitySortPriority(700)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("auth.name.label".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(accessibleSecondaryColor())
                .accessibilityHidden(true)

            TextField("auth.name.placeholder".localized, text: $name)
                .textFieldStyle(AccessibleTextFieldStyle())
                .textContentType(.name)
                .autocapitalization(.words)
                .accessibilityFocused($nameFieldFocused)
                .accessibleTextField(
                    label: "auth.name.label".localized,
                    hint: "auth.name.hint".localized,
                    value: name
                )
                .accessibilityIdentifier("name_field")
                .onChange(of: name) { _, _ in
                    validateName()
                }

            if let error = nameValidationError {
                Text(error)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("auth.email.label".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(accessibleSecondaryColor())
                .accessibilityHidden(true)

            TextField("auth.email.placeholder".localized, text: $email)
                .textFieldStyle(AccessibleTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .accessibilityFocused($emailFieldFocused)
                .accessibleTextField(
                    label: "auth.email.label".localized,
                    hint: "auth.email.hint".localized,
                    value: email
                )
                .accessibilityIdentifier("email_field")
                .onChange(of: email) { _, _ in
                    validateEmail()
                }

            if let error = emailValidationError {
                Text(error)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("auth.password.label".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(accessibleSecondaryColor())
                .accessibilityHidden(true)

            HStack {
                if showPassword {
                    TextField("auth.password.placeholder".localized, text: $password)
                        .textFieldStyle(AccessibleTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                } else {
                    SecureField("auth.password.placeholder".localized, text: $password)
                        .textFieldStyle(AccessibleTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                }

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(accessibleSecondaryColor())
                        .frame(
                            minWidth: accessibilityManager.minimumTouchTargetSize.width,
                            minHeight: accessibilityManager.minimumTouchTargetSize.height
                        )
                }
                .accessibilityLabel(showPassword ? "auth.password.hide".localized : "auth.password.show".localized)
                .accessibilityHint("auth.password.toggle.hint".localized)
            }
            .accessibilityFocused($passwordFieldFocused)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("auth.password.label".localized)
            .accessibilityValue(password.isEmpty ? "auth.password.value.empty".localized : "auth.password.value.hidden".localized)
            .accessibilityHint("auth.password.hint".localized)
            .accessibilityIdentifier("password_field")

            if let error = passwordValidationError {
                Text(error)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("auth.phone.label".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(accessibleSecondaryColor())
                .accessibilityHidden(true)

            TextField("auth.phone.placeholder".localized, text: $phoneNumber)
                .textFieldStyle(AccessibleTextFieldStyle())
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .accessibilityFocused($phoneFieldFocused)
                .accessibleTextField(
                    label: "auth.phone.label".localized,
                    hint: "auth.phone.hint".localized,
                    value: phoneNumber
                )
                .accessibilityIdentifier("phone_field")
                .onChange(of: phoneNumber) { _, _ in
                    validatePhone()
                }

            if let error = phoneValidationError {
                Text(error)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: dynamicSpacing(16)) {
            // Submit Button
            submitButton

            // Toggle Sign Up/Sign In
            toggleModeButton

            // Forgot Password (Sign In only)
            if !isSignUp {
                forgotPasswordButton
            }
        }
        .accessibilitySortPriority(600)
    }

    private var submitButton: some View {
        Button(action: performAuthentication) {
            HStack {
                Text(isSignUp ? "auth.signup.button".localized : "auth.signin.button".localized)
                    .font(dynamicFont(.headline))
                    .foregroundColor(.white)

                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .accessibilityLabel("auth.loading".localized)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: accessibilityManager.minimumTouchTargetSize.height)
            .background(
                isFormValid ?
                Color.taxedPrimary :
                Color.gray
            )
            .cornerRadius(AppConstants.UI.cornerRadius)
            .overlay(
                showButtonShapes ?
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(Color.white, lineWidth: 2) : nil
            )
        }
        .disabled(!isFormValid || authService.isLoading)
        .accessibilityFocused($submitButtonFocused)
        .accessibleButton(
            label: isSignUp ? "auth.signup.button".localized : "auth.signin.button".localized,
            hint: isFormValid ?
                  "auth.submit.hint.valid".localized :
                  "auth.submit.hint.invalid".localized
        )
        .accessibilityIdentifier("submit_button")
    }

    private var toggleModeButton: some View {
        Button(action: {
            withAnimation(accessibilityManager.shouldDisableAnimations ? nil : .default) {
                isSignUp.toggle()
                resetForm()
            }
        }) {
            Text(isSignUp ? "auth.signin.prompt".localized : "auth.signup.prompt".localized)
                .font(dynamicFont(.subheadline))
                .foregroundColor(Color.taxedPrimary)
        }
        .accessibilityLabel(isSignUp ? "auth.switch.signin".localized : "auth.switch.signup".localized)
        .accessibilityHint("auth.switch.signup".localized)
        .accessibilityIdentifier("toggle_mode_button")
    }

    private var forgotPasswordButton: some View {
        Button(action: { showPasswordReset = true }) {
            Text("auth.forgot.password".localized)
                .font(dynamicFont(.caption))
                .foregroundColor(Color.taxedPrimary)
        }
        .accessibilityLabel("auth.forgot.password".localized)
        .accessibilityHint("auth.forgot.password.hint".localized)
        .accessibilityIdentifier("forgot_password_button")
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
                .accessibilityOptimized()
        }
    }

    // MARK: - Additional Options Section

    private var additionalOptionsSection: some View {
        VStack(spacing: dynamicSpacing(12)) {
            // Terms and Privacy Links
            HStack(spacing: dynamicSpacing(4)) {
                Text("auth.terms.prefix".localized)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(accessibleSecondaryColor())

                Button(action: openTerms) {
                    Text("auth.terms.link".localized)
                        .font(dynamicFont(.caption2))
                        .foregroundColor(Color.taxedPrimary)
                        .underline()
                }
                .accessibilityLabel("auth.terms.link".localized)
                .accessibilityHint("auth.terms.hint".localized)

                Text("auth.terms.and".localized)
                    .font(dynamicFont(.caption2))
                    .foregroundColor(accessibleSecondaryColor())

                Button(action: openPrivacy) {
                    Text("auth.privacy.link".localized)
                        .font(dynamicFont(.caption2))
                        .foregroundColor(Color.taxedPrimary)
                        .underline()
                }
                .accessibilityLabel("auth.privacy.link".localized)
                .accessibilityHint("auth.privacy.hint".localized)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("auth.terms.privacy.label".localized)
        }
        .accessibilitySortPriority(500)
    }

    // MARK: - Helper Methods

    private func dynamicSpacing(_ base: CGFloat) -> CGFloat {
        if dynamicTypeSize >= .accessibility1 {
            return base * 1.5
        } else if dynamicTypeSize >= .xxLarge {
            return base * 1.25
        }
        return base
    }

    private func dynamicFont(_ style: Font.TextStyle) -> Font {
        if dynamicTypeSize.isAccessibilitySize {
            switch style {
            case .largeTitle:
                return .system(size: 40, weight: .bold, design: .rounded)
            case .title:
                return .system(size: 32, weight: .semibold, design: .rounded)
            case .headline:
                return .system(size: 20, weight: .semibold, design: .default)
            case .subheadline:
                return .system(size: 18, weight: .regular, design: .default)
            case .caption:
                return .system(size: 16, weight: .regular, design: .default)
            case .caption2:
                return .system(size: 14, weight: .regular, design: .default)
            default:
                return .system(style)
            }
        }
        return .system(style)
    }

    private func dynamicLogoSize() -> CGFloat {
        if dynamicTypeSize >= .accessibility1 {
            return 150
        } else if dynamicTypeSize >= .xxLarge {
            return 120
        }
        return 100
    }

    private func accessibleSecondaryColor() -> Color {
        if differentiateWithoutColor {
            return .primary.opacity(0.7)
        }
        return .secondary
    }

    private func accessibleGradient() -> LinearGradient {
        if reduceTransparency {
            return LinearGradient(
                colors: [Color.taxedPrimary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty &&
                   !email.isEmpty &&
                   !password.isEmpty &&
                   emailValidationError == nil &&
                   passwordValidationError == nil &&
                   nameValidationError == nil
        } else {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   emailValidationError == nil &&
                   passwordValidationError == nil
        }
    }

    // MARK: - Actions

    private func performAuthentication() {
        Task {
            // Save password for potential biometric setup
            let enteredPassword = password

            if isSignUp {
                await authService.signUp(
                    email: email,
                    password: password,
                    name: name,
                    phone: phoneNumber
                )
            } else {
                await authService.signIn(
                    email: email,
                    password: password
                )
            }

            if authService.isAuthenticated {
                announceAuthenticationSuccess()

                // Offer biometric setup if available and not already enabled
                if biometricAuth.canEvaluatePolicy && !biometricAuth.isBiometricEnabled() {
                    pendingBiometricPassword = enteredPassword
                    // Small delay to ensure the main UI has updated
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showBiometricPrompt = true
                }
            } else if let error = authService.errorMessage {
                announceError(error)
            }
        }
    }

    private func performBiometricLogin() {
        Task {
            let success = await biometricAuth.performQuickLogin(authService: authService)
            if !success {
                authService.errorMessage = biometricAuth.errorMessage
                if let error = biometricAuth.errorMessage {
                    announceError(error)
                }
            } else {
                announceAuthenticationSuccess()
            }
        }
    }

    private func performGoogleSignIn() {
        Task {
            await authService.handleSignInWithGoogle()

            if authService.isAuthenticated {
                announceAuthenticationSuccess()
            } else if let error = authService.errorMessage {
                announceError(error)
            }
        }
    }

    private func resetForm() {
        email = ""
        password = ""
        name = ""
        phoneNumber = ""
        emailValidationError = nil
        passwordValidationError = nil
        nameValidationError = nil
        phoneValidationError = nil
    }

    private func openTerms() {
        // Open terms of service
    }

    private func openPrivacy() {
        // Open privacy policy
    }

    // MARK: - Validation

    private func validateEmail() {
        if email.isEmpty {
            emailValidationError = nil
        } else if !email.contains("@") || !email.contains(".") {
            emailValidationError = "auth.validation.email.invalid".localized
        } else {
            emailValidationError = nil
        }
    }

    private func validatePassword() {
        if password.isEmpty {
            passwordValidationError = nil
        } else if password.count < 6 {
            passwordValidationError = "auth.validation.password.short".localized
        } else {
            passwordValidationError = nil
        }
    }

    private func validateName() {
        if name.isEmpty {
            nameValidationError = nil
        } else if name.count < 2 {
            nameValidationError = "auth.validation.name.short".localized
        } else {
            nameValidationError = nil
        }
    }

    private func validatePhone() {
        if phoneNumber.isEmpty {
            phoneValidationError = nil
        } else if phoneNumber.count < 10 {
            phoneValidationError = "auth.validation.phone.invalid".localized
        } else {
            phoneValidationError = nil
        }
    }

    // MARK: - Accessibility

    private func setupAccessibilityFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isSignUp {
                nameFieldFocused = true
            } else {
                emailFieldFocused = true
            }
        }
    }

    private func announceScreenContext() {
        if accessibilityManager.isVoiceOverRunning {
            let message = isSignUp ?
                "auth.screen.signup.announce".localized :
                "auth.screen.signin.announce".localized
            AccessibilityAnnouncer.announceScreenChange(message)
        }
    }

    private func announceAuthenticationSuccess() {
        if accessibilityManager.isVoiceOverRunning {
            AccessibilityAnnouncer.announce(
                "auth.success.announce".localized,
                priority: .announcement
            )
        }
    }

    private func announceError(_ error: String) {
        if accessibilityManager.isVoiceOverRunning {
            AccessibilityAnnouncer.announce(
                "Error: \(error)",
                priority: .announcement
            )
        }
    }
}

// MARK: - Accessible Text Field Style

struct AccessibleTextFieldStyle: TextFieldStyle {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(
                        colorSchemeContrast == .increased ?
                        Color.primary :
                        Color.gray.opacity(0.3),
                        lineWidth: colorSchemeContrast == .increased ? 2 : 1
                    )
            )
            .frame(minHeight: accessibilityManager.minimumTouchTargetSize.height)
    }
}

// MARK: - Custom TextField (Legacy Support for PasswordResetView)

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

// MARK: - Custom SecureField (Legacy Support for PasswordResetView)

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

// MARK: - Biometric Prompt Sheet

struct BiometricPromptSheet: View {
    @Environment(\.dismiss) var dismiss
    let biometricType: BiometricType
    let onEnable: () -> Void
    let onSkip: () -> Void

    private var biometricName: String {
        biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    private var biometricIcon: String {
        biometricType == .faceID ? "faceid" : "touchid"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: biometricIcon)
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text(biometricType == .faceID ?
                 "auth.biometric.prompt.faceid.title".localized :
                 "auth.biometric.prompt.touchid.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Description
            Text(biometricType == .faceID ?
                 "auth.biometric.prompt.faceid.description".localized :
                 "auth.biometric.prompt.touchid.description".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onEnable()
                    dismiss()
                }) {
                    Text(biometricType == .faceID ?
                         "auth.biometric.prompt.enable.faceid".localized :
                         "auth.biometric.prompt.enable.touchid".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.taxedPrimary)
                        .cornerRadius(10)
                }

                Button(action: {
                    onSkip()
                    dismiss()
                }) {
                    Text("auth.biometric.prompt.skip".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }
}
