import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator)
}

protocol OnboardingCoordinating: Coordinator {
    func finishOnboarding()
}

final class OnboardingCoordinator: OnboardingCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var delegate: OnboardingCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = OnboardingModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func finishOnboarding() {
        delegate?.onboardingCoordinatorDidFinish(self)
    }
}
