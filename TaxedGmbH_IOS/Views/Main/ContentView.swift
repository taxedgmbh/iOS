//
//  ContentView.swift
//  TaxedGmbH_IOS
//
//  Created by Emanuel Flury on 22.10.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Group {
            if authService.isLoading {
                VStack {
                    ProgressView("common.loading".localized)
                        .progressViewStyle(CircularProgressViewStyle())
                    Text(AppConstants.App.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                .background(Color.primaryBackground)
            } else if authService.isAuthenticated {
                // Show Main Tab View when authenticated
                MainTabView()
            } else {
                // Show Liquid Glass Authentication when not logged in
                AuthenticationView_LiquidGlass()
            }
        }
        .applyTheme()
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
}
