import Foundation
import Combine
import FirebaseFirestore

final class UserManager {

    static let shared = UserManager()

    @Published private(set) var currentUser: UserData?
    @Published private(set) var isLoading: Bool = false

    private var userListener: ListenerRegistration?
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Loading

    func loadUser() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        let user = try await AuthManager.shared.getUser()
        await MainActor.run { self.currentUser = user }

        // Start listening for real-time updates
        startListeningToUser()
    }

    // MARK: - Real-time Listener

    func startListeningToUser() {
        guard let userId = AuthManager.shared.currentUserId else { return }

        userListener?.remove()

        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else { return }

                // Parse profile if exists
                var profile: UserProfile? = nil
                if let profileData = data["profile"] as? [String: Any] {
                    profile = UserProfile(
                        firstName: profileData["firstName"] as? String ?? "",
                        photoUrl: profileData["photoUrl"] as? String ?? "",
                        age: profileData["age"] as? Int ?? 0,
                        gender: Gender(rawValue: profileData["gender"] as? String ?? "") ?? .male,
                        vanLifeStatus: VanLifeStatus(rawValue: profileData["vanLifeStatus"] as? String ?? "") ?? .planning,
                        region: profileData["region"] as? String ?? "",
                        activities: profileData["activities"] as? [String] ?? [],
                        bio: profileData["bio"] as? String
                    )
                }

                // Parse trust info
                var trust = TrustInfo.empty
                if let trustData = data["trust"] as? [String: Any] {
                    trust = TrustInfo(
                        level: trustData["level"] as? Int ?? 0,
                        badges: trustData["badges"] as? [String] ?? [],
                        eventsAttended: trustData["eventsAttended"] as? Int ?? 0,
                        positiveReviews: trustData["positiveReviews"] as? Int ?? 0,
                        negativeReviews: trustData["negativeReviews"] as? Int ?? 0,
                        reviewCount: trustData["reviewCount"] as? Int ?? 0
                    )
                }

                let user = UserData(
                    id: userId,
                    email: data["email"] as? String,
                    accessLevel: AccessLevel(rawValue: data["accessLevel"] as? String ?? "guest") ?? .guest,
                    role: UserRole(rawValue: data["role"] as? String ?? "user") ?? .user,
                    profile: profile,
                    trust: trust,
                    reviewStatus: ReviewStatus(rawValue: data["reviewStatus"] as? String ?? "none") ?? .none,
                    isPremium: data["isPremium"] as? Bool ?? false,
                    inviteCode: data["inviteCode"] as? String,
                    isNewUser: data["isNewUser"] as? Bool
                )

                DispatchQueue.main.async {
                    self?.currentUser = user
                }
            }
    }

    func stopListeningToUser() {
        userListener?.remove()
        userListener = nil
    }

    // MARK: - User Updates

    func updateProfile(
        firstName: String? = nil,
        photoUrl: String? = nil,
        age: Int? = nil,
        vanLifeStatus: VanLifeStatus? = nil,
        region: String? = nil,
        activities: [String]? = nil,
        bio: String? = nil
    ) async throws {
        let updatedUser = try await AuthManager.shared.updateProfile(
            firstName: firstName,
            photoUrl: photoUrl,
            age: age,
            vanLifeStatus: vanLifeStatus,
            region: region,
            activities: activities,
            bio: bio
        )
        await MainActor.run { self.currentUser = updatedUser }
    }

    func clearUser() {
        stopListeningToUser()
        currentUser = nil
    }
}
