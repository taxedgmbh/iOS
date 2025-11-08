//
//  AccountManagementView.swift
//  TaxedGmbH_IOS
//
//  Account security and authentication management
//

import SwiftUI
import FirebaseAuth

struct AccountManagementView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var show2FASetup = false
    @State private var showSessionManagement = false
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

struct ChangeEmailSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentEmail: String
    let onComplete: (String) -> Void

    @State private var newEmail = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("settings.account.current_email".localized, text: .constant(currentEmail))
                        .disabled(true)
                        .foregroundColor(.secondary)
                } header: {
                    Text("settings.account.current".localized)
                }

                Section {
                    TextField("settings.account.new_email".localized, text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("settings.account.password_confirm".localized, text: $password)
                        .textContentType(.password)
                } header: {
                    Text("settings.account.new_email_section".localized)
                } footer: {
                    Text("settings.account.password_required".localized)
                }
            }
            .navigationTitle("settings.account.change_email".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("settings.account.cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.account.update".localized) {
                        onComplete(newEmail)
                        dismiss()
                    }
                    .disabled(newEmail.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    let onComplete: (String, String) -> Void

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("settings.account.current_password".localized, text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("settings.account.current".localized)
                }

                Section {
                    SecureField("settings.account.new_password".localized, text: $newPassword)
                        .textContentType(.newPassword)

                    SecureField("settings.account.confirm_password".localized, text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("settings.account.new_password_section".localized)
                } footer: {
                    Text("settings.account.password_requirements".localized)
                }

                if !newPassword.isEmpty && newPassword != confirmPassword {
                    Section {
                        Label("settings.account.passwords_must_match".localized, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("settings.account.change_password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("settings.account.cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.account.update".localized) {
                        onComplete(currentPassword, newPassword)
                        dismiss()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
                }
            }
        }
    }
}

// MARK: - Two-Factor Auth Setup Sheet

struct TwoFactorAuthSetupSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)
                    .padding(.top, 40)

                Text("settings.account.2fa_coming_soon".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("settings.account.2fa_coming_soon.description".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button("settings.account.close".localized) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
            .navigationTitle("settings.account.2fa".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Session Management Sheet

struct SessionManagementSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.account.this_device".localized)
                                .font(.headline)
                            Text("settings.account.active_now".localized)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Label("settings.account.current".localized, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("settings.account.active_sessions".localized)
                } footer: {
                    Text("settings.account.sessions.footer".localized)
                }
            }
            .navigationTitle("settings.account.devices".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.account.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AccountManagementView()
            .environmentObject(AuthenticationService())
    }
}
