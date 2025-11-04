//
//  Conversation.swift
//  TaxedGmbH_IOS
//
//  Conversation model for expert-customer chat threads
//

import Foundation
import FirebaseFirestore

enum ConversationStatus: String, Codable {
    case active = "active"
    case archived = "archived"
    case closed = "closed"
}

struct Conversation: Codable, Identifiable {
    var id: String
    let customerId: String
    let customerName: String
    let expertId: String
    let expertName: String
    let expertImageUrl: String?

    // Conversation State
    var status: ConversationStatus
    var lastMessage: String?
    var lastMessageAt: Date?
    var lastMessageSenderId: String?

    // Unread counts
    var unreadCountCustomer: Int // Unread messages for customer
    var unreadCountExpert: Int // Unread messages for expert

    // Metadata
    let taxYear: Int
    let createdAt: Date
    var updatedAt: Date

    // Expert info for customer display
    var expertLanguages: [String]? // e.g., ["de", "en", "fr"]
    var expertSpecialization: [String]? // e.g., ["expat", "cross-border"]

    init(
        id: String = UUID().uuidString,
        customerId: String,
        customerName: String,
        expertId: String,
        expertName: String,
        expertImageUrl: String? = nil,
        status: ConversationStatus = .active,
        lastMessage: String? = nil,
        lastMessageAt: Date? = nil,
        lastMessageSenderId: String? = nil,
        unreadCountCustomer: Int = 0,
        unreadCountExpert: Int = 0,
        taxYear: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expertLanguages: [String]? = nil,
        expertSpecialization: [String]? = nil
    ) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.expertId = expertId
        self.expertName = expertName
        self.expertImageUrl = expertImageUrl
        self.status = status
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCountCustomer = unreadCountCustomer
        self.unreadCountExpert = unreadCountExpert
        self.taxYear = taxYear
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expertLanguages = expertLanguages
        self.expertSpecialization = expertSpecialization
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "customerId": customerId,
            "customerName": customerName,
            "expertId": expertId,
            "expertName": expertName,
            "status": status.rawValue,
            "unreadCountCustomer": unreadCountCustomer,
            "unreadCountExpert": unreadCountExpert,
            "taxYear": taxYear,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let expertImageUrl = expertImageUrl { dict["expertImageUrl"] = expertImageUrl }
        if let lastMessage = lastMessage { dict["lastMessage"] = lastMessage }
        if let lastMessageAt = lastMessageAt { dict["lastMessageAt"] = Timestamp(date: lastMessageAt) }
        if let lastMessageSenderId = lastMessageSenderId { dict["lastMessageSenderId"] = lastMessageSenderId }
        if let expertLanguages = expertLanguages { dict["expertLanguages"] = expertLanguages }
        if let expertSpecialization = expertSpecialization { dict["expertSpecialization"] = expertSpecialization }

        return dict
    }

    // Create from Firestore dictionary
    static func fromDictionary(id: String, data: [String: Any]) -> Conversation? {
        guard let customerId = data["customerId"] as? String,
              let customerName = data["customerName"] as? String,
              let expertId = data["expertId"] as? String,
              let expertName = data["expertName"] as? String,
              let statusString = data["status"] as? String,
              let status = ConversationStatus(rawValue: statusString),
              let unreadCountCustomer = data["unreadCountCustomer"] as? Int,
              let unreadCountExpert = data["unreadCountExpert"] as? Int,
              let taxYear = data["taxYear"] as? Int else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let lastMessageAt = (data["lastMessageAt"] as? Timestamp)?.dateValue()

        return Conversation(
            id: id,
            customerId: customerId,
            customerName: customerName,
            expertId: expertId,
            expertName: expertName,
            expertImageUrl: data["expertImageUrl"] as? String,
            status: status,
            lastMessage: data["lastMessage"] as? String,
            lastMessageAt: lastMessageAt,
            lastMessageSenderId: data["lastMessageSenderId"] as? String,
            unreadCountCustomer: unreadCountCustomer,
            unreadCountExpert: unreadCountExpert,
            taxYear: taxYear,
            createdAt: createdAt,
            updatedAt: updatedAt,
            expertLanguages: data["expertLanguages"] as? [String],
            expertSpecialization: data["expertSpecialization"] as? [String]
        )
    }

    // Helper: Get language flags for display
    var languageFlags: String {
        guard let languages = expertLanguages else { return "" }
        return languages.compactMap { code in
            switch code.lowercased() {
            case "de": return "🇩🇪"
            case "en": return "🇬🇧"
            case "fr": return "🇫🇷"
            case "it": return "🇮🇹"
            default: return nil
            }
        }.joined(separator: " ")
    }

    // Helper: Has unread messages for customer
    var hasUnread: Bool {
        unreadCountCustomer > 0
    }
}
