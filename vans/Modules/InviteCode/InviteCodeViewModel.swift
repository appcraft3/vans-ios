import Foundation

final class InviteCodeViewModel: ActionableViewModel {
    @Published var inviteCode: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    @Published var showWaitlistSuccess: Bool = false
    @Published var waitlistMessage: String = ""
    @Published var isOnWaitlist: Bool = false

    private weak var coordinator: InviteCodeCoordinating?

    init(coordinator: InviteCodeCoordinating?) {
        self.coordinator = coordinator
        checkWaitlistStatus()
    }

    func checkWaitlistStatus() {
        // Check if user is already on waitlist
        if let user = UserManager.shared.currentUser ?? AuthManager.shared.currentUser {
            isOnWaitlist = user.accessLevel == .waitlist
        }
    }

    func joinWaitlist() {
        guard !isOnWaitlist else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let response = try await AuthManager.shared.submitToWaitlist()
                waitlistMessage = response.message
                isOnWaitlist = true
                showWaitlistSuccess = true
            } catch {
                errorMessage = parseError(error)
                showError = true
            }
            isLoading = false
        }
    }

    func submitCode() {
        guard !inviteCode.isEmpty else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let response = try await AuthManager.shared.useInviteCode(inviteCode.uppercased())
                successMessage = response.message
                showSuccess = true
            } catch {
                errorMessage = parseError(error)
                showError = true
            }
            isLoading = false
        }
    }

    func continueToApp() {
        coordinator?.didEnterValidCode()
    }

    func signOut() {
        Task { @MainActor in
            do {
                try await AuthManager.shared.signOut()
                UserManager.shared.clearUser()
                NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            } catch {
                errorMessage = "Failed to sign out"
                showError = true
            }
        }
    }

    private func parseError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let message):
                return message
            default:
                return "Something went wrong"
            }
        }
        return error.localizedDescription
    }
}
