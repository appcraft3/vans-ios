import Foundation
import FirebaseFunctions

@MainActor
final class BuilderListViewModel: ObservableObject {
    @Published var builders: [BuilderProfile] = []
    @Published var selectedCategory: BuilderCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()
    private weak var coordinator: BuildersCoordinating?
    private let sourceEventId: String?

    init(coordinator: BuildersCoordinating?, initialCategory: BuilderCategory? = nil, sourceEventId: String? = nil) {
        self.coordinator = coordinator
        self.selectedCategory = initialCategory
        self.sourceEventId = sourceEventId
    }

    func loadBuilders() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            var params: [String: Any] = ["limit": 30]
            if let category = selectedCategory {
                params["category"] = category.rawValue
            }
            if let eventId = sourceEventId {
                params["eventId"] = eventId
            }

            let result = try await functions.httpsCallable("getBuilders").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let buildersData = data["builders"] as? [[String: Any]] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            builders = buildersData.compactMap { parseBuilder($0) }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectCategory(_ category: BuilderCategory?) {
        selectedCategory = category
        Task {
            await loadBuilders()
        }
    }

    func openBuilderProfile(_ builder: BuilderProfile) {
        coordinator?.showBuilderProfile(builder: builder)
    }

    func bookSession(with builder: BuilderProfile) {
        coordinator?.showBookSession(builder: builder, category: selectedCategory, sourceEventId: sourceEventId)
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    private func parseBuilder(_ data: [String: Any]) -> BuilderProfile? {
        guard let userId = data["odId"] as? String ?? data["userId"] as? String,
              let categoriesRaw = data["categories"] as? [String],
              let bio = data["bio"] as? String,
              let sessionPricesData = data["sessionPrices"] as? [String: Any],
              let price15 = sessionPricesData["15"] as? Int,
              let price30 = sessionPricesData["30"] as? Int else {
            return nil
        }

        let categories = categoriesRaw.compactMap { BuilderCategory(rawValue: $0) }
        let statusRaw = data["status"] as? String ?? "approved"
        let status = BuilderStatus(rawValue: statusRaw) ?? .approved

        var profile: UserProfile?
        if let profileData = data["profile"] as? [String: Any] {
            profile = parseUserProfile(profileData)
        }

        var trust: TrustInfo?
        if let trustData = data["trust"] as? [String: Any] {
            trust = parseTrustInfo(trustData)
        }

        return BuilderProfile(
            userId: userId,
            categories: categories,
            bio: bio,
            sessionPrices: SessionPrices(fifteenMin: price15, thirtyMin: price30),
            availability: data["availability"] as? String ?? "",
            status: status,
            totalSessions: data["totalSessions"] as? Int ?? 0,
            completedSessions: data["completedSessions"] as? Int ?? 0,
            positiveReviews: data["positiveReviews"] as? Int ?? 0,
            negativeReviews: data["negativeReviews"] as? Int ?? 0,
            rating: data["rating"] as? Int ?? 100,
            createdAt: data["createdAt"] as? String,
            updatedAt: data["updatedAt"] as? String,
            profile: profile,
            trust: trust,
            isPremium: data["isPremium"] as? Bool ?? false,
            sharedEventsCount: data["sharedEventsCount"] as? Int ?? 0
        )
    }

    private func parseUserProfile(_ data: [String: Any]) -> UserProfile? {
        guard let firstName = data["firstName"] as? String,
              let photoUrl = data["photoUrl"] as? String,
              let age = data["age"] as? Int,
              let region = data["region"] as? String,
              let genderString = data["gender"] as? String else {
            return nil
        }

        return UserProfile(
            firstName: firstName,
            photoUrl: photoUrl,
            age: age,
            gender: Gender(rawValue: genderString) ?? .male,
            vanLifeStatus: VanLifeStatus(rawValue: data["vanLifeStatus"] as? String ?? "") ?? .planning,
            region: region,
            activities: data["activities"] as? [String] ?? [],
            bio: data["bio"] as? String
        )
    }

    private func parseTrustInfo(_ data: [String: Any]) -> TrustInfo {
        TrustInfo(
            level: data["level"] as? Int ?? 0,
            badges: data["badges"] as? [String] ?? [],
            eventsAttended: data["eventsAttended"] as? Int ?? 0,
            positiveReviews: data["positiveReviews"] as? Int ?? 0,
            negativeReviews: data["negativeReviews"] as? Int ?? 0
        )
    }
}
