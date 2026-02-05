import Foundation
import Combine

struct DiscoveryUser: Identifiable, Codable {
    let id: String
    let profile: UserProfile
    let trust: TrustInfo
    let isPremium: Bool

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case profile
        case trust
        case isPremium
    }

    init(id: String, profile: UserProfile, trust: TrustInfo, isPremium: Bool) {
        self.id = id
        self.profile = profile
        self.trust = trust
        self.isPremium = isPremium
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        profile = try container.decode(UserProfile.self, forKey: .profile)
        trust = try container.decode(TrustInfo.self, forKey: .trust)
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
    }
}

struct DiscoveryProfilesResponse: Codable {
    let success: Bool
    let profiles: [DiscoveryUser]
    let hasMore: Bool
}

final class ExploreViewModel: ActionableViewModel {
    @Published var users: [DiscoveryUser] = []
    @Published var isLoading: Bool = false
    @Published var hasMore: Bool = false

    private weak var coordinator: ExploreCoordinating?
    private var lastUserId: String?

    init(coordinator: ExploreCoordinating?) {
        self.coordinator = coordinator
    }

    func loadUsers() {
        guard !isLoading else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: DiscoveryProfilesResponse = try await FirebaseManager.shared.callFunction(
                    name: "getDiscoveryProfiles",
                    data: ["limit": 20]
                )
                self.users = response.profiles
                self.hasMore = response.hasMore
                self.lastUserId = response.profiles.last?.id
            } catch {
                print("Failed to load users: \(error)")
            }
            isLoading = false
        }
    }

    func loadMoreUsers() {
        guard !isLoading, hasMore, let lastId = lastUserId else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: DiscoveryProfilesResponse = try await FirebaseManager.shared.callFunction(
                    name: "getDiscoveryProfiles",
                    data: ["limit": 20, "lastUserId": lastId]
                )
                self.users.append(contentsOf: response.profiles)
                self.hasMore = response.hasMore
                self.lastUserId = response.profiles.last?.id
            } catch {
                print("Failed to load more users: \(error)")
            }
            isLoading = false
        }
    }

    func refreshUsers() {
        lastUserId = nil
        users = []
        loadUsers()
    }

    func openUserProfile(_ user: DiscoveryUser) {
        coordinator?.showUserProfile(user)
    }
}
