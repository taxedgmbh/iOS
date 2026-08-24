//
//  PortalDocumentsService.swift
//  TaxedGmbH_IOS
//
//  Listing, uploading and downloading a household's documents.
//

import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class PortalDocumentsService: ObservableObject {

    @Published private(set) var documents: [PortalDocument] = []
    /// Served by the API alongside the list. The app never hard-codes the
    /// taxonomy — it is data on the server, and it will change.
    @Published private(set) var categories: [PortalCategory] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?

    /// The documents grouped the way the Drive folders are, in folder order.
    var grouped: [(category: String, documents: [PortalDocument])] {
        Dictionary(grouping: documents, by: \.categoryKey)
            .sorted { DriveCategory.sortKey($0.key) < DriveCategory.sortKey($1.key) }
            .map { (category: $0.key, documents: $0.value) }
    }

    // MARK: - List

    func load(householdId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: DocumentsResponse = try await PortalAPI.shared.get(
                "/api/portal/documents",
                query: [URLQueryItem(name: "householdId", value: householdId)]
            )
            documents = response.documents
            categories = response.categories
            error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Upload

    /// Uploads one file, in the three steps the contract defines.
    ///
    /// 1. Ask the API for a resumable session. The request names a **category**,
    ///    never a folder id — a folder id from a device would let any session
    ///    write anywhere in the company's Drive.
    /// 2. PUT the bytes straight to Drive.
    /// 3. Tell the API what landed.
    ///
    /// Step 3 is a **latency optimisation, not the correctness path.** If it
    /// fails — the app is killed, the network drops — the server's sweep finds
    /// the file within minutes and indexes it anyway. So a failure there is not
    /// reported as an upload failure: telling the client their upload failed
    /// when the bytes are safely in Drive invites them to send it twice.
    ///
    /// - Returns: the Drive file id, once the bytes are stored.
    @discardableResult
    func upload(
        fileURL: URL,
        fileName: String,
        category: String,
        taxYear: Int?,
        householdId: String
    ) async throws -> String {
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }

        let size = try Self.fileSize(of: fileURL)
        guard size > 0 else { throw PortalError.invalidSize }
        guard size <= AppConstants.Uploads.maximumFileSize else { throw PortalError.fileTooLarge }

        let mimeType = Self.mimeType(for: fileURL)

        var body: [String: Any] = [
            "householdId": householdId,
            "category": category,
            "fileName": fileName,
            "mimeType": mimeType,
            "size": size
        ]
        if let taxYear { body["taxYear"] = String(taxYear) }

        let session: UploadSession = try await PortalAPI.shared.post(
            "/api/portal/uploads/session",
            body: body
        )

        let fileId = try await PortalAPI.shared.upload(
            fileURL: fileURL,
            to: session.sessionUri,
            size: size,
            mimeType: mimeType
        )

        // Best effort by design — see the note above.
        do {
            let _: UploadComplete = try await PortalAPI.shared.post(
                "/api/portal/uploads/complete",
                body: ["householdId": householdId, "fileId": fileId, "uploadId": session.uploadId]
            )
        } catch {
            // Swallowed on purpose, and only here. The bytes are in Drive; the
            // sweep will index them. Reporting this would tell the client to
            // send the document a second time.
        }

        return fileId
    }

    // MARK: - Download

    /// Fetches a document and returns a local file URL to hand to a share sheet
    /// or a preview controller.
    func download(_ document: PortalDocument, householdId: String) async throws -> URL {
        try await PortalAPI.shared.download(
            fileId: document.fileId,
            householdId: householdId,
            suggestedName: document.name
        )
    }

    // MARK: - File facts

    private static func fileSize(of url: URL) throws -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values?.fileSize else { throw PortalError.invalidSize }
        return Int64(size)
    }

    /// Derived from the file itself, not from a name a user typed.
    private static func mimeType(for url: URL) -> String {
        let type = UTType(filenameExtension: url.pathExtension)
        return type?.preferredMIMEType ?? "application/octet-stream"
    }
}
