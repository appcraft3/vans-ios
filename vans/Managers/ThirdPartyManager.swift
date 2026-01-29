import Foundation

final class ThirdPartyManager {

    static let shared = ThirdPartyManager()

    private init() {}

    func setup() {
        setupFirebase()
        setupAnalytics()
    }

    private func setupFirebase() {
        FirebaseManager.shared.configure()
    }

    private func setupAnalytics() {
        // Initialize other analytics if needed
    }
}
