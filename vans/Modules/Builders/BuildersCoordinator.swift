import UIKit
import SwiftUI

protocol BuildersCoordinating: AnyObject {
    @MainActor func showBuilderProfile(builder: BuilderProfile)
    @MainActor func showBuilderSession(session: BuilderSession, asBuilder: Bool)
    @MainActor func showBookSession(builder: BuilderProfile, category: BuilderCategory?, sourceEventId: String?)
    @MainActor func showBecomeBuilder()
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
    func start(category: BuilderCategory? = nil, sourceEventId: String? = nil) {
        let viewModel = BuilderListViewModel(
            coordinator: self,
            initialCategory: category,
            sourceEventId: sourceEventId
        )
        let view = BuilderListView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = "Get Help"
        navigationController.setViewControllers([hostingController], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        presentingController?.present(navigationController, animated: true)
    }

    @MainActor
    func showBuilderProfile(builder: BuilderProfile) {
        let viewModel = BuilderProfileViewModel(builder: builder, coordinator: self)
        let view = BuilderProfileView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func showBuilderSession(session: BuilderSession, asBuilder: Bool) {
        let viewModel = BuilderSessionViewModel(session: session, asBuilder: asBuilder, coordinator: self)
        let view = BuilderSessionView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func showBookSession(builder: BuilderProfile, category: BuilderCategory?, sourceEventId: String?) {
        let viewModel = BookSessionViewModel(
            builder: builder,
            selectedCategory: category,
            sourceEventId: sourceEventId,
            coordinator: self
        )
        let view = BookSessionView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(hostingController, animated: true)
    }

    @MainActor
    func showBecomeBuilder() {
        let viewModel = BecomeBuilderViewModel(coordinator: self)
        let view = BecomeBuilderView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func dismiss() {
        navigationController.dismiss(animated: true)
    }
}
