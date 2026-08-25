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

    private enum Field { case name, email, password, note }

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @FocusState private var focus: Field?

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

                AuthField(
                    title: "auth.name".localized,
                    text: $name,
                    focus: $focus,
                    field: .name,
                    contentType: .name,
                    submitLabel: .next,
                    onSubmit: { focus = .email }
                )

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

                // `.newPassword`, not `.password`. With the associated domain in
                // place this is what makes iOS offer a generated strong password
                // and save it against taxed.ch — so the same credential works on
                // the website, and nobody invents "Taxed2026!".
                AuthField(
                    title: "auth.password".localized,
                    text: $password,
                    focus: $focus,
                    field: .password,
                    isSecure: true,
                    contentType: .newPassword,
                    submitLabel: .next,
                    onSubmit: { focus = .note }
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
                        .focused($focus, equals: .note)
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
        .toolbar {
            // A free-text field has no Return to submit on, so it needs a way
            // back out of the keyboard.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done".localized) { focus = nil }
            }
        }
    }

    private func signUp() async {
        focus = nil
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
