import SwiftUI
import Kingfisher

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    let onSelectChat: (String, ChatUser, String?, Bool) -> Void  // chatId, user, eventName, waitingForHer

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Messages")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                if viewModel.isLoading && viewModel.chats.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.chats.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("No matches yet")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Attend events and mark people you'd like\nto connect with using the ❤️ button")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.chats) { chat in
                                ChatRow(chat: chat)
                                    .onTapGesture {
                                        // Don't allow opening expired connections
                                        guard chat.isExpired != true else { return }
                                        onSelectChat(
                                            chat.chatId,
                                            chat.otherUser,
                                            chat.sourceEventName,
                                            chat.waitingForHer ?? false
                                        )
                                    }

                                Divider()
                                    .background(AppTheme.divider)
                            }
                        }
                        .padding(.bottom, 120)
                    }
                    .refreshable {
                        viewModel.refreshChats()
                    }
                }
            }
        }
        .onAppear {
            if viewModel.chats.isEmpty {
                viewModel.loadChats()
            }
        }
    }
}

struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            CachedProfileImage(url: chat.otherUser.profile?.photoUrl, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.otherUser.profile?.firstName ?? "User")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    if chat.otherUser.isPremium {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.primary)
                    }

                    Spacer()

                    if let lastMessageAt = chat.lastMessageAt {
                        Text(formatDate(lastMessageAt))
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }

                // Event source badge
                if let eventName = chat.sourceEventName {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(eventName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(AppTheme.secondary)
                }

                HStack {
                    if chat.isExpired == true {
                        Text("Connection expired")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.error)
                            .italic()
                    } else if chat.waitingForHer == true {
                        Text("Waiting for her to message first...")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .italic()
                    } else if let lastMessage = chat.lastMessage {
                        Text(lastMessage)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    } else if chat.hasMessaged == false {
                        Text("Say hello! 👋")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accent)
                    } else {
                        Text("Start a conversation")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .italic()
                    }

                    Spacer()

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(chat.isExpired == true ? AppTheme.surface : AppTheme.background)
        .opacity(chat.isExpired == true ? 0.6 : 1.0)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }
}
