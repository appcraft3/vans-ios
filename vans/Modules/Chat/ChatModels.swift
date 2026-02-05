import Foundation

struct ChatUser: Codable {
    let odId: String?
    let userId: String?
    let profile: UserProfile?
    let isPremium: Bool

    var id: String {
        odId ?? odId ?? ""
    }
}

struct Chat: Identifiable, Codable {
    let chatId: String
    let otherUser: ChatUser
    let lastMessage: String?
    let lastMessageAt: String?
    let unreadCount: Int
    let canSendMessage: Bool
    // Event connection fields
    let sourceEventName: String?
    let waitingForHer: Bool?
    let hasMessaged: Bool?
    let isExpired: Bool?

    var id: String { chatId }
}

// Event match from getEventMatches
struct EventMatchChat: Identifiable, Codable {
    let odId: String
    let otherUser: ChatUser
    let sourceEventName: String
    let sharedEventsCount: Int
    let createdAt: String?
    let dmExpiresAt: String?
    let isExpired: Bool
    let canSendMessage: Bool
    let waitingForHer: Bool
    let hasMessaged: Bool

    var id: String { odId }
}

struct EventMatchesResponse: Codable {
    let success: Bool
    let matches: [EventMatchChat]
}

struct ChatsResponse: Codable {
    let success: Bool
    let chats: [Chat]
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let content: String
    let createdAt: String?
    let read: Bool
}

struct MessagesResponse: Codable {
    let success: Bool
    let messages: [ChatMessage]
    let hasMore: Bool
}

struct GetChatResponse: Codable {
    let success: Bool
    let chatId: String
    let otherUser: ChatUser
    let canSendMessage: Bool
    let waitingForFemale: Bool
    let firstMessageSentBy: String?
}

struct SendMessageResponse: Codable {
    let success: Bool
    let message: ChatMessage
}

struct MarkReadResponse: Codable {
    let success: Bool
    let markedCount: Int
}
