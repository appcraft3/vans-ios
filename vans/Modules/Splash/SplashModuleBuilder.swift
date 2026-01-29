import UIKit

typealias SplashViewController = ActionableHostingViewController<SplashView, SplashViewModel>

enum SplashModuleBuilder {
    static func build(coordinator: SplashCoordinating) -> SplashViewController {
        let viewModel = SplashViewModel(coordinator: coordinator)
        let view = SplashView(viewModel: viewModel)
        return SplashViewController(rootView: view, viewModel: viewModel)
    }
}
