import SwiftUI
import Kingfisher
import FirebaseFunctions

struct EventChatView: View {
    let eventId: String
    let onTapUser: ((String) -> Void)?
    @StateObject private var viewModel: EventChatViewModel
    @FocusState private var isInputFocused: Bool

    init(eventId: String, onTapUser: ((String) -> Void)? = nil) {
        self.eventId = eventId
        self.onTapUser = onTapUser
        _viewModel = StateObject(wrappedValue: EventChatViewModel(eventId: eventId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            EventMessageBubble(
                                message: message,
                                isOwnMessage: message.senderId == viewModel.currentUserId,
                                onTapAvatar: {
                                    onTapUser?(message.senderId)
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input
            HStack(spacing: 12) {
                TextField("Message...", text: $viewModel.messageText)
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .foregroundColor(AppTheme.textPrimary)
                    .focused($isInputFocused)

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.textTertiary : AppTheme.accent)
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.background)
        }
        .background(AppTheme.background)
        .task {
            await viewModel.loadMessages()
        }
    }
}

struct EventMessageBubble: View {
    let message: EventMessage
    let isOwnMessage: Bool
    let onTapAvatar: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isOwnMessage {
                Spacer(minLength: 50)
            } else {
                // Avatar
                Button {
                    onTapAvatar?()
                } label: {
                    KFImage(URL(string: message.senderPhotoUrl ?? ""))
                        .resizable()
                        .placeholder {
                            Circle()
                                .fill(AppTheme.card)
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
            }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                if !isOwnMessage {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }

                Text(message.content)
                    .font(.body)
                    .foregroundColor(isOwnMessage ? .black : AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOwnMessage ? AppTheme.secondary : AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)
            }

            if !isOwnMessage {
                Spacer(minLength: 50)
            }
        }
    }
}

struct EventMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let senderPhotoUrl: String?
    let content: String
    let createdAt: Date

    var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: createdAt)
    }
}

@MainActor
class EventChatViewModel: ObservableObject {
    @Published var messages: [EventMessage] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isSending = false

    let eventId: String
    let currentUserId: String

    private let functions = Functions.functions()

    init(eventId: String) {
        self.eventId = eventId
        self.currentUserId = AuthManager.shared.currentUser?.id ?? ""
    }

    func loadMessages() async {
        isLoading = true

        do {
            let result = try await functions.httpsCallable("getEventMessages").call([
                "eventId": eventId,
                "limit": 100
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let messagesData = data["messages"] as? [[String: Any]] else {
                return
            }

            messages = messagesData.compactMap { parseMessage($0) }
        } catch {
            print("Error loading messages: \(error)")
        }

        isLoading = false
    }

    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        isSending = true
        let tempText = text
        messageText = ""

        do {
            let result = try await functions.httpsCallable("sendEventMessage").call([
                "eventId": eventId,
                "content": tempText
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let messageData = data["message"] as? [String: Any],
                  let newMessage = parseMessage(messageData) else {
                messageText = tempText
                return
            }

            messages.append(newMessage)
        } catch {
            print("Error sending message: \(error)")
            messageText = tempText
        }

        isSending = false
    }

    private func parseMessage(_ data: [String: Any]) -> EventMessage? {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let content = data["content"] as? String else {
            return nil
        }

        let createdAtString = data["createdAt"] as? String ?? ""
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.date(from: createdAtString) ?? Date()

        return EventMessage(
            id: id,
            senderId: senderId,
            senderName: senderName,
            senderPhotoUrl: data["senderPhotoUrl"] as? String,
            content: content,
            createdAt: createdAt
        )
    }
}
