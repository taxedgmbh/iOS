import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case customer = "customer"
    case expert = "expert"
    case admin = "admin"
}

struct User: Codable {
    var id: String?
    let email: String
    let name: String
    let role: UserRole
    var profileImageUrl: String?
    var phone: String?
    var assignedExpertId: String?
    var canton: String?
    var municipality: String?
    var assignedCustomers: [String]?
    var expertise: [String]?
    var isOnline: Bool?
    var responseTime: Int?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        email: String,
        name: String,
        role: UserRole = .customer,
        profileImageUrl: String? = nil,
        phone: String? = nil,
        assignedExpertId: String? = nil,
        canton: String? = nil,
        municipality: String? = nil,
        assignedCustomers: [String]? = nil,
        expertise: [String]? = nil,
        isOnline: Bool? = nil,
        responseTime: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.profileImageUrl = profileImageUrl
        self.phone = phone
        self.assignedExpertId = assignedExpertId
        self.canton = canton
        self.municipality = municipality
        self.assignedCustomers = assignedCustomers
        self.expertise = expertise
        self.isOnline = isOnline
        self.responseTime = responseTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "name": name,
            "role": role.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let id = id { dict["id"] = id }
        if let profileImageUrl = profileImageUrl { dict["profileImageUrl"] = profileImageUrl }
        if let phone = phone { dict["phone"] = phone }
        if let assignedExpertId = assignedExpertId { dict["assignedExpertId"] = assignedExpertId }
        if let canton = canton { dict["canton"] = canton }
        if let municipality = municipality { dict["municipality"] = municipality }
        if let assignedCustomers = assignedCustomers { dict["assignedCustomers"] = assignedCustomers }
        if let expertise = expertise { dict["expertise"] = expertise }
        if let isOnline = isOnline { dict["isOnline"] = isOnline }
        if let responseTime = responseTime { dict["responseTime"] = responseTime }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> User? {
        guard let email = dict["email"] as? String,
              let name = dict["name"] as? String,
              let roleString = dict["role"] as? String,
              let role = UserRole(rawValue: roleString) else {
            return nil
        }

        // Handle Firestore Timestamp conversion
        let createdAt: Date
        if let timestamp = dict["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = dict["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }

        let updatedAt: Date
        if let timestamp = dict["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else if let date = dict["updatedAt"] as? Date {
            updatedAt = date
        } else {
            updatedAt = Date()
        }

        let user = User(
            id: dict["id"] as? String,
            email: email,
            name: name,
            role: role,
            profileImageUrl: dict["profileImageUrl"] as? String,
            phone: dict["phone"] as? String,
            assignedExpertId: dict["assignedExpertId"] as? String,
            canton: dict["canton"] as? String,
            municipality: dict["municipality"] as? String,
            assignedCustomers: dict["assignedCustomers"] as? [String],
            expertise: dict["expertise"] as? [String],
            isOnline: dict["isOnline"] as? Bool,
            responseTime: dict["responseTime"] as? Int,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        return user
    }
}