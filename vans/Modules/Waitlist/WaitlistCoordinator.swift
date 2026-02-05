import UIKit

protocol WaitlistCoordinatorDelegate: AnyObject {
    func waitlistCoordinatorDidGetApproved(_ coordinator: WaitlistCoordinator)
}

protocol WaitlistCoordinating: Coordinator {
    func finishWaitlist()
}

final class WaitlistCoordinator: WaitlistCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: WaitlistCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = WaitlistModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func finishWaitlist() {
        delegate?.waitlistCoordinatorDidGetApproved(self)
    }
}
