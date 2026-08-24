//
//  PortalError.swift
//  TaxedGmbH_IOS
//
//  The error half of the API contract.
//
//  Every portal route answers a uniform body `{"error": "<code>"}` and never
//  includes internal detail. This maps those codes to something the UI can act
//  on, and — just as importantly — refuses to invent distinctions the server
//  deliberately does not make.
//

import Foundation

enum PortalError: LocalizedError, Equatable {

    // MARK: Authentication (401)

    /// No `Authorization` header reached the server. A bug on this side.
    case missingToken
    /// Malformed or unverifiable token.
    case invalidToken
    /// The session was revoked. This is the ONE case that should send someone
    /// back to a sign-in screen; the others should not.
    case tokenRevoked

    // MARK: Authorisation

    /// Authenticated, but not the right tier. (403)
    case forbidden

    /// 404. **Also returned when a household exists but you are not a member.**
    /// That is deliberate: status codes must not let anyone discover which
    /// household ids are real. Never "helpfully" distinguish this in the UI —
    /// one message for both.
    case notFound

    // MARK: Uploads

    case invalidSize
    case fileTooLarge
    case unknownCategory
    /// `10_Filed_By_Us` and `11_Tax_Office` are ours to write, not the
    /// client's.
    case categoryReadOnly
    /// The household has no Drive folders yet.
    case notProvisioned
    case missingFileId
    case driveUnavailable

    // MARK: Other

    case alreadyApproved
    case server
    case offline
    /// Transport or decoding failure — never a server-authored code.
    case transport(String)

    // MARK: - Mapping

    /// Builds the error from what the server actually said.
    ///
    /// The status is authoritative and the code refines it, because a proxy or
    /// a cold start can produce a status with no JSON body at all.
    static func from(status: Int, code: String?) -> PortalError {
        switch code {
        case "missing-token": return .missingToken
        case "invalid-token": return .invalidToken
        case "token-revoked": return .tokenRevoked
        case "forbidden": return .forbidden
        case "not-found": return .notFound
        case "already-approved": return .alreadyApproved
        case "invalid-size": return .invalidSize
        case "file-too-large": return .fileTooLarge
        case "unknown-category": return .unknownCategory
        case "category-read-only": return .categoryReadOnly
        case "not-provisioned": return .notProvisioned
        case "missing-file-id": return .missingFileId
        case "drive-unavailable": return .driveUnavailable
        case "internal": return .server
        default: break
        }

        switch status {
        case 401: return .invalidToken
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .alreadyApproved
        case 413: return .fileTooLarge
        case 502, 503: return .driveUnavailable
        default: return .server
        }
    }

    /// True only for a revoked session. Nothing else may sign a user out:
    /// deciding "you may not be here" is a routing concern, and a client that
    /// signs out on a 403 destroys a perfectly good session for every other
    /// screen.
    var requiresReauthentication: Bool { self == .tokenRevoked }

    // MARK: - Presentation

    var errorDescription: String? {
        switch self {
        case .missingToken, .invalidToken:
            return "error.session_invalid".localized
        case .tokenRevoked:
            return "error.session_revoked".localized
        case .forbidden:
            return "error.forbidden".localized
        case .notFound:
            // One message for "does not exist" and "not yours". See above.
            return "error.not_found".localized
        case .invalidSize:
            return "error.upload_invalid_size".localized
        case .fileTooLarge:
            return "error.upload_too_large".localized
        case .unknownCategory:
            return "error.upload_unknown_category".localized
        case .categoryReadOnly:
            return "error.upload_read_only".localized
        case .notProvisioned:
            return "error.not_provisioned".localized
        case .missingFileId:
            return "error.generic".localized
        case .driveUnavailable:
            return "error.drive_unavailable".localized
        case .alreadyApproved:
            return "error.already_approved".localized
        case .server:
            return "error.generic".localized
        case .offline:
            return "error.offline".localized
        case .transport:
            return "error.network".localized
        }
    }
}
