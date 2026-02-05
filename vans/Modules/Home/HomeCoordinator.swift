import UIKit
import SwiftUI

protocol HomeCoordinating: Coordinator {
    func showChat(chatId: String, otherUser: ChatUser, sourceEventName: String?, waitingForHer: Bool)
}

final class HomeCoordinator: NSObject, HomeCoordinating {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    override init() {
        self.navigationController = UINavigationController()
        super.init()
    }

    func start() {
        let viewController = HomeModuleBuilder.build(coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func showChat(chatId: String, otherUser: ChatUser, sourceEventName: String? = nil, waitingForHer: Bool = false) {
        let chatView = ChatView(
            chatId: chatId,
            otherUser: otherUser,
            sourceEventName: sourceEventName,
            waitingForHer: waitingForHer
        )
        let hostingController = UIHostingController(rootView: chatView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }
}
