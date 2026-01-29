import Foundation
import Combine

final class SplashViewModel: ActionableViewModel {

    enum State: Equatable {
        case idle
        case loading
        case success
        case failed(String)
        case forceUpdate

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.success, .success), (.forceUpdate, .forceUpdate):
                return true
            case (.failed(let lhsMsg), .failed(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    @Published var state: State = .idle
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private weak var coordinator: SplashCoordinating?
    private var isLoggedIn: Bool = false
    private var isNewUser: Bool = false

    init(coordinator: SplashCoordinating?) {
        self.coordinator = coordinator
    }

    func onAppear() {
        startLoading()
    }

    func retry() {
        startLoading()
    }

    func openAppStore() {
        ForceUpdateManager.shared.openAppStore()
    }

    private func startLoading() {
        state = .loading

        Task { @MainActor in
            do {
                // 1. Fetch remote config
                await RemoteConfigManager.shared.fetchConfig()

                // 2. Check for force update
                if ForceUpdateManager.shared.needsForceUpdate {
                    state = .forceUpdate
                    return
                }

                // 3. Check if user is already logged in
                if AuthManager.shared.isLoggedIn {
                    // Refresh token
                    try await AuthManager.shared.refreshAuthToken()

                    // Load user data
                    try await UserManager.shared.loadUser()
                    isLoggedIn = true
                    isNewUser = UserManager.shared.currentUser?.isNewUser ?? false
                } else {
                    // Not logged in - will show sign in screen
                    isLoggedIn = false
                    isNewUser = false
                }

                // 4. Success - navigate to next screen
                state = .success

                // Small delay for visual feedback
                try await Task.sleep(nanoseconds: 500_000_000)

                coordinator?.finishSplash(isLoggedIn: isLoggedIn, isNewUser: isNewUser)

            } catch {
                // If error while refreshing token, treat as not logged in
                if case APIError.unauthorized = error {
                    isLoggedIn = false
                    state = .success
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    coordinator?.finishSplash(isLoggedIn: false, isNewUser: false)
                    return
                }

                state = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
