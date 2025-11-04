//
//  PasswordResetView.swift
//  TaxedGmbH_IOS
//
//  Password reset view with email and phone options
//

import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var resetMethod: ResetMethod = .email
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showPhoneVerification = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPasswordFields = false

    enum ResetMethod {
        case email
        case phone
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.taxedPrimary)

                        Text("auth.reset.title".localized)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("auth.reset.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Reset Method Picker
                    Picker("auth.reset.method".localized, selection: $resetMethod) {
                        Text("auth.reset.method.email".localized).tag(ResetMethod.email)
                        Text("auth.reset.method.phone".localized).tag(ResetMethod.phone)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Input Field
                    if resetMethod == .email {
                        VStack(spacing: 16) {
                            CustomTextField(
                                text: $email,
                                placeholder: "auth.email.placeholder".localized,
                                icon: "envelope.fill"
                            )
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)

                            Text("auth.reset.email.hint".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        VStack(spacing: 16) {
                            // Phone Number Field with Country Picker (like signup)
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

                            Text("auth.reset.phone.hint".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // New Password Fields (shown after phone verification)
                            if showNewPasswordFields {
                                VStack(spacing: 12) {
                                    Text("auth.reset.new_password".localized)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    CustomSecureField(
                                        text: $newPassword,
                                        placeholder: "auth.reset.new_password.placeholder".localized,
                                        showPassword: .constant(false)
                                    )

                                    CustomSecureField(
                                        text: $confirmPassword,
                                        placeholder: "auth.reset.confirm_password.placeholder".localized,
                                        showPassword: .constant(false)
                                    )

                                    if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                                        Text("auth.reset.passwords_dont_match".localized)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.top, 8)
                            }
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

                    // Success Message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(AppConstants.UI.cornerRadius)
                    }

                    // Send Reset Button
                    Button(action: {
                        Task {
                            await sendPasswordReset()
                        }
                    }) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text(buttonTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(isFormValid ? Color.taxedPrimary : Color.gray)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .disabled(authService.isLoading || !isFormValid)

                    // Back to Login
                    Button(action: {
                        dismiss()
                    }) {
                        Text("auth.reset.back_to_login".localized)
                            .font(.subheadline)
                            .foregroundColor(.taxedPrimary)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhoneVerification) {
            PhoneVerificationView(
                isPresented: $showPhoneVerification,
                verifiedPhoneNumber: $phoneNumber
            )
        }
        .onChange(of: phoneNumber) { _, newValue in
            // When phone is verified, show password fields
            if !newValue.isEmpty && resetMethod == .phone {
                withAnimation {
                    showNewPasswordFields = true
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var buttonTitle: String {
        if resetMethod == .email {
            return "auth.reset.send".localized
        } else {
            return showNewPasswordFields ? "auth.reset.update_password".localized : "auth.reset.verify_phone".localized
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        if resetMethod == .email {
            return !email.isEmpty && email.contains("@")
        } else {
            if showNewPasswordFields {
                return !phoneNumber.isEmpty &&
                       !newPassword.isEmpty &&
                       !confirmPassword.isEmpty &&
                       newPassword == confirmPassword &&
                       newPassword.count >= AppConstants.Validation.minimumPasswordLength
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
                successMessage = String(format: "auth.reset.email.success".localized, email)
                showSuccess = true

                // Dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            } else {
                // Phone-based reset
                if !showNewPasswordFields {
                    // Step 1: Just trigger phone verification
                    showPhoneVerification = true
                } else {
                    // Step 2: After phone is verified, update password
                    // Note: This requires the user to be signed in via phone first
                    // For now, we'll show a success message and guide them to sign in
                    successMessage = "auth.reset.phone.verified".localized
                    showSuccess = true

                    // In a production app, you would:
                    // 1. Sign in the user with the verified phone number
                    // 2. Update their password using Firebase Auth
                    // 3. Sign them out

                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            }
        } catch {
            print("❌ Password reset error: \(error.localizedDescription)")
            authService.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    PasswordResetView()
        .environmentObject(AuthenticationService())
}
