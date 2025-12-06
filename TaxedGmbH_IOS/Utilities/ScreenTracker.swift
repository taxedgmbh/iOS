//
//  ScreenTracker.swift
//  TaxedGmbH_IOS
//
//  Global screen tracking for bug reports
//  Tracks which screen the user is currently viewing
//

import Foundation
import SwiftUI
import Combine

class ScreenTracker: ObservableObject {
    @MainActor static let shared = ScreenTracker()

    @Published var currentScreen: String = "Unknown Screen"

    private init() {}

    /// Update the current screen name
    /// Call this from each view's .onAppear() modifier
    @MainActor
    func setScreen(_ screenName: String) {
        currentScreen = screenName
        print("📍 Screen tracked: \(screenName)")
    }
}

// MARK: - View Extension for Easy Tracking

extension View {
    /// Track the current screen for bug reporting
    /// Usage: .trackScreen("DocumentDetailView")
    func trackScreen(_ screenName: String) -> some View {
        self.onAppear {
            Task { @MainActor in
                ScreenTracker.shared.setScreen(screenName)
            }
        }
    }
}
