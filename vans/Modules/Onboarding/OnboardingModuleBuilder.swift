import UIKit

typealias OnboardingViewController = ActionableHostingViewController<OnboardingView, OnboardingViewModel>

enum OnboardingModuleBuilder {
    static func build(coordinator: OnboardingCoordinating) -> OnboardingViewController {
        let viewModel = OnboardingViewModel(coordinator: coordinator)
        let view = OnboardingView(viewModel: viewModel)
        return OnboardingViewController(rootView: view, viewModel: viewModel)
    }
}
