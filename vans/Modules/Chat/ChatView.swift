import SwiftUI
import Kingfisher

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool

    let sourceEventName: String?
    let initialWaitingForHer: Bool

    init(chatId: String, otherUser: ChatUser, sourceEventName: String? = nil, waitingForHer: Bool = false) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId, otherUser: otherUser))
        self.sourceEventName = sourceEventName
        self.initialWaitingForHer = waitingForHer
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                chatHeader

                Divider()
                    .background(AppTheme.divider)

                // Messages
                messagesArea

                // Input or waiting message
                if viewModel.waitingForFemale {
                    waitingBanner
                } else {
                    inputArea
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.waitingForFemale = initialWaitingForHer
            viewModel.loadMessages()
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            CachedProfileImage(url: viewModel.otherUser.profile?.photoUrl, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(viewModel.otherUser.profile?.firstName ?? "User")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    if viewModel.otherUser.isPremium {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.primary)
                    }
                }

                if let eventName = sourceEventName {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Met at \(eventName)")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.secondary)
                } else if let region = viewModel.otherUser.profile?.region {
                    Text(region)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppTheme.background)
    }

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.hasMore {
                        Button(action: { viewModel.loadMoreMessages() }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                            } else {
                                Text("Load earlier messages")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                        .padding()
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: viewModel.isFromCurrentUser(message)
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal)
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
    }

    private var waitingBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.wave.fill")
                .font(.title2)
                .foregroundColor(AppTheme.primary)

            Text("Waiting for her to message first")
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)

            Text("Women send the first message in this community")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.primary.opacity(0.1))
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.card)
                    .cornerRadius(20)
                    .foregroundColor(AppTheme.textPrimary)
                    .focused($isInputFocused)
                    .lineLimit(1...5)

                Button(action: sendMessage) {
                    if viewModel.isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.textPrimary))
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(messageText.isEmpty ? AppTheme.textTertiary : .black)
                            .frame(width: 44, height: 44)
                            .background(messageText.isEmpty ? AppTheme.card : AppTheme.accent)
                            .clipShape(Circle())
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(AppTheme.background)
        }
    }

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        messageText = ""
        viewModel.sendMessage(content)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .black : AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? AppTheme.secondary : AppTheme.card)
                    .cornerRadius(18)

                if let createdAt = message.createdAt {
                    HStack(spacing: 4) {
                        Text(formatTime(createdAt))
                            .font(.caption2)
                            .foregroundColor(AppTheme.textTertiary)

                        if isFromCurrentUser && message.read {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }
}
