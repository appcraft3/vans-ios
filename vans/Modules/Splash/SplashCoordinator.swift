import UIKit

protocol SplashCoordinatorDelegate: AnyObject {
    func splashCoordinatorDidFinish(_ coordinator: SplashCoordinator, isLoggedIn: Bool, isNewUser: Bool)
}

protocol SplashCoordinating: Coordinator {
    func finishSplash(isLoggedIn: Bool, isNewUser: Bool)
}

final class SplashCoordinator: SplashCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: SplashCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = SplashModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func finishSplash(isLoggedIn: Bool, isNewUser: Bool) {
        delegate?.splashCoordinatorDidFinish(self, isLoggedIn: isLoggedIn, isNewUser: isNewUser)
    }
}
