import Foundation

struct VanEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let activityType: String
    let region: String
    let approximateArea: String
    let date: Date
    let endDate: Date
    let maxAttendees: Int
    var attendeesCount: Int
    let createdBy: String
    let createdAt: Date
    var status: EventStatus
    var checkInEnabled: Bool
    var isInterested: Bool
    var isAttending: Bool

    enum EventStatus: String, Codable {
        case upcoming
        case ongoing
        case completed
        case cancelled
    }

    var activityIcon: String {
        switch activityType {
        case "hiking": return "figure.hiking"
        case "surfing": return "figure.surfing"
        case "climbing": return "figure.climbing"
        case "cycling": return "figure.outdoor.cycle"
        case "kayaking": return "figure.rowing"
        case "photography": return "camera"
        case "yoga": return "figure.yoga"
        case "cooking": return "fork.knife"
        case "reading": return "book"
        case "music": return "music.note"
        case "art": return "paintbrush"
        case "remote_work": return "laptopcomputer"
        case "stargazing": return "star"
        case "fishing": return "fish"
        case "birdwatching": return "bird"
        default: return "calendar"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    var statusColor: String {
        switch status {
        case .upcoming: return "blue"
        case .ongoing: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }
}

struct EventAttendee: Identifiable {
    let id: String
    let profile: UserProfile
    let trust: TrustInfo
    let isPremium: Bool
    let checkedIn: Bool
    var isInterestedIn: Bool // Whether current user has sent interest to this attendee
}

// Event match from mutual interests
struct EventMatch: Identifiable {
    let id: String
    let otherUser: MatchedUser
    let sourceEventName: String
    let sharedEventsCount: Int
    let createdAt: Date
    let dmExpiresAt: Date?
    let isExpired: Bool
    let canSendMessage: Bool
    let waitingForHer: Bool
    let hasMessaged: Bool
}

struct MatchedUser {
    let userId: String
    let profile: UserProfile
    let trust: TrustInfo
    let isPremium: Bool
}

struct EventDetailResponse {
    let event: VanEvent
    let attendees: [EventAttendee]
    let isInterested: Bool
    let isAttending: Bool
    let canReview: Bool
    let isAdmin: Bool
    let checkInCode: String?
}
