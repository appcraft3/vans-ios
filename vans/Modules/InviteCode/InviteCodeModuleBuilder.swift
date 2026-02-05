import UIKit

enum InviteCodeModuleBuilder {
    typealias ViewController = ActionableHostingViewController<InviteCodeView, InviteCodeViewModel>

    static func build(coordinator: InviteCodeCoordinating) -> (ViewController, InviteCodeViewModel) {
        let viewModel = InviteCodeViewModel(coordinator: coordinator)
        let view = InviteCodeView(viewModel: viewModel)
        let viewController = ActionableHostingViewController(rootView: view, viewModel: viewModel)
        return (viewController, viewModel)
    }
}
