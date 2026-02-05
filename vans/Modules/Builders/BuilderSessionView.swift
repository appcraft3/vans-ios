import SwiftUI
import Kingfisher

struct BuilderSessionView: View {
    @StateObject var viewModel: BuilderSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Session Info Banner
                sessionInfoBanner

                // Messages
                messagesSection

                // Input (if chat enabled)
                if viewModel.session.chatEnabled {
                    inputSection
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadMessages()
            }
        }
        .alert("Complete Session", isPresented: $viewModel.showCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                Task {
                    await viewModel.completeSession()
                }
            }
        } message: {
            Text("Mark this session as complete? The chat will become read-only.")
        }
        .sheet(isPresented: $viewModel.showReviewSheet) {
            ReviewSessionSheet(viewModel: viewModel)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            // Other user info
            if let photoUrl = viewModel.session.otherUser?.profile?.photoUrl {
                KFImage(URL(string: photoUrl))
                    .placeholder {
                        Circle().fill(AppTheme.surface)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(viewModel.otherUserName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    if !viewModel.asBuilder {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                }

                Text(viewModel.session.category.displayName)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Complete button (if session is active)
            if viewModel.session.status == .paid || viewModel.session.status == .inProgress {
                Button(action: { viewModel.showCompleteAlert = true }) {
                    Text("Complete")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.2))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
    }

    private var sessionInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(viewModel.session.duration) min \u{2022} $\(viewModel.session.price)")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Review button if eligible
            if viewModel.session.canReview && !viewModel.asBuilder {
                Button(action: { viewModel.showReviewSheet = true }) {
                    Text("Leave Review")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .padding()
        .background(AppTheme.card)
    }

    private var statusIcon: String {
        switch viewModel.session.status {
        case .pendingPayment: return "clock.fill"
        case .paid, .inProgress: return "message.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled, .refunded: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.session.status {
        case .pendingPayment: return AppTheme.warning
        case .paid, .inProgress: return AppTheme.accent
        case .completed: return AppTheme.secondary
        case .cancelled, .refunded: return AppTheme.error
        }
    }

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message
                    welcomeMessage

                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: isFromCurrentUser(message)
                        )
                        .id(message.id)
                    }
                }
                .padding()
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

    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.session.category.icon)
                .font(.largeTitle)
                .foregroundColor(AppTheme.primary)

            Text("Session started")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text("Share photos and details about your \(viewModel.session.category.displayName.lowercased()) issue. \(viewModel.otherUserName) will help you out!")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .cornerRadius(16)
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.inputBackground)
                .cornerRadius(24)
                .focused($isInputFocused)
                .lineLimit(1...5)

            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: viewModel.isSending ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.canSendMessage ? AppTheme.accent : AppTheme.divider)
            }
            .disabled(!viewModel.canSendMessage)
        }
        .padding()
        .background(AppTheme.surface)
    }

    private func isFromCurrentUser(_ message: BuilderSessionMessage) -> Bool {
        if viewModel.asBuilder {
            return message.senderId == viewModel.session.builderId
        } else {
            return message.senderId == viewModel.session.clientId
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: BuilderSessionMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .black : AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? AppTheme.accent : AppTheme.card)
                    .cornerRadius(18)

                if let createdAt = message.createdAt {
                    Text(formatTime(createdAt))
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Review Session Sheet

struct ReviewSessionSheet: View {
    @ObservedObject var viewModel: BuilderSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Handle
                Capsule()
                    .fill(AppTheme.divider)
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("How was your session?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your feedback helps the community")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack(spacing: 24) {
                    // Thumbs up
                    Button(action: {
                        Task {
                            await viewModel.submitReview(isPositive: true)
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.accent)

                            Text("Helpful")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }

                    // Thumbs down
                    Button(action: {
                        Task {
                            await viewModel.submitReview(isPositive: false)
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.error)

                            Text("Not helpful")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)

                Button(action: { dismiss() }) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()
            }
            .padding()
        }
        .presentationDetents([.medium])
    }
}
