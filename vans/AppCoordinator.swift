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

    private func showTabbar() {
        childCoordinators.removeAll()

        let tabbarCoordinator = TabbarCoordinator(window: window)
        childCoordinators.append(tabbarCoordinator)
        tabbarCoordinator.start()
    }

    private func showOnboarding() {
        // TODO: Implement OnboardingCoordinator
        // For now, just show tabbar
        showTabbar()
    }
}

// MARK: - SplashCoordinatorDelegate

extension AppCoordinator: SplashCoordinatorDelegate {
    func splashCoordinatorDidFinish(_ coordinator: SplashCoordinator, isLoggedIn: Bool, isNewUser: Bool) {
        childCoordinators.removeAll { $0 === coordinator }

        if isLoggedIn {
            if isNewUser {
                showOnboarding()
            } else {
                showTabbar()
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

        if user.isNewUser {
            showOnboarding()
        } else {
            showTabbar()
        }
    }
}
