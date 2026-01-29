import UIKit

typealias HomeViewController = ActionableHostingViewController<HomeView, HomeViewModel>

enum HomeModuleBuilder {
    static func build(coordinator: HomeCoordinating) -> HomeViewController {
        let viewModel = HomeViewModel(coordinator: coordinator)
        let view = HomeView(viewModel: viewModel)
        return HomeViewController(rootView: view, viewModel: viewModel)
    }
}
