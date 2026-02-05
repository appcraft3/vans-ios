import SwiftUI

struct HomeView: ActionableView {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ChatListView { chatId, otherUser, sourceEventName, waitingForHer in
            viewModel.openChat(
                chatId: chatId,
                otherUser: otherUser,
                sourceEventName: sourceEventName,
                waitingForHer: waitingForHer
            )
        }
        .navigationBarHidden(true)
    }
}
