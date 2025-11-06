//
//  AboutView_HIGCompliant.swift
//  TaxedGmbH_IOS
//
//  Apple HIG compliant About section
//  Follows https://developer.apple.com/design/ guidelines
//

import SwiftUI

/// Main About view displaying company information, services, and app details
/// Complies with Apple Human Interface Guidelines for Settings-style layouts
struct AboutView_HIGCompliant: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            // MARK: - Company Header
            Section {
                VStack(spacing: 16) {
                    // App Icon with proper accessibility
                    Image("taxed-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .accessibilityLabel("more.about.logo_label".localized)

                    VStack(spacing: 8) {
                        Text("Taxed GmbH")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("more.about.tagline".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .padding(.vertical)
            }

            // MARK: - About Company
            Section {
                ForEach(1...4, id: \.self) { index in
                    Label {
                        Text("more.about.bullet\(index)".localized)
                            .font(.body)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.small)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("more.about.header".localized)
            }

            // MARK: - Company Information
            Section {
                LabeledContent("more.company_details.name".localized) {
                    Text("Taxed GmbH")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("more.company_details.address".localized) {
                    Text("Aegertenstrasse 10\n2503 Biel/Bienne")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("more.company_details.country".localized) {
                    Text("Switzerland 🇨🇭")
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "tel:+41799107787")!) {
                    LabeledContent("more.company_details.phone".localized) {
                        HStack(spacing: 4) {
                            Text("+41 79 910 77 87")
                            Image(systemName: "phone.fill")
                                .imageScale(.small)
                        }
                    }
                }
                .accessibilityLabel("more.company_details.phone".localized)
                .accessibilityHint("Double tap to call")

                Link(destination: URL(string: "mailto:info@taxed.ch")!) {
                    LabeledContent("more.company_details.email".localized) {
                        HStack(spacing: 4) {
                            Text("info@taxed.ch")
                            Image(systemName: "envelope.fill")
                                .imageScale(.small)
                        }
                    }
                }
                .accessibilityLabel("more.company_details.email".localized)
                .accessibilityHint("Double tap to send email")

                Link(destination: URL(string: "https://taxed.ch")!) {
                    LabeledContent("more.company_details.website".localized) {
                        HStack(spacing: 4) {
                            Text("taxed.ch")
                            Image(systemName: "arrow.up.right")
                                .imageScale(.small)
                        }
                    }
                }
                .accessibilityLabel("more.company_details.website".localized)
                .accessibilityHint("Double tap to open website")
            } header: {
                Text("more.company_details.header".localized)
            }

            // MARK: - Business Registration
            Section {
                Link(destination: URL(string: "https://www.zefix.ch")!) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.blue)
                            Text("more.business_info.zefix_entry".localized)
                                .font(.body)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                        }

                        Text("more.business_info.zefix_subtitle".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("more.business_info.zefix_entry".localized)
                .accessibilityHint("Double tap to verify company registration")
            } header: {
                Text("more.business_info.header".localized)
            } footer: {
                Text("more.business_info.uid".localized)
            }

            // MARK: - Services
            Section {
                ServiceRow(
                    icon: "doc.text.fill",
                    title: "more.services.tax_returns.title".localized,
                    description: "more.services.tax_returns.description".localized,
                    color: .blue
                )

                ServiceRow(
                    icon: "person.2.fill",
                    title: "more.services.expat_advice.title".localized,
                    description: "more.services.expat_advice.description".localized,
                    color: .orange
                )

                ServiceRow(
                    icon: "checkmark.circle.fill",
                    title: "more.services.ai_processing.title".localized,
                    description: "more.services.ai_processing.description".localized,
                    color: .green
                )

                ServiceRow(
                    icon: "lock.shield.fill",
                    title: "more.services.data_protection.title".localized,
                    description: "more.services.data_protection.description".localized,
                    color: .purple
                )
            } header: {
                Text("more.services.header".localized)
            }

            // MARK: - Data Security & Storage Location
            Section {
                TrustRow(
                    icon: "server.rack",
                    title: "Data Storage Location",
                    subtitle: "Zurich, Switzerland (europe-west6) - Your data never leaves Swiss/EU jurisdiction"
                )

                TrustRow(
                    icon: "lock.shield.fill",
                    title: "AES-256 Encryption",
                    subtitle: "Military-grade encryption at rest with TLS 1.3 for all data transfers"
                )

                TrustRow(
                    icon: "building.columns.fill",
                    title: "Swiss Data Protection",
                    subtitle: "Full compliance with Swiss FADP (revDSG 2023) and EU GDPR"
                )

                TrustRow(
                    icon: "checkmark.seal.fill",
                    title: "ISO Certified Infrastructure",
                    subtitle: "Google Cloud Firestore with ISO 27001, 27017, 27018, SOC 2/3 certifications"
                )
            } header: {
                Text("Data Security & Storage")
            } footer: {
                Text("Database ID: taxedgmbh • Location: europe-west6 (Zurich) • Provider: Google Cloud Platform Switzerland")
                    .font(.caption2)
            }

            // MARK: - Trust & Compliance
            Section {
                TrustRow(
                    icon: "checkmark.seal.fill",
                    title: "more.trust.gdpr.title".localized,
                    subtitle: "more.trust.gdpr.subtitle".localized
                )

                TrustRow(
                    icon: "lock.fill",
                    title: "more.trust.encryption.title".localized,
                    subtitle: "more.trust.encryption.subtitle".localized
                )

                TrustRow(
                    icon: "person.badge.shield.checkmark.fill",
                    title: "more.trust.experts.title".localized,
                    subtitle: "more.trust.experts.subtitle".localized
                )

                TrustRow(
                    icon: "cloud.fill",
                    title: "more.trust.cloud.title".localized,
                    subtitle: "more.trust.cloud.subtitle".localized
                )
            } header: {
                Text("more.trust.header".localized)
            }

            // MARK: - App Information
            Section {
                LabeledContent("more.app_info.version".localized) {
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("more.app_info.build".localized) {
                    Text(buildNumber)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("more.app_info.platform".localized) {
                    Text("iOS \(systemVersion)+")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("more.app_info.header".localized)
            }

            // MARK: - Legal Links
            Section {
                Link(destination: URL(string: "https://taxed.ch/privacy")!) {
                    HStack {
                        Label("more.app_info.privacy".localized, systemImage: "hand.raised.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://taxed.ch/terms")!) {
                    HStack {
                        Label("more.app_info.terms".localized, systemImage: "doc.text.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://taxed.ch/impressum")!) {
                    HStack {
                        Label("more.app_info.imprint".localized, systemImage: "info.circle.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Footer
            Section {
                VStack(spacing: 12) {
                    Text("more.app_info.copyright".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        Link(destination: URL(string: "https://taxed.ch")!) {
                            Label("Website", systemImage: "globe")
                                .font(.caption)
                        }
                        .accessibilityLabel("Visit website")

                        Link(destination: URL(string: "https://www.linkedin.com/company/taxed-gmbh")!) {
                            Label("LinkedIn", systemImage: "person.2.fill")
                                .font(.caption)
                        }
                        .accessibilityLabel("Visit LinkedIn profile")
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("more.about".localized)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)"
    }
}

// MARK: - Service Row Component

/// Displays a service offering with icon, title, and description
/// Follows HIG guidelines for list row design
private struct ServiceRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Trust Row Component

/// Displays trust and compliance information
/// Uses green checkmark to indicate verified status
private struct TrustRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .imageScale(.medium)
                .accessibilityLabel("Verified")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("About View") {
    NavigationStack {
        AboutView_HIGCompliant()
    }
}

#Preview("About View - Dark Mode") {
    NavigationStack {
        AboutView_HIGCompliant()
    }
    .preferredColorScheme(.dark)
}
