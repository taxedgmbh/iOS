//
//  PlaceholderViews.swift
//  TaxedGmbH_IOS
//
//  Placeholder views for settings and features
//

import SwiftUI

// MARK: - Accessibility Settings View
struct AccessibilitySettingsView: View {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared

    var body: some View {
        List {
            // System Status Section
            Section {
                if accessibilityManager.isVoiceOverRunning {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.green)
                        Text("accessibility.voiceover.active".localized)
                            .fontWeight(.medium)
                    }
                    .accessibilityElement(children: .combine)
                }

                if accessibilityManager.isSwitchControlRunning {
                    HStack {
                        Image(systemName: "switch.2")
                            .foregroundColor(.blue)
                        Text("accessibility.switchcontrol.active".localized)
                            .fontWeight(.medium)
                    }
                    .accessibilityElement(children: .combine)
                }

                if accessibilityManager.isAssistiveTouchRunning {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.orange)
                        Text("accessibility.assistivetouch.active".localized)
                            .fontWeight(.medium)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("accessibility.active_features".localized)
            } footer: {
                Text("accessibility.active_features.footer".localized)
            }

            // Visual Accessibility
            Section {
                AccessibilityStatusRow(
                    icon: "eyes",
                    title: "accessibility.bold_text".localized,
                    isEnabled: accessibilityManager.isBoldTextEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "circle.lefthalf.filled",
                    title: "accessibility.increase_contrast.title".localized,
                    isEnabled: accessibilityManager.isIncreaseContrastEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "rectangle.3.offgrid.fill",
                    title: "accessibility.reduce_transparency".localized,
                    isEnabled: accessibilityManager.isReduceTransparencyEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "sun.max.fill",
                    title: "accessibility.darker_colors".localized,
                    isEnabled: accessibilityManager.isDarkerSystemColorsEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "circle.grid.cross.fill",
                    title: "accessibility.invert_colors".localized,
                    isEnabled: accessibilityManager.isInvertColorsEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "camera.filters",
                    title: "accessibility.grayscale".localized,
                    isEnabled: accessibilityManager.isGrayscaleEnabled,
                    systemSetting: true
                )
            } header: {
                Text("accessibility.visual".localized)
            } footer: {
                Text("accessibility.visual.footer".localized)
            }

            // Motion
            Section {
                AccessibilityStatusRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "accessibility.reduce_motion".localized,
                    isEnabled: accessibilityManager.isReduceMotionEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "arrow.left.and.right.circle.fill",
                    title: "accessibility.crossfade".localized,
                    isEnabled: accessibilityManager.prefersCrossFadeTransitions,
                    systemSetting: true
                )
            } header: {
                Text("accessibility.motion".localized)
            } footer: {
                Text("accessibility.motion.footer".localized)
            }

            // Audio & Hearing
            Section {
                AccessibilityStatusRow(
                    icon: "speaker.wave.1.fill",
                    title: "accessibility.mono_audio".localized,
                    isEnabled: accessibilityManager.isMonoAudioEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "captions.bubble.fill",
                    title: "accessibility.closed_captions".localized,
                    isEnabled: accessibilityManager.isClosedCaptioningEnabled,
                    systemSetting: true
                )
            } header: {
                Text("accessibility.hearing".localized)
            }

            // Motor & Interaction
            Section {
                AccessibilityStatusRow(
                    icon: "figure.wave",
                    title: "accessibility.shake_undo".localized,
                    isEnabled: accessibilityManager.isShakeToUndoEnabled,
                    systemSetting: true
                )
            } header: {
                Text("accessibility.motor".localized)
            }

            // Guided Access & Learning
            Section {
                AccessibilityStatusRow(
                    icon: "app.badge.checkmark.fill",
                    title: "accessibility.guided_access".localized,
                    isEnabled: accessibilityManager.isGuidedAccessEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "text.bubble.fill",
                    title: "accessibility.speak_screen".localized,
                    isEnabled: accessibilityManager.isSpeakScreenEnabled,
                    systemSetting: true
                )

                AccessibilityStatusRow(
                    icon: "text.viewfinder",
                    title: "accessibility.speak_selection".localized,
                    isEnabled: accessibilityManager.isSpeakSelectionEnabled,
                    systemSetting: true
                )
            } header: {
                Text("accessibility.guided_speech".localized)
            }

            // Text Size
            Section {
                HStack {
                    Image(systemName: "textformat.size")
                        .foregroundColor(.taxedPrimary)
                        .frame(width: 24)
                    Text("accessibility.dynamic_type".localized)
                    Spacer()
                    Text("\(accessibilityManager.preferredContentSizeCategory.rawValue)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .accessibilityElement(children: .combine)
            } header: {
                Text("accessibility.text_size".localized)
            } footer: {
                Text("accessibility.text_size.footer".localized)
            }

            // Open iOS Settings
            Section {
                Button(action: openAccessibilitySettings) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("accessibility.open_settings".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("accessibility.open_settings.footer".localized)
            }
        }
        .navigationTitle("more.accessibility".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Accessibility Status Row
struct AccessibilityStatusRow: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let systemSetting: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("accessibility.status.enabled".localized)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .accessibilityLabel("accessibility.status.disabled".localized)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isEnabled ? "accessibility.status.enabled".localized : "accessibility.status.disabled".localized)")
    }
}

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("autoLockTime") private var autoLockTime = "5 minutes"
    @AppStorage("secureBackupEnabled") private var secureBackupEnabled = false
    @State private var showPasswordChange = false
    @State private var showSecurityLog = false

    var body: some View {
        List {
            // Authentication
            Section {
                Toggle(isOn: $biometricEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Face ID / Touch ID")
                                .font(.body)
                            Text("Use biometrics for app login")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Face ID or Touch ID authentication")
                .accessibilityHint("Enable biometric authentication for secure app access")

                HStack {
                    Image(systemName: "lock.rotation")
                        .foregroundColor(.taxedPrimary)
                        .frame(width: 24)
                    Text("Auto-Lock")
                    Spacer()
                    Menu {
                        Button("30 seconds") { autoLockTime = "30 seconds" }
                        Button("1 minute") { autoLockTime = "1 minute" }
                        Button("5 minutes") { autoLockTime = "5 minutes" }
                        Button("Never") { autoLockTime = "Never" }
                    } label: {
                        HStack {
                            Text(autoLockTime)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Auto-lock timeout: \(autoLockTime)")
            } header: {
                Text("Authentication")
            } footer: {
                Text("Auto-lock requires re-authentication after the specified time")
            }

            // Data Protection
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Encrypt Local Data")
                            .font(.body)
                        Text("All data is encrypted using AES-256")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .accessibilityLabel("Encrypt Local Data: Always enabled. All data is encrypted using AES-256")

                Toggle(isOn: $secureBackupEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Secure Cloud Backup")
                                .font(.body)
                            Text("Encrypted backup to iCloud")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Secure Cloud Backup")
                .accessibilityHint("Enable encrypted backup to iCloud")
            } header: {
                Text("Data Protection")
            } footer: {
                Text("All backups are encrypted and stored securely")
            }

            // Password & Account
            Section {
                Button(action: { showPasswordChange = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("Change Password")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel("Change password")
                .accessibilityHint("Update your account password")

                Button(action: { showSecurityLog = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundColor(.taxedPrimary)
                            .frame(width: 24)
                        Text("Security Activity Log")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel("View security activity log")
                .accessibilityHint("See recent security events")
            } header: {
                Text("Account Security")
            }

            // Security Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Data Encryption")
                            .fontWeight(.medium)
                    }
                    Text("• End-to-end encryption for all data")
                        .font(.caption)
                    Text("• AES-256 encryption at rest")
                        .font(.caption)
                    Text("• TLS 1.3 encryption in transit")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .accessibilityElement(children: .combine)
            } header: {
                Text("Security Features")
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Change Password", isPresented: $showPasswordChange) {
            Button("OK") { showPasswordChange = false }
        } message: {
            Text("Password changes must be done through your account settings in the web portal")
        }
        .alert("Security Log", isPresented: $showSecurityLog) {
            Button("OK") { showSecurityLog = false }
        } message: {
            Text("Security activity logging will be available in a future update")
        }
    }
}

// MARK: - Report Issue View
struct ReportIssueView: View {
    @Environment(\.dismiss) var dismiss
    @State private var issueType = "Bug"
    @State private var description = ""
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false

    var body: some View {
        Form {
            Section {
                Picker("report.type".localized, selection: $issueType) {
                    Label("report.type.bug".localized, systemImage: "ladybug.fill").tag("Bug")
                    Label("report.type.feature".localized, systemImage: "lightbulb.fill").tag("Feature")
                    Label("report.type.performance".localized, systemImage: "speedometer").tag("Performance")
                    Label("report.type.other".localized, systemImage: "ellipsis.circle.fill").tag("Other")
                }
                .pickerStyle(.menu)
                .accessibilityLabel(String(format: "report.type.label".localized, issueType))
            } header: {
                Text("report.type".localized)
            }

            Section {
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .accessibilityLabel("report.description".localized)
                    .accessibilityHint("report.description.hint".localized)
            } header: {
                Text("report.description".localized)
            } footer: {
                Text("report.description.footer".localized)
            }

            Section {
                TextField("report.email.placeholder".localized, text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("report.email".localized)
                    .accessibilityHint("report.email.hint".localized)
            } header: {
                Text("report.email".localized)
            } footer: {
                Text("report.email.footer".localized)
            }

            Section {
                Button(action: submitIssue) {
                    HStack {
                        Spacer()
                        Text("report.submit".localized)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(description.isEmpty)
                .foregroundColor(.white)
                .listRowBackground(description.isEmpty ? Color.gray : Color.taxedPrimary)
                .accessibilityLabel("report.submit".localized)
                .accessibilityHint(description.isEmpty ? "report.submit.hint.empty".localized : "report.submit.hint.ready".localized)
            }
        }
        .navigationTitle("report.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("report.success.title".localized, isPresented: $showSuccess) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text("report.success.message".localized)
        }
        .alert("report.error.title".localized, isPresented: $showError) {
            Button("common.ok".localized) { showError = false }
        } message: {
            Text("report.error.message".localized)
        }
    }

    private func submitIssue() {
        guard !description.isEmpty else { return }

        // Create email URL
        var emailComponents = URLComponents()
        emailComponents.scheme = "mailto"
        emailComponents.path = "support@taxed.ch"

        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "subject", value: "[\(issueType)] Issue Report - TaxedGmbH iOS"),
            URLQueryItem(name: "body", value: """
            \("report.email.issue_type".localized) \(issueType)

            \("report.email.description".localized)
            \(description)

            \("report.email.contact_email".localized) \(email.isEmpty ? "report.email.not_provided".localized : email)

            ---
            \("report.email.device".localized) iOS \(UIDevice.current.systemVersion)
            \("report.email.app_version".localized) 1.0.0
            """)
        ]

        emailComponents.queryItems = queryItems

        if let emailURL = emailComponents.url {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL) { success in
                    if success {
                        showSuccess = true
                    } else {
                        showError = true
                    }
                }
            } else {
                showError = true
            }
        } else {
            showError = true
        }
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)

                        Text("Last Updated: January 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 16) {
                            PrivacySection(
                                title: "Data Collection",
                                content: "We collect minimal data necessary to provide tax services. This includes your name, email, canton of residence, and tax-related documents you choose to upload."
                            )

                            PrivacySection(
                                title: "Data Usage",
                                content: "Your data is used exclusively to provide tax filing assistance. We do not sell or share your personal information with third parties except as required by Swiss law."
                            )

                            PrivacySection(
                                title: "privacy.data_storage_auth.title".localized,
                                content: "privacy.data_storage_auth.content".localized
                            )

                            PrivacySection(
                                title: "privacy.data_storage_app.title".localized,
                                content: "privacy.data_storage_app.content".localized
                            )

                            PrivacySection(
                                title: "privacy.data_processing.title".localized,
                                content: "privacy.data_processing.content".localized
                            )

                            PrivacySection(
                                title: "Data Retention",
                                content: "Tax documents are retained for 10 years as required by Article 958f of the Swiss Code of Obligations. Personal account data is retained while your account is active. You may request deletion of non-essential data at any time, subject to legal retention requirements."
                            )

                            PrivacySection(
                                title: "Your Rights (GDPR & Swiss FADP)",
                                content: "You have the right to: access your data (Art. 15 GDPR / Art. 25 FADP), rectify inaccurate data (Art. 16 GDPR / Art. 32 FADP), request deletion (Art. 17 GDPR / Art. 32 FADP), data portability (Art. 20 GDPR), object to processing (Art. 21 GDPR / Art. 30 FADP), and lodge complaints with the Federal Data Protection and Information Commissioner (FDPIC). Contact privacy@taxed.ch to exercise these rights."
                            )

                            PrivacySection(
                                title: "Security Measures",
                                content: "Technical measures: AES-256 encryption at rest, TLS 1.3 in transit, multi-factor authentication, role-based access control, automated security monitoring. Organizational measures: regular security audits, staff training, incident response procedures, backup and disaster recovery protocols. Infrastructure: Google Cloud Platform Tier 4 data centers with 24/7 physical security."
                            )

                            PrivacySection(
                                title: "privacy.data_transfers.title".localized,
                                content: "privacy.data_transfers.content".localized
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Terms View
struct TermsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)

                        Text("Effective Date: January 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 16) {
                            TermsSection(
                                title: "1. Acceptance of Terms",
                                content: "By using TaxedGmbH services, you agree to these Terms of Service. If you do not agree, please do not use our services."
                            )

                            TermsSection(
                                title: "2. Service Description",
                                content: "TaxedGmbH provides tax preparation and filing assistance for Swiss residents and expats. We are not a substitute for professional tax advice."
                            )

                            TermsSection(
                                title: "3. User Responsibilities",
                                content: "You are responsible for providing accurate information and maintaining the confidentiality of your account. You must comply with all applicable Swiss tax laws."
                            )

                            TermsSection(
                                title: "4. Fees and Payment",
                                content: "Our fee structure is transparent and displayed before any purchase. All fees are in Swiss Francs (CHF) and include applicable taxes."
                            )

                            TermsSection(
                                title: "5. Data Storage and Security",
                                content: "Your data is stored on Google Cloud Firestore servers located exclusively in Zurich, Switzerland (region: europe-west6). All data is encrypted using AES-256 encryption at rest and TLS 1.3 in transit. We comply with Swiss Federal Data Protection Act (FADP) and GDPR. Your data remains within Swiss/EU jurisdiction at all times. See our Privacy Policy for detailed information."
                            )

                            TermsSection(
                                title: "6. Limitation of Liability",
                                content: "TaxedGmbH is not liable for any tax penalties or issues arising from inaccurate information provided by users or misuse of the service. Maximum liability is limited to the amount paid for services in the preceding 12 months, as permitted under Swiss law (Art. 100 OR)."
                            )

                            TermsSection(
                                title: "7. Intellectual Property",
                                content: "All content, features, and functionality are owned by TaxedGmbH and protected by Swiss and international copyright and trademark laws (URG - Federal Act on Copyright and Related Rights)."
                            )

                            TermsSection(
                                title: "8. Data Protection Compliance",
                                content: "We comply with the revised Swiss Federal Data Protection Act (revDSG/FADP, effective September 2023) and EU GDPR. Your rights include access, rectification, deletion, data portability, and objection to processing. Contact our Data Protection Officer at privacy@taxed.ch or the Federal Data Protection and Information Commissioner (FDPIC) for complaints."
                            )

                            TermsSection(
                                title: "9. Termination",
                                content: "We reserve the right to terminate or suspend access to our service for violations of these terms or fraudulent activity. Upon termination, your data will be retained for the legally required period (10 years for tax documents per Art. 958f OR) and then securely deleted."
                            )

                            TermsSection(
                                title: "10. Governing Law and Jurisdiction",
                                content: "These terms are governed exclusively by Swiss law (Swiss Code of Obligations). Any disputes shall be resolved in the competent courts of Biel/Bienne, Switzerland, with appeals to the Canton of Bern and Swiss Federal Supreme Court."
                            )

                            TermsSection(
                                title: "11. Contact Information",
                                content: "For questions about these terms: legal@taxed.ch\nFor data protection inquiries: privacy@taxed.ch\nMailing address: TaxedGmbH, Aegertenstrasse 10, 2503 Biel/Bienne, Switzerland\nPhone: +41 79 910 77 87"
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct PrivacySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Accessibility") {
    AccessibilitySettingsView()
}

#Preview("Security") {
    SecuritySettingsView()
}

#Preview("Report Issue") {
    ReportIssueView()
}

#Preview("Privacy") {
    PrivacyView()
}

#Preview("Terms") {
    TermsView()
}