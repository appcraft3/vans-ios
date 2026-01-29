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

                let user = UserData(
                    id: userId,
                    displayName: data["displayName"] as? String,
                    avatarUrl: data["avatarUrl"] as? String,
                    email: data["email"] as? String,
                    isNewUser: data["isNewUser"] as? Bool ?? false
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

    func updateUser(displayName: String?, avatarUrl: String?) async throws {
        let updatedUser = try await AuthManager.shared.updateUser(
            displayName: displayName,
            avatarUrl: avatarUrl
        )
        await MainActor.run { self.currentUser = updatedUser }
    }

    func clearUser() {
        stopListeningToUser()
        currentUser = nil
    }
}
