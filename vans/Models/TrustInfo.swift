import Foundation

enum Badge: String, Codable, CaseIterable {
    case eventParticipant = "event_participant"
    case verified
    case trustedMember = "trusted_member"
    case trustedBuilder = "trusted_builder"

    var displayName: String {
        switch self {
        case .eventParticipant: return "Event Participant"
        case .verified: return "Verified"
        case .trustedMember: return "Trusted Member"
        case .trustedBuilder: return "Builder"
        }
    }

    var icon: String {
        switch self {
        case .eventParticipant: return "calendar.badge.checkmark"
        case .verified: return "checkmark.seal.fill"
        case .trustedMember: return "star.fill"
        case .trustedBuilder: return "wrench.and.screwdriver.fill"
        }
    }
}

struct TrustInfo: Codable {
    let level: Int // Kept for backwards compatibility but not displayed
    let badges: [String]
    let eventsAttended: Int
    let positiveReviews: Int
    let negativeReviews: Int
    let reviewCount: Int

    var badgeList: [Badge] {
        badges.compactMap { Badge(rawValue: $0) }
    }

    static var empty: TrustInfo {
        TrustInfo(level: 0, badges: [], eventsAttended: 0, positiveReviews: 0, negativeReviews: 0, reviewCount: 0)
    }

    enum CodingKeys: String, CodingKey {
        case level, badges, eventsAttended, positiveReviews, negativeReviews, reviewCount
    }

    init(level: Int, badges: [String], eventsAttended: Int, positiveReviews: Int, negativeReviews: Int, reviewCount: Int = 0) {
        self.level = level
        self.badges = badges
        self.eventsAttended = eventsAttended
        self.positiveReviews = positiveReviews
        self.negativeReviews = negativeReviews
        self.reviewCount = reviewCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        badges = try container.decodeIfPresent([String].self, forKey: .badges) ?? []
        eventsAttended = try container.decodeIfPresent(Int.self, forKey: .eventsAttended) ?? 0
        positiveReviews = try container.decodeIfPresent(Int.self, forKey: .positiveReviews) ?? 0
        negativeReviews = try container.decodeIfPresent(Int.self, forKey: .negativeReviews) ?? 0
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
    }
}
