//
//  SignUpView.swift
//  TaxedGmbH_IOS
//
//  Creating an account, and asking for a client area — two separate things that
//  happen in one screen.
//
//  Signing up creates an **account**, never an **environment**. A household
//  consumes real Drive folders against a shared quota, so it is created when a
//  person at the firm approves the request. That is why this screen ends on the
//  pending state rather than in a document list, and why the note field matters:
//  it is what the approver reads.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: PortalSession
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    private var passwordIsLongEnough: Bool {
        password.count >= AppConstants.Validation.minimumPasswordLength
    }

    private var canSubmit: Bool {
        !email.isBlank && passwordIsLongEnough && !isWorking
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .paddingRelaxed) {
                VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
                    Text("auth.sign_up.title".localized)
                        .font(.title.weight(.bold))
                    Text("auth.sign_up.subtitle".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                AuthField(title: "auth.name".localized, text: $name, contentType: .name)
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
                    contentType: .newPassword
                )

                Text("auth.password.requirement".localized(
                    with: AppConstants.Validation.minimumPasswordLength
                ))
                .font(.footnote)
                .foregroundStyle(passwordIsLongEnough || password.isEmpty ? .secondary : Color.brandRed)

                VStack(alignment: .leading, spacing: .verticalSpacingStandard) {
                    Text("auth.note".localized)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $note)
                        .frame(minHeight: 96)
                        .padding(.paddingTight)
                        .background(Color.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
                        .accessibilityLabel("auth.note".localized)
                    Text("auth.note.hint".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    if isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Text("auth.sign_up.submit".localized)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSubmit)
            }
            .padding(.paddingSpacious)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primaryBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("auth.sign_up.nav".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signUp() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await session.signUp(email: email, password: password, name: name, note: note)
            // No navigation here: creating the account changes the session
            // state, and RootView routes on that. A push from this screen would
            // put a pending screen on top of a stack it does not belong in.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
