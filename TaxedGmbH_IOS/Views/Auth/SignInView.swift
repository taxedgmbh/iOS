//
//  SignInView.swift
//  TaxedGmbH_IOS
//
//  Email and password, the same as the web portal.
//
//  Apple and Google sign-in were removed with the rest of what the backend does
//  not have: taxed.ch offers one way in, and two front doors to the same
//  accounts is a support problem ("I signed up with Google and now it says no
//  account") rather than a convenience.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var session: PortalSession

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var showSignUp = false
    @State private var showReset = false

    private var canSubmit: Bool {
        !email.isBlank && !password.isEmpty && !isWorking
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .paddingRelaxed) {
                    header

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    AuthField(
                        title: "auth.email".localized,
                        text: $email,
                        contentType: .username,
                        keyboard: .emailAddress
                    )
                    AuthField(
                        title: "auth.password".localized,
                        text: $password,
                        isSecure: true,
                        contentType: .password
                    )

                    Button {
                        Task { await signIn() }
                    } label: {
                        if isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("auth.sign_in".localized)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)

                    HStack {
                        Button("auth.forgot_password".localized) { showReset = true }
                            .buttonStyle(QuietButtonStyle())
                        Spacer()
                        Button("auth.create_account".localized) { showSignUp = true }
                            .buttonStyle(QuietButtonStyle())
                    }
                }
                .padding(.paddingSpacious)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showReset) { PasswordResetView(email: email) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
            Image("taxed-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .accessibilityLabel(AppConstants.App.name)
                .padding(.bottom, .paddingTight)

            Text("auth.sign_in.title".localized)
                .font(.title.weight(.bold))
            Text("auth.sign_in.subtitle".localized)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, .paddingTight)
    }

    private func signIn() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
