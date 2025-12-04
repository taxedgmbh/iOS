//
//  MoreView.swift
//  TaxedGmbH_IOS
//
//  Production-ready More menu with complete company information
//  Taxed GmbH, Biel/Bienne, Switzerland
//

import SwiftUI
import FirebaseStorage
import MessageUI

struct MoreView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var showSignOutAlert = false

    var body: some View {
        List {
            // Profile Section
            Section {
                NavigationLink(destination: UnifiedProfileView()) {
                    HStack(spacing: 16) {
                        // Profile Avatar
                        ZStack {
                            Circle()
                                .fill(Color.taxedPrimary.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Text(authService.user?.name.prefix(1).uppercased() ?? "U")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.taxedPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.user?.name ?? "")
                                .font(.headline)

                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Account Section
            Section(header: Text("more.account.header".localized)) {
                MoreMenuItem(
                    icon: "gearshape.fill",
                    iconColor: .blue,
                    title: "more.settings".localized,
                    subtitle: "more.settings.subtitle".localized,
                    destination: AnyView(SettingsView())
                )

                MoreMenuItem(
                    icon: "paintpalette.fill",
                    iconColor: .purple,
                    title: "more.appearance".localized,
                    subtitle: "more.appearance.subtitle".localized,
                    destination: AnyView(AppearanceSettingsView())
                )

                MoreMenuItem(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "more.notifications".localized,
                    subtitle: "more.notifications.subtitle".localized,
                    destination: AnyView(NotificationSettingsView())
                )
            }

            // Tax Settings Section
            Section(header: Text("more.tax_settings.header".localized)) {
                MoreMenuItem(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: "more.tax_settings".localized,
                    subtitle: "more.tax_settings.subtitle".localized,
                    destination: AnyView(TaxSettingsView())
                )

                MoreMenuItem(
                    icon: "map.fill",
                    iconColor: .red,
                    title: "more.canton_settings".localized,
                    subtitle: "more.canton_settings.subtitle".localized,
                    destination: AnyView(CantonSettingsView())
                )

                MoreMenuItem(
                    icon: "calendar.badge.exclamationmark",
                    iconColor: .orange,
                    title: "more.tax_deadlines".localized,
                    subtitle: "more.tax_deadlines.subtitle".localized,
                    destination: AnyView(TaxDeadlinesView())
                )

                MoreMenuItem(
                    icon: "person.2.circle.fill",
                    iconColor: .green,
                    title: "more.expert_connection".localized,
                    subtitle: "more.expert_connection.subtitle".localized,
                    destination: AnyView(ExpertConnectionView())
                )
            }

            // Accessibility Section
            Section(header: Text("more.accessibility.header".localized)) {
                MoreMenuItem(
                    icon: "accessibility",
                    iconColor: .purple,
                    title: "more.accessibility".localized,
                    subtitle: "more.accessibility.subtitle".localized,
                    destination: AnyView(AccessibilitySettingsView())
                )
            }

            // Security Section
            Section(header: Text("more.security.header".localized)) {
                MoreMenuItem(
                    icon: "person.badge.key.fill",
                    iconColor: .blue,
                    title: "more.account_management".localized,
                    subtitle: "more.account_management.subtitle".localized,
                    destination: AnyView(AccountManagementView())
                )

                MoreMenuItem(
                    icon: "lock.shield.fill",
                    iconColor: .red,
                    title: "more.security".localized,
                    subtitle: "more.security.subtitle".localized,
                    destination: AnyView(SecuritySettingsView())
                )
            }

            // Data & Privacy Section
            Section(header: Text("more.data_privacy.header".localized)) {
                MoreMenuItem(
                    icon: "externaldrive.fill",
                    iconColor: .green,
                    title: "more.data_management".localized,
                    subtitle: "more.data_management.subtitle".localized,
                    destination: AnyView(DataManagementView())
                )
            }

            // Resources Section
            Section(header: Text("more.resources.header".localized)) {
                MoreMenuItem(
                    icon: "globe.europe.africa.fill",
                    iconColor: .green,
                    title: "more.expat_guide".localized,
                    subtitle: "more.expat_guide.subtitle".localized,
                    destination: AnyView(ExpatOnboardingView())
                )

                MoreMenuItem(
                    icon: "book.fill",
                    iconColor: .cyan,
                    title: "more.help".localized,
                    subtitle: "more.help.subtitle".localized,
                    destination: AnyView(HelpView())
                )

                MoreMenuItem(
                    icon: "envelope.fill",
                    iconColor: .indigo,
                    title: "more.contact".localized,
                    subtitle: "more.contact.subtitle".localized,
                    destination: AnyView(ContactView())
                )
            }

            // Feedback Section
            Section(header: Text("more.feedback.header".localized)) {
                MoreMenuItem(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "more.rate_app".localized,
                    subtitle: "more.rate_app.subtitle".localized,
                    action: rateApp
                )

                MoreMenuItem(
                    icon: "exclamationmark.bubble.fill",
                    iconColor: .orange,
                    title: "more.report_issue".localized,
                    subtitle: "more.report_issue.subtitle".localized,
                    destination: AnyView(ReportIssueView())
                )
            }

            // About Section
            Section(header: Text("more.about.header".localized)) {
                MoreMenuItem(
                    icon: "info.circle.fill",
                    iconColor: .teal,
                    title: "more.about".localized,
                    subtitle: "more.about.subtitle".localized,
                    destination: AnyView(AboutView_HIGCompliant())
                )

                MoreMenuItem(
                    icon: "shield.fill",
                    iconColor: .mint,
                    title: "more.privacy".localized,
                    subtitle: "more.privacy.subtitle".localized,
                    destination: AnyView(PrivacyView())
                )

                MoreMenuItem(
                    icon: "doc.text.fill",
                    iconColor: .brown,
                    title: "more.terms".localized,
                    subtitle: "more.terms.subtitle".localized,
                    destination: AnyView(TermsView())
                )

                HStack {
                    Text("more.version".localized)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }

            // Sign Out Section
            Section {
                Button(action: {
                    showSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)

                        Text("more.signout".localized)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle("more.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("more.signout.alert.title".localized, isPresented: $showSignOutAlert) {
            Button("more.signout.alert.cancel".localized, role: .cancel) { }
            Button("more.signout.alert.confirm".localized, role: .destructive) {
                do {
                    try authService.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } message: {
            Text("more.signout.alert.message".localized)
        }
    }

    // MARK: - Rate App Function

    private func rateApp() {
        // TODO: Replace with actual App Store ID when published
        // Format: https://apps.apple.com/app/id{APP_STORE_ID}?action=write-review
        // For now, open App Store search for Taxed
        if let url = URL(string: "https://apps.apple.com/search?term=taxed+gmbh+tax") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var destination: AnyView? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    menuContent
                }
            } else {
                Button(action: { action?() }) {
                    menuContent
                }
            }
        }
    }

    private var menuContent: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
