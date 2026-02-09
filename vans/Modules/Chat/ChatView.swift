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
            viewModel.startListening()
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

                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        if shouldShowDateSeparator(at: index) {
                            dateSeparator(for: message.createdAt)
                        }

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
                ZStack(alignment: .leading) {
                    if messageText.isEmpty {
                        Text("Type a message...")
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.leading, 16)
                    }
                    TextField("", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($isInputFocused)
                        .lineLimit(1...5)
                }
                .background(AppTheme.card)
                .cornerRadius(20)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(messageText.isEmpty ? AppTheme.textTertiary : .black)
                        .frame(width: 44, height: 44)
                        .background(messageText.isEmpty ? AppTheme.card : AppTheme.accent)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) { return date }
        // Fallback for dates without fractional seconds (optimistic messages)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func shouldShowDateSeparator(at index: Int) -> Bool {
        let message = viewModel.messages[index]
        guard let date = parseDate(message.createdAt) else { return false }
        if index == 0 { return true }
        let previous = viewModel.messages[index - 1]
        guard let prevDate = parseDate(previous.createdAt) else { return true }
        return !Calendar.current.isDate(date, inSameDayAs: prevDate)
    }

    private func dateSeparator(for dateString: String?) -> some View {
        let label: String = {
            guard let dateString, let date = parseDate(dateString) else { return "" }
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
        }()

        return Text(label)
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
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let date else { return "" }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }
}
