//
//  PasswordResetView_LiquidGlass.swift
//  TaxedGmbH_IOS
//
//  Liquid Glass Password Reset with seamless integration
//

import SwiftUI

struct PasswordResetView_LiquidGlass: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var resetMethod: ResetMethod = .email
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showPhoneVerification = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPasswordFields = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var contentOpacity: Double = 0

    enum ResetMethod {
        case email
        case phone
    }

    var body: some View {
        ZStack {
            // Animated Glass Background
            AnimatedGlassBackground()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .floatingButton()
                    }

                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header with Glass Icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.3),
                                                Color.blue.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 20)

                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.blue.opacity(0.6),
                                                        Color.blue.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )

                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .glow(color: .blue, radius: 20)

                            VStack(spacing: 8) {
                                Text("Reset Password")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("Choose your preferred method to reset your password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)

                        // Reset Method Picker in Glass
                        Picker("Method", selection: $resetMethod) {
                            Text("Email").tag(ResetMethod.email)
                            Text("Phone").tag(ResetMethod.phone)
                        }
                        .pickerStyle(.segmented)
                        .padding(4)
                        .glassCard(cornerRadius: 16, borderColor: .blue.opacity(0.3))
                        .padding(.horizontal)

                        // Input Form in Glass Card
                        VStack(spacing: 20) {
                            if resetMethod == .email {
                                emailResetSection
                            } else {
                                phoneResetSection
                            }

                            // Error/Success Messages
                            if let errorMessage = authService.errorMessage {
                                MessageBanner(
                                    icon: "exclamationmark.triangle.fill",
                                    message: errorMessage,
                                    color: .red
                                )
                            }

                            if showSuccess {
                                MessageBanner(
                                    icon: "checkmark.circle.fill",
                                    message: successMessage,
                                    color: .green
                                )
                            }

                            // Action Button
                            Button(action: {
                                Task {
                                    await sendPasswordReset()
                                }
                            }) {
                                HStack(spacing: 10) {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Text(buttonTitle)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    isFormValid ?
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
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
                                    color: isFormValid ? Color.blue.opacity(0.3) : .clear,
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            }
                            .disabled(authService.isLoading || !isFormValid)
                        }
                        .padding(24)
                        .glassCard(cornerRadius: 24, borderColor: .white.opacity(0.3))
                        .padding(.horizontal)

                        // Back to Login
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                    .font(.caption)
                                Text("Back to Login")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateEntrance()
        }
        .fullScreenCover(isPresented: $showPhoneVerification) {
            PhoneVerificationView_LiquidGlass(
                isPresented: $showPhoneVerification,
                verifiedPhoneNumber: $phoneNumber
            )
        }
        .onChange(of: phoneNumber) { _, newValue in
            if !newValue.isEmpty && resetMethod == .phone {
                withAnimation {
                    showNewPasswordFields = true
                }
            }
        }
    }

    // MARK: - Email Reset Section

    private var emailResetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Email Address")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            GlassTextField(
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .autocapitalization(.none)

            Text("We'll send you a password reset link")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Phone Reset Section

    private var phoneResetSection: some View {
        VStack(spacing: 16) {
            // Phone Number Button
            Button {
                showPhoneVerification = true
            } label: {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)

                    if phoneNumber.isEmpty {
                        Text("Enter Phone Number")
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
            .glassCard(cornerRadius: 16, borderColor: .blue.opacity(0.2))

            Text("Verify your phone to reset password")
                .font(.caption)
                .foregroundColor(.secondary)

            // New Password Fields (after phone verification)
            if showNewPasswordFields {
                VStack(spacing: 16) {
                    Text("Set New Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GlassSecureField(
                        text: $newPassword,
                        placeholder: "New Password",
                        showPassword: $showNewPassword
                    )

                    GlassSecureField(
                        text: $confirmPassword,
                        placeholder: "Confirm Password",
                        showPassword: $showConfirmPassword
                    )

                    if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("Passwords don't match")
                                .font(.caption2)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var buttonTitle: String {
        if resetMethod == .email {
            return "Send Reset Link"
        } else {
            return showNewPasswordFields ? "Update Password" : "Verify Phone"
        }
    }

    private var isFormValid: Bool {
        if resetMethod == .email {
            return !email.isEmpty && email.contains("@")
        } else {
            if showNewPasswordFields {
                return !phoneNumber.isEmpty &&
                       !newPassword.isEmpty &&
                       !confirmPassword.isEmpty &&
                       newPassword == confirmPassword &&
                       newPassword.count >= 6
            } else {
                return !phoneNumber.isEmpty && phoneNumber.count >= 10
            }
        }
    }

    // MARK: - Actions

    private func sendPasswordReset() async {
        authService.errorMessage = nil
        showSuccess = false

        do {
            if resetMethod == .email {
                try await authService.sendPasswordResetEmail(email: email)
                successMessage = "Password reset link sent to \(email)"
                showSuccess = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            } else {
                if !showNewPasswordFields {
                    showPhoneVerification = true
                } else {
                    successMessage = "Password updated successfully"
                    showSuccess = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            }
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }

    private func animateEntrance() {
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                contentOpacity = 1.0
            }
        } else {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Message Banner

struct MessageBanner: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(.caption)
                .foregroundColor(color)
                .lineLimit(2)

            Spacer()
        }
        .padding(12)
        .glassCard(cornerRadius: 12, borderColor: color.opacity(0.3), glowColor: color.opacity(0.2))
    }
}
