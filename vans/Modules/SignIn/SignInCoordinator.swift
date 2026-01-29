import UIKit

protocol SignInCoordinatorDelegate: AnyObject {
    func signInCoordinatorDidFinish(_ coordinator: SignInCoordinator, user: UserData)
}

protocol SignInCoordinating: Coordinator {
    func finishSignIn(user: UserData)
}

final class SignInCoordinator: SignInCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: SignInCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = SignInModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func finishSignIn(user: UserData) {
        delegate?.signInCoordinatorDidFinish(self, user: user)
    }
}
