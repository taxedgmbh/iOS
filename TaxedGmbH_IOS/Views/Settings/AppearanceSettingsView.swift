//
//  AppearanceSettingsView.swift
//  TaxedGmbH_IOS
//
//  Appearance and display settings for the app
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        List {
            // Theme Selection
            Section {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: {
                        themeManager.setTheme(theme)
                    }) {
                        HStack {
                            Image(systemName: theme.icon)
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme == theme ? .taxedPrimary : .gray)
                                .frame(width: 32)

                            Text(theme.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.taxedPrimary)
                            }
                        }
                    }
                }
            } header: {
                Text("settings.appearance.theme".localized)
            } footer: {
                Text("settings.appearance.theme.footer".localized)
            }

            // Font Size (future enhancement)
            Section {
                HStack {
                    Text("settings.appearance.font_size".localized)
                    Spacer()
                    Text("settings.appearance.system_default".localized)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("settings.appearance.font_size".localized)
                .accessibilityValue("settings.appearance.system_default".localized)
            } header: {
                Text("settings.appearance.display".localized)
            } footer: {
                Text("settings.appearance.display.footer".localized)
            }
        }
        .navigationTitle("settings.appearance.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AppearanceSettingsView()
    }
}
