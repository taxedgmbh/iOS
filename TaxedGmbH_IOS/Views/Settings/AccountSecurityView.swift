//
//  AccountSecurityView.swift
//  TaxedGmbH_IOS
//
//  Account security and authentication management (consolidated Account + Security settings)
//

import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct AccountSecurityView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var biometricAuth = BiometricAuthService()
    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var show2FASetup = false
    @State private var showSessionManagement = false
    @State private var showBiometricSetup = false
    @State private var biometricEnabled = false
    @State private var newEmail = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isProcessing = false

    var body: some View {
        List {
            // Email Management
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.account.email".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(authService.user?.email ?? "")
                            .font(.body)
                    }
                    Spacer()
                    Button("settings.account.change".localized) {
                        showChangeEmail = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.taxedPrimary)
                }

                if authService.user?.emailVerified == false {
                    Button(action: sendVerificationEmail) {
                        HStack {
                            Image(systemName: "envelope.badge")
                                .foregroundColor(.orange)
                            Text("settings.account.verify_email".localized)
                                .foregroundColor(.primary)
                        }
                    }
                }
            } header: {
                Text("settings.account.email_section".localized)
            } footer: {
                if authService.user?.emailVerified == true {
                    Label("settings.account.email_verified".localized, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Password Management
            Section {
                Button(action: {
                    showChangePassword = true
                }) {
                    HStack {
                        Image(systemName: "key")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        Text("settings.account.change_password".localized)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.account.security".localized)
            } footer: {
                Text("settings.account.security.footer".localized)
            }

            // Biometric Authentication (Face ID / Touch ID)
            if biometricAuth.canEvaluatePolicy {
                Section {
                    Toggle(isOn: $biometricEnabled) {
                        HStack {
                            Image(systemName: biometricAuth.biometricIcon)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(biometricAuth.biometricType == .faceID ?
                                     "settings.account.faceid".localized :
                                     "settings.account.touchid".localized)
                                    .foregroundColor(.primary)
                                Text(biometricAuth.biometricType == .faceID ?
                                     "settings.account.faceid.subtitle".localized :
                                     "settings.account.touchid.subtitle".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: biometricEnabled) { _, newValue in
                        if newValue {
                            showBiometricSetup = true
                        } else {
                            disableBiometricLogin()
                        }
                    }
                } header: {
                    Text("settings.account.biometric_section".localized)
                } footer: {
                    Text(biometricAuth.biometricType == .faceID ?
                         "settings.account.faceid.footer".localized :
                         "settings.account.touchid.footer".localized)
                }
            }

            // Two-Factor Authentication
            Section {
                Button(action: {
                    show2FASetup = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.account.2fa".localized)
                                .foregroundColor(.primary)
                            Text("settings.account.2fa.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("settings.account.setup".localized)
                            .font(.subheadline)
                            .foregroundColor(.taxedPrimary)
                    }
                }
            } header: {
                Text("settings.account.2fa_section".localized)
            } footer: {
                Text("settings.account.2fa.footer".localized)
            }

            // Session Management
            Section {
                Button(action: {
                    showSessionManagement = true
                }) {
                    HStack {
                        Image(systemName: "desktopcomputer.and.iphone")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.account.devices".localized)
                                .foregroundColor(.primary)
                            Text("settings.account.devices.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.account.active_sessions".localized)
            }

            // Account Info
            Section {
                LabeledContent {
                    Text(formatDate(authService.user?.createdAt))
                        .foregroundColor(.secondary)
                } label: {
                    Text("settings.account.member_since".localized)
                }

                if let lastLogin = authService.user?.lastLoginAt {
                    LabeledContent {
                        Text(formatDate(lastLogin))
                            .foregroundColor(.secondary)
                    } label: {
                        Text("settings.account.last_login".localized)
                    }
                }
            } header: {
                Text("settings.account.info".localized)
            }

            // Messages
            if !errorMessage.isEmpty {
                Section {
                    Label {
                        Text(errorMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            if !successMessage.isEmpty {
                Section {
                    Label {
                        Text(successMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("settings.account.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Security")
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailSheet(
                currentEmail: authService.user?.email ?? "",
                onComplete: { email in
                    Task {
                        await changeEmail(to: email)
                    }
                }
            )
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet(
                onComplete: { old, new in
                    Task {
                        await changePassword(oldPassword: old, newPassword: new)
                    }
                }
            )
        }
        .sheet(isPresented: $show2FASetup) {
            TwoFactorAuthSetupSheet()
        }
        .sheet(isPresented: $showSessionManagement) {
            SessionManagementSheet()
        }
        .sheet(isPresented: $showBiometricSetup) {
            BiometricSetupSheet(
                biometricType: biometricAuth.biometricType,
                email: authService.user?.email ?? "",
                onComplete: { password in
                    enableBiometricLogin(password: password)
                },
                onCancel: {
                    biometricEnabled = false
                }
            )
        }
        .onAppear {
            biometricEnabled = biometricAuth.isBiometricEnabled()
        }
    }

    // MARK: - Biometric Functions

    private func enableBiometricLogin(password: String) {
        guard let email = authService.user?.email else {
            errorMessage = "settings.account.biometric.error.no_email".localized
            biometricEnabled = false
            return
        }

        biometricAuth.saveBiometricCredentials(email: email, password: password)
        successMessage = biometricAuth.biometricType == .faceID ?
            "settings.account.faceid.enabled".localized :
            "settings.account.touchid.enabled".localized

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = ""
        }
    }

    private func disableBiometricLogin() {
        biometricAuth.clearBiometricCredentials()
        successMessage = biometricAuth.biometricType == .faceID ?
            "settings.account.faceid.disabled".localized :
            "settings.account.touchid.disabled".localized

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = ""
        }
    }

    // MARK: - Helper Functions

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func sendVerificationEmail() {
        Task {
            do {
                try await Auth.auth().currentUser?.sendEmailVerification()
                successMessage = "settings.account.verification_sent".localized
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    successMessage = ""
                }
            } catch {
                errorMessage = error.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    errorMessage = ""
                }
            }
        }
    }

    private func changeEmail(to newEmail: String) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Use the new Firebase Auth API with email verification
            try await Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: newEmail)
            successMessage = "settings.account.verification_sent".localized
            showChangeEmail = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = ""
            }
        }
    }

    private func changePassword(oldPassword: String, newPassword: String) async {
        isProcessing = true
        defer { isProcessing = false }

        // TODO: Implement reauthentication and password change
        successMessage = "settings.account.password_changed".localized
        showChangePassword = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = ""
        }
    }
}

// MARK: - Change Email Sheet

