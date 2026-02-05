import Foundation

// MARK: - Builder Category

enum BuilderCategory: String, Codable, CaseIterable, Identifiable {
    case electrical
    case solar
    case plumbing
    case insulation
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .electrical: return "Electrical"
        case .solar: return "Solar"
        case .plumbing: return "Plumbing"
        case .insulation: return "Insulation"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .electrical: return "bolt.fill"
        case .solar: return "sun.max.fill"
        case .plumbing: return "drop.fill"
        case .insulation: return "square.stack.3d.up.fill"
        case .general: return "wrench.and.screwdriver.fill"
        }
    }

    var emoji: String {
        switch self {
        case .electrical: return "\u{26A1}"
        case .solar: return "\u{2600}"
        case .plumbing: return "\u{1F6BF}"
        case .insulation: return "\u{1F9F1}"
        case .general: return "\u{1F6E0}"
        }
    }
}

// MARK: - Builder Status

enum BuilderStatus: String, Codable {
    case pending
    case approved
    case suspended
}

// MARK: - Session Status

enum SessionStatus: String, Codable {
    case pendingPayment = "pending_payment"
    case paid
    case inProgress = "in_progress"
    case completed
    case cancelled
    case refunded

    var displayName: String {
        switch self {
        case .pendingPayment: return "Awaiting Payment"
        case .paid: return "Paid"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }

    var color: String {
        switch self {
        case .pendingPayment: return "orange"
        case .paid: return "blue"
        case .inProgress: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .refunded: return "purple"
        }
    }
}

// MARK: - Builder Profile

struct BuilderProfile: Codable, Identifiable {
    let userId: String
    let categories: [BuilderCategory]
    let bio: String
    let sessionPrices: SessionPrices
    let availability: String
    let status: BuilderStatus
    let totalSessions: Int
    let completedSessions: Int
    let positiveReviews: Int
    let negativeReviews: Int
    let rating: Int
    let createdAt: String?
    let updatedAt: String?

    // User info (populated from user document)
    var profile: UserProfile?
    var trust: TrustInfo?
    var isPremium: Bool?
    var sharedEventsCount: Int?

    var id: String { odId ?? odId ?? userId }
    var odId: String? { userId }

    var ratingText: String {
        if completedSessions == 0 {
            return "New"
        }
        return "\(rating)%"
    }

    var totalReviews: Int {
        positiveReviews + negativeReviews
    }
}

struct SessionPrices: Codable {
    let fifteenMin: Int
    let thirtyMin: Int

    enum CodingKeys: String, CodingKey {
        case fifteenMin = "15"
        case thirtyMin = "30"
    }

    init(fifteenMin: Int, thirtyMin: Int) {
        self.fifteenMin = fifteenMin
        self.thirtyMin = thirtyMin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fifteenMin = try container.decode(Int.self, forKey: .fifteenMin)
        thirtyMin = try container.decode(Int.self, forKey: .thirtyMin)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fifteenMin, forKey: .fifteenMin)
        try container.encode(thirtyMin, forKey: .thirtyMin)
    }

    func price(for duration: Int) -> Int {
        duration == 15 ? fifteenMin : thirtyMin
    }
}

// MARK: - Builder Session

struct BuilderSession: Codable, Identifiable {
    let id: String
    let builderId: String
    let clientId: String
    let category: BuilderCategory
    let duration: Int
    let price: Int
    let status: SessionStatus
    let sourceEventId: String?
    let scheduledAt: String?
    let paidAt: String?
    let startedAt: String?
    let completedAt: String?
    let cancelledAt: String?
    let cancelReason: String?
    let chatEnabled: Bool
    let reviewed: Bool
    let createdAt: String?

    // Other user info (populated based on context)
    var otherUser: SessionOtherUser?

    var canChat: Bool {
        chatEnabled && (status == .paid || status == .inProgress)
    }

    var canReview: Bool {
        status == .completed && !reviewed
    }

    var statusDisplayName: String {
        status.displayName
    }
}

struct SessionOtherUser: Codable {
    let odId: String
    let profile: UserProfile?
    let trust: TrustInfo?
}

// MARK: - API Responses

struct BuilderProfileResponse: Codable {
    let success: Bool
    let builder: BuilderProfile
}

struct BuildersListResponse: Codable {
    let success: Bool
    let builders: [BuilderProfile]
}

struct MyBuilderProfileResponse: Codable {
    let success: Bool
    let isBuilder: Bool
    let canBecomeBuilder: Bool?
    let builder: BuilderProfile?
}

struct CreateSessionResponse: Codable {
    let success: Bool
    let session: BuilderSession
    let message: String
}

struct BuilderSessionsResponse: Codable {
    let success: Bool
    let sessions: [BuilderSession]
}

struct BuilderSessionMessagesResponse: Codable {
    let success: Bool
    let messages: [BuilderSessionMessage]
    let chatEnabled: Bool
    let sessionStatus: SessionStatus
}

struct BuilderSessionMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let content: String
    let createdAt: String?
    let read: Bool
}

struct BecomeBuilderResponse: Codable {
    let success: Bool
    let message: String
    let builder: BuilderProfile?
}
