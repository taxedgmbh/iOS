//
//  LocalizationService.swift
//  TaxedGmbH_IOS
//
//  Language selection, and the `.localized` lookup every screen uses.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Languages

/// The four languages taxed.ch serves. German, French and Italian are the
/// Swiss national languages the firm works in; English is what most of its
/// expatriate clients read.
nonisolated enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case german = "de"
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
}

// MARK: - The bundle `.localized` reads

/// Deliberately separate from `LocalizationService`.
///
/// `.localized` is called from everywhere — including `PortalError`, which is
/// constructed inside an actor, off the main thread. Reading a main-actor
/// property from there is a data race that the compiler will eventually refuse
/// outright. This holder is written only when the language changes, which
/// happens on the main actor from a settings screen, and read everywhere else.
nonisolated enum LocalizedBundle {
    nonisolated(unsafe) private(set) static var current: Bundle = .main

    static func use(_ language: AppLanguage) {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            // A missing .lproj is a packaging mistake, not a reason to show
            // nothing: the main bundle still resolves the development language.
            current = .main
            return
        }
        current = bundle
    }
}

// MARK: - Service

@MainActor
final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published private(set) var currentLanguage: AppLanguage

    private static let storageKey = "app_language_preference"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        let language = stored.flatMap(AppLanguage.init(rawValue:)) ?? Self.systemPreference()
        currentLanguage = language
        LocalizedBundle.use(language)
    }

    /// The first of our languages the device asks for, English otherwise.
    ///
    /// Not `Locale.current.language` alone: a phone set to Spanish with German
    /// second should get German, not the fallback.
    private static func systemPreference() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let code = Locale(identifier: identifier).language.languageCode?.identifier ?? ""
            if let match = AppLanguage(rawValue: code) { return match }
        }
        return .english
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        LocalizedBundle.use(language)
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
    }
}

// MARK: - Lookup

// `nonisolated`, and it has to be: the module defaults to MainActor isolation,
// so without this every `.localized` in `PortalError` and `DriveCategory` —
// both of which run inside the API actor — is a main-actor hop that the
// compiler will refuse outright in the Swift 6 language mode.
nonisolated extension String {
    /// The localized value for this key, in the language the client chose.
    ///
    /// Returns the key itself when there is no entry — which is what makes
    /// `tools/check-localization.py` worth running, because that is what a
    /// client would see on screen.
    var localized: String {
        NSLocalizedString(self, bundle: LocalizedBundle.current, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
