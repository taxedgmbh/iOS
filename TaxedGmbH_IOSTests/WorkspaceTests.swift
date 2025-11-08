//
//  WorkspaceTests.swift
//  TaxedGmbH_IOSTests
//
//  Comprehensive workspace database functionality tests
//

import XCTest
@testable import TaxedGmbH_IOS

final class WorkspaceTests: XCTestCase {

    // MARK: - Workspace Model Tests

    func testWorkspaceMemberIdsComputedProperty() {
        // Given: A workspace with 3 members
        let member1 = WorkspaceMember(
            userId: "user1",
            email: "user1@test.com",
            name: "User 1",
            role: .owner,
            joinedAt: Date()
        )
        let member2 = WorkspaceMember(
            userId: "user2",
            email: "user2@test.com",
            name: "User 2",
            role: .member,
            joinedAt: Date()
        )
        let member3 = WorkspaceMember(
            userId: "user3",
            email: "user3@test.com",
            name: "User 3",
            role: .viewer,
            joinedAt: Date()
        )

        let workspace = Workspace(
            name: "Test Workspace",
            ownerId: "user1",
            members: [member1, member2, member3],
            taxYear: 2024
        )

        // When: Accessing memberIds
        let memberIds = workspace.memberIds

        // Then: Should contain all user IDs
        XCTAssertEqual(memberIds.count, 3, "Should have 3 member IDs")
        XCTAssertTrue(memberIds.contains("user1"), "Should contain user1")
        XCTAssertTrue(memberIds.contains("user2"), "Should contain user2")
        XCTAssertTrue(memberIds.contains("user3"), "Should contain user3")
    }

    func testWorkspaceIsMember() {
        // Given: A workspace with specific members
        let owner = WorkspaceMember(
            userId: "owner123",
            email: "owner@test.com",
            name: "Owner",
            role: .owner,
            joinedAt: Date()
        )
        let member = WorkspaceMember(
            userId: "member456",
            email: "member@test.com",
            name: "Member",
            role: .member,
            joinedAt: Date()
        )

        let workspace = Workspace(
            name: "Test Workspace",
            ownerId: "owner123",
            members: [owner, member],
            taxYear: 2024
        )

        // When/Then: Check membership
        XCTAssertTrue(workspace.isMember(userId: "owner123"), "Owner should be a member")
        XCTAssertTrue(workspace.isMember(userId: "member456"), "Member should be a member")
        XCTAssertFalse(workspace.isMember(userId: "stranger789"), "Stranger should not be a member")
    }

    func testWorkspaceHasAdminAccess() {
        // Given: A workspace with owner and admin
        let owner = WorkspaceMember(
            userId: "owner123",
            email: "owner@test.com",
            name: "Owner",
            role: .owner,
            joinedAt: Date()
        )
        let admin = WorkspaceMember(
            userId: "admin456",
            email: "admin@test.com",
            name: "Admin",
            role: .admin,
            joinedAt: Date()
        )
        let member = WorkspaceMember(
            userId: "member789",
            email: "member@test.com",
            name: "Member",
            role: .member,
            joinedAt: Date()
        )
        let viewer = WorkspaceMember(
            userId: "viewer012",
            email: "viewer@test.com",
            name: "Viewer",
            role: .viewer,
            joinedAt: Date()
        )

        let workspace = Workspace(
            name: "Test Workspace",
            ownerId: "owner123",
            members: [owner, admin, member, viewer],
            taxYear: 2024
        )

        // When/Then: Check admin access
        XCTAssertTrue(workspace.hasAdminAccess(userId: "owner123"), "Owner should have admin access")
        XCTAssertTrue(workspace.hasAdminAccess(userId: "admin456"), "Admin should have admin access")
        XCTAssertFalse(workspace.hasAdminAccess(userId: "member789"), "Member should not have admin access")
        XCTAssertFalse(workspace.hasAdminAccess(userId: "viewer012"), "Viewer should not have admin access")
    }

    func testWorkspaceCanEditDocuments() {
        // Given: A workspace with different roles
        let owner = WorkspaceMember(
            userId: "owner123",
            email: "owner@test.com",
            name: "Owner",
            role: .owner,
            joinedAt: Date()
        )
        let admin = WorkspaceMember(
            userId: "admin456",
            email: "admin@test.com",
            name: "Admin",
            role: .admin,
            joinedAt: Date()
        )
        let member = WorkspaceMember(
            userId: "member789",
            email: "member@test.com",
            name: "Member",
            role: .member,
            joinedAt: Date()
        )
        let viewer = WorkspaceMember(
            userId: "viewer012",
            email: "viewer@test.com",
            name: "Viewer",
            role: .viewer,
            joinedAt: Date()
        )

        let workspace = Workspace(
            name: "Test Workspace",
            ownerId: "owner123",
            members: [owner, admin, member, viewer],
            taxYear: 2024
        )

        // When/Then: Check document edit permissions
        XCTAssertTrue(workspace.canEditDocuments(userId: "owner123"), "Owner should be able to edit")
        XCTAssertTrue(workspace.canEditDocuments(userId: "admin456"), "Admin should be able to edit")
        XCTAssertTrue(workspace.canEditDocuments(userId: "member789"), "Member should be able to edit")
        XCTAssertFalse(workspace.canEditDocuments(userId: "viewer012"), "Viewer should not be able to edit")
    }

    func testWorkspaceToDictionary() {
        // Given: A workspace with members
        let member = WorkspaceMember(
            userId: "user123",
            email: "user@test.com",
            name: "User",
            role: .owner,
            joinedAt: Date()
        )

        let workspace = Workspace(
            id: "workspace123",
            name: "My Workspace",
            type: .personal,
            ownerId: "user123",
            members: [member],
            taxYear: 2024,
            description: "Test workspace"
        )

        // When: Converting to dictionary
        let dict = workspace.toDictionary()

        // Then: Should include all required fields
        XCTAssertEqual(dict["id"] as? String, "workspace123")
        XCTAssertEqual(dict["name"] as? String, "My Workspace")
        XCTAssertEqual(dict["type"] as? String, "personal")
        XCTAssertEqual(dict["ownerId"] as? String, "user123")
        XCTAssertEqual(dict["taxYear"] as? Int, 2024)
        XCTAssertEqual(dict["description"] as? String, "Test workspace")
        XCTAssertEqual(dict["isActive"] as? Bool, true)

        // Critical: Check memberIds array
        let memberIds = dict["memberIds"] as? [String]
        XCTAssertNotNil(memberIds, "memberIds should be present in dictionary")
        XCTAssertEqual(memberIds?.count, 1, "memberIds should have 1 element")
        XCTAssertEqual(memberIds?.first, "user123", "memberIds should contain user123")
    }

    // MARK: - Workspace Member Tests

    func testWorkspaceMemberToDictionary() {
        // Given: A workspace member
        let member = WorkspaceMember(
            userId: "user123",
            email: "user@test.com",
            name: "Test User",
            role: .admin,
            joinedAt: Date(),
            invitedBy: "inviter456"
        )

        // When: Converting to dictionary
        let dict = member.toDictionary()

        // Then: Should include all fields
        XCTAssertEqual(dict["userId"] as? String, "user123")
        XCTAssertEqual(dict["email"] as? String, "user@test.com")
        XCTAssertEqual(dict["name"] as? String, "Test User")
        XCTAssertEqual(dict["role"] as? String, "admin")
        XCTAssertEqual(dict["invitedBy"] as? String, "inviter456")
        XCTAssertNotNil(dict["joinedAt"])
    }

    // MARK: - TaxDocument Model Tests

    func testTaxDocumentWorkspaceIdSerialization() {
        // Given: A document with workspace ID
        let document = TaxDocument(
            id: "doc123",
            customerId: "user123",
            workspaceId: "workspace456",
            name: "test.pdf",
            storageUrl: "https://example.com/test.pdf",
            taxYear: 2024
        )

        // When: Converting to dictionary
        let dict = document.toDictionary()

        // Then: Should include workspaceId
        XCTAssertEqual(dict["workspaceId"] as? String, "workspace456", "workspaceId should be in dictionary")
        XCTAssertEqual(dict["customerId"] as? String, "user123")
    }

    func testTaxDocumentWorkspaceIdDeserialization() {
        // Given: A dictionary with workspaceId
        let dict: [String: Any] = [
            "customerId": "user123",
            "workspaceId": "workspace456",
            "name": "test.pdf",
            "storageUrl": "https://example.com/test.pdf",
            "status": "pending",
            "taxYear": 2024,
            "category": "income"
        ]

        // When: Creating document from dictionary
        let document = TaxDocument.fromDictionary(id: "doc123", data: dict)

        // Then: Should parse workspaceId
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.workspaceId, "workspace456", "workspaceId should be parsed")
        XCTAssertEqual(document?.customerId, "user123")
    }

    // MARK: - User Model Tests

    func testUserWorkspaceFieldsSerialization() {
        // Given: A user with workspace data
        var user = User(
            id: "user123",
            email: "user@test.com",
            name: "Test User"
        )
        user.workspaceIds = ["workspace1", "workspace2", "workspace3"]
        user.activeWorkspaceId = "workspace2"

        // When: Converting to dictionary
        let dict = user.toDictionary()

        // Then: Should include workspace fields
        let workspaceIds = dict["workspaceIds"] as? [String]
        XCTAssertEqual(workspaceIds?.count, 3, "Should have 3 workspace IDs")
        XCTAssertEqual(dict["activeWorkspaceId"] as? String, "workspace2")
    }

    func testUserWorkspaceFieldsDeserialization() {
        // Given: A dictionary with workspace data
        let dict: [String: Any] = [
            "id": "user123",
            "email": "user@test.com",
            "name": "Test User",
            "role": "customer",
            "workspaceIds": ["workspace1", "workspace2"],
            "activeWorkspaceId": "workspace1"
        ]

        // When: Creating user from dictionary
        let user = User.fromDictionary(dict)

        // Then: Should parse workspace fields
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.workspaceIds?.count, 2)
        XCTAssertEqual(user?.activeWorkspaceId, "workspace1")
    }

    // MARK: - Workspace Invitation Tests

    func testWorkspaceInvitationIsExpired() {
        // Given: An expired invitation
        let calendar = Calendar.current
        let expiredDate = calendar.date(byAdding: .day, value: -8, to: Date())!

        let expiredInvitation = WorkspaceInvitation(
            workspaceId: "workspace123",
            workspaceName: "Test Workspace",
            invitedEmail: "invitee@test.com",
            invitedByUserId: "inviter123",
            invitedByName: "Inviter",
            expiresAt: expiredDate
        )

        // When: Checking if expired
        let isExpired = expiredInvitation.isExpired

        // Then: Should be expired
        XCTAssertTrue(isExpired, "Invitation should be expired")

        // Given: A valid invitation
        let validDate = calendar.date(byAdding: .day, value: 5, to: Date())!
        let validInvitation = WorkspaceInvitation(
            workspaceId: "workspace123",
            workspaceName: "Test Workspace",
            invitedEmail: "invitee@test.com",
            invitedByUserId: "inviter123",
            invitedByName: "Inviter",
            expiresAt: validDate
        )

        // When: Checking if expired
        let isValid = !validInvitation.isExpired

        // Then: Should not be expired
        XCTAssertTrue(isValid, "Invitation should still be valid")
    }

    // MARK: - Integration Tests

    func testWorkspaceCreationFlow() {
        // Given: A user creating their first workspace
        let user = User(
            id: "user123",
            email: "user@test.com",
            name: "Test User"
        )

        // When: Creating a workspace
        let ownerMember = WorkspaceMember(
            userId: user.id!,
            email: user.email,
            name: user.name,
            role: .owner,
            joinedAt: Date()
        )

        let workspace = Workspace(
            name: "My First Workspace",
            type: .personal,
            ownerId: user.id!,
            members: [ownerMember],
            taxYear: 2024
        )

        // Then: Workspace should be properly configured
        XCTAssertEqual(workspace.members.count, 1)
        XCTAssertEqual(workspace.memberIds.count, 1)
        XCTAssertEqual(workspace.memberIds.first, user.id)
        XCTAssertTrue(workspace.isMember(userId: user.id!))
        XCTAssertTrue(workspace.hasAdminAccess(userId: user.id!))
        XCTAssertTrue(workspace.canEditDocuments(userId: user.id!))
    }

    func testMultiMemberWorkspace() {
        // Given: A joint workspace with spouse
        let person1 = WorkspaceMember(
            userId: "person1",
            email: "person1@test.com",
            name: "Person 1",
            role: .owner,
            joinedAt: Date()
        )

        let person2 = WorkspaceMember(
            userId: "person2",
            email: "person2@test.com",
            name: "Person 2",
            role: .member,
            joinedAt: Date(),
            invitedBy: "person1"
        )

        let workspace = Workspace(
            name: "Family Taxes 2024",
            type: .joint,
            ownerId: "person1",
            members: [person1, person2],
            taxYear: 2024
        )

        // Then: Both members should have access
        XCTAssertEqual(workspace.memberIds.count, 2)
        XCTAssertTrue(workspace.isMember(userId: "person1"))
        XCTAssertTrue(workspace.isMember(userId: "person2"))
        XCTAssertTrue(workspace.canEditDocuments(userId: "person1"))
        XCTAssertTrue(workspace.canEditDocuments(userId: "person2"))

        // Only owner should have admin access
        XCTAssertTrue(workspace.hasAdminAccess(userId: "person1"))
        XCTAssertFalse(workspace.hasAdminAccess(userId: "person2"))
    }
}
