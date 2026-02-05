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
    case nonBinary = "non_binary"

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        }
    }
}

struct UserProfile: Codable {
    let firstName: String
    let photoUrl: String
    let age: Int
    let gender: Gender
    let vanLifeStatus: VanLifeStatus
    let region: String
    let activities: [String]
    let bio: String?

    init(firstName: String, photoUrl: String, age: Int, gender: Gender, vanLifeStatus: VanLifeStatus, region: String, activities: [String], bio: String?) {
        self.firstName = firstName
        self.photoUrl = photoUrl
        self.age = age
        self.gender = gender
        self.vanLifeStatus = vanLifeStatus
        self.region = region
        self.activities = activities
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
