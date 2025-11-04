//
//  BrandedFooterView.swift
//  TaxedGmbH_IOS
//
//  Professional footer branding component inspired by enterprise apps
//  Shows company logo, tagline, and contact information
//

import SwiftUI

struct BrandedFooterView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    var style: FooterStyle = .full

    enum FooterStyle {
        case full        // Logo + tagline + company info
        case compact     // Logo + tagline only
        case minimal     // Logo only
        case compliance  // Logo + compliance badges
    }

    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.top, 8)

            switch style {
            case .full:
                fullFooter
            case .compact:
                compactFooter
            case .minimal:
                minimalFooter
            case .compliance:
                complianceFooter
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }

    // MARK: - Full Footer (Logo + Tagline + Info)

    private var fullFooter: some View {
        VStack(spacing: 20) {
            // Logo and Tagline
            VStack(spacing: 12) {
                Image("taxed-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .cornerRadius(12)

                Text(currentTagline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.taxedPrimary)
                    .multilineTextAlignment(.center)
            }

            // Contact Info
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    // Phone
                    Link(destination: URL(string: "tel:\(AppConstants.Branding.Contact.phone.replacingOccurrences(of: " ", with: ""))")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                                .foregroundColor(.taxedPrimary)
                            Text(AppConstants.Branding.Contact.phone)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }

                    // Email
                    Link(destination: URL(string: "mailto:\(AppConstants.Branding.Contact.email)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                                .foregroundColor(.taxedPrimary)
                            Text(AppConstants.Branding.Contact.email)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }

                // Address
                Text(AppConstants.Branding.Address.fullAddress)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // App Version
            Text("common.version".localized(with: AppConstants.App.version))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Compact Footer (Logo + Tagline)

    private var compactFooter: some View {
        VStack(spacing: 12) {
            Image("taxed-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
                .cornerRadius(10)

            Text(currentTagline)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.taxedPrimary)
                .multilineTextAlignment(.center)

            Text("common.version".localized(with: AppConstants.App.version))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Minimal Footer (Logo Only)

    private var minimalFooter: some View {
        VStack(spacing: 8) {
            Image("taxed-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
                .cornerRadius(8)

            Text("common.version".localized(with: AppConstants.App.version))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Compliance Footer (Logo + Compliance Badges)

    private var complianceFooter: some View {
        VStack(spacing: 16) {
            Image("taxed-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
                .cornerRadius(8)

            // Compliance badges
            HStack(spacing: 12) {
                // GDPR Compliance
                ComplianceBadge(
                    icon: "checkmark.shield.fill",
                    title: "GDPR",
                    subtitle: "Compliant"
                )

                // Swiss DSG Compliance
                ComplianceBadge(
                    icon: "checkmark.shield.fill",
                    title: "Swiss DSG",
                    subtitle: "Compliant"
                )

                // Encryption
                ComplianceBadge(
                    icon: "lock.shield.fill",
                    title: "256-bit",
                    subtitle: "Encrypted"
                )
            }

            Text("Your data is secured and compliant with Swiss and EU data protection laws")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private var currentTagline: String {
        switch localizationService.currentLanguage {
        case .german:
            return AppConstants.Branding.tagline
        case .english:
            return AppConstants.Branding.taglineEN
        case .french:
            return AppConstants.Branding.taglineFR
        case .italian:
            return AppConstants.Branding.taglineIT
        }
    }
}

// MARK: - Compliance Badge Component

struct ComplianceBadge: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.taxedPrimary)

            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("Full Footer Style")
                    .font(.headline)
                BrandedFooterView(style: .full)
            }

            Divider()

            VStack(spacing: 20) {
                Text("Compact Footer Style")
                    .font(.headline)
                BrandedFooterView(style: .compact)
            }

            Divider()

            VStack(spacing: 20) {
                Text("Minimal Footer Style")
                    .font(.headline)
                BrandedFooterView(style: .minimal)
            }

            Divider()

            VStack(spacing: 20) {
                Text("Compliance Footer Style")
                    .font(.headline)
                BrandedFooterView(style: .compliance)
            }
        }
        .padding()
    }
}
