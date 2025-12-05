//
//  MoreView.swift
//  TaxedGmbH_IOS
//
//  Ultra-lean More view with only app information (Feedback + About)
//  All user settings moved to UnifiedProfileView
//  Taxed GmbH, Biel/Bienne, Switzerland
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section(header: Text("more.profile.header".localized)) {
                    MoreMenuItem(
                        icon: "person.circle.fill",
                        iconColor: .blue,
                        title: "more.profile".localized,
                        subtitle: "more.profile.subtitle".localized,
                        destination: AnyView(UnifiedProfileView())
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
            }
            .navigationTitle("more.title".localized)
            .navigationBarTitleDisplayMode(.inline)
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
