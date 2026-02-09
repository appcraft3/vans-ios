import UIKit
import SwiftUI

protocol ProfileCoordinating: Coordinator {
    func showWaitlistReview()
    func showBecomeBuilder()
    func showPaywall()
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

    func showWaitlistReview() {
        let viewModel = WaitlistReviewViewModel()
        let view = WaitlistReviewView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func showBecomeBuilder() {
        let viewModel = BecomeBuilderViewModel(coordinator: nil)
        let view = BecomeBuilderView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func showPaywall() {
        let view = PaywallView()
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        navigationController.present(hostingController, animated: true)
    }
}
