//
//  PortalProviders.swift
//  TaxedGmbH_IOS
//
//  Sign in with Apple and Sign in with Google.
//
//  Both end in the same place as the email path: a Firebase credential, then
//  `POST /api/portal/account`. That call is what creates `users/{uid}`, and an
//  account without it is invisible to the portal — so it runs for every route
//  in, not just the one where it was first needed.
//
//  taxed.ch offers these same two providers. That is not decoration: a Google
//  account has no password, so if the app offered Google and the website did
//  not, anyone who used it here could never sign in there.
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

// MARK: - Apple

/// Runs the Apple authorisation and hands back a Firebase credential.
///
/// A class rather than a function because `ASAuthorizationController` reports
/// through a delegate and will not retain its own; something has to hold it for
/// the length of the sheet.
@MainActor
final class AppleSignInCoordinator: NSObject {

    private var continuation: CheckedContinuation<AuthCredential, Error>?
    /// The un-hashed nonce. Apple receives the SHA-256 of it and echoes the hash
    /// back inside the identity token; Firebase re-hashes this and compares. It
    /// is what stops an intercepted token being replayed.
    private var currentNonce: String?
    /// Apple sends the name **only on the very first authorisation** for an app.
    /// Miss it and it is gone for good — there is no second chance and no API to
    /// ask again.
    private(set) var fullName: String?

    func credential() async throws -> AuthCredential {
        let nonce = Self.randomNonce()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            // The system CSPRNG failing is not a condition to paper over with a
            // weaker nonce; a predictable one defeats the replay protection.
            fatalError("SecRandomCopyBytes failed")
        }
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = apple.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(throwing: PortalError.transport("apple-credential"))
            continuation = nil
            return
        }

        let name = [apple.fullName?.givenName, apple.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        fullName = name.isEmpty ? nil : name

        continuation?.resume(returning: OAuthProvider.appleCredential(
            withIDToken: token,
            rawNonce: nonce,
            fullName: apple.fullName
        ))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Cancelling is not a failure and must not raise an error banner.
        if (error as? ASAuthorizationError)?.code == .canceled {
            continuation?.resume(throwing: PortalCancelled())
        } else {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.foremostWindow ?? ASPresentationAnchor()
    }
}

// MARK: - Google

enum GoogleSignInFlow {
    /// Presents Google's sheet and returns a Firebase credential.
    @MainActor
    static func credential() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw PortalError.transport("google-no-client-id")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = UIApplication.shared.foremostViewController else {
            throw PortalError.transport("google-no-presenter")
        }

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch let error as NSError where error.code == GIDSignInError.canceled.rawValue {
            throw PortalCancelled()
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw PortalError.transport("google-no-id-token")
        }
        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }
}

// MARK: - Cancellation

/// Someone dismissing a sign-in sheet. Distinct from a failure, because the one
/// thing the interface must not do is tell them something went wrong when they
/// simply changed their mind.
struct PortalCancelled: Error {}

// MARK: - Presentation helpers

extension UIApplication {
    var foremostWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    var foremostViewController: UIViewController? {
        var controller = foremostWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
