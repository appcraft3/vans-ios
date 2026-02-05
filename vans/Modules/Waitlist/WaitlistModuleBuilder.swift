import UIKit

typealias WaitlistViewController = ActionableHostingViewController<WaitlistView, WaitlistViewModel>

enum WaitlistModuleBuilder {
    static func build(coordinator: WaitlistCoordinating) -> WaitlistViewController {
        let viewModel = WaitlistViewModel(coordinator: coordinator)
        let view = WaitlistView(viewModel: viewModel)
        return WaitlistViewController(rootView: view, viewModel: viewModel)
    }
}
