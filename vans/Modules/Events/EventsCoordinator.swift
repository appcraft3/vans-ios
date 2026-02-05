import UIKit
import SwiftUI

protocol EventsCoordinating: Coordinator {
    @MainActor func showEventDetail(eventId: String)
    @MainActor func showUserProfile(userId: String, profile: UserProfile, trust: TrustInfo, isPremium: Bool)
}

final class EventsCoordinator: NSObject, EventsCoordinating {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    override init() {
        self.navigationController = UINavigationController()
        super.init()
    }

    @MainActor
    func start() {
        let viewController = EventsModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func showEventDetail(eventId: String) {
        let viewModel = EventDetailViewModel(eventId: eventId, coordinator: self)
        let detailView = EventDetailView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: detailView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }

    @MainActor
    func showUserProfile(userId: String, profile: UserProfile, trust: TrustInfo, isPremium: Bool) {
        let user = DiscoveryUser(id: userId, profile: profile, trust: trust, isPremium: isPremium)
        let view = UserProfileView(user: user)
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }
}
