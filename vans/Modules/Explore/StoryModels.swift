import Foundation

struct Story: Identifiable, Codable {
    let userId: String
    let photoUrl: String
    let user: StoryUser

    private let createdAtStr: String?
    private let expiresAtStr: String?

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId, photoUrl, user
        case createdAtStr = "createdAt"
        case expiresAtStr = "expiresAt"
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    var createdAt: Date {
        guard let str = createdAtStr else { return Date() }
        return Story.isoFormatter.date(from: str) ?? Date()
    }

    var expiresAt: Date {
        guard let str = expiresAtStr else { return Date() }
        return Story.isoFormatter.date(from: str) ?? Date()
    }

    /// 1.0 = freshly posted, 0.0 = about to expire
    var freshness: Double {
        let total = expiresAt.timeIntervalSince(createdAt)
        let remaining = expiresAt.timeIntervalSince(Date())
        guard total > 0 else { return 0 }
        return max(0, min(1, remaining / total))
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

struct StoryUser: Codable {
    let firstName: String
    let photoUrl: String
}

struct GetStoriesResponse: Codable {
    let success: Bool
    let stories: [Story]
}

struct PostStoryResponse: Codable {
    let success: Bool
    let photoUrl: String
    let expiresAt: String
}
