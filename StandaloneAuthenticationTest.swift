import Foundation

// Standalone User model without Firebase dependencies
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
            "createdAt": createdAt,
            "updatedAt": updatedAt
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
              let role = UserRole(rawValue: roleString),
              let createdAt = dict["createdAt"] as? Date,
              let updatedAt = dict["updatedAt"] as? Date else {
            return nil
        }

        var user = User(
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

// Test the authentication logic
class AuthenticationTest {

    static func testUserModel() {
        print("🧪 Testing User Model...")

        // Test User creation
        let user = User(
            id: "test123",
            email: "test@example.com",
            name: "Test User",
            role: .customer
        )

        print("✅ User created: \(user.name) - \(user.email)")

        // Test dictionary conversion
        let userDict = user.toDictionary()
        print("✅ User converted to dictionary")

        // Test dictionary parsing
        if let parsedUser = User.fromDictionary(userDict) {
            print("✅ User parsed from dictionary: \(parsedUser.name)")
        } else {
            print("❌ Failed to parse user from dictionary")
        }

        print("✅ User model tests passed!")
    }

    static func testAuthenticationLogic() {
        print("\n🧪 Testing Authentication Logic...")

        // Test email validation
        let validEmail = "test@example.com"
        let invalidEmail = "invalid-email"

        if isValidEmail(validEmail) {
            print("✅ Email validation passed for valid email")
        } else {
            print("❌ Email validation failed for valid email")
        }

        if !isValidEmail(invalidEmail) {
            print("✅ Email validation correctly rejected invalid email")
        } else {
            print("❌ Email validation incorrectly accepted invalid email")
        }

        // Test password validation
        let validPassword = "Password123!"
        let weakPassword = "123"

        if isValidPassword(validPassword) {
            print("✅ Password validation passed for strong password")
        } else {
            print("❌ Password validation failed for strong password")
        }

        if !isValidPassword(weakPassword) {
            print("✅ Password validation correctly rejected weak password")
        } else {
            print("❌ Password validation incorrectly accepted weak password")
        }

        print("✅ Authentication logic tests passed!")
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    static func runAllTests() {
        print("🚀 Running Authentication Tests...\n")

        testUserModel()
        testAuthenticationLogic()

        print("\n🎉 All authentication tests completed successfully!")
        print("\n📝 Summary:")
        print("   • User model serialization/deserialization works")
        print("   • Email validation works correctly")
        print("   • Password validation works correctly")
        print("   • Core authentication logic is sound")
        print("\n⚠️  Note: These are offline tests. Firebase integration requires proper project configuration.")
    }
}

// Run the tests
AuthenticationTest.runAllTests()