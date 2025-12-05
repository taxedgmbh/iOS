//
//  AuthenticationView_LiquidGlass.swift
//  TaxedGmbH_IOS
//
//  Liquid Glass Authentication with seamless biometric and 2FA integration
//  Apple HIG compliant with premium glass design
//

import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct AuthenticationView_LiquidGlass: View {
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
    @State private var showPasswordReset = false

    // Validation States
    @State private var emailValidationError: String?
    @State private var passwordValidationError: String?
    @State private var nameValidationError: String?

    // Animation States
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    // Accessibility Focus States
    @AccessibilityFocusState private var emailFieldFocused: Bool

    // Accessibility Environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Animated Glass Background
            AnimatedGlassBackground()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo Section with Glass
                        logoSectionGlass
                            .padding(.top, 60)

                        // Quick Login Options (Login only)
                        if !isSignUp {
                            quickLoginGlassSection
                        }

                        // Divider
                        accessibleDividerGlass

                        // Form Fields in Glass Card
                        formFieldsGlassCard

                        // Action Buttons
                        actionButtonsGlass

                        // Additional Options
                        additionalOptionsGlass
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateEntrance()
            setupAccessibilityFocus()
        }
        .fullScreenCover(isPresented: $showPasswordReset) {
            PasswordResetView_LiquidGlass()
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showPhoneVerification) {
            PhoneVerificationView_LiquidGlass(
                isPresented: $showPhoneVerification,
                verifiedPhoneNumber: $phoneNumber
            )
        }
    }

    // MARK: - Logo Section with Glass

    private var logoSectionGlass: some View {
        VStack(spacing: 16) {
            // Glass Logo Container
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.taxedPrimary.opacity(0.6),
                                        Color.taxedPrimary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image("taxed-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
            }
            .glow(color: .taxedPrimary, radius: 20)
            .scaleEffect(logoScale)

            VStack(spacing: 8) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(isSignUp ? "Join Taxed to simplify your taxes" : "Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(contentOpacity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Quick Login Glass Section

    private var quickLoginGlassSection: some View {
        VStack(spacing: 16) {
            // Biometric Authentication Glass Button
            if biometricAuth.isBiometricEnabled() {
                biometricGlassButton
            }

            // Apple Sign-In Glass Button
            appleSignInGlassButton
        }
        .opacity(contentOpacity)
    }

    private var biometricGlassButton: some View {
        Button(action: performBiometricLogin) {
            HStack(spacing: 12) {
                Image(systemName: biometricAuth.biometricIcon)
                    .font(.title3)
                    .foregroundColor(.taxedPrimary)

                Text(biometricAuth.biometricType == .faceID ?
                     "Sign in with Face ID" :
                     "Sign in with Touch ID")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .glassCard(cornerRadius: 16, borderColor: .taxedPrimary.opacity(0.3), glowColor: .taxedPrimary.opacity(0.2))
        .accessibilityLabel(biometricAuth.biometricType == .faceID ?
                           "Sign in with Face ID" :
                           "Sign in with Touch ID")
    }

    private var appleSignInGlassButton: some View {
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
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 56)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Divider Glass

    private var accessibleDividerGlass: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.secondary.opacity(0.3),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.secondary.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Form Fields Glass Card

    private var formFieldsGlassCard: some View {
        VStack(spacing: 16) {
            // Name Field (Sign Up only)
            if isSignUp {
                GlassTextField(
                    text: $name,
                    placeholder: "auth.name.placeholder".localized,
                    icon: "person.fill",
                    keyboardType: .default,
                    textContentType: .name,
                    errorMessage: nameValidationError
                )
                .onChange(of: name) { _, _ in validateName() }
            }

            // Email Field
            GlassTextField(
                text: $email,
                placeholder: "auth.email.placeholder".localized,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                errorMessage: emailValidationError
            )
            .autocapitalization(.none)
            .onChange(of: email) { _, _ in validateEmail() }
            .accessibilityFocused($emailFieldFocused)

            // Password Field
            GlassSecureField(
                text: $password,
                placeholder: "auth.password.placeholder".localized,
                showPassword: $showPassword,
                errorMessage: passwordValidationError
            )
            .onChange(of: password) { _, _ in validatePassword() }

            // Phone Field (Sign Up only)
            if isSignUp {
                Button {
                    showPhoneVerification = true
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 20)

                        if phoneNumber.isEmpty {
                            Text("Phone Number (Optional)")
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
                    .padding(16)
                }
                .glassCard(cornerRadius: 16, borderColor: .taxedPrimary.opacity(0.2))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24, borderColor: .white.opacity(0.3))
        .opacity(contentOpacity)
    }

    // MARK: - Action Buttons Glass

    private var actionButtonsGlass: some View {
        VStack(spacing: 16) {
            // Submit Button with Glass Gradient
            Button(action: performAuthentication) {
                HStack(spacing: 10) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isFormValid ?
                    LinearGradient(
                        colors: [
                            Color.taxedPrimary,
                            Color.taxedPrimary.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: isFormValid ? Color.taxedPrimary.opacity(0.3) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!isFormValid || authService.isLoading)

            // Toggle Mode Button
            Button(action: toggleMode) {
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(isSignUp ? "Sign In" : "Sign Up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.taxedPrimary)
                }
            }

            // Forgot Password (Login only)
            if !isSignUp {
                Button(action: { showPasswordReset = true }) {
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundColor(.taxedPrimary)
                }
            }
        }
        .opacity(contentOpacity)
    }

    // MARK: - Additional Options Glass

    private var additionalOptionsGlass: some View {
        VStack(spacing: 12) {
            // Error Message
            if let errorMessage = authService.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(12)
                .glassCard(cornerRadius: 12, borderColor: .red.opacity(0.3))
            }

            // Terms and Privacy
            HStack(spacing: 4) {
                Text("auth.terms.agreement".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Button("auth.terms.button".localized) {
                    // Open terms
                }
                .font(.caption2)
                .foregroundColor(.taxedPrimary)

                Text("auth.terms.and".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Button("auth.privacy.button".localized) {
                    // Open privacy
                }
                .font(.caption2)
                .foregroundColor(.taxedPrimary)
            }
        }
        .opacity(contentOpacity)
    }

    // MARK: - Helper Methods

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

    private func animateEntrance() {
        if !reduceMotion {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                logoScale = 1.0
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                contentOpacity = 1.0
            }
        } else {
            logoScale = 1.0
            contentOpacity = 1.0
        }
    }

    private func toggleMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isSignUp.toggle()
            resetForm()
        }
    }

    // MARK: - Actions

    private func performAuthentication() {
        Task {
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
        }
    }

    private func performBiometricLogin() {
        Task {
            let success = await biometricAuth.performQuickLogin(authService: authService)
            if !success {
                authService.errorMessage = biometricAuth.errorMessage
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
    }

    private func setupAccessibilityFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            emailFieldFocused = true
        }
    }

    // MARK: - Validation

    private func validateEmail() {
        if email.isEmpty {
            emailValidationError = nil
        } else if !email.contains("@") || !email.contains(".") {
            emailValidationError = "Invalid email address"
        } else {
            emailValidationError = nil
        }
    }

    private func validatePassword() {
        if password.isEmpty {
            passwordValidationError = nil
        } else if password.count < 6 {
            passwordValidationError = "Password must be at least 6 characters"
        } else {
            passwordValidationError = nil
        }
    }

    private func validateName() {
        if name.isEmpty {
            nameValidationError = nil
        } else if name.count < 2 {
            nameValidationError = "Name must be at least 2 characters"
        } else {
            nameValidationError = nil
        }
    }
}

// MARK: - Animated Glass Background

struct AnimatedGlassBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Base background
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            // Animated gradient blobs
            if !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.taxedPrimary.opacity(0.3),
                                Color.taxedPrimary.opacity(0.1),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: animateGradient ? -50 : -100, y: animateGradient ? -50 : -100)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: animateGradient ? 50 : 100, y: animateGradient ? 50 : 100)
                    .blur(radius: 60)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 8)
                        .repeatForever(autoreverses: true)
                ) {
                    animateGradient.toggle()
                }
            }
        }
    }
}

// MARK: - Glass Text Field

struct GlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? .taxedPrimary : .secondary)
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .focused($isFocused)
                    .foregroundColor(.primary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isFocused ? Color.taxedPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isFocused ? Color.taxedPrimary.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.caption2)
                }
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Glass Secure Field

struct GlassSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
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

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showPassword.toggle()
                    }
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isFocused ? Color.taxedPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isFocused ? Color.taxedPrimary.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.caption2)
                }
                .foregroundColor(.red)
            }
        }
    }
}
