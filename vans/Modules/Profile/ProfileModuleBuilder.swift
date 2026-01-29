import UIKit

typealias ProfileViewController = ActionableHostingViewController<ProfileView, ProfileViewModel>

enum ProfileModuleBuilder {
    static func build(coordinator: ProfileCoordinating) -> ProfileViewController {
        let viewModel = ProfileViewModel(coordinator: coordinator)
        let view = ProfileView(viewModel: viewModel)
        return ProfileViewController(rootView: view, viewModel: viewModel)
    }
}
