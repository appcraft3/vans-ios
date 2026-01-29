import UIKit

final class AppCoordinator: Coordinator {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showSplash()
    }

    private func showSplash() {
        let splashCoordinator = SplashCoordinator(navigationController: navigationController)
        splashCoordinator.delegate = self
        childCoordinators.append(splashCoordinator)
        splashCoordinator.start()
    }

    private func showHome() {
        // TODO: Implement TabbarCoordinator
    }

    private func showOnboarding() {
        // TODO: Implement OnboardingCoordinator
    }
}

// MARK: - SplashCoordinatorDelegate

extension AppCoordinator: SplashCoordinatorDelegate {
    func splashCoordinatorDidFinish(_ coordinator: SplashCoordinator, isNewUser: Bool) {
        childCoordinators.removeAll { $0 === coordinator }

        if isNewUser {
            showOnboarding()
        } else {
            showHome()
        }
    }
}
