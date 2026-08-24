//
//  TaxedGmbH_IOSApp.swift
//  TaxedGmbH_IOS
//

import SwiftUI
import FirebaseCore

@main
struct TaxedGmbH_IOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var session = PortalSession()
    @ObservedObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(theme.colorScheme)
                .task { session.start() }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        LegacyCleanup.run()
        return true
    }
}

/// One-time removal of state written by versions of this app that no longer
/// exist.
enum LegacyCleanup {
    /// An earlier build offered Face ID sign-in by storing the account's
    /// **password**, base64-encoded, in `UserDefaults` — which is an unencrypted
    /// plist included in device backups. The feature is gone; the stored
    /// password is not, until something removes it. This does, on the next
    /// launch after updating.
    static func run() {
        let defaults = UserDefaults.standard
        for key in ["biometric_enabled", "saved_email", "saved_password_token"] {
            defaults.removeObject(forKey: key)
        }
    }
}
