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
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        errorMessage = nil

        // Optimistic: show message immediately
        let tempId = "temp_\(UUID().uuidString)"
        let formatter = ISO8601DateFormatter()
        let optimisticMessage = ChatMessage(
            id: tempId,
            senderId: currentUserId,
            content: text,
            createdAt: formatter.string(from: Date()),
            read: false
        )
        messages.append(optimisticMessage)
        canSendMessage = true
        waitingForFemale = false

        // Send in background, undo on failure
        Task { @MainActor in
            do {
                let _: SendMessageResponse = try await FirebaseManager.shared.callFunction(
                    name: "sendEventConnectionMessage",
                    data: ["connectionId": chatId, "content": text]
                )
            } catch let error as NSError {
                // Undo optimistic message
                messages.removeAll { $0.id == tempId }
                if let message = error.userInfo["message"] as? String {
                    self.errorMessage = message
                } else {
                    self.errorMessage = "Failed to send message"
                }
                print("Failed to send message: \(error)")
            }
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
