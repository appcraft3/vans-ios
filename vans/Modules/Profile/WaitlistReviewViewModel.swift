import Foundation
import Combine
import SwiftUI

struct WaitlistUser: Identifiable, Codable {
    let id: String
    let email: String?
    let profile: UserProfile?
    let submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case email
        case profile
        case submittedAt
    }
}

struct WaitlistQueueResponse: Codable {
    let success: Bool
    let users: [WaitlistUser]
    let total: Int
}

struct ReviewProfileResponse: Codable {
    let success: Bool
    let message: String
}

final class WaitlistReviewViewModel: ObservableObject {
    @Published var waitlistUsers: [WaitlistUser] = []
    @Published var isLoading: Bool = false
    @Published var processingUserId: String?

    init() {
        loadWaitlist()
    }

    func loadWaitlist() {
        guard !isLoading else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let response: WaitlistQueueResponse = try await FirebaseManager.shared.callFunction(
                    name: "getWaitlistQueue"
                )
                self.waitlistUsers = response.users
            } catch {
                print("Failed to load waitlist: \(error)")
            }
            isLoading = false
        }
    }

    func refreshWaitlist() {
        waitlistUsers = []
        loadWaitlist()
    }

    func approveUser(_ user: WaitlistUser) {
        reviewUser(user, decision: "approved")
    }

    func rejectUser(_ user: WaitlistUser) {
        reviewUser(user, decision: "rejected")
    }

    private func reviewUser(_ user: WaitlistUser, decision: String) {
        processingUserId = user.id

        Task { @MainActor in
            do {
                let _: ReviewProfileResponse = try await FirebaseManager.shared.callFunction(
                    name: "reviewProfile",
                    data: [
                        "targetUserId": user.id,
                        "decision": decision
                    ]
                )

                withAnimation {
                    waitlistUsers.removeAll { $0.id == user.id }
                }
            } catch {
                print("Failed to \(decision) user: \(error)")
            }
            processingUserId = nil
        }
    }
}
