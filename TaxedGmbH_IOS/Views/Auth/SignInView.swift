//
//  SignInView.swift
//  TaxedGmbH_IOS
//
//  Email and password, Apple and Google — the same three as the web portal.
//
//  The parity is the point: a Google account carries no password, so an
//  app-only provider would strand people on the website ("I signed up with
//  Google and now it says no account"). Apple is required alongside Google by
//  App Store Guideline 4.8.
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
            MastheadScaffold { form }
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
                        icon: "envelope",
                        contentType: .username,
                        keyboard: .emailAddress,
                        submitLabel: .next,
                        onSubmit: { focus = .password }
                    )

                    VStack(alignment: .trailing, spacing: .verticalSpacingComfortable) {
                        AuthField(
                            title: "auth.password".localized,
                            text: $password,
                            focus: $focus,
                            field: .password,
                            icon: "lock",
                            isSecure: true,
                            contentType: .password,
                            submitLabel: .go,
                            onSubmit: { if canSubmit { Task { await signIn() } } }
                        )

                        // Directly under the password, right-aligned. It used to
                        // sit in a bottom row sharing weight with "Create an
                        // account", where it read as absent — the first report
                        // of this screen was that the app had no password
                        // recovery at all. It always had; nobody could find it.
                        Button("auth.forgot_password".localized) { showReset = true }
                            .buttonStyle(QuietButtonStyle())
                    }

                    Button {
                        Task { await signIn() }
                    } label: {
                        if isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("auth.sign_in".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)

                    LabelledDivider(title: "auth.or_continue".localized)
                        .padding(.vertical, .paddingExtraTight)

                    ProviderButton(provider: .apple) {
                        Task { await signIn(with: session.signInWithApple) }
                    }
                    ProviderButton(provider: .google) {
                        Task { await signIn(with: session.signInWithGoogle) }
                    }

                    signUpPrompt
                        .padding(.top, .paddingTight)
        }
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
                .font(BrandFont.display(size: 30, weight: 700))
            Text("auth.sign_in.subtitle".localized)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, .paddingTight)
    }

    /// "Don't have an account? Sign up" — a sentence, not a bare link sharing a
    /// row with recovery. The two were never equivalent actions and should never
    /// have had equivalent weight.
    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("auth.no_account".localized)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("auth.create_account".localized) { showSignUp = true }
                .buttonStyle(QuietButtonStyle())
        }
        .frame(maxWidth: .infinity)
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

    /// Runs a provider flow with the same working/error handling as the email
    /// one — and stays silent when somebody simply dismisses the sheet.
    private func signIn(with flow: @escaping () async throws -> Void) async {
        focus = nil
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await flow()
        } catch is PortalCancelled {
            // Changing your mind is not an error and must not raise a banner.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
