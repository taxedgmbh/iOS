//
//  RootView.swift
//  TaxedGmbH_IOS
//
//  The only place that decides which surface a person sees.
//
//  Routing lives here, not in the session object, for the reason the web portal
//  learned the hard way: a session that decides where you may be will eventually
//  sign you out to enforce it, and that destroys a valid login for every other
//  screen.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: PortalSession

    var body: some View {
        Group {
            switch session.state {
            case .initialising:
                LaunchView()
            case .signedOut:
                SignInView()
            case .pending:
                PendingAccessView()
            case .staffOnly:
                StaffNoticeView()
            case .ready(let householdId):
                PortalShell(householdId: householdId)
            }
        }
        .animation(.default, value: session.state)
    }
}

/// Shown until Firebase answers with who, if anyone, is signed in.
///
/// This state is why there is no flash of the sign-in screen on every cold
/// launch for an already-signed-in client.
private struct LaunchView: View {
    var body: some View {
        VStack(spacing: .paddingRelaxed) {
            Image("taxed-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .accessibilityLabel(AppConstants.App.name)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

/// Staff sign in with the same accounts, so they land here rather than in a
/// client's document list. Saying so plainly beats an empty portal.
private struct StaffNoticeView: View {
    @EnvironmentObject private var session: PortalSession

    var body: some View {
        NavigationStack {
            MessageScreen(
                systemImage: "person.badge.key",
                title: "staff.title".localized,
                message: "staff.message".localized
            ) {
                Link(destination: AppConstants.Company.website) {
                    Text("staff.open_web".localized)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("account.sign_out".localized) { session.signOut() }
                    .buttonStyle(QuietButtonStyle())
            }
            .navigationTitle(AppConstants.App.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// The signed-in client app: documents, and an account screen.
///
/// Two tabs, both of which do something. The previous version of this app had
/// five tabs over features with no backend behind them.
private struct PortalShell: View {
    let householdId: String

    var body: some View {
        TabView {
            NavigationStack {
                DocumentsView(householdId: householdId)
            }
            .tabItem { Label("tab.documents".localized, systemImage: "doc.text") }

            NavigationStack {
                AccountView()
            }
            .tabItem { Label("tab.account".localized, systemImage: "person.crop.circle") }
        }
        .tint(.taxedPrimary)
    }
}
