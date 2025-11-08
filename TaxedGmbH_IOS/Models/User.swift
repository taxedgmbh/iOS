import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case customer = "customer"
    case expert = "expert"
    case admin = "admin"
}

enum MaritalStatus: String, Codable {
    case single = "single"
    case married = "married"
    case divorced = "divorced"
    case widowed = "widowed"
    case registered_partnership = "registered_partnership"
}

struct User: Codable {
    var id: String?
    let email: String
    var emailVerified: Bool
    let name: String
    let role: UserRole
    var profileImageUrl: String?
    var phone: String?

    // Person 1 Information (Primary taxpayer)
    var person1Name: String?  // Full name of person 1
    var person1AhvNumber: String?  // AHV/AVS for person 1

    // Person 2 Information (Spouse/Partner for joint filing)
    var person2Name: String?  // Full name of spouse/partner
    var person2AhvNumber: String?  // AHV/AVS for spouse/partner

    // Swiss Tax Information
    var ahvNumber: String?  // Deprecated: Use person1AhvNumber instead
    var canton: String?
    var municipality: String?
    var municipalityId: String?  // BFS-Nummer (Official municipality ID)
    var maritalStatus: MaritalStatus?
    var numberOfChildren: Int?

    // Address Information
    var street: String?
    var postalCode: String?
    var city: String?

    // Expert/Admin fields
    var assignedExpertId: String?
    var assignedCustomers: [String]?
    var expertise: [String]?
    var isOnline: Bool?
    var responseTime: Int?

    // Profile Versioning (Phase 2: Versioning)
    var profileVersion: Int  // Incremented on profile changes to trigger PDF regeneration
    var profileLastUpdatedAt: Date  // When profile was last modified

    // Workspace Management (Collaborative Tax Filing)
    var workspaceIds: [String]?  // All workspaces this user is a member of
    var activeWorkspaceId: String?  // Currently selected workspace for document viewing

    let createdAt: Date
    var updatedAt: Date
    var lastLoginAt: Date?

    init(
        id: String? = nil,
        email: String,
        emailVerified: Bool = false,
        name: String,
        role: UserRole = .customer,
        profileImageUrl: String? = nil,
        phone: String? = nil,
        person1Name: String? = nil,
        person1AhvNumber: String? = nil,
        person2Name: String? = nil,
        person2AhvNumber: String? = nil,
        ahvNumber: String? = nil,
        canton: String? = nil,
        municipality: String? = nil,
        municipalityId: String? = nil,
        maritalStatus: MaritalStatus? = nil,
        numberOfChildren: Int? = nil,
        street: String? = nil,
        postalCode: String? = nil,
        city: String? = nil,
        assignedExpertId: String? = nil,
        assignedCustomers: [String]? = nil,
        expertise: [String]? = nil,
        isOnline: Bool? = nil,
        responseTime: Int? = nil,
        profileVersion: Int = 1,
        profileLastUpdatedAt: Date = Date(),
        workspaceIds: [String]? = nil,
        activeWorkspaceId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastLoginAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.emailVerified = emailVerified
        self.name = name
        self.role = role
        self.profileImageUrl = profileImageUrl
        self.phone = phone
        self.person1Name = person1Name
        self.person1AhvNumber = person1AhvNumber
        self.person2Name = person2Name
        self.person2AhvNumber = person2AhvNumber
        self.ahvNumber = ahvNumber
        self.canton = canton
        self.municipality = municipality
        self.municipalityId = municipalityId
        self.maritalStatus = maritalStatus
        self.numberOfChildren = numberOfChildren
        self.street = street
        self.postalCode = postalCode
        self.city = city
        self.assignedExpertId = assignedExpertId
        self.assignedCustomers = assignedCustomers
        self.expertise = expertise
        self.isOnline = isOnline
        self.responseTime = responseTime
        self.profileVersion = profileVersion
        self.profileLastUpdatedAt = profileLastUpdatedAt
        self.workspaceIds = workspaceIds
        self.activeWorkspaceId = activeWorkspaceId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLoginAt = lastLoginAt
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "emailVerified": emailVerified,
            "name": name,
            "role": role.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let id = id { dict["id"] = id }
        if let profileImageUrl = profileImageUrl { dict["profileImageUrl"] = profileImageUrl }
        if let phone = phone { dict["phone"] = phone }
        if let person1Name = person1Name { dict["person1Name"] = person1Name }
        if let person1AhvNumber = person1AhvNumber { dict["person1AhvNumber"] = person1AhvNumber }
        if let person2Name = person2Name { dict["person2Name"] = person2Name }
        if let person2AhvNumber = person2AhvNumber { dict["person2AhvNumber"] = person2AhvNumber }
        if let ahvNumber = ahvNumber { dict["ahvNumber"] = ahvNumber }
        if let canton = canton { dict["canton"] = canton }
        if let municipality = municipality { dict["municipality"] = municipality }
        if let municipalityId = municipalityId { dict["municipalityId"] = municipalityId }
        if let maritalStatus = maritalStatus { dict["maritalStatus"] = maritalStatus.rawValue }
        if let numberOfChildren = numberOfChildren { dict["numberOfChildren"] = numberOfChildren }
        if let street = street { dict["street"] = street }
        if let postalCode = postalCode { dict["postalCode"] = postalCode }
        if let city = city { dict["city"] = city }
        if let assignedExpertId = assignedExpertId { dict["assignedExpertId"] = assignedExpertId }
        if let assignedCustomers = assignedCustomers { dict["assignedCustomers"] = assignedCustomers }
        if let expertise = expertise { dict["expertise"] = expertise }
        if let isOnline = isOnline { dict["isOnline"] = isOnline }
        if let responseTime = responseTime { dict["responseTime"] = responseTime }

        // Profile Versioning
        dict["profileVersion"] = profileVersion
        dict["profileLastUpdatedAt"] = Timestamp(date: profileLastUpdatedAt)

        // Workspace Management
        if let workspaceIds = workspaceIds { dict["workspaceIds"] = workspaceIds }
        if let activeWorkspaceId = activeWorkspaceId { dict["activeWorkspaceId"] = activeWorkspaceId }

        // Last Login
        if let lastLoginAt = lastLoginAt { dict["lastLoginAt"] = Timestamp(date: lastLoginAt) }

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

        // Parse marital status
        let maritalStatus: MaritalStatus?
        if let maritalStatusString = dict["maritalStatus"] as? String {
            maritalStatus = MaritalStatus(rawValue: maritalStatusString)
        } else {
            maritalStatus = nil
        }

        // Parse profile versioning
        let profileVersion = dict["profileVersion"] as? Int ?? 1
        let profileLastUpdatedAt: Date
        if let timestamp = dict["profileLastUpdatedAt"] as? Timestamp {
            profileLastUpdatedAt = timestamp.dateValue()
        } else if let date = dict["profileLastUpdatedAt"] as? Date {
            profileLastUpdatedAt = date
        } else {
            profileLastUpdatedAt = Date()
        }

        let lastLoginAt: Date?
        if let timestamp = dict["lastLoginAt"] as? Timestamp {
            lastLoginAt = timestamp.dateValue()
        } else if let date = dict["lastLoginAt"] as? Date {
            lastLoginAt = date
        } else {
            lastLoginAt = nil
        }

        let user = User(
            id: dict["id"] as? String,
            email: email,
            emailVerified: dict["emailVerified"] as? Bool ?? false,
            name: name,
            role: role,
            profileImageUrl: dict["profileImageUrl"] as? String,
            phone: dict["phone"] as? String,
            person1Name: dict["person1Name"] as? String,
            person1AhvNumber: dict["person1AhvNumber"] as? String,
            person2Name: dict["person2Name"] as? String,
            person2AhvNumber: dict["person2AhvNumber"] as? String,
            ahvNumber: dict["ahvNumber"] as? String,
            canton: dict["canton"] as? String,
            municipality: dict["municipality"] as? String,
            municipalityId: dict["municipalityId"] as? String,
            maritalStatus: maritalStatus,
            numberOfChildren: dict["numberOfChildren"] as? Int,
            street: dict["street"] as? String,
            postalCode: dict["postalCode"] as? String,
            city: dict["city"] as? String,
            assignedExpertId: dict["assignedExpertId"] as? String,
            assignedCustomers: dict["assignedCustomers"] as? [String],
            expertise: dict["expertise"] as? [String],
            isOnline: dict["isOnline"] as? Bool,
            responseTime: dict["responseTime"] as? Int,
            profileVersion: profileVersion,
            profileLastUpdatedAt: profileLastUpdatedAt,
            workspaceIds: dict["workspaceIds"] as? [String],
            activeWorkspaceId: dict["activeWorkspaceId"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastLoginAt: lastLoginAt
        )

        return user
    }
}