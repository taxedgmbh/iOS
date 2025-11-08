//
//  Workspace.swift
//  TaxedGmbH_IOS
//
//  Workspace model for collaborative tax filing
//  Enables spouses, partners, or family members to share document access
//

import Foundation
import FirebaseFirestore

/// Workspace member role defining access levels
enum WorkspaceMemberRole: String, Codable {
    case owner = "owner"       // Full control, can delete workspace
    case admin = "admin"       // Can invite/remove members, full document access
    case member = "member"     // Full document access, can upload/edit
    case viewer = "viewer"     // Read-only access
}

/// Workspace type for UI and organization
enum WorkspaceType: String, Codable {
    case personal = "personal"      // Single user workspace (default)
    case joint = "joint"            // Married couples, registered partnerships
    case family = "family"          // Family with multiple members
    case business = "business"      // Business/self-employment workspace
}

/// Represents a workspace member with permissions
struct WorkspaceMember: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let email: String
    let name: String
    let role: WorkspaceMemberRole
    let joinedAt: Date
    var invitedBy: String?  // UserId of who invited this member

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "email": email,
            "name": name,
            "role": role.rawValue,
            "joinedAt": Timestamp(date: joinedAt)
        ]
        if let invitedBy = invitedBy {
            dict["invitedBy"] = invitedBy
        }
        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> WorkspaceMember? {
        guard let userId = dict["userId"] as? String,
              let email = dict["email"] as? String,
              let name = dict["name"] as? String,
              let roleString = dict["role"] as? String,
              let role = WorkspaceMemberRole(rawValue: roleString) else {
            return nil
        }

        let joinedAt: Date
        if let timestamp = dict["joinedAt"] as? Timestamp {
            joinedAt = timestamp.dateValue()
        } else if let date = dict["joinedAt"] as? Date {
            joinedAt = date
        } else {
            joinedAt = Date()
        }

        return WorkspaceMember(
            userId: userId,
            email: email,
            name: name,
            role: role,
            joinedAt: joinedAt,
            invitedBy: dict["invitedBy"] as? String
        )
    }
}

/// Workspace for collaborative tax filing
struct Workspace: Codable, Identifiable {
    var id: String?
    let name: String                    // e.g., "Smith Family Taxes", "My Taxes 2025"
    let type: WorkspaceType
    let ownerId: String                 // User who created the workspace
    var members: [WorkspaceMember]      // All workspace members including owner
    var taxYear: Int                    // Primary tax year for this workspace
    var description: String?            // Optional description
    var isActive: Bool                  // Can be archived
    let createdAt: Date
    var updatedAt: Date

    // Computed property for efficient Firestore queries
    var memberIds: [String] {
        return members.map { $0.userId }
    }

    init(
        id: String? = nil,
        name: String,
        type: WorkspaceType = .personal,
        ownerId: String,
        members: [WorkspaceMember] = [],
        taxYear: Int,
        description: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.ownerId = ownerId
        self.members = members
        self.taxYear = taxYear
        self.description = description
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Check if a user is a member of this workspace
    func isMember(userId: String) -> Bool {
        return members.contains { $0.userId == userId }
    }

    /// Get a specific member
    func getMember(userId: String) -> WorkspaceMember? {
        return members.first { $0.userId == userId }
    }

    /// Check if user has admin or owner privileges
    func hasAdminAccess(userId: String) -> Bool {
        guard let member = getMember(userId: userId) else { return false }
        return member.role == .owner || member.role == .admin
    }

    /// Check if user can edit documents
    func canEditDocuments(userId: String) -> Bool {
        guard let member = getMember(userId: userId) else { return false }
        return member.role == .owner || member.role == .admin || member.role == .member
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "ownerId": ownerId,
            "members": members.map { $0.toDictionary() },
            "memberIds": memberIds,  // For efficient querying
            "taxYear": taxYear,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let id = id { dict["id"] = id }
        if let description = description { dict["description"] = description }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> Workspace? {
        guard let name = dict["name"] as? String,
              let typeString = dict["type"] as? String,
              let type = WorkspaceType(rawValue: typeString),
              let ownerId = dict["ownerId"] as? String,
              let taxYear = dict["taxYear"] as? Int else {
            return nil
        }

        // Parse members array
        var members: [WorkspaceMember] = []
        if let membersArray = dict["members"] as? [[String: Any]] {
            members = membersArray.compactMap { WorkspaceMember.fromDictionary($0) }
        }

        // Parse dates
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

        return Workspace(
            id: dict["id"] as? String,
            name: name,
            type: type,
            ownerId: ownerId,
            members: members,
            taxYear: taxYear,
            description: dict["description"] as? String,
            isActive: dict["isActive"] as? Bool ?? true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Pending invitation to join a workspace
struct WorkspaceInvitation: Codable, Identifiable {
    var id: String?
    let workspaceId: String
    let workspaceName: String
    let invitedEmail: String
    let invitedByUserId: String
    let invitedByName: String
    let role: WorkspaceMemberRole
    var status: InvitationStatus
    let createdAt: Date
    var expiresAt: Date  // Invitations expire after 7 days

    enum InvitationStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
    }

    init(
        id: String? = nil,
        workspaceId: String,
        workspaceName: String,
        invitedEmail: String,
        invitedByUserId: String,
        invitedByName: String,
        role: WorkspaceMemberRole = .member,
        status: InvitationStatus = .pending,
        createdAt: Date = Date(),
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ) {
        self.id = id
        self.workspaceId = workspaceId
        self.workspaceName = workspaceName
        self.invitedEmail = invitedEmail
        self.invitedByUserId = invitedByUserId
        self.invitedByName = invitedByName
        self.role = role
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "workspaceId": workspaceId,
            "workspaceName": workspaceName,
            "invitedEmail": invitedEmail,
            "invitedByUserId": invitedByUserId,
            "invitedByName": invitedByName,
            "role": role.rawValue,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "expiresAt": Timestamp(date: expiresAt)
        ]

        if let id = id { dict["id"] = id }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> WorkspaceInvitation? {
        guard let workspaceId = dict["workspaceId"] as? String,
              let workspaceName = dict["workspaceName"] as? String,
              let invitedEmail = dict["invitedEmail"] as? String,
              let invitedByUserId = dict["invitedByUserId"] as? String,
              let invitedByName = dict["invitedByName"] as? String,
              let roleString = dict["role"] as? String,
              let role = WorkspaceMemberRole(rawValue: roleString),
              let statusString = dict["status"] as? String,
              let status = InvitationStatus(rawValue: statusString) else {
            return nil
        }

        let createdAt: Date
        if let timestamp = dict["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = dict["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }

        let expiresAt: Date
        if let timestamp = dict["expiresAt"] as? Timestamp {
            expiresAt = timestamp.dateValue()
        } else if let date = dict["expiresAt"] as? Date {
            expiresAt = date
        } else {
            expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        }

        return WorkspaceInvitation(
            id: dict["id"] as? String,
            workspaceId: workspaceId,
            workspaceName: workspaceName,
            invitedEmail: invitedEmail,
            invitedByUserId: invitedByUserId,
            invitedByName: invitedByName,
            role: role,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }
}
