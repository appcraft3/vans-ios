import Foundation
import Combine
import FirebaseFirestore

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
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var pendingTempIds: Set<String> = []

    init(chatId: String, otherUser: ChatUser) {
        self.chatId = chatId
        self.otherUser = otherUser
        self.currentUserId = AuthManager.shared.currentUserId ?? ""
    }

    deinit {
        listener?.remove()
    }

    func startListening() {
        guard listener == nil else { return }
        isLoading = true

        listener = db.collection("eventChats").document(chatId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(toLast: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Error listening to messages: \(error)")
                    self.isLoading = false
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }

                let serverMessages: [ChatMessage] = documents.compactMap { doc in
                    let data = doc.data()
                    guard let senderId = data["senderId"] as? String,
                          let content = data["content"] as? String else {
                        return nil
                    }

                    let createdAt: String?
                    if let timestamp = data["createdAt"] as? Timestamp {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        createdAt = formatter.string(from: timestamp.dateValue())
                    } else {
                        createdAt = nil
                    }

                    return ChatMessage(
                        id: doc.documentID,
                        senderId: senderId,
                        content: content,
                        createdAt: createdAt,
                        read: data["read"] as? Bool ?? false
                    )
                }

                // Remove optimistic messages that now have server counterparts
                let remainingOptimistic = self.messages.filter { $0.id.hasPrefix("temp_") }
                var filtered = remainingOptimistic
                for opt in remainingOptimistic {
                    if serverMessages.contains(where: { $0.senderId == opt.senderId && $0.content == opt.content }) {
                        filtered.removeAll { $0.id == opt.id }
                        self.pendingTempIds.remove(opt.id)
                    }
                }

                self.messages = serverMessages + filtered
                self.isLoading = false
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
        pendingTempIds.insert(tempId)
        canSendMessage = true
        waitingForFemale = false

        // Send in background, undo on failure
        Task { @MainActor in
            do {
                let _: SendMessageResponse = try await FirebaseManager.shared.callFunction(
                    name: "sendEventConnectionMessage",
                    data: ["connectionId": chatId, "content": text]
                )
                // Listener will pick up the new message
            } catch let error as NSError {
                // Undo optimistic message
                messages.removeAll { $0.id == tempId }
                pendingTempIds.remove(tempId)
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
