//
//  ChatMessage.swift
//  TaxedGmbH_IOS
//
//  Chat message model for expert-customer communication
//

import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case document = "document"
    case system = "system" // System messages like "Expert assigned"
}

enum MessageSender: String, Codable {
    case customer = "customer"
    case expert = "expert"
    case system = "system"
}

struct ChatMessage: Codable, Identifiable, Hashable {
    var id: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let senderRole: MessageSender

    // Message Content
    let type: MessageType
    let content: String
    var imageUrl: String?
    var documentUrl: String?
    var documentName: String?

    // Status & Metadata
    var isRead: Bool
    var readAt: Date?
    let sentAt: Date

    // Optional features
    var replyToMessageId: String?
    var isEdited: Bool
    var editedAt: Date?

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        senderId: String,
        senderName: String,
        senderRole: MessageSender,
        type: MessageType = .text,
        content: String,
        imageUrl: String? = nil,
        documentUrl: String? = nil,
        documentName: String? = nil,
        isRead: Bool = false,
        readAt: Date? = nil,
        sentAt: Date = Date(),
        replyToMessageId: String? = nil,
        isEdited: Bool = false,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.senderRole = senderRole
        self.type = type
        self.content = content
        self.imageUrl = imageUrl
        self.documentUrl = documentUrl
        self.documentName = documentName
        self.isRead = isRead
        self.readAt = readAt
        self.sentAt = sentAt
        self.replyToMessageId = replyToMessageId
        self.isEdited = isEdited
        self.editedAt = editedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "conversationId": conversationId,
            "senderId": senderId,
            "senderName": senderName,
            "senderRole": senderRole.rawValue,
            "type": type.rawValue,
            "content": content,
            "isRead": isRead,
            "sentAt": Timestamp(date: sentAt),
            "isEdited": isEdited
        ]

        if let imageUrl = imageUrl { dict["imageUrl"] = imageUrl }
        if let documentUrl = documentUrl { dict["documentUrl"] = documentUrl }
        if let documentName = documentName { dict["documentName"] = documentName }
        if let readAt = readAt { dict["readAt"] = Timestamp(date: readAt) }
        if let replyToMessageId = replyToMessageId { dict["replyToMessageId"] = replyToMessageId }
        if let editedAt = editedAt { dict["editedAt"] = Timestamp(date: editedAt) }

        return dict
    }

    // Create from Firestore dictionary
    static func fromDictionary(id: String, data: [String: Any]) -> ChatMessage? {
        guard let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let senderRoleString = data["senderRole"] as? String,
              let senderRole = MessageSender(rawValue: senderRoleString),
              let typeString = data["type"] as? String,
              let type = MessageType(rawValue: typeString),
              let content = data["content"] as? String,
              let isRead = data["isRead"] as? Bool,
              let isEdited = data["isEdited"] as? Bool else {
            return nil
        }

        let sentAt = (data["sentAt"] as? Timestamp)?.dateValue() ?? Date()
        let readAt = (data["readAt"] as? Timestamp)?.dateValue()
        let editedAt = (data["editedAt"] as? Timestamp)?.dateValue()

        return ChatMessage(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            type: type,
            content: content,
            imageUrl: data["imageUrl"] as? String,
            documentUrl: data["documentUrl"] as? String,
            documentName: data["documentName"] as? String,
            isRead: isRead,
            readAt: readAt,
            sentAt: sentAt,
            replyToMessageId: data["replyToMessageId"] as? String,
            isEdited: isEdited,
            editedAt: editedAt
        )
    }

    // Helper: Format time for display
    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(sentAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(sentAt) {
            return "expert_chat.yesterday".localized
        } else {
            formatter.dateFormat = "dd.MM.yy"
        }

        return formatter.string(from: sentAt)
    }
}
