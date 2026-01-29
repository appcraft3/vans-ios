import Foundation
import Combine

final class ProfileViewModel: ActionableViewModel {
    @Published var user: UserData?

    private weak var coordinator: ProfileCoordinating?

    init(coordinator: ProfileCoordinating?) {
        self.coordinator = coordinator
    }

    func loadUser() {
        user = UserManager.shared.currentUser
    }

    func signOut() {
        Task { @MainActor in
            do {
                try await AuthManager.shared.signOut()
                // App will need to handle navigation back to sign in
                // This can be done via notification or delegate
                NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            } catch {
                print("Sign out error: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}
