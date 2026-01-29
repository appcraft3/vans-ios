import UIKit

protocol HomeCoordinating: Coordinator {
}

final class HomeCoordinator: NSObject, HomeCoordinating {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    override init() {
        self.navigationController = UINavigationController()
        super.init()
    }

    func start() {
        let viewController = HomeModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
