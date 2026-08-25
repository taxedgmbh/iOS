//
//  PasswordResetView.swift
//  TaxedGmbH_IOS
//

import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject private var session: PortalSession
    @Environment(\.dismiss) private var dismiss

    private enum Field { case email }

    @State var email: String
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var sent = false
    @FocusState private var focus: Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .paddingRelaxed) {
                VStack(alignment: .leading, spacing: .verticalSpacingComfortable) {
                    Text("auth.reset.title".localized)
                        .font(.title.weight(.bold))
                    Text("auth.reset.subtitle".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                if sent {
                    // Deliberately the same message whether or not an account
                    // exists. "No account with that email" answers a question
                    // about the firm's client list that nobody outside it
                    // should be able to ask.
                    Text("auth.reset.sent".localized)
                        .font(.callout)
                        .padding(.paddingStandard)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.taxedPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
                } else {
                    AuthField(
                        title: "auth.email".localized,
                        text: $email,
                        focus: $focus,
                        field: .email,
                        contentType: .username,
                        keyboard: .emailAddress,
                        submitLabel: .send,
                        onSubmit: { if !email.isBlank { Task { await send() } } }
                    )

                    Button {
                        Task { await send() }
                    } label: {
                        if isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("auth.reset.submit".localized)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.isBlank || isWorking)
                }
            }
            .padding(.paddingSpacious)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primaryBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("auth.reset.nav".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() async {
        focus = nil
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await session.sendPasswordReset(to: email)
            sent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
