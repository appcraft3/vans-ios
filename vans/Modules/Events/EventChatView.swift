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
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            if shouldShowDateSeparator(at: index) {
                                dateSeparator(for: message.createdAt)
                            }

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
                ZStack(alignment: .leading) {
                    if viewModel.messageText.isEmpty {
                        Text("Message...")
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.leading, 12)
                    }
                    TextField("", text: $viewModel.messageText)
                        .padding(12)
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($isInputFocused)
                }
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.textTertiary : AppTheme.accent)
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func shouldShowDateSeparator(at index: Int) -> Bool {
        let message = viewModel.messages[index]
        if index == 0 { return true }
        let previous = viewModel.messages[index - 1]
        return !Calendar.current.isDate(message.createdAt, inSameDayAs: previous.createdAt)
    }

    private func dateSeparator(for date: Date) -> some View {
        Text(dayLabel(for: date))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.textTertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
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
                    CachedProfileImage(url: message.senderPhotoUrl, size: 32)
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

    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messageText = ""

        // Optimistic: show message immediately
        let tempId = "temp_\(UUID().uuidString)"
        let currentUser = AuthManager.shared.currentUser
        let optimisticMessage = EventMessage(
            id: tempId,
            senderId: currentUserId,
            senderName: currentUser?.profile?.firstName ?? "",
            senderPhotoUrl: currentUser?.profile?.photoUrl,
            content: text,
            createdAt: Date()
        )
        messages.append(optimisticMessage)

        // Send in background, undo on failure
        Task {
            do {
                let result = try await functions.httpsCallable("sendEventMessage").call([
                    "eventId": eventId,
                    "content": text
                ])

                guard let data = result.data as? [String: Any],
                      let success = data["success"] as? Bool,
                      success else {
                    messages.removeAll { $0.id == tempId }
                    messageText = text
                    return
                }
            } catch {
                print("Error sending message: \(error)")
                messages.removeAll { $0.id == tempId }
                messageText = text
            }
        }
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
