import UIKit
import Combine

final class AppCoordinator: Coordinator {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, navigationController: UINavigationController) {
        self.window = window
        self.navigationController = navigationController
        setupNotifications()
    }

    func start() {
        showSplash()
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .userDidSignOut)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSignOut()
            }
            .store(in: &cancellables)
    }

    private func handleSignOut() {
        childCoordinators.removeAll()

        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        self.navigationController = navigationController

        window.rootViewController = navigationController
        showSignIn()
    }

    // MARK: - Navigation based on User State

    func handleUserState(_ user: UserData) {
        switch user.accessLevel {
        case .guest:
            // Check if profile is complete
            if user.hasCompletedProfile {
                // Profile done, show waitlist/invite code screen
                showInviteCode()
            } else {
                // Need to complete profile first
                showOnboarding()
            }

        case .waitlist:
            // On waitlist, show waitlist/invite code screen
            showInviteCode()

        case .member, .premium:
            // Approved member - show main app
            showTabbar()
        }
    }

    // MARK: - Show Modules

    private func showSplash() {
        let splashCoordinator = SplashCoordinator(navigationController: navigationController)
        splashCoordinator.delegate = self
        childCoordinators.append(splashCoordinator)
        splashCoordinator.start()
    }

    private func showSignIn() {
        let signInCoordinator = SignInCoordinator(navigationController: navigationController)
        signInCoordinator.delegate = self
        childCoordinators.append(signInCoordinator)
        signInCoordinator.start()
    }

    private func showOnboarding() {
        childCoordinators.removeAll()

        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.delegate = self
        childCoordinators.append(onboardingCoordinator)
        onboardingCoordinator.start()
    }

    private func showInviteCode() {
        childCoordinators.removeAll()

        let inviteCodeCoordinator = InviteCodeCoordinator(navigationController: navigationController)
        inviteCodeCoordinator.delegate = self
        childCoordinators.append(inviteCodeCoordinator)
        inviteCodeCoordinator.start()
    }

    private func showTabbar() {
        childCoordinators.removeAll()

        let tabbarCoordinator = TabbarCoordinator(window: window)
        childCoordinators.append(tabbarCoordinator)
        tabbarCoordinator.start()
    }
}

// MARK: - SplashCoordinatorDelegate

extension AppCoordinator: SplashCoordinatorDelegate {
    func splashCoordinatorDidFinish(_ coordinator: SplashCoordinator, isLoggedIn: Bool, isNewUser: Bool) {
        childCoordinators.removeAll { $0 === coordinator }

        if isLoggedIn {
            // Get current user and route based on access level
            Task { @MainActor in
                do {
                    let user = try await AuthManager.shared.getUser()
                    handleUserState(user)
                } catch {
                    // Error getting user - show sign in
                    showSignIn()
                }
            }
        } else {
            showSignIn()
        }
    }
}

// MARK: - SignInCoordinatorDelegate

extension AppCoordinator: SignInCoordinatorDelegate {
    func signInCoordinatorDidFinish(_ coordinator: SignInCoordinator, user: UserData) {
        childCoordinators.removeAll { $0 === coordinator }
        handleUserState(user)
    }
}

// MARK: - OnboardingCoordinatorDelegate

extension AppCoordinator: OnboardingCoordinatorDelegate {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }

        // After onboarding, show waitlist/invite code screen
        showInviteCode()
    }
}

// MARK: - InviteCodeCoordinatorDelegate

extension AppCoordinator: InviteCodeCoordinatorDelegate {
    func inviteCodeCoordinatorDidComplete(_ coordinator: InviteCodeCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }

        // Code accepted - show main app
        showTabbar()
    }
}
