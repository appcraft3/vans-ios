import UIKit

protocol ProfileCoordinating: Coordinator {
}

final class ProfileCoordinator: NSObject, ProfileCoordinating {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    override init() {
        self.navigationController = UINavigationController()
        super.init()
    }

    func start() {
        let viewController = ProfileModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
