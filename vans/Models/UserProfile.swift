import Foundation

enum VanLifeStatus: String, Codable, CaseIterable {
    case fullTime = "full_time"
    case partTime = "part_time"
    case planning

    var displayName: String {
        switch self {
        case .fullTime: return "Full-time Van Lifer"
        case .partTime: return "Part-time Van Lifer"
        case .planning: return "Planning Van Life"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .female: return "♀"
        case .male: return "♂"
        case .other: return ""
        }
    }
}

struct UserProfile: Codable {
    let firstName: String
    let photoUrl: String
    let age: Int
    let birthday: String? // ISO date string
    let gender: Gender
    let vanLifeStatus: VanLifeStatus
    let region: String
    let activities: [String]
    let languages: [String]?
    let instagramUsername: String?
    let linkedinUrl: String?
    let bio: String?

    init(firstName: String, photoUrl: String, age: Int, birthday: String? = nil, gender: Gender, vanLifeStatus: VanLifeStatus, region: String, activities: [String], languages: [String]? = nil, instagramUsername: String? = nil, linkedinUrl: String? = nil, bio: String? = nil) {
        self.firstName = firstName
        self.photoUrl = photoUrl
        self.age = age
        self.birthday = birthday
        self.gender = gender
        self.vanLifeStatus = vanLifeStatus
        self.region = region
        self.activities = activities
        self.languages = languages
        self.instagramUsername = instagramUsername
        self.linkedinUrl = linkedinUrl
        self.bio = bio
    }
}

struct Activity: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let category: String
}

struct Region: Codable, Identifiable {
    let id: String
    let name: String
    let country: String
}

struct ProfileSetupData: Codable {
    let success: Bool
    let activities: [Activity]
    let regions: [Region]
}

// Available languages for selection
struct Language: Identifiable, Hashable {
    let id: String
    let name: String

    static let allLanguages: [Language] = [
        Language(id: "en", name: "English"),
        Language(id: "es", name: "Spanish"),
        Language(id: "fr", name: "French"),
        Language(id: "de", name: "German"),
        Language(id: "pt", name: "Portuguese"),
        Language(id: "it", name: "Italian"),
        Language(id: "nl", name: "Dutch"),
        Language(id: "pl", name: "Polish"),
        Language(id: "ru", name: "Russian"),
        Language(id: "tr", name: "Turkish"),
        Language(id: "ja", name: "Japanese"),
        Language(id: "zh", name: "Chinese"),
        Language(id: "ko", name: "Korean"),
        Language(id: "ar", name: "Arabic"),
        Language(id: "hi", name: "Hindi"),
        Language(id: "sv", name: "Swedish"),
        Language(id: "no", name: "Norwegian"),
        Language(id: "da", name: "Danish"),
        Language(id: "fi", name: "Finnish"),
        Language(id: "cs", name: "Czech"),
    ]
}
