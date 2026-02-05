import Foundation

enum AccessLevel: String, Codable {
    case guest
    case waitlist
    case member
    case premium
}

enum UserRole: String, Codable {
    case user
    case moderator
    case admin

    var isModerator: Bool {
        self == .moderator || self == .admin
    }
}

enum ReviewStatus: String, Codable {
    case none
    case pending
    case approved
    case rejected
    case onHold = "on_hold"
}
