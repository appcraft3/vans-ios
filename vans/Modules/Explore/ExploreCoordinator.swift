import UIKit
import SwiftUI

protocol ExploreCoordinating: Coordinator {
    func showUserProfile(_ user: DiscoveryUser)
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

    func showUserProfile(_ user: DiscoveryUser) {
        let view = UserProfileView(user: user)
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }
}
