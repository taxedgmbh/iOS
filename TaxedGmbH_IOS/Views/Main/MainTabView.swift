import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Übersicht (Overview/Dashboard)
            NavigationView {
                DashboardView()
                    .background(Color.primaryBackground)
            }
            .tabItem {
                Label("tab.dashboard".localized, systemImage: "house.fill")
            }
            .tag(0)

            // Tab 2: Process Stage
            NavigationView {
                ProcessStageView()
            }
            .tabItem {
                Label("tab.process".localized, systemImage: "list.clipboard.fill")
            }
            .tag(1)

            // Tab 3: All Documents (Unified View)
            NavigationView {
                AllDocumentsView()
            }
            .tabItem {
                Label("tab.documents".localized, systemImage: "doc.fill")
            }
            .tag(2)

            // Tab 4: Expert Chat
            NavigationView {
                ExpertChatView()
            }
            .tabItem {
                Label("tab.chat".localized, systemImage: "message.fill")
            }
            .tag(3)

            // Tab 5: More (replaces Settings for enterprise-grade UX)
            NavigationView {
                MoreView()
            }
            .tabItem {
                Label("tab.more".localized, systemImage: "ellipsis.circle.fill")
            }
            .tag(4)
        }
        .accentColor(.taxedPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
}
