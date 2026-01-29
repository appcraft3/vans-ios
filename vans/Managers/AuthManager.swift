import Foundation
import Combine
import FirebaseAuth

// MARK: - Response Models

struct CreateSessionResponse: Codable {
    let success: Bool
    let token: String
    let userId: String
    let isNewUser: Bool
}

struct GetUserResponse: Codable {
    let success: Bool
    let user: UserData
}

struct DeleteUserResponse: Codable {
    let success: Bool
    let message: String
}

struct UserData: Codable {
    let id: String
    let displayName: String?
    let avatarUrl: String?
    let email: String?
    let isNewUser: Bool

    enum CodingKeys: String, CodingKey {
        case id, displayName, avatarUrl, email, isNewUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        isNewUser = try container.decodeIfPresent(Bool.self, forKey: .isNewUser) ?? false
    }

    init(id: String, displayName: String?, avatarUrl: String?, email: String?, isNewUser: Bool) {
        self.id = id
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.email = email
        self.isNewUser = isNewUser
    }
}

// MARK: - AuthManager

final class AuthManager {

    static let shared = AuthManager()

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        setupAuthStateListener()
    }

    var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    var currentFirebaseUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            self?.currentUserId = user?.uid
        }
    }

    // MARK: - Session Management

    func createSession() async throws -> UserData {
        // Call cloud function to create session
        let response: CreateSessionResponse = try await FirebaseManager.shared.callFunction(name: "createSession")

        // Sign in with custom token
        try await Auth.auth().signIn(withCustomToken: response.token)

        // Get full user data
        return try await getUser()
    }

    func refreshAuthToken() async throws {
        guard let user = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }

        // Force token refresh
        _ = try await user.getIDTokenResult(forcingRefresh: true)
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        currentUserId = nil
    }

    func getUser() async throws -> UserData {
        let response: GetUserResponse = try await FirebaseManager.shared.callFunction(name: "getUser")
        return response.user
    }

    func updateUser(displayName: String? = nil, avatarUrl: String? = nil, email: String? = nil) async throws -> UserData {
        var data: [String: Any] = [:]
        if let displayName = displayName { data["displayName"] = displayName }
        if let avatarUrl = avatarUrl { data["avatarUrl"] = avatarUrl }
        if let email = email { data["email"] = email }

        let response: GetUserResponse = try await FirebaseManager.shared.callFunction(name: "updateUser", data: data)
        return response.user
    }

    func deleteUser() async throws {
        let _: DeleteUserResponse = try await FirebaseManager.shared.callFunction(name: "deleteUser")
        try await signOut()
    }
}
