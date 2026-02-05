import Foundation
import Combine

final class ChatListViewModel: ObservableObject {
    @Published var matches: [EventMatchChat] = []
    @Published var isLoading: Bool = false

    // Legacy support - convert matches to chats for existing views
    var chats: [Chat] {
        matches.map { match in
            Chat(
                chatId: match.odId,
                otherUser: match.otherUser,
                lastMessage: nil, // Will be fetched separately
                lastMessageAt: match.createdAt,
                unreadCount: 0,
                canSendMessage: match.canSendMessage,
                sourceEventName: match.sourceEventName,
                waitingForHer: match.waitingForHer,
                hasMessaged: match.hasMessaged,
                isExpired: match.isExpired
            )
        }
    }

    func loadChats() {
        guard !isLoading else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: EventMatchesResponse = try await FirebaseManager.shared.callFunction(
                    name: "getEventMatches"
                )
                self.matches = response.matches
            } catch {
                print("Failed to load event matches: \(error)")
            }
            isLoading = false
        }
    }

    func refreshChats() {
        matches = []
        loadChats()
    }
}
