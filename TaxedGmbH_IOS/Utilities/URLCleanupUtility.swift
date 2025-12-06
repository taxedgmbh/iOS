//
//  URLCleanupUtility.swift
//  TaxedGmbH_IOS
//
//  Utility to clean up any public URLs stored in documents and convert them to storage paths
//

import Foundation
import FirebaseFirestore

@MainActor
class URLCleanupUtility {
    static let shared = URLCleanupUtility()

    private init() {}

    /// Clean up all documents for a user, converting any public URLs to storage paths
    func cleanupDocumentURLs(for userId: String) async {
        print("🧹 Starting URL cleanup for user: \(userId)")

        do {
            let documents = try await FirestoreService.shared.getDocumentsForCustomer(customerId: userId)
            var cleanedCount = 0

            for var document in documents {
                var needsUpdate = false

                // Check and clean processedDocumentUrl
                if let processedUrl = document.processedDocumentUrl,
                   processedUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: processedUrl) {
                        document.processedDocumentUrl = cleanPath
                        needsUpdate = true
                        print("  ✅ Cleaned processedDocumentUrl for \(document.id)")
                    }
                }

                // Check and clean coverSheetUrl
                if let coverUrl = document.coverSheetUrl,
                   coverUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: coverUrl) {
                        document.coverSheetUrl = cleanPath
                        needsUpdate = true
                        print("  ✅ Cleaned coverSheetUrl for \(document.id)")
                    }
                }

                // Check and clean storageUrl (this should always be a path, but let's check)
                if document.storageUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: document.storageUrl) {
                        document.storageUrl = cleanPath
                        needsUpdate = true
                        print("  ✅ Cleaned storageUrl for \(document.id)")
                    }
                }

                // Update the document if any URLs were cleaned
                if needsUpdate {
                    try await FirestoreService.shared.updateDocument(document)
                    cleanedCount += 1
                }
            }

            print("✅ URL cleanup complete. Cleaned \(cleanedCount) documents.")
        } catch {
            print("❌ Error during URL cleanup: \(error)")
        }
    }

    /// Extract storage path from a Firebase Storage public URL
    private func extractStoragePath(from urlString: String) -> String? {
        // URL format: https://firebasestorage.googleapis.com:443/v0/b/BUCKET/o/ENCODED_PATH?alt=media&token=TOKEN

        // Find the "/o/" part and the "?" part
        guard let oIndex = urlString.range(of: "/o/"),
              let queryIndex = urlString.range(of: "?") else {
            return nil
        }

        // Extract the encoded path between "/o/" and "?"
        let encodedPath = String(urlString[oIndex.upperBound..<queryIndex.lowerBound])

        // Decode the path
        return encodedPath.removingPercentEncoding
    }

    /// Clean up all documents in a workspace
    func cleanupWorkspaceDocumentURLs(workspaceId: String, taxYear: Int) async {
        print("🧹 Starting URL cleanup for workspace: \(workspaceId), year: \(taxYear)")

        do {
            let documents = try await FirestoreService.shared.getDocumentsForWorkspace(
                workspaceId: workspaceId
            )
            var cleanedCount = 0

            for var document in documents {
                var needsUpdate = false

                // Check and clean all URL fields
                if let processedUrl = document.processedDocumentUrl,
                   processedUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: processedUrl) {
                        document.processedDocumentUrl = cleanPath
                        needsUpdate = true
                    }
                }

                if let coverUrl = document.coverSheetUrl,
                   coverUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: coverUrl) {
                        document.coverSheetUrl = cleanPath
                        needsUpdate = true
                    }
                }

                if document.storageUrl.contains("firebasestorage.googleapis.com") {
                    if let cleanPath = extractStoragePath(from: document.storageUrl) {
                        document.storageUrl = cleanPath
                        needsUpdate = true
                    }
                }

                if needsUpdate {
                    try await FirestoreService.shared.updateDocument(document)
                    cleanedCount += 1
                    print("  ✅ Cleaned document: \(document.id)")
                }
            }

            print("✅ Workspace URL cleanup complete. Cleaned \(cleanedCount) documents.")
        } catch {
            print("❌ Error during workspace URL cleanup: \(error)")
        }
    }
}