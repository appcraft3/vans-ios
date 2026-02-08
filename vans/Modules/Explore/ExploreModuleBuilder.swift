import UIKit

typealias ExploreViewController = ActionableHostingViewController<ExploreView, ExploreViewModel>

enum ExploreModuleBuilder {
    @MainActor
    static func build(coordinator: ExploreCoordinating) -> ExploreViewController {
        let viewModel = ExploreViewModel(coordinator: coordinator)
        let view = ExploreView(viewModel: viewModel)
        return ExploreViewController(rootView: view, viewModel: viewModel)
    }
}
