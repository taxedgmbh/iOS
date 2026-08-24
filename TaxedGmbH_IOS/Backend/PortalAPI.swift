//
//  PortalAPI.swift
//  TaxedGmbH_IOS
//
//  The single door to the taxed.ch portal API.
//
//  Nothing else in this app builds a request to the backend. That is the point:
//  the bearer token, the error mapping and the 404-is-also-403 rule are applied
//  in exactly one place, so no screen can quietly do it differently.
//

import Foundation
import FirebaseAuth

actor PortalAPI {
    static let shared = PortalAPI()

    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            // Tax documents are private per request; a shared URL cache would
            // write them to disk unencrypted.
            config.urlCache = nil
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.waitsForConnectivity = true
            config.timeoutIntervalForRequest = 30
            // Uploads and downloads of a scanned dossier are slow on a train.
            config.timeoutIntervalForResource = 600
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Token

    /// Asks the Firebase SDK for a token before every request.
    ///
    /// The SDK decides whether to refresh. Implementing that by hand — caching
    /// a token and a expiry — is how clients end up sending a token that expired
    /// four seconds ago.
    private func idToken(forceRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else { throw PortalError.missingToken }
        do {
            return try await user.getIDToken(forcingRefresh: forceRefresh)
        } catch {
            // A revoked or disabled account fails here, not at the server.
            throw PortalError.tokenRevoked
        }
    }

    // MARK: - Requests

    func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let request = try await authorized(path, method: "GET", query: query, body: nil)
        return try await send(request)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        let data = try body.map { try JSONSerialization.data(withJSONObject: $0) }
        let request = try await authorized(path, method: "POST", query: [], body: data)
        return try await send(request)
    }

    private func authorized(
        _ path: String,
        method: String,
        query: [URLQueryItem],
        body: Data?
    ) async throws -> URLRequest {
        guard var components = URLComponents(
            url: AppConstants.Backend.apiBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw PortalError.transport("bad-url")
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw PortalError.transport("bad-url") }

        let token = try await idToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await perform(request)
        try Self.check(response: response, data: data)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw PortalError.transport("decode")
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw PortalError.offline
        } catch {
            throw PortalError.transport(error.localizedDescription)
        }
    }

    /// Turns a non-2xx response into the contract's error, reading the
    /// `{"error": "<code>"}` body when there is one.
    nonisolated static func check(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw PortalError.transport("no-response")
        }
        guard !(200...299).contains(http.statusCode) else { return }

        let code = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
        throw PortalError.from(status: http.statusCode, code: code)
    }

    nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: text) { return date }
            if let date = ISO8601DateFormatter.plain.date(from: text) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "unparseable date \(text)")
            )
        }
        return decoder
    }()

    // MARK: - Bytes

    /// Uploads a file to a Drive resumable session in a single PUT.
    ///
    /// The bytes go straight to Google. They deliberately do not pass through
    /// the API: Cloud Run caps a request body at 32 MB, a scanned dossier
    /// routinely exceeds that, and proxying would bill every megabyte twice.
    ///
    /// Streamed from the file rather than loaded into memory — a 100 MB `Data`
    /// on an older device is a jetsam kill, not a slow upload.
    ///
    /// - Returns: the Drive file id of what actually landed.
    func upload(fileURL: URL, to sessionUri: String, size: Int64, mimeType: String) async throws -> String {
        guard let url = URL(string: sessionUri) else { throw PortalError.transport("bad-session-uri") }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue(String(size), forHTTPHeaderField: "Content-Length")
        // No Authorization header: the session URI carries its own credential.
        // Adding ours would leak an ID token to a Google endpoint that has no
        // business seeing it.

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.upload(for: request, fromFile: fileURL)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw PortalError.offline
        } catch {
            throw PortalError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PortalError.driveUnavailable
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let fileId = json["id"] as? String
        else {
            // Drive accepted the bytes but we cannot read the id. The file
            // exists; the five-minute sweep will index it. Surfacing this as a
            // failure would tell the client to upload it twice.
            throw PortalError.missingFileId
        }
        return fileId
    }

    /// Streams a document to a temporary file and returns its location.
    ///
    /// Documents proxy through the API because Drive has no signed-URL
    /// equivalent for private files. Written to disk rather than held in memory
    /// for the same reason uploads are streamed.
    func download(fileId: String, householdId: String, suggestedName: String) async throws -> URL {
        let path = "/api/portal/documents/\(fileId)/content"
        let request = try await authorized(
            path,
            method: "GET",
            query: [URLQueryItem(name: "householdId", value: householdId)],
            body: nil
        )

        let (tempURL, response): (URL, URLResponse)
        do {
            (tempURL, response) = try await session.download(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw PortalError.offline
        } catch {
            throw PortalError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw PortalError.transport("no-response") }
        guard (200...299).contains(http.statusCode) else {
            let data = (try? Data(contentsOf: tempURL)) ?? Data()
            let code = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw PortalError.from(status: http.statusCode, code: code)
        }

        // Moved out of the URLSession temp location, which is deleted the moment
        // this call returns, and into a per-file directory so two documents with
        // the same name do not collide.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("documents", isDirectory: true)
            .appendingPathComponent(fileId, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent(
            suggestedName.isEmpty ? fileId : suggestedName
        )
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: tempURL, to: destination)
        } catch {
            throw PortalError.transport("write-failed")
        }
        return destination
    }
}

private extension ISO8601DateFormatter {
    nonisolated(unsafe) static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let plain = ISO8601DateFormatter()
}
