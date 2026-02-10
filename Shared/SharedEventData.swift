import Foundation

/// Lightweight Codable event model shared between the main app and widget.
struct WidgetEvent: Codable, Identifiable {
    let id: String
    let title: String
    let activityType: String
    let region: String
    let approximateArea: String
    let date: Date
    let endDate: Date
    let attendeesCount: Int
    let maxAttendees: Int
    let status: String
    let firstPhotoURL: String?

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

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    var displayLocation: String {
        approximateArea.isEmpty ? region : approximateArea
    }

    var isUpcomingOrOngoing: Bool {
        status == "upcoming" || status == "ongoing"
    }
}

/// Container for storing events in shared UserDefaults.
struct WidgetEventStore: Codable {
    let events: [WidgetEvent]
    let lastUpdated: Date
}
