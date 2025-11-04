//
//  ThemeManager.swift
//  TaxedGmbH_IOS
//
//  Manages app appearance and theme settings
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

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
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") private var storedTheme: String = AppTheme.system.rawValue
    @Published var currentTheme: AppTheme = .system
    @Published var colorScheme: ColorScheme?

    private init() {
        loadTheme()
    }

    private func loadTheme() {
        if let theme = AppTheme(rawValue: storedTheme) {
            currentTheme = theme
            updateColorScheme()
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        storedTheme = theme.rawValue
        updateColorScheme()
    }

    private func updateColorScheme() {
        switch currentTheme {
        case .system:
            colorScheme = nil
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
}

// MARK: - Color Palette
extension Color {
    // Dynamic System Colors (automatically adapt to dark mode)
    static let dynamicBackground = Color(UIColor.systemBackground)
    static let dynamicSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let dynamicTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let dynamicGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let dynamicSecondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)

    static let dynamicLabel = Color(UIColor.label)
    static let dynamicSecondaryLabel = Color(UIColor.secondaryLabel)
    static let dynamicTertiaryLabel = Color(UIColor.tertiaryLabel)
    static let dynamicQuaternaryLabel = Color(UIColor.quaternaryLabel)

    static let dynamicSeparator = Color(UIColor.separator)
    static let dynamicOpaqueSeparator = Color(UIColor.opaqueSeparator)

    static let dynamicSystemGray = Color(UIColor.systemGray)
    static let dynamicSystemGray2 = Color(UIColor.systemGray2)
    static let dynamicSystemGray3 = Color(UIColor.systemGray3)
    static let dynamicSystemGray4 = Color(UIColor.systemGray4)
    static let dynamicSystemGray5 = Color(UIColor.systemGray5)
    static let dynamicSystemGray6 = Color(UIColor.systemGray6)
}

// MARK: - View Modifiers
struct ThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func applyTheme() -> some View {
        self.modifier(ThemeModifier())
    }

    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .background(Color.taxedPrimary)
            .cornerRadius(10)
    }

    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(Color.taxedPrimary)
            .padding()
            .background(Color.secondaryBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.taxedPrimary, lineWidth: 1)
            )
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkModeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.1), Color(white: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var lightModeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.98), Color(white: 0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}