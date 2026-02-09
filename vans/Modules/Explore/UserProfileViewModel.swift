import Foundation
import Combine
import FirebaseFunctions

struct UserProfileData: Codable {
    let userId: String
    let profile: UserProfile
    let trust: TrustInfo
    let isPremium: Bool
    let connectionsCount: Int
}

struct UserProfileResponse: Codable {
    let success: Bool
    let user: UserProfileData
}

struct UserReview: Identifiable, Codable {
    let id: String
    let reviewerFirstName: String
    let reviewerPhotoUrl: String
    let eventTitle: String
    let reviewText: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case reviewerFirstName = "reviewerFirstName"
        case reviewerPhotoUrl = "reviewerPhotoUrl"
        case eventTitle = "eventTitle"
        case reviewText = "reviewText"
        case createdAt = "createdAt"
    }
}

struct UserReviewsResponse: Codable {
    let success: Bool
    let reviews: [UserReview]
}

final class UserProfileViewModel: ObservableObject {
    @Published var user: UserProfileData?
    @Published var isLoading: Bool = false
    @Published var connectionsCount: Int = 0
    @Published var reviews: [UserReview] = []
    @Published var isLoadingReviews: Bool = false

    private let userId: String
    private let initialUser: DiscoveryUser

    init(user: DiscoveryUser) {
        self.userId = user.id
        self.initialUser = user
    }

    func loadProfile() {
        guard !isLoading else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: UserProfileResponse = try await FirebaseManager.shared.callFunction(
                    name: "getUserProfile",
                    data: ["userId": userId]
                )
                self.user = response.user
                self.connectionsCount = response.user.connectionsCount
            } catch {
                print("Failed to load profile: \(error)")
            }
            isLoading = false
        }

        loadReviews()
    }

    func loadReviews() {
        guard !isLoadingReviews else { return }
        isLoadingReviews = true

        Task { @MainActor in
            do {
                let result = try await Functions.functions().httpsCallable("getUserReviews").call(["userId": userId])
                guard let data = result.data as? [String: Any],
                      let success = data["success"] as? Bool, success,
                      let reviewsData = data["reviews"] as? [[String: Any]] else {
                    isLoadingReviews = false
                    return
                }

                self.reviews = reviewsData.map { d in
                    UserReview(
                        id: d["id"] as? String ?? UUID().uuidString,
                        reviewerFirstName: d["reviewerFirstName"] as? String ?? "Anonymous",
                        reviewerPhotoUrl: d["reviewerPhotoUrl"] as? String ?? "",
                        eventTitle: d["eventTitle"] as? String ?? "",
                        reviewText: d["reviewText"] as? String ?? "",
                        createdAt: d["createdAt"] as? String
                    )
                }
            } catch {
                print("Failed to load reviews: \(error)")
            }
            isLoadingReviews = false
        }
    }

    // Use initial user data until full profile loads
    var displayProfile: UserProfile {
        user?.profile ?? initialUser.profile
    }

    var displayTrust: TrustInfo {
        user?.trust ?? initialUser.trust
    }

    var displayIsPremium: Bool {
        user?.isPremium ?? initialUser.isPremium
    }
}
