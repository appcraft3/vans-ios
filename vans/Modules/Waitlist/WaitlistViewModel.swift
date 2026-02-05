import Foundation
import Combine

final class WaitlistViewModel: ActionableViewModel {

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    @Published var reviewStatus: ReviewStatus = .none
    @Published var position: Int?
    @Published var totalPending: Int = 0

    @Published var inviteCode: String = ""
    @Published var showInviteCodeInput: Bool = false

    private weak var coordinator: WaitlistCoordinating?
    private var statusCheckTimer: Timer?

    init(coordinator: WaitlistCoordinating?) {
        self.coordinator = coordinator
    }

    deinit {
        statusCheckTimer?.invalidate()
    }

    var statusMessage: String {
        switch reviewStatus {
        case .none:
            return "Complete your profile to join the waitlist"
        case .pending:
            if let pos = position {
                return "You're #\(pos) in line"
            }
            return "Your application is being reviewed"
        case .approved:
            return "Welcome to the community!"
        case .rejected:
            return "Your application was not approved"
        case .onHold:
            return "Your application is on hold"
        }
    }

    var canSubmitToWaitlist: Bool {
        reviewStatus == .none
    }

    func onAppear() {
        checkStatus()
        startStatusPolling()
    }

    func onDisappear() {
        statusCheckTimer?.invalidate()
    }

    private func startStatusPolling() {
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }

    func checkStatus() {
        Task { @MainActor in
            do {
                let status = try await AuthManager.shared.checkWaitlistStatus()
                self.reviewStatus = status.reviewStatus
                self.position = status.position
                self.totalPending = status.totalPending

                // If approved, navigate to main app
                if status.accessLevel == .member || status.accessLevel == .premium {
                    coordinator?.finishWaitlist()
                }
            } catch {
                // Silently fail for status checks
            }
        }
    }

    func submitToWaitlist() {
        Task { @MainActor in
            isLoading = true
            do {
                _ = try await AuthManager.shared.submitToWaitlist()
                checkStatus()
            } catch {
                showError(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    func useInviteCode() {
        guard !inviteCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError(message: "Please enter an invite code")
            return
        }

        Task { @MainActor in
            isLoading = true
            do {
                let response = try await AuthManager.shared.useInviteCode(inviteCode.trimmingCharacters(in: .whitespaces))

                if response.accessLevel == .member || response.accessLevel == .premium {
                    coordinator?.finishWaitlist()
                }
            } catch {
                showError(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
