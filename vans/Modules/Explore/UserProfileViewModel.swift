import Foundation
import Combine

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
                let response: UserReviewsResponse = try await FirebaseManager.shared.callFunction(
                    name: "getUserReviews",
                    data: ["userId": userId]
                )
                self.reviews = response.reviews
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
