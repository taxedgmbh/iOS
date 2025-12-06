//
//  BugReportService.swift
//  TaxedGmbH_IOS
//
//  Service for handling screenshot-triggered bug reports
//  Uploads screenshots to Firebase Storage and saves reports to Firestore
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import Combine

@MainActor
class BugReportService: ObservableObject {
    static let shared = BugReportService()

    @Published var isSubmitting: Bool = false
    @Published var error: String?

    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Submit Bug Report

    /// Submit a bug report with screenshot
    func submitBugReport(
        screenshot: UIImage,
        comment: String,
        screenName: String,
        user: User
    ) async throws -> BugReport {
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        guard let userId = user.id else {
            throw NSError(domain: "BugReportService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "User must have a valid ID"
            ])
        }

        print("🐛 Submitting bug report for user: \(userId)")

        // Step 1: Generate report ID
        let reportId = UUID().uuidString

        // Step 2: Upload screenshot to Firebase Storage
        print("   📸 Uploading screenshot...")
        let screenshotUrl = try await uploadScreenshot(screenshot, userId: userId, reportId: reportId)
        print("   ✅ Screenshot uploaded: \(screenshotUrl)")

        // Step 3: Create bug report
        let bugReport = BugReport(
            id: reportId,
            userId: userId,
            userEmail: user.email,
            screenshotUrl: screenshotUrl,
            comment: comment,
            screenName: screenName,
            createdAt: Date(),
            status: .open
        )

        // Step 4: Save to Firestore
        print("   💾 Saving bug report to Firestore...")
        try await saveBugReport(bugReport, userId: userId)
        print("   ✅ Bug report saved successfully")

        return bugReport
    }

    // MARK: - Private Methods

    /// Upload screenshot to Firebase Storage
    private func uploadScreenshot(_ image: UIImage, userId: String, reportId: String) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "BugReportService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert screenshot to JPEG"
            ])
        }

        // Storage path: bugReports/{userId}/{reportId}/screenshot.jpg
        let storagePath = "bugReports/\(userId)/\(reportId)/screenshot.jpg"
        let storageRef = storage.reference().child(storagePath)

        // Upload with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "reportId": reportId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }

    /// Save bug report to Firestore
    private func saveBugReport(_ report: BugReport, userId: String) async throws {
        guard let reportId = report.id else {
            throw NSError(domain: "BugReportService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Bug report must have a valid ID"
            ])
        }

        // Firestore path: customers/{userId}/bugReports/{reportId}
        let docRef = db.collection("customers")
            .document(userId)
            .collection("bugReports")
            .document(reportId)

        try await docRef.setData(report.toDictionary())
    }

    /// Get all bug reports for a user (for admin review)
    func getBugReports(for userId: String) async throws -> [BugReport] {
        let snapshot = try await db.collection("customers")
            .document(userId)
            .collection("bugReports")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            BugReport.fromDictionary(doc.data())
        }
    }
}
