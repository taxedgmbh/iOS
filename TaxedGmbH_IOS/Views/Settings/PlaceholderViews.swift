//
//  PlaceholderViews.swift
//  TaxedGmbH_IOS
//
//  Placeholder views for settings and features
//

import SwiftUI

// MARK: - Accessibility Settings View
struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Visual")) {
                    Toggle("Increase Contrast", isOn: .constant(false))
                    Toggle("Reduce Transparency", isOn: .constant(false))
                    Toggle("Bold Text", isOn: .constant(false))
                }

                Section(header: Text("Motion")) {
                    Toggle("Reduce Motion", isOn: .constant(false))
                }

                Section(header: Text("Audio")) {
                    Toggle("Mono Audio", isOn: .constant(false))
                }
            }
            .navigationTitle("Accessibility")
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

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var biometricEnabled = false
    @State private var autoLockTime = "5 minutes"

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Authentication")) {
                    Toggle("Face ID / Touch ID", isOn: $biometricEnabled)

                    HStack {
                        Text("Auto-Lock")
                        Spacer()
                        Menu {
                            Button("30 seconds") { autoLockTime = "30 seconds" }
                            Button("1 minute") { autoLockTime = "1 minute" }
                            Button("5 minutes") { autoLockTime = "5 minutes" }
                            Button("Never") { autoLockTime = "Never" }
                        } label: {
                            Text(autoLockTime)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Data Protection")) {
                    Toggle("Encrypt Local Data", isOn: .constant(true))
                        .disabled(true)
                    Toggle("Secure Backup", isOn: .constant(false))
                }

                Section {
                    Button(action: {}) {
                        Text("Change Password")
                            .foregroundColor(.blue)
                    }

                    Button(action: {}) {
                        Text("Export Security Log")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Security")
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

// MARK: - Report Issue View
struct ReportIssueView: View {
    @Environment(\.dismiss) var dismiss
    @State private var issueType = "Bug"
    @State private var description = ""
    @State private var email = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Issue Type")) {
                    Picker("Type", selection: $issueType) {
                        Text("Bug").tag("Bug")
                        Text("Feature Request").tag("Feature")
                        Text("Performance").tag("Performance")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section(header: Text("Contact (Optional)")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section {
                    Button(action: submitIssue) {
                        HStack {
                            Spacer()
                            Text("Submit Report")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(red: 227/255, green: 30/255, blue: 36/255))
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitIssue() {
        // Submit the issue
        dismiss()
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