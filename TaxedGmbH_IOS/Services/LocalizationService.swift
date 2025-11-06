//
//  LocalizationService.swift
//  TaxedGmbH_IOS
//
//  Localization service following Apple best practices
//  Uses SwiftUI environment and proper Bundle localization
//

import Foundation
import SwiftUI
import Combine

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Codable {
    case german = "de"
    case english = "en"
    case french = "fr"
    case italian = "it"

    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        case .french: return "Français"
        case .italian: return "Italiano"
        }
    }

    var flag: String {
        switch self {
        case .german: return "🇩🇪"
        case .english: return "🇬🇧"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        }
    }

    var locale: Locale {
        return Locale(identifier: rawValue)
    }
}

// MARK: - Localization Service (Apple Best Practice)

@MainActor
class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var currentLanguage: AppLanguage {
        didSet {
            // Update UserDefaults to persist language preference
            saveLanguagePreference()

            // Trigger view refresh by posting notification
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    private let languageKey = "app_language_preference"

    // Bundle for localized strings
    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }

    private init() {
        // Load saved language or detect from system with priority order
        if let savedLang = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = language
        } else {
            // Priority order: English → German → French → Italian → English (fallback)
            // Check system preferred languages against our priority list
            let systemLanguages = Locale.preferredLanguages.map {
                Locale(identifier: $0).language.languageCode?.identifier ?? ""
            }

            // Define priority order
            let priorityOrder: [AppLanguage] = [.english, .german, .french, .italian]

            // Find first matching language from priority list
            var selectedLanguage: AppLanguage = .english // Default fallback
            for priorityLang in priorityOrder {
                if systemLanguages.contains(priorityLang.rawValue) {
                    selectedLanguage = priorityLang
                    break
                }
            }

            self.currentLanguage = selectedLanguage
            print("✅ Language initialized: \(selectedLanguage.displayName) (Priority: \(priorityOrder.map { $0.displayName }.joined(separator: " → ")))")
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        print("✅ Language changed to: \(language.displayName)")
    }

    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        UserDefaults.standard.synchronize()
    }

    // Localize a string key
    func localize(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }

    // Localize with format arguments
    func localize(_ key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = localize(key, comment: comment)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - String Extension (Apple Best Practice)

extension String {
    /// Localizes the string using the current app language
    var localized: String {
        let service = LocalizationService.shared
        return NSLocalizedString(self, bundle: service.bundle, comment: "")
    }

    /// Localizes with format arguments
    func localized(with arguments: CVarArg...) -> String {
        let format = self.localized
        return String(format: format, arguments: arguments)
    }

    /// Localizes with a specific comment for translators
    func localized(comment: String) -> String {
        let service = LocalizationService.shared
        return NSLocalizedString(self, bundle: service.bundle, comment: comment)
    }
}

// MARK: - SwiftUI Text Extension (Best Practice)

extension Text {
    /// Creates a Text view with localized string
    init(localized key: String) {
        let service = LocalizationService.shared
        let localizedString = NSLocalizedString(key, bundle: service.bundle, comment: "")
        self.init(localizedString)
    }
}

// MARK: - SwiftUI LocalizedStringKey Support

extension LocalizedStringKey {
    /// Converts a string to LocalizedStringKey using current language
    init(_ key: String, bundle: Bundle) {
        self.init(key)
    }
}
