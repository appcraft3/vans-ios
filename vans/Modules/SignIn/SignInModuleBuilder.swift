import UIKit

typealias SignInViewController = ActionableHostingViewController<SignInView, SignInViewModel>

enum SignInModuleBuilder {
    static func build(coordinator: SignInCoordinating) -> SignInViewController {
        let viewModel = SignInViewModel(coordinator: coordinator)
        let view = SignInView(viewModel: viewModel)
        return SignInViewController(rootView: view, viewModel: viewModel)
    }
}
