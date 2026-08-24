//
//  PortalModels.swift
//  TaxedGmbH_IOS
//
//  Wire types for the portal API, and the two Firestore rows this app reads.
//
//  Every type here is `nonisolated`. The target sets
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, which would otherwise give each
//  of them a main-actor-isolated `Decodable` conformance — and a conformance
//  pinned to the main actor cannot satisfy a `Sendable` requirement inside the
//  `PortalAPI` actor, which is where all of this is decoded.
//  Field names and optionality mirror docs/SCHEMA.md; where the server says a
//  value may be null, it is optional here rather than defaulted, so a missing
//  value shows as missing instead of as a plausible wrong answer.
//

import Foundation

// MARK: - Documents

/// One indexed document. The `fileId` **is** the Drive file id, which is what
/// makes re-indexing idempotent on the server side and what every other
/// endpoint keys on.
nonisolated struct PortalDocument: Identifiable, Decodable, Equatable, Sendable {
    let fileId: String
    let name: String
    let mimeType: String?
    let size: Int64
    let category: String?
    let taxYear: String?
    /// `portal` when it came through an uploader, `drive` when someone dropped
    /// it straight into the Shared Drive. Worth showing: "added in Drive"
    /// explains a file the client does not remember sending.
    let source: String?
    let indexedAt: Date?
    let modifiedTime: String?

    var id: String { fileId }

    /// Documents with no category are grouped under Other rather than hidden.
    /// A file that exists but is invisible is the failure mode this avoids.
    var categoryKey: String { category ?? DriveCategory.otherKey }

    var isFromDrive: Bool { source == "drive" }

    private enum CodingKeys: String, CodingKey {
        case fileId, name, mimeType, size, category, taxYear, source, indexedAt, modifiedTime
    }

    /// Decoded field by field rather than by the synthesised initialiser.
    ///
    /// Synthesised decoding is all-or-nothing: one row missing `name` throws,
    /// `documents` comes back empty, and a client sees "nothing here yet" while
    /// holding a folder full of tax records. Every field here has a fallback,
    /// so a surprising row degrades to a slightly worse row.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // The one field with no sensible fallback: without an id the row cannot
        // be downloaded, so it is better dropped than shown.
        fileId = try container.decode(String.self, forKey: .fileId)
        name = (try? container.decode(String.self, forKey: .name)) ?? fileId
        mimeType = try? container.decodeIfPresent(String.self, forKey: .mimeType)
        size = (try? container.decodeIfPresent(Int64.self, forKey: .size)) ?? 0
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        taxYear = try? container.decodeIfPresent(String.self, forKey: .taxYear)
        source = try? container.decodeIfPresent(String.self, forKey: .source)
        indexedAt = try? container.decodeIfPresent(Date.self, forKey: .indexedAt)
        modifiedTime = try? container.decodeIfPresent(String.self, forKey: .modifiedTime)
    }
}

/// A category a client may upload into. The list is **served**, not hard-coded:
/// the taxonomy is data now, so a client that embedded it would drift the first
/// time it changed.
nonisolated struct PortalCategory: Decodable, Equatable, Hashable, Sendable {
    let key: String
    /// `00_Permanent` — not year-bound. Permit, AHV certificate, deeds.
    let permanent: Bool
}

nonisolated struct DocumentsResponse: Decodable, Sendable {
    let documents: [PortalDocument]
    let categories: [PortalCategory]
}

// MARK: - Uploads

nonisolated struct UploadSession: Decodable, Sendable {
    let uploadId: String
    /// The Drive resumable session URI. Bytes go here directly — they never
    /// pass through the API.
    let sessionUri: String
    let category: String
    let taxYear: String?
}

nonisolated struct UploadComplete: Decodable, Sendable {
    let fileId: String
    let name: String
    let category: String?
    let taxYear: String?
}

// MARK: - Account

nonisolated struct AccountResponse: Decodable, Sendable {
    let ok: Bool
    /// Whether the account already reaches a household. Signing up creates an
    /// account, never an environment, so this is `false` for every new signup.
    let hasAccess: Bool
}

nonisolated struct AccessRequestResponse: Decodable, Sendable {
    let ok: Bool
    let status: String
}

// MARK: - Firestore rows

/// `households/{householdId}`, read directly for display.
///
/// The id is a readable slug with a random tail — `mueller-meier-a7f3`.
/// **Nothing parses it.** It is not a name, not a client, and not a year.
nonisolated struct Household: Identifiable, Sendable {
    let id: String
    let displayName: String
    let language: String?
    /// `unprovisioned` until the Drive folders exist.
    let provisionState: String?
    let rootFolderId: String?

    /// A household with no Drive root has no document store yet.
    ///
    /// This distinction earns its keep: an empty list where documents are
    /// expected reads as data loss to someone whose tax records we hold. Show a
    /// setup state instead.
    var hasDocumentStore: Bool {
        (rootFolderId?.isEmpty == false) && provisionState != "unprovisioned"
    }

    init(id: String, data: [String: Any]) {
        self.id = id
        self.displayName = data["displayName"] as? String ?? ""
        self.language = data["language"] as? String
        let drive = data["drive"] as? [String: Any]
        self.provisionState = drive?["provisionState"] as? String
        self.rootFolderId = drive?["rootFolderId"] as? String
    }
}

// MARK: - Drive categories

/// Display names for the twelve Drive category folders.
///
/// The **keys come from the server**; only the labels live here, and an
/// unrecognised key falls back to its own prettified folder name rather than
/// being dropped. That way a category added on the server shows up in this app
/// without a release — just without a translation.
nonisolated enum DriveCategory {
    static let otherKey = "99_Other_Documents"

    /// Read-only to clients: these are the firm's statements about what it did,
    /// not something a client account may add to. The server enforces it with a
    /// 403; the app simply never offers them.
    static let readOnlyKeys: Set<String> = ["10_Filed_By_Us", "11_Tax_Office"]

    static func label(for key: String) -> String {
        let localizationKey = "category.\(key)"
        let localized = localizationKey.localized
        if localized != localizationKey { return localized }
        return prettify(key)
    }

    /// `02_Income_Salary_And_Other` → `Income Salary And Other`.
    ///
    /// The leading number orders the folders in Drive and carries no meaning
    /// for a reader, so it is dropped — but only when it really is the number,
    /// never from a name that happens to start with a digit.
    private static func prettify(_ key: String) -> String {
        var parts = key.split(separator: "_")
        if let first = parts.first, first.allSatisfy(\.isNumber) {
            parts.removeFirst()
        }
        return parts.isEmpty ? key : parts.joined(separator: " ")
    }

    /// Sorted the way the folders are numbered, so the app's order matches what
    /// the client sees in Drive.
    static func sortKey(_ key: String) -> String { key }
}
