import UIKit

protocol InviteCodeCoordinatorDelegate: AnyObject {
    func inviteCodeCoordinatorDidComplete(_ coordinator: InviteCodeCoordinator)
}

protocol InviteCodeCoordinating: Coordinator {
    func didEnterValidCode()
}

final class InviteCodeCoordinator: InviteCodeCoordinating {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: InviteCodeCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let (viewController, _) = InviteCodeModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func didEnterValidCode() {
        delegate?.inviteCodeCoordinatorDidComplete(self)
    }
}
