import UIKit

protocol ExploreCoordinating: Coordinator {
}

final class ExploreCoordinator: NSObject, ExploreCoordinating {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    override init() {
        self.navigationController = UINavigationController()
        super.init()
    }

    func start() {
        let viewController = ExploreModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
