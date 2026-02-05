import Foundation
import Combine

final class HomeViewModel: ActionableViewModel {
    private weak var coordinator: HomeCoordinating?

    init(coordinator: HomeCoordinating?) {
        self.coordinator = coordinator
    }

    func openChat(chatId: String, otherUser: ChatUser, sourceEventName: String?, waitingForHer: Bool) {
        coordinator?.showChat(
            chatId: chatId,
            otherUser: otherUser,
            sourceEventName: sourceEventName,
            waitingForHer: waitingForHer
        )
    }
}
