//
//  AppConstants.swift
//  TaxedGmbH_IOS
//
//  App-wide configuration.
//
//  Everything here is a fact about the deployed system, not a preference.
//  The authoritative description of what the backend offers is docs/SCHEMA.md
//  in the taxed.ch repository; this file must not drift from it.
//

import Foundation

/// `nonisolated` because the API actor reads it. See PortalModels.swift.
nonisolated enum AppConstants {

    // MARK: - App

    enum App {
        static let name = "Taxed GmbH"
        static let bundleIdentifier = "com.taxed.app"

        /// Marketing version, read from the bundle rather than hard-coded — a
        /// constant here goes stale the first time someone bumps the target
        /// and forgets, and a wrong version in a bug report costs an hour.
        static var version: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        }

        static var build: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        }
    }

    // MARK: - Backend

    enum Backend {
        static let projectId = "taxedgmbh"

        /// The portal API. Every route takes `Authorization: Bearer <idToken>`
        /// and answers `{"error": "<code>"}` on failure — see `PortalError`.
        static let apiBaseURL = URL(string: "https://taxed.ch")!

        /// Firestore is the **`(default)`** database, Standard edition,
        /// europe-west6.
        ///
        /// It used to be a NAMED database, also called `taxedgmbh`, on
        /// Enterprise edition — which silently breaks every snapshot listener.
        /// The web portal moved off it; this app pointed at it until now, which
        /// is why the two could never see each other's data. There is nothing
        /// to configure: `Firestore.firestore()` is the default database.
        /// Do not reintroduce `Firestore.firestore(database:)`.
        static let usesDefaultDatabase = true

        enum Collections {
            /// Read-only, and for display only. Authorisation comes from the
            /// token's claims, never from this document — the two can disagree
            /// for up to an hour and the security rules will win.
            static let users = "users"

            /// The isolation key. Everything a client can see hangs off one.
            static let households = "households"

            /// `households/{hid}/documents/{driveFileId}` — the document id IS
            /// the Drive file id.
            static let documents = "documents"
        }
    }

    // MARK: - Uploads

    enum Uploads {
        /// Matches the server's cap in `app/api/portal/uploads/session`. Checked
        /// on the device too so a 90 MB video fails before the bytes move
        /// rather than after.
        static let maximumFileSize: Int64 = 150 * 1024 * 1024

        /// Swiss individuals file in arrears: through 2026 the return being
        /// prepared covers the 2025 period. The server applies the same default
        /// when the client sends none, so this only pre-selects the picker.
        static var defaultTaxYear: Int {
            Calendar.current.component(.year, from: Date()) - 1
        }
    }

    // MARK: - Validation

    enum Validation {
        /// Firebase Auth rejects anything shorter than 6; the portal asks for 8.
        static let minimumPasswordLength = 8
    }

    // MARK: - Localization

    enum Localization {
        static let supportedLanguages = ["en", "de", "fr", "it"]
    }

    // MARK: - Company

    // Every value below is checkable: the commercial register for the company
    // facts, the live site for the rest. Nothing aspirational goes in here.

    enum Company {
        static let name = "Taxed GmbH"
        static let website = URL(string: "https://taxed.ch")!
        static let email = "info@taxed.ch"
        static let phone = "+41 79 910 77 87"

        static let street = "Aegertenstrasse 10"
        static let postalCode = "2503"
        static let city = "Biel/Bienne"
        static let country = "Switzerland"

        static var address: String { "\(street), \(postalCode) \(city), \(country)" }

        static let privacyPolicyURL = URL(string: "https://taxed.ch/privacy-policy")!
        static let termsURL = URL(string: "https://taxed.ch/terms")!
        static let contactURL = URL(string: "https://taxed.ch/contact")!
    }
}
