//
//  FirestoreService.swift
//  TaxedGmbH_IOS
//
//  Handles Firestore database operations for tax documents
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    @Published var documents: [TaxDocument] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var documentListeners: [String: ListenerRegistration] = [:]

    private init() {}

    // MARK: - Document CRUD Operations

    /// Create a new document record in Firestore
    func createDocument(_ document: TaxDocument) async throws {
        isLoading = true
        defer { isLoading = false }

        let docData = document.toDictionary()

        do {
            try await db.collection(AppConstants.Firebase.Collections.documents).document(document.id).setData(docData)
            print("✅ Document created in Firestore: \(document.id)")
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            print("❌ Error creating document: \(error)")
            throw error
        }
    }

    /// Update an existing document
    func updateDocument(_ document: TaxDocument) async throws {
        var docData = document.toDictionary()
        docData["updatedAt"] = FieldValue.serverTimestamp()

        do {
            try await db.collection(AppConstants.Firebase.Collections.documents).document(document.id).updateData(docData)
            print("✅ Document updated: \(document.id)")
        } catch {
            errorMessage = "Fehler beim Aktualisieren: \(error.localizedDescription)"
            print("❌ Error updating document: \(error)")
            throw error
        }
    }

    /// Update document status (for swipe approval/rejection)
    func updateDocumentStatus(documentId: String, status: DocumentStatus) async throws {
        let updateData: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection(AppConstants.Firebase.Collections.documents).document(documentId).updateData(updateData)
            print("✅ Document status updated to \(status.rawValue): \(documentId)")
        } catch {
            errorMessage = "Fehler beim Status-Update: \(error.localizedDescription)"
            print("❌ Error updating document status: \(error)")
            throw error
        }
    }

    /// Delete a document
    func deleteDocument(documentId: String) async throws {
        do {
            try await db.collection(AppConstants.Firebase.Collections.documents).document(documentId).delete()
            print("✅ Document deleted: \(documentId)")
        } catch {
            errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
            print("❌ Error deleting document: \(error)")
            throw error
        }
    }

    /// Get a single document by ID
    func getDocument(documentId: String) async throws -> TaxDocument? {
        do {
            let snapshot = try await db.collection(AppConstants.Firebase.Collections.documents).document(documentId).getDocument()

            guard snapshot.exists, let data = snapshot.data() else {
                print("⚠️ Document not found: \(documentId)")
                return nil
            }

            return TaxDocument.fromDictionary(id: snapshot.documentID, data: data)
        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
            print("❌ Error getting document: \(error)")
            throw error
        }
    }

    // MARK: - Query Operations

    /// Get all documents for a customer
    func getDocumentsForCustomer(customerId: String) async throws -> [TaxDocument] {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection(AppConstants.Firebase.Collections.documents)
                .whereField("customerId", isEqualTo: customerId)
                .order(by: "uploadedAt", descending: true)
                .getDocuments()

            let documents = snapshot.documents.compactMap { doc in
                TaxDocument.fromDictionary(id: doc.documentID, data: doc.data())
            }

            self.documents = documents
            print("✅ Loaded \(documents.count) documents for customer: \(customerId)")
            return documents

        } catch {
            errorMessage = "Fehler beim Laden der Dokumente: \(error.localizedDescription)"
            print("❌ Error getting documents: \(error)")
            throw error
        }
    }

    /// Get documents by category
    func getDocumentsByCategory(customerId: String, category: TaxCategory) async throws -> [TaxDocument] {
        do {
            let snapshot = try await db.collection(AppConstants.Firebase.Collections.documents)
                .whereField("customerId", isEqualTo: customerId)
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: "uploadedAt", descending: true)
                .getDocuments()

            let documents = snapshot.documents.compactMap { doc in
                TaxDocument.fromDictionary(id: doc.documentID, data: doc.data())
            }

            print("✅ Loaded \(documents.count) \(category.displayName) documents")
            return documents

        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
            print("❌ Error getting documents by category: \(error)")
            throw error
        }
    }

    /// Get documents by status
    func getDocumentsByStatus(customerId: String, status: DocumentStatus) async throws -> [TaxDocument] {
        do {
            let snapshot = try await db.collection(AppConstants.Firebase.Collections.documents)
                .whereField("customerId", isEqualTo: customerId)
                .whereField("status", isEqualTo: status.rawValue)
                .order(by: "uploadedAt", descending: true)
                .getDocuments()

            let documents = snapshot.documents.compactMap { doc in
                TaxDocument.fromDictionary(id: doc.documentID, data: doc.data())
            }

            print("✅ Loaded \(documents.count) documents with status: \(status.displayName)")
            return documents

        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
            print("❌ Error getting documents by status: \(error)")
            throw error
        }
    }

    // MARK: - Real-time Listeners

    /// Listen to a single document for real-time updates (for AI processing status)
    func observeDocument(documentId: String, completion: @escaping (TaxDocument?) -> Void) {
        // Remove existing listener if any
        documentListeners[documentId]?.remove()

        let listener = db.collection(AppConstants.Firebase.Collections.documents).document(documentId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error observing document: \(error)")
                    completion(nil)
                    return
                }

                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    print("⚠️ Document doesn't exist: \(documentId)")
                    completion(nil)
                    return
                }

                let document = TaxDocument.fromDictionary(id: snapshot.documentID, data: data)
                completion(document)
            }

        documentListeners[documentId] = listener
    }

    /// Listen to all customer documents for real-time updates
    func observeCustomerDocuments(customerId: String, completion: @escaping ([TaxDocument]) -> Void) {
        let listenerId = "customer_\(customerId)"
        documentListeners[listenerId]?.remove()

        let listener = db.collection(AppConstants.Firebase.Collections.documents)
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "uploadedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error observing documents: \(error)")
                    completion([])
                    return
                }

                guard let snapshot = snapshot else {
                    completion([])
                    return
                }

                let documents = snapshot.documents.compactMap { doc in
                    TaxDocument.fromDictionary(id: doc.documentID, data: doc.data())
                }

                Task { @MainActor in
                    self.documents = documents
                }

                completion(documents)
            }

        documentListeners[listenerId] = listener
    }

    /// Stop observing a document
    func stopObserving(documentId: String) {
        documentListeners[documentId]?.remove()
        documentListeners.removeValue(forKey: documentId)
    }

    /// Stop all listeners
    func stopAllObservers() {
        documentListeners.values.forEach { $0.remove() }
        documentListeners.removeAll()
    }

    // MARK: - Statistics

    /// Get document count by category for a customer
    func getDocumentStats(customerId: String) async throws -> [TaxCategory: Int] {
        let documents = try await getDocumentsForCustomer(customerId: customerId)

        var stats: [TaxCategory: Int] = [:]
        for category in TaxCategory.allCases {
            stats[category] = documents.filter { $0.category == category }.count
        }

        return stats
    }

    /// Get completion percentage for customer's tax documents
    func getCompletionPercentage(customerId: String, requiredCount: Int? = nil) async throws -> Double {
        let documents = try await getDocumentsForCustomer(customerId: customerId)
        let approvedCount = documents.filter { $0.status == .approved || $0.status == .reviewed }.count
        let required = requiredCount ?? AppConstants.Tax.requiredDocumentCount

        return Double(approvedCount) / Double(required) * 100.0
    }

    // MARK: - FCM Token Management

    /// Update user's FCM token for push notifications
    func updateUserFCMToken(userId: String, fcmToken: String, platform: String, deviceId: String) async throws {
        let tokenData: [String: Any] = [
            "fcmToken": fcmToken,
            "platform": platform,
            "deviceId": deviceId,
            "updatedAt": FieldValue.serverTimestamp(),
            "active": true
        ]

        // Store in a subcollection for managing multiple devices
        try await db.collection("customers")
            .document(userId)
            .collection("devices")
            .document(deviceId)
            .setData(tokenData, merge: true)

        // Also update the main user document with the latest token
        try await db.collection("customers")
            .document(userId)
            .updateData([
                "fcmToken": fcmToken,
                "notificationsEnabled": true,
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ])

        print("✅ FCM token updated in Firestore for user: \(userId)")
    }

    /// Remove FCM token when user logs out or disables notifications
    func removeUserFCMToken(userId: String, deviceId: String) async throws {
        // Mark device as inactive
        try await db.collection("customers")
            .document(userId)
            .collection("devices")
            .document(deviceId)
            .updateData([
                "active": false,
                "removedAt": FieldValue.serverTimestamp()
            ])

        print("✅ FCM token removed for device: \(deviceId)")
    }
}
