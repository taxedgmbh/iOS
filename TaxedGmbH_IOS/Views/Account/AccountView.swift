//
//  AccountView.swift
//  TaxedGmbH_IOS
//
//  Everything here is either a device preference or a link to the website.
//
//  Nothing on this screen writes to the backend, because no client may: profile
//  and household records are Admin-SDK-written server side. A settings screen
//  with a Save button that silently fails a security rule is worse than no
//  settings screen, and that is what this replaced.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var session: PortalSession
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var showSignOutConfirmation = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    if let name = session.displayName, !name.isEmpty {
                        Text(name).font(.body)
                    }
                    Text(session.email ?? "—")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
            } header: {
                Text("account.signed_in_as".localized)
            } footer: {
                Text("account.changes_footer".localized)
            }

            Section("settings.appearance".localized) {
                Picker("settings.appearance".localized, selection: themeBinding) {
                    ForEach(AppTheme.allCases, id: \.self) { option in
                        Label(option.displayName, systemImage: option.icon).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("settings.language".localized, selection: languageBinding) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text("\(language.flag) \(language.displayName)").tag(language)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("account.help".localized) {
                Link(destination: AppConstants.Company.contactURL) {
                    row("account.contact".localized, systemImage: "envelope")
                }
                Link(destination: AppConstants.Company.website) {
                    row("account.website".localized, systemImage: "safari")
                }
            }

            // Linked, never copied. The app used to carry its own privacy
            // policy and terms, which had already drifted from the published
            // ones — and two versions of a privacy policy that disagree is a
            // liability, not a convenience. taxed.ch is the canonical text.
            Section("account.legal".localized) {
                Link(destination: AppConstants.Company.privacyPolicyURL) {
                    row("account.privacy".localized, systemImage: "hand.raised")
                }
                Link(destination: AppConstants.Company.termsURL) {
                    row("account.terms".localized, systemImage: "doc.text")
                }
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Text("account.sign_out".localized).frame(minHeight: 44)
                }
            } footer: {
                Text(verbatim: "\(AppConstants.App.name) \(AppConstants.App.version) (\(AppConstants.App.build))")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("tab.account".localized)
        .confirmationDialog(
            "account.sign_out.confirm".localized,
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("account.sign_out".localized, role: .destructive) { session.signOut() }
            Button("common.cancel".localized, role: .cancel) {}
        }
    }

    private func row(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(minHeight: 44)
            .foregroundStyle(.primary)
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { theme.currentTheme }, set: { theme.setTheme($0) })
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { localization.currentLanguage }, set: { localization.setLanguage($0) })
    }
}
