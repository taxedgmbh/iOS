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
//  Passkeys would be the modern answer and are deliberately not here: Firebase
//  Authentication has no passkey provider, so supporting them would mean a
//  second identity system alongside it. Password AutoFill against
//  `webcredentials:taxed.ch` gets most of the same benefit — one credential
//  shared with the website, filled with Face ID — without that.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var session: PortalSession

    private enum Field { case email, password }

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var showSignUp = false
    @State private var showReset = false
    @FocusState private var focus: Field?

    private var canSubmit: Bool {
        !email.isBlank && !password.isEmpty && !isWorking
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Zero spacing: the masthead runs edge to edge and top to top,
                // and any gap above it would show as a white band under the
                // status bar.
                VStack(spacing: 0) {
                    SignInMasthead()
                    form
                }
                // Pinned to the container width. Without this the masthead's
                // `maxWidth: .infinity` and the form's `maxWidth: 460` resolve
                // against an unbounded proposal inside the scroll view, the
                // content lays out at 460 on a 402pt screen, and both edges
                // clip — which is exactly how it first shipped.
                .containerRelativeFrame(.horizontal)
            }
            .background(Color.primaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showReset) { PasswordResetView(email: email) }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .paddingRelaxed) {
                    header

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    AuthField(
                        title: "auth.email".localized,
                        text: $email,
                        focus: $focus,
                        field: .email,
                        contentType: .username,
                        keyboard: .emailAddress,
                        submitLabel: .next,
                        onSubmit: { focus = .password }
                    )

                    AuthField(
                        title: "auth.password".localized,
                        text: $password,
                        focus: $focus,
                        field: .password,
                        isSecure: true,
                        contentType: .password,
                        submitLabel: .go,
                        onSubmit: { if canSubmit { Task { await signIn() } } }
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
        // No autofocus, deliberately. Both `onAppear` and `defaultFocus`
        // proved unreliable here — the assignment races the first layout — and
        // the only fix is a timed guess. It is also the weaker design: raising
        // the keyboard on launch buries the masthead, which is the thing that
        // says whose app this is.
    }

    /// No logo here any more — the masthead above IS the logo, and repeating it
    /// twelve points below itself is the kind of thing that makes a screen feel
    /// assembled rather than designed.
    private var header: some View {
        VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
            Text("auth.sign_in.title".localized)
                .font(.title2.weight(.bold))
            Text("auth.sign_in.subtitle".localized)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, .paddingTight)
    }

    private func signIn() async {
        focus = nil
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            // Back to the password, with it selected-for-replacement in effect:
            // the email is rarely the half that was wrong.
            focus = .password
        }
    }
}
