import UIKit
import SwiftUI

protocol BuildersCoordinating: AnyObject {
    @MainActor func dismiss()
}

final class BuildersCoordinator: NSObject, BuildersCoordinating {
    let navigationController: UINavigationController
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?) {
        self.navigationController = UINavigationController()
        self.presentingController = presentingController
        super.init()
    }

    @MainActor
    func showBecomeBuilder() {
        let viewModel = BecomeBuilderViewModel(coordinator: self)
        let view = BecomeBuilderView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.setViewControllers([hostingController], animated: false)
        navigationController.modalPresentationStyle = .pageSheet
        presentingController?.present(navigationController, animated: true)
    }

    @MainActor
    func dismiss() {
        navigationController.dismiss(animated: true)
    }
}
