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

    var badgeList: [Badge] {
        badges.compactMap { Badge(rawValue: $0) }
    }

    static var empty: TrustInfo {
        TrustInfo(level: 0, badges: [], eventsAttended: 0, positiveReviews: 0, negativeReviews: 0)
    }
}
