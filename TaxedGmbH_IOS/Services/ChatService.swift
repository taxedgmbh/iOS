//
//  ChatService.swift
//  TaxedGmbH_IOS
//
//  Real-time chat service for expert-customer communication
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()

    private let db: Firestore = {
        if let databaseId = AppConstants.Firebase.databaseId {
            return Firestore.firestore(database: databaseId)
        } else {
            return Firestore.firestore()
        }
    }()
    private let storage = Storage.storage()

    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var conversationListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    // MARK: - Conversation Management

    /// Get or create conversation for a customer
    func getOrCreateConversation(customerId: String, customerName: String, taxYear: Int) async throws -> Conversation {
        print("🔧 ChatService using named database: taxedgmbh")
        print("📍 Looking for chat in 'chats' collection...")

        // First, try to find existing active conversation
        let query = db.collection("chats")
            .whereField("customerId", isEqualTo: customerId)
            .whereField("taxYear", isEqualTo: taxYear)
            .whereField("status", isEqualTo: "active")
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        if let doc = snapshot.documents.first,
           let conversation = Conversation.fromDictionary(id: doc.documentID, data: doc.data()) {
            print("✅ Found existing chat: \(doc.documentID)")
            return conversation
        }

        // No conversation found, create new one
        // In production, you'd match with available expert based on languages, specialization, etc.
        print("📝 Creating new chat for customer: \(customerId)")
        let conversation = Conversation(
            customerId: customerId,
            customerName: customerName,
            expertId: "expert_placeholder", // TODO: Implement expert matching
            expertName: "Maria Schmidt",
            expertImageUrl: nil,
            taxYear: taxYear,
            expertLanguages: ["de", "en"],
            expertSpecialization: ["expat", "cross-border"]
        )

        let docRef = db.collection("chats").document(conversation.id)
        try await docRef.setData(conversation.toDictionary())

        // Create welcome message
        let welcomeMessage = ChatMessage(
            conversationId: conversation.id,
            senderId: "system",
            senderName: "Taxed",
            senderRole: .system,
            type: .system,
            content: "expert_chat.welcome_message".localized
        )

        try await sendMessage(welcomeMessage)

        return conversation
    }

    /// Get customer's conversations
    func getConversations(customerId: String) async throws -> [Conversation] {
        let query = db.collection("chats")
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "updatedAt", descending: true)

        let snapshot = try await query.getDocuments()

        return snapshot.documents.compactMap { doc in
            Conversation.fromDictionary(id: doc.documentID, data: doc.data())
        }
    }

    /// Observe conversation changes in real-time
    func observeConversation(conversationId: String, completion: @escaping (Conversation?) -> Void) {
        conversationListener?.remove()

        conversationListener = db.collection("chats").document(conversationId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error observing conversation: \(error)")
                    completion(nil)
                    return
                }

                guard let data = snapshot?.data() else {
                    completion(nil)
                    return
                }

                let conversation = Conversation.fromDictionary(id: conversationId, data: data)
                completion(conversation)
            }
    }

    // MARK: - Message Management

    /// Send a text message
    func sendMessage(_ message: ChatMessage) async throws {
        print("💬 Sending message to Firestore...")
        print("   Message ID: \(message.id)")
        print("   Conversation ID: \(message.conversationId)")
        print("   Sender: \(message.senderName) (\(message.senderId))")
        print("   Content: \(message.content)")

        let docRef = db.collection("messages").document(message.id)
        let messageData = message.toDictionary()

        print("📝 Message data: \(messageData)")

        do {
            try await docRef.setData(messageData)
            print("✅ Message saved to Firestore successfully")
        } catch {
            print("❌ Failed to save message to Firestore: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }

        // Update conversation last message
        do {
            try await updateConversationLastMessage(message)
            print("✅ Conversation updated with last message")
        } catch {
            print("⚠️ Failed to update conversation: \(error)")
            // Don't throw - message is already saved
        }
    }

    /// Send a message with text
    func sendTextMessage(
        conversationId: String,
        senderId: String,
        senderName: String,
        senderRole: MessageSender,
        text: String
    ) async throws {
        let message = ChatMessage(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: text
        )

        try await sendMessage(message)
    }

    /// Send a message with image
    func sendImageMessage(
        conversationId: String,
        senderId: String,
        senderName: String,
        senderRole: MessageSender,
        image: Data,
        caption: String = ""
    ) async throws {
        // Upload image to Firebase Storage
        let imageUrl = try await uploadImage(image, conversationId: conversationId)

        let message = ChatMessage(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            type: .image,
            content: caption,
            imageUrl: imageUrl
        )

        try await sendMessage(message)
    }

    /// Get messages for a conversation
    func getMessages(conversationId: String, limit: Int = 50) async throws -> [ChatMessage] {
        let query = db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "sentAt", descending: false)
            .limit(to: limit)

        let snapshot = try await query.getDocuments()

        return snapshot.documents.compactMap { doc in
            ChatMessage.fromDictionary(id: doc.documentID, data: doc.data())
        }
    }

    /// Observe messages in real-time
    func observeMessages(conversationId: String, completion: @escaping ([ChatMessage]) -> Void) {
        messagesListener?.remove()

        messagesListener = db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error observing messages: \(error)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let messages = documents.compactMap { doc in
                    ChatMessage.fromDictionary(id: doc.documentID, data: doc.data())
                }

                completion(messages)
            }
    }

    /// Mark message as read
    func markMessageAsRead(messageId: String) async throws {
        let docRef = db.collection("messages").document(messageId)
        try await docRef.updateData([
            "isRead": true,
            "readAt": Timestamp(date: Date())
        ])
    }

    /// Mark all messages in conversation as read
    func markAllMessagesAsRead(conversationId: String, forUserId: String) async throws {
        let query = db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("isRead", isEqualTo: false)
            .whereField("senderId", isNotEqualTo: forUserId)

        let snapshot = try await query.getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData([
                "isRead": true,
                "readAt": Timestamp(date: Date())
            ], forDocument: doc.reference)
        }

        try await batch.commit()

        // Reset unread count in conversation
        let conversationRef = db.collection("chats").document(conversationId)

        // Determine which field to update based on user role
        // For now, assume customer
        try await conversationRef.updateData([
            "unreadCountCustomer": 0
        ])
    }

    // MARK: - Typing Indicator

    /// Set typing indicator
    func setTyping(conversationId: String, userId: String, isTyping: Bool) async {
        let docRef = db.collection("chats").document(conversationId)

        do {
            try await docRef.updateData([
                "typingUserId": isTyping ? userId : FieldValue.delete()
            ])
        } catch {
            print("❌ Error setting typing indicator: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func updateConversationLastMessage(_ message: ChatMessage) async throws {
        let docRef = db.collection("chats").document(message.conversationId)

        var updateData: [String: Any] = [
            "lastMessage": message.content,
            "lastMessageAt": Timestamp(date: message.sentAt),
            "lastMessageSenderId": message.senderId,
            "updatedAt": Timestamp(date: Date())
        ]

        // Increment unread count for recipient
        if message.senderRole == .customer {
            updateData["unreadCountExpert"] = FieldValue.increment(Int64(1))
        } else if message.senderRole == .expert {
            updateData["unreadCountCustomer"] = FieldValue.increment(Int64(1))
        }

        try await docRef.updateData(updateData)
    }

    private func uploadImage(_ imageData: Data, conversationId: String) async throws -> String {
        // Get customerId from conversation to match regular document upload structure
        let conversationRef = db.collection("chats").document(conversationId)
        let conversationDoc = try await conversationRef.getDocument()

        guard let customerId = conversationDoc.data()?["customerId"] as? String else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Customer ID not found in conversation"])
        }

        let filename = "\(UUID().uuidString).jpg"
        // Use same structure as regular uploads: documents/{customerId}/chat_images/
        let path = "documents/\(customerId)/chat_images/\(filename)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedBy": customerId,
            "conversationId": conversationId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        print("📤 Uploading chat image to: \(path)")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        print("✅ Chat image uploaded successfully: \(downloadURL.absoluteString)")

        return downloadURL.absoluteString
    }

    // MARK: - Cleanup

    func stopObserving() {
        conversationListener?.remove()
        messagesListener?.remove()
    }
}
