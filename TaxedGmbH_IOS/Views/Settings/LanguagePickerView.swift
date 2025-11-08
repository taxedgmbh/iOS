//
//  LanguagePickerView.swift
//  TaxedGmbH_IOS
//
//  Language picker following Apple best practices
//

import SwiftUI

struct LanguagePickerView: View {
    @ObservedObject private var localizationService = LocalizationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button(action: {
                    withAnimation {
                        localizationService.setLanguage(language)
                    }

                    // Dismiss after a brief delay to show the checkmark
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.displayName)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(getLanguageName(for: language))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if localizationService.currentLanguage == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.taxedPrimary)
                                .font(.title3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("settings.language".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Get native language name
    private func getLanguageName(for language: AppLanguage) -> String {
        switch language {
        case .english: return "language.english".localized
        case .german: return "language.german".localized
        case .french: return "language.french".localized
        case .italian: return "language.italian".localized
        }
    }
}

#Preview {
    NavigationView {
        LanguagePickerView()
    }
}
