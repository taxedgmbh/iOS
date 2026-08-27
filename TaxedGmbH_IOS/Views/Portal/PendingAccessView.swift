//
//  PendingAccessView.swift
//  TaxedGmbH_IOS
//
//  Where a signed-in account with no household lands.
//
//  Rare since signup provisions the household itself: it is reached only when
//  that call failed (network, Drive, the server's hourly cap) or by an account
//  from before it existed. "Check again" does the real work — it calls the
//  account route again, which creates or finishes the household.
//
//  It wears the same masthead and sheet as sign-in. It is the second thing a new
//  client ever sees, and the first version of it was a bare centred icon on
//  white — which read as an error page rather than as part of the same product.
//

import SwiftUI

struct PendingAccessView: View {
    @EnvironmentObject private var session: PortalSession

    @State private var isChecking = false
    @State private var notice: String?
    @State private var errorMessage: String?
    @State private var showRequest = false
    @State private var note = ""

    var body: some View {
        NavigationStack {
            MastheadScaffold {
                VStack(alignment: .leading, spacing: .paddingRelaxed) {
                    ScaffoldHeader(
                        title: "pending.title".localized,
                        message: "pending.message".localized
                    )

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    if let notice {
                        NoticeBanner(message: notice)
                    }

                    Button {
                        Task { await checkAgain() }
                    } label: {
                        if isChecking {
                            ProgressView().tint(.white)
                        } else {
                            Text("pending.check_again".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isChecking)

                    Button("pending.request_again".localized) { showRequest = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(maxWidth: .infinity)

                    Button("account.sign_out".localized) { session.signOut() }
                        .buttonStyle(QuietButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.top, .paddingTight)
                }
            }
            .sheet(isPresented: $showRequest) {
                AccessRequestSheet(note: $note) { await submitRequest() }
            }
        }
    }

    /// Approval is purely additive, so it does **not** revoke the session — the
    /// token in this app keeps working with its old, householdless claims until
    /// it happens to refresh. Forcing that refresh is this button's whole job.
    private func checkAgain() async {
        isChecking = true
        notice = nil
        errorMessage = nil
        defer { isChecking = false }

        await session.refreshAccess()
        if case .pending = session.state {
            notice = "pending.not_yet".localized
        }
    }

    private func submitRequest() async {
        errorMessage = nil
        do {
            try await session.requestAccess(note: note)
            showRequest = false
            notice = "pending.request_sent".localized
        } catch let error as PortalError where error == .alreadyApproved {
            // Already approved but the token has not caught up.
            showRequest = false
            await session.refreshAccess()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AccessRequestSheet: View {
    @Binding var note: String
    let submit: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .paddingRelaxed) {
                Text("pending.request.hint".localized)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: $note)
                    .frame(minHeight: 140)
                    .padding(.paddingTight)
                    .background(Color.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.fieldBorder, lineWidth: 1)
                    )
                    .focused($focused)
                    .accessibilityLabel("auth.note".localized)

                Button {
                    Task {
                        isWorking = true
                        await submit()
                        isWorking = false
                    }
                } label: {
                    if isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Text("pending.request.submit".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isWorking)

                Spacer()
            }
            .padding(.paddingSpacious)
            .background(Color.primaryBackground)
            .navigationTitle("pending.request_again".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done".localized) { focused = false }
                }
            }
        }
    }
}
