//
//  PortalSession.swift
//  TaxedGmbH_IOS
//
//  Who is signed in, and what they may reach.
//
//  Three rules here are not style choices — each is a bug that was already paid
//  for once on the web side:
//
//  1. **This object never signs anyone out.** Deciding "you may not be here" is
//     a routing concern. A session that force-signs-out on an authorisation
//     answer destroys a valid login for every other screen. Only an explicit
//     sign-out, or a genuinely revoked token, ends a session.
//  2. **Authorisation comes from claims, never from a Firestore read.** The
//     token and the security rules read the same claims, so they cannot
//     disagree. `users/{uid}` can lag the claims by up to an hour, and the
//     rules win. That document is fetched for a display name and nothing else —
//     a missing profile must never deny access.
//  3. **A signed-in user with no household is normal, not an error.** Signing up
//     creates an account, never an environment; the household is created when
//     staff approve the request. Showing an empty document list there reads as
//     "my tax documents are gone", which is the worst possible impression for a
//     firm holding them.
//

import Foundation
import os
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class PortalSession: ObservableObject {

    enum State: Equatable {
        /// Before the first auth callback. Not "signed out" — rendering a
        /// sign-in screen here flashes it at every already-signed-in user.
        case initialising
        case signedOut
        /// Signed in, no household yet. Waiting on approval.
        case pending
        case ready(householdId: String)
        /// Staff. Their tools are on the web; this app is the client portal.
        case staffOnly
    }

    @Published private(set) var state: State = .initialising
    @Published private(set) var email: String?
    @Published private(set) var displayName: String?
    /// Everything the token says this account may reach. Treated as the
    /// complete list — never merged with anything remembered from last time.
    @Published private(set) var householdIds: [String] = []
    @Published private(set) var isStaff = false
    /// The household record, for display. Its `hasDocumentStore` is what tells
    /// an empty document list apart from a household whose Drive folders do not
    /// exist yet — and an empty list where documents are expected reads as data
    /// loss to someone whose tax records we hold.
    @Published private(set) var household: Household?

    // Touched from `deinit`, which is not main-actor isolated.
    private nonisolated(unsafe) var authHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Lifecycle

    func start() {
        guard authHandle == nil else { return }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                await self?.adopt(user)
            }
        }
    }

    deinit {
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
    }

    /// Reads the claims on the current user and moves to the matching state.
    ///
    /// `forceRefresh` is for the one moment it is needed: after an action that
    /// should have *granted* access. A grant does not revoke the session (see
    /// the revocation rule), so an existing token keeps working with stale
    /// claims until it happens to refresh.
    private func adopt(_ user: FirebaseAuth.User?, forceRefresh: Bool = false) async {
        guard let user else {
            // Nothing is carried across a sign-out. Household ids especially:
            // they are the isolation key, and a stale one from a previous
            // account is the beginning of showing one client another's files.
            email = nil
            displayName = nil
            household = nil
            householdIds = []
            isStaff = false
            state = .signedOut
            return
        }

        email = user.email

        let claims: [String: Any]
        do {
            claims = try await user.getIDTokenResult(forcingRefresh: forceRefresh).claims
        } catch {
            // The token could not be read. This is a network or revocation
            // problem, not an authorisation answer — hold the current state
            // rather than demoting someone to `pending`, which would tell a
            // provisioned client their documents are being set up.
            if state == .initialising { state = .pending }
            return
        }

        let households = claims["hh"] as? [String: Any] ?? [:]
        householdIds = households.keys.sorted()
        isStaff = claims["staff"] as? Bool == true || claims["admin"] as? Bool == true

        if let first = householdIds.first {
            state = .ready(householdId: first)
        } else if isStaff {
            state = .staffOnly
        } else {
            state = .pending
        }

        // Display only, and deliberately after the state is already decided.
        // Neither of these may gate access: a profile read that fails must not
        // be able to lock someone out of their own documents.
        await loadDisplayName(uid: user.uid, fallback: user.displayName)
        await loadHousehold(householdIds.first)
    }

    private func loadHousehold(_ id: String?) async {
        guard let id else { household = nil; return }
        let snapshot = try? await Firestore.firestore()
            .collection(AppConstants.Backend.Collections.households)
            .document(id)
            .getDocument()
        if let data = snapshot?.data() {
            household = Household(id: id, data: data)
        }
    }

    /// Re-reads the claims, forcing a token refresh. This is what the "check
    /// again" button on the pending screen actually does.
    func refreshAccess() async {
        await adopt(Auth.auth().currentUser, forceRefresh: true)
    }

    private func loadDisplayName(uid: String, fallback: String?) async {
        displayName = fallback
        let snapshot = try? await Firestore.firestore()
            .collection(AppConstants.Backend.Collections.users)
            .document(uid)
            .getDocument()
        if let name = snapshot?.data()?["displayName"] as? String, !name.isEmpty {
            displayName = name
        }
    }

    // MARK: - Sign in

    func signIn(email: String, password: String) async throws {
        do {
            _ = try await Auth.auth().signIn(withEmail: email.trimmed.lowercased(), password: password)
        } catch {
            throw AuthFailure(error)
        }
        await adopt(Auth.auth().currentUser)
    }

    /// Creates the account, then the `users/{uid}` record, then asks for access.
    ///
    /// The order matters: the account record must exist before the access
    /// request references it. Both server calls are idempotent, so a retried
    /// signup is harmless.
    func signUp(email: String, password: String, name: String, note: String) async throws {
        let address = email.trimmed.lowercased()
        let name = name.trimmed
        do {
            _ = try await Auth.auth().createUser(withEmail: address, password: password)
        } catch {
            throw AuthFailure(error)
        }

        if !name.isEmpty, let user = Auth.auth().currentUser {
            let change = user.createProfileChangeRequest()
            change.displayName = name
            // A missing display name is cosmetic. Never fail a signup over it.
            try? await change.commitChanges()
        }

        let _: AccountResponse = try await PortalAPI.shared.post(
            "/api/portal/account",
            body: ["displayName": name]
        )
        let _: AccessRequestResponse = try await PortalAPI.shared.post(
            "/api/portal/access-request",
            body: ["displayName": name, "note": note.trimmed]
        )

        await adopt(Auth.auth().currentUser)
    }

    // MARK: - Apple and Google

    /// Signs in with Apple, then makes sure the portal knows about the account.
    ///
    /// Apple hands over a name only on the first authorisation ever, so it is
    /// written to the Firebase profile immediately. Come back later and there is
    /// nothing to write.
    func signInWithApple() async throws {
        let coordinator = AppleSignInCoordinator()
        let credential = try await coordinator.credential()
        try await completeProviderSignIn(with: credential, name: coordinator.fullName)
    }

    func signInWithGoogle() async throws {
        let credential = try await GoogleSignInFlow.credential()
        try await completeProviderSignIn(with: credential, name: nil)
    }

    /// The shared tail of both provider flows.
    ///
    /// `POST /api/portal/account` runs on **every** sign-in, not only the first.
    /// It is idempotent, and making it conditional on "is this a new user"
    /// depends on `additionalUserInfo.isNewUser`, which is false for anyone who
    /// signed in before this app knew to create the record — leaving accounts
    /// the portal cannot see.
    private func completeProviderSignIn(with credential: AuthCredential, name: String?) async throws {
        let result: AuthDataResult
        do {
            result = try await Auth.auth().signIn(with: credential)
        } catch {
            throw AuthFailure(error)
        }

        if let name, !name.isEmpty, result.user.displayName?.isEmpty != false {
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try? await change.commitChanges()
        }

        let displayName = name ?? result.user.displayName ?? ""
        let _: AccountResponse = try await PortalAPI.shared.post(
            "/api/portal/account",
            body: ["displayName": displayName]
        )

        await adopt(Auth.auth().currentUser)
    }

    /// Asks for a client area from an account that already exists — the path
    /// for someone who signed up, never finished, and came back.
    func requestAccess(note: String) async throws {
        let _: AccessRequestResponse = try await PortalAPI.shared.post(
            "/api/portal/access-request",
            body: ["displayName": displayName ?? "", "note": note.trimmed]
        )
    }

    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email.trimmed.lowercased())
        } catch {
            throw AuthFailure(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    /// The one place an API error may end a session. Only `tokenRevoked`
    /// qualifies (see `PortalError.requiresReauthentication`); everything else
    /// stays on screen as a banner. Signing out here lets the auth listener
    /// route back to `SignInView`, which is what a revoked session deserves —
    /// retrying forever with a token the server refuses would not.
    func noteAPIError(_ error: Error) {
        guard let portalError = error as? PortalError, portalError.requiresReauthentication else { return }
        signOut()
    }
}

// MARK: - Auth errors

/// Firebase Auth errors, translated once.
///
/// Sign-in failures are deliberately not specific about *which* half was wrong:
/// "no account with this email" tells anyone who asks whether an address is a
/// client of this firm.
struct AuthFailure: LocalizedError {
    let errorDescription: String?

    init(_ error: Error) {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:
            errorDescription = "auth.error.invalid_email".localized
        case .emailAlreadyInUse:
            errorDescription = "auth.error.email_in_use".localized
        case .weakPassword:
            errorDescription = "auth.error.weak_password".localized
        case .networkError:
            errorDescription = "error.network".localized
        case .tooManyRequests:
            errorDescription = "auth.error.too_many_attempts".localized
        case .userDisabled:
            errorDescription = "auth.error.disabled".localized
        case .wrongPassword, .userNotFound, .invalidCredential:
            errorDescription = "auth.error.invalid_credentials".localized
        default:
            // The user sees the generic line; the code goes to the unified log
            // so a failure on a device can be diagnosed from Console.app. No
            // identity in the message — the code and domain are enough.
            let nsError = error as NSError
            Logger(subsystem: AppConstants.App.bundleIdentifier, category: "auth")
                .error("Unmapped auth failure: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)")
            errorDescription = "auth.error.generic".localized
        }
    }
}
