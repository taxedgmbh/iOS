import Foundation

/// Temporary in-memory database service
/// This is a TEMPORARY solution until MongoDB is properly integrated
/// DO NOT use in production - data is not persisted
@MainActor
class TemporaryDatabaseService {
    static let shared = TemporaryDatabaseService()

    // In-memory storage
    private var users: [String: [String: Any]] = [:]

    private init() {
        // Only log when actually being used
    }

    // MARK: - User Operations

    func userExists(userId: String) -> Bool {
        return users[userId] != nil
    }

    func createUser(userId: String, data: [String: Any]) throws {
        print("⚠️ Using TEMPORARY in-memory storage (not persisted)")
        print("💾 Creating user in temporary storage: \(userId)")
        users[userId] = data
    }

    func getUser(userId: String) -> [String: Any]? {
        print("📖 Fetching user from temporary storage: \(userId)")
        return users[userId]
    }

    func updateUser(userId: String, data: [String: Any]) throws {
        print("✏️ Updating user in temporary storage: \(userId)")
        users[userId] = data
    }

    func deleteUser(userId: String) {
        print("🗑️ Deleting user from temporary storage: \(userId)")
        users.removeValue(forKey: userId)
    }

    // MARK: - Debug

    func printAllUsers() {
        print("📊 Users in temporary storage: \(users.count)")
        for (id, _) in users {
            print("  - User ID: \(id)")
        }
    }
}
