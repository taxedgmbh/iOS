//
//  ThemeManager.swift
//  TaxedGmbH_IOS
//
//  Light, dark, or whatever the device is doing.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "settings.appearance.system".localized
        case .light: return "settings.appearance.light".localized
        case .dark: return "settings.appearance.dark".localized
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// `nil` means "follow the device", which is the default and what most
    /// people want — an app that ignores the system setting at night is the
    /// one they remember.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentTheme: AppTheme

    private static let storageKey = "appTheme"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        currentTheme = stored.flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    var colorScheme: ColorScheme? { currentTheme.colorScheme }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
    }
}
