//
//  DataManagementService.swift
//  TaxedGmbH_IOS
//
//  GDPR-compliant data management service
//  Handles storage calculation, data export, and account deletion with workspace safeguards
//

import Foundation
import Combine
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DataManagementService: ObservableObject {
    static let shared = DataManagementService()

    // Published state
    @Published var storageUsed: Int64 = 0  // Bytes
    @Published var documentCount: Int = 0
    @Published var isCalculating: Bool = false
    @Published var isExporting: Bool = false
    @Published var isDeleting: Bool = false

    // Dependencies
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private lazy var firestoreService = FirestoreService.shared
    private lazy var workspaceManager = WorkspaceManager.shared

    private init() {}

    // MARK: - Workspace Helpers

    /// Fetch all workspaces for a user from Firestore
    private func getWorkspacesForUser(userId: String) async throws -> [Workspace] {
        let snapshot = try await db
            .collection(AppConstants.Firebase.Collections.workspaces)
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return Workspace.fromDictionary(dict)
        }
    }

    // MARK: - Storage Calculation

    /// Calculate total storage used by user across all workspaces
    func calculateStorageUsage(for userId: String) async {
        isCalculating = true
        defer { isCalculating = false }

        print("📊 Calculating storage usage for user: \(userId)")

        do {
            // Get all documents for user
            let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
            documentCount = documents.count

            var totalSize: Int64 = 0

            // Calculate size of each document
            for document in documents {
                // Get size of original document
                if let size = await getFileSize(path: document.storageUrl) {
                    totalSize += size
                }

                // Get size of processed document (with cover sheet)
                if let processedUrl = document.processedDocumentUrl,
                   let size = await getFileSize(path: processedUrl) {
                    totalSize += size
                }

                // Get size of cover sheet
                if let coverUrl = document.coverSheetUrl,
                   let size = await getFileSize(path: coverUrl) {
                    totalSize += size
                }
            }

            // Get size of tax packages
            let workspaces = try await getWorkspacesForUser(userId: userId)
            for workspace in workspaces {
                guard let workspaceId = workspace.id else { continue }
                let packagePath = "workspaces/\(workspaceId)/\(workspace.taxYear)/tax_submission_package_\(workspace.taxYear).pdf"
                if let size = await getFileSize(path: packagePath) {
                    totalSize += size
                }
            }

            storageUsed = totalSize
            print("✅ Storage calculation complete: \(formatBytes(totalSize)), \(documentCount) documents")

        } catch {
            print("❌ Storage calculation failed: \(error)")
        }
    }

    /// Get file size from Firebase Storage
    private func getFileSize(path: String) async -> Int64? {
        do {
            let ref: StorageReference

            // Handle both storage paths and full URLs
            if path.contains("firebasestorage.googleapis.com") {
                ref = storage.reference(forURL: path)
            } else {
                ref = storage.reference().child(path)
            }

            let metadata = try await ref.getMetadata()
            return metadata.size
        } catch {
            // File might not exist - not an error
            return nil
        }
    }

    /// Format bytes to human-readable string
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Data Export (GDPR Compliance)

    /// Export all user data as JSON + PDFs in a ZIP file
    func exportAllData(for userId: String, userName: String) async throws -> URL {
        isExporting = true
        defer { isExporting = false }

        print("📦 Starting data export for user: \(userId)")

        // Create temporary directory for export
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TaxedExport_\(userId)")
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Export user profile
        let profileData = try await exportUserProfile(userId: userId, to: tempDir)

        // Export documents
        let documentsData = try await exportDocuments(userId: userId, to: tempDir)

        // Export workspaces
        let workspacesData = try await exportWorkspaces(userId: userId, to: tempDir)

        // Create summary JSON
        let summary: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "user_id": userId,
            "user_name": userName,
            "profile": profileData,
            "documents_count": documentsData.count,
            "workspaces_count": workspacesData.count,
            "total_storage": storageUsed
        ]

        let summaryJSON = try JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted)
        try summaryJSON.write(to: tempDir.appendingPathComponent("export_summary.json"))

        // Return the directory - iOS share sheet will handle it
        // User can use Files app to zip if needed
        print("✅ Data export complete: \(tempDir.path)")
        return tempDir
    }

    private func exportUserProfile(userId: String, to directory: URL) async throws -> [String: Any] {
        let user = try await firestoreService.getUserProfile(userId: userId)
        let userData = user.toDictionary()

        let json = try JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)
        try json.write(to: directory.appendingPathComponent("user_profile.json"))

        return userData
    }

    private func exportDocuments(userId: String, to directory: URL) async throws -> [[String: Any]] {
        let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)

        // Create documents subdirectory
        let docsDir = directory.appendingPathComponent("documents")
        try FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)

        var documentsData: [[String: Any]] = []

        for document in documents {
            // Export document metadata
            let docData = document.toDictionary()
            documentsData.append(docData)

            // Download PDFs
            if let pdfData = await downloadFile(path: document.storageUrl) {
                let filename = "\(document.id)_original.pdf"
                try pdfData.write(to: docsDir.appendingPathComponent(filename))
            }

            if let processedUrl = document.processedDocumentUrl,
               let pdfData = await downloadFile(path: processedUrl) {
                let filename = "\(document.id)_with_cover.pdf"
                try pdfData.write(to: docsDir.appendingPathComponent(filename))
            }
        }

        // Write documents index
        let json = try JSONSerialization.data(withJSONObject: documentsData, options: .prettyPrinted)
        try json.write(to: docsDir.appendingPathComponent("documents_index.json"))

        return documentsData
    }

    private func exportWorkspaces(userId: String, to directory: URL) async throws -> [[String: Any]] {
        let workspaces = try await getWorkspacesForUser(userId: userId)

        var workspacesData: [[String: Any]] = []

        for workspace in workspaces {
            let wsData = workspace.toDictionary()
            workspacesData.append(wsData)
        }

        if !workspacesData.isEmpty {
            let json = try JSONSerialization.data(withJSONObject: workspacesData, options: .prettyPrinted)
            try json.write(to: directory.appendingPathComponent("workspaces.json"))
        }

        return workspacesData
    }

    private func downloadFile(path: String) async -> Data? {
        do {
            let ref: StorageReference

            if path.contains("firebasestorage.googleapis.com") {
                ref = storage.reference(forURL: path)
            } else {
                ref = storage.reference().child(path)
            }

            let maxSize: Int64 = 10 * 1024 * 1024 // 10 MB
            return try await ref.data(maxSize: maxSize)
        } catch {
            print("⚠️ Failed to download file: \(path) - \(error)")
            return nil
        }
    }

    // MARK: - Account Deletion with Workspace Safeguards

    /// Check if user can delete their account (workspace safety checks)
    func canDeleteAccount(userId: String) async throws -> (canDelete: Bool, reason: String?, workspaceConflicts: [Workspace]) {
        print("🔍 Checking if user \(userId) can delete account...")

        // Get all workspaces user is part of
        let workspaces = try await getWorkspacesForUser(userId: userId)
        var conflicts: [Workspace] = []

        for workspace in workspaces {
            // Skip personal workspaces with only this user
            if workspace.type == WorkspaceType.personal && workspace.memberIds.count == 1 {
                continue
            }

            // Check if user is owner of multi-member workspace
            if workspace.ownerId == userId && workspace.memberIds.count > 1 {
                conflicts.append(workspace)
            }

            // Check if this is a joint workspace (spouse)
            if workspace.type == WorkspaceType.joint && workspace.memberIds.count > 1 {
                conflicts.append(workspace)
            }
        }

        if !conflicts.isEmpty {
            let reason = conflicts.count == 1
                ? "You are part of a shared workspace '\(conflicts[0].name)'. Other members will lose access if you delete your account."
                : "You are part of \(conflicts.count) shared workspaces. Other members will lose access if you delete your account."

            return (false, reason, conflicts)
        }

        return (true, nil, [])
    }

    /// Delete user account and ALL associated data (GDPR Right to be Forgotten)
    /// CRITICAL: This permanently deletes everything
    func deleteAccount(userId: String, forceDelete: Bool = false) async throws {
        isDeleting = true
        defer { isDeleting = false }

        print("🗑️ Starting account deletion for user: \(userId)")

        // Safety check
        if !forceDelete {
            let (canDelete, reason, conflicts) = try await canDeleteAccount(userId: userId)
            if !canDelete {
                throw NSError(domain: "DataManagement", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: reason ?? "Cannot delete account due to workspace conflicts",
                    "conflicts": conflicts.map { $0.name }
                ])
            }
        }

        // Step 1: Delete all documents from Firebase Storage
        print("📁 Deleting all Storage files...")
        let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)

        for document in documents {
            // Delete original document
            await deleteFile(path: document.storageUrl)

            // Delete processed document
            if let processedUrl = document.processedDocumentUrl {
                await deleteFile(path: processedUrl)
            }

            // Delete cover sheet
            if let coverUrl = document.coverSheetUrl {
                await deleteFile(path: coverUrl)
            }
        }

        // Step 2: Delete tax packages from owned workspaces
        print("📦 Deleting tax packages...")
        let workspaces = try await getWorkspacesForUser(userId: userId)
        for workspace in workspaces where workspace.ownerId == userId {
            guard let workspaceId = workspace.id else { continue }
            let packagePath = "workspaces/\(workspaceId)/\(workspace.taxYear)/tax_submission_package_\(workspace.taxYear).pdf"
            await deleteFile(path: packagePath)
        }

        // Step 3: Delete all Firestore documents
        print("🗄️ Deleting all Firestore data...")
        for document in documents {
            try await firestoreService.deleteDocument(documentId: document.id)
        }

        // Step 4: Remove user from all workspaces
        // Note: We don't delete workspaces to preserve data for other members (GDPR-safe)
        print("👥 Removing user from all workspaces...")
        guard let userProfile = try? await firestoreService.getUserProfile(userId: userId) else {
            print("⚠️ Could not fetch user profile for workspace removal")
            return
        }

        for workspace in workspaces {
            do {
                // Remove user from workspace (preserves workspace for other members)
                try await workspaceManager.removeMember(userId: userId, from: workspace, removedBy: userProfile)
                print("  ✓ Removed user from workspace: \(workspace.name)")
            } catch {
                print("  ⚠️ Could not remove user from workspace \(workspace.name): \(error)")
            }
        }

        // Step 5: Delete user profile from Firestore
        print("👤 Deleting user profile...")
        try await db.collection("customers").document(userId).delete()

        // Step 6: Delete Firebase Auth account
        print("🔐 Deleting Firebase Auth account...")
        try await Auth.auth().currentUser?.delete()

        print("✅ Account deletion complete for user: \(userId)")
    }

    private func deleteFile(path: String) async {
        do {
            let ref: StorageReference

            if path.contains("firebasestorage.googleapis.com") {
                ref = storage.reference(forURL: path)
            } else {
                ref = storage.reference().child(path)
            }

            try await ref.delete()
            print("  ✓ Deleted: \(path)")
        } catch {
            // File might not exist - not a critical error
            print("  ⚠️ Could not delete: \(path) - \(error.localizedDescription)")
        }
    }

    /// Send deletion notification to other workspace members
    func notifyWorkspaceMembersAboutDeletion(conflicts: [Workspace], userId: String) async {
        // TODO: Implement notification system
        // This should send in-app notifications or emails to other workspace members
        // warning them that a member wants to delete their account

        for workspace in conflicts {
            let otherMembers = workspace.members.filter { $0.userId != userId }
            for member in otherMembers {
                print("📧 Would notify \(member.email) about pending deletion in workspace: \(workspace.name)")
                // Implement actual notification here
            }
        }
    }
}
