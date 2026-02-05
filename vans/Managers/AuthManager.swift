import Foundation
import Combine
import FirebaseAuth

// MARK: - Response Models

struct GetUserResponse: Codable {
    let success: Bool
    let user: UserData
}

struct DeleteUserResponse: Codable {
    let success: Bool
    let message: String
}

struct SubmitProfileResponse: Codable {
    let success: Bool
    let user: UserData
}

struct WaitlistStatusResponse: Codable {
    let success: Bool
    let accessLevel: AccessLevel
    let reviewStatus: ReviewStatus
    let position: Int?
    let totalPending: Int
}

struct UseInviteCodeResponse: Codable {
    let success: Bool
    let message: String
    let accessLevel: AccessLevel
    let role: UserRole
}

struct SubmitWaitlistResponse: Codable {
    let success: Bool
    let message: String
    let status: String
}

// MARK: - UserData

struct UserData: Codable {
    let id: String
    let email: String?
    let accessLevel: AccessLevel
    let role: UserRole
    let profile: UserProfile?
    let trust: TrustInfo
    let reviewStatus: ReviewStatus
    let isPremium: Bool
    let inviteCode: String?
    let isNewUser: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, accessLevel, role, profile, trust, reviewStatus, isPremium, inviteCode, isNewUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        accessLevel = try container.decodeIfPresent(AccessLevel.self, forKey: .accessLevel) ?? .guest
        role = try container.decodeIfPresent(UserRole.self, forKey: .role) ?? .user
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
        trust = try container.decodeIfPresent(TrustInfo.self, forKey: .trust) ?? .empty
        reviewStatus = try container.decodeIfPresent(ReviewStatus.self, forKey: .reviewStatus) ?? .none
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        inviteCode = try container.decodeIfPresent(String.self, forKey: .inviteCode)
        isNewUser = try container.decodeIfPresent(Bool.self, forKey: .isNewUser)
    }

    init(id: String, email: String?, accessLevel: AccessLevel, role: UserRole, profile: UserProfile?, trust: TrustInfo, reviewStatus: ReviewStatus, isPremium: Bool, inviteCode: String?, isNewUser: Bool?) {
        self.id = id
        self.email = email
        self.accessLevel = accessLevel
        self.role = role
        self.profile = profile
        self.trust = trust
        self.reviewStatus = reviewStatus
        self.isPremium = isPremium
        self.inviteCode = inviteCode
        self.isNewUser = isNewUser
    }

    // Convenience properties
    var displayName: String? {
        profile?.firstName
    }

    var photoUrl: String? {
        profile?.photoUrl
    }

    var hasCompletedProfile: Bool {
        profile != nil
    }

    var isMember: Bool {
        accessLevel == .member || accessLevel == .premium
    }
}

// MARK: - AuthManager

final class AuthManager {

    static let shared = AuthManager()

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var currentUser: UserData?

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

    func refreshAuthToken() async throws {
        guard let user = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        _ = try await user.getIDTokenResult(forcingRefresh: true)
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        currentUserId = nil
        currentUser = nil
    }

    func getUser() async throws -> UserData {
        let response: GetUserResponse = try await FirebaseManager.shared.callFunction(name: "getUser")
        await MainActor.run {
            self.currentUser = response.user
        }
        return response.user
    }

    func deleteUser() async throws {
        let _: DeleteUserResponse = try await FirebaseManager.shared.callFunction(name: "deleteUser")
        try await signOut()
    }

    // MARK: - Profile Management

    func submitProfile(
        firstName: String,
        photoUrl: String,
        age: Int,
        gender: Gender,
        vanLifeStatus: VanLifeStatus,
        region: String,
        activities: [String],
        bio: String?
    ) async throws -> UserData {
        let data: [String: Any] = [
            "firstName": firstName,
            "photoUrl": photoUrl,
            "age": age,
            "gender": gender.rawValue,
            "vanLifeStatus": vanLifeStatus.rawValue,
            "region": region,
            "activities": activities,
            "bio": bio ?? ""
        ]

        let response: SubmitProfileResponse = try await FirebaseManager.shared.callFunction(
            name: "submitProfile",
            data: data
        )

        // Refresh user data and start listener
        try await UserManager.shared.loadUser()

        return response.user
    }

    func updateProfile(
        firstName: String? = nil,
        photoUrl: String? = nil,
        age: Int? = nil,
        vanLifeStatus: VanLifeStatus? = nil,
        region: String? = nil,
        activities: [String]? = nil,
        bio: String? = nil
    ) async throws -> UserData {
        var data: [String: Any] = [:]
        if let firstName = firstName { data["firstName"] = firstName }
        if let photoUrl = photoUrl { data["photoUrl"] = photoUrl }
        if let age = age { data["age"] = age }
        if let vanLifeStatus = vanLifeStatus { data["vanLifeStatus"] = vanLifeStatus.rawValue }
        if let region = region { data["region"] = region }
        if let activities = activities { data["activities"] = activities }
        if let bio = bio { data["bio"] = bio }

        let response: GetUserResponse = try await FirebaseManager.shared.callFunction(
            name: "updateProfile",
            data: data
        )

        // Refresh user data and start listener
        try await UserManager.shared.loadUser()

        return response.user
    }

    func getProfileSetupData() async throws -> ProfileSetupData {
        return try await FirebaseManager.shared.callFunction(name: "getProfileSetupData")
    }

    // MARK: - Waitlist Management

    func submitToWaitlist() async throws -> SubmitWaitlistResponse {
        let response: SubmitWaitlistResponse = try await FirebaseManager.shared.callFunction(name: "submitToWaitlist")

        // Refresh user data and start listener
        try await UserManager.shared.loadUser()

        return response
    }

    func checkWaitlistStatus() async throws -> WaitlistStatusResponse {
        return try await FirebaseManager.shared.callFunction(name: "checkWaitlistStatus")
    }

    func useInviteCode(_ code: String) async throws -> UseInviteCodeResponse {
        let data: [String: Any] = ["code": code]
        let response: UseInviteCodeResponse = try await FirebaseManager.shared.callFunction(
            name: "useInviteCode",
            data: data
        )

        // Refresh user data and start listener
        try await UserManager.shared.loadUser()

        return response
    }
}
