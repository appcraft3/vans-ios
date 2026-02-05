import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var canSendMessage: Bool = true
    @Published var waitingForFemale: Bool = false
    @Published var hasMore: Bool = false
    @Published var errorMessage: String?

    let chatId: String  // This is the connectionId for event connections
    let otherUser: ChatUser
    private let currentUserId: String

    init(chatId: String, otherUser: ChatUser) {
        self.chatId = chatId
        self.otherUser = otherUser
        self.currentUserId = AuthManager.shared.currentUserId ?? ""
    }

    func loadMessages() {
        guard !isLoading else { return }
        isLoading = true

        Task { @MainActor in
            do {
                // Use event connection messages endpoint
                let response: MessagesResponse = try await FirebaseManager.shared.callFunction(
                    name: "getEventConnectionMessages",
                    data: ["connectionId": chatId, "limit": 50]
                )
                self.messages = response.messages
                self.hasMore = response.hasMore
            } catch {
                print("Failed to load messages: \(error)")
            }
            isLoading = false
        }
    }

    func loadMoreMessages() {
        guard !isLoading, hasMore, let firstMessage = messages.first else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: MessagesResponse = try await FirebaseManager.shared.callFunction(
                    name: "getEventConnectionMessages",
                    data: ["connectionId": chatId, "limit": 50, "beforeMessageId": firstMessage.id]
                )
                self.messages.insert(contentsOf: response.messages, at: 0)
                self.hasMore = response.hasMore
            } catch {
                print("Failed to load more messages: \(error)")
            }
            isLoading = false
        }
    }

    func sendMessage(_ content: String) {
        guard !isSending, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        errorMessage = nil

        Task { @MainActor in
            do {
                // Use event connection send message endpoint
                let response: SendMessageResponse = try await FirebaseManager.shared.callFunction(
                    name: "sendEventConnectionMessage",
                    data: ["connectionId": chatId, "content": content]
                )
                self.messages.append(response.message)
                self.canSendMessage = true
                self.waitingForFemale = false
            } catch let error as NSError {
                if let message = error.userInfo["message"] as? String {
                    self.errorMessage = message
                } else {
                    self.errorMessage = "Failed to send message"
                }
                print("Failed to send message: \(error)")
            }
            isSending = false
        }
    }

    func checkCanSendMessage() {
        // For event connections, this is handled by getEventMatches response
        // The canSendMessage and waitingForFemale are passed when creating the view
    }

    func isFromCurrentUser(_ message: ChatMessage) -> Bool {
        message.senderId == currentUserId
    }
}
