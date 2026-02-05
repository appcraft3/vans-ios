import Foundation
import FirebaseFunctions

@MainActor
final class BookSessionViewModel: ObservableObject {
    @Published var selectedCategory: BuilderCategory?
    @Published var selectedDuration: Int = 15
    @Published var isBooking = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var createdSession: BuilderSession?

    let builder: BuilderProfile
    let sourceEventId: String?
    private let functions = Functions.functions()
    private weak var coordinator: BuildersCoordinating?

    init(builder: BuilderProfile, selectedCategory: BuilderCategory?, sourceEventId: String?, coordinator: BuildersCoordinating?) {
        self.builder = builder
        self.selectedCategory = selectedCategory ?? builder.categories.first
        self.sourceEventId = sourceEventId
        self.coordinator = coordinator
    }

    var currentPrice: Int {
        builder.sessionPrices.price(for: selectedDuration)
    }

    var canBook: Bool {
        selectedCategory != nil && !isBooking
    }

    func selectCategory(_ category: BuilderCategory) {
        if builder.categories.contains(category) {
            selectedCategory = category
        }
    }

    func selectDuration(_ duration: Int) {
        if duration == 15 || duration == 30 {
            selectedDuration = duration
        }
    }

    func bookSession() async {
        guard let category = selectedCategory else {
            errorMessage = "Please select a category"
            return
        }

        isBooking = true
        errorMessage = nil

        do {
            var params: [String: Any] = [
                "builderId": builder.userId,
                "category": category.rawValue,
                "duration": selectedDuration
            ]

            if let eventId = sourceEventId {
                params["sourceEventId"] = eventId
            }

            let result = try await functions.httpsCallable("createBuilderSession").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create session"])
            }

            let message = data["message"] as? String ?? "Session created!"
            successMessage = message

            // Parse created session
            if let sessionData = data["session"] as? [String: Any] {
                createdSession = parseSession(sessionData)
            }

            // In production, this would trigger payment flow
            // For now, auto-confirm payment for testing
            if let session = createdSession {
                await confirmPayment(sessionId: session.id)
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isBooking = false
    }

    private func confirmPayment(sessionId: String) async {
        do {
            let result = try await functions.httpsCallable("confirmBuilderSessionPayment").call([
                "sessionId": sessionId,
                "paymentId": "test_payment_\(UUID().uuidString)"
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                return
            }

            successMessage = data["message"] as? String ?? "Payment confirmed! Chat is now open."

            // Navigate to session chat
            if var session = createdSession {
                session = BuilderSession(
                    id: session.id,
                    builderId: session.builderId,
                    clientId: session.clientId,
                    category: session.category,
                    duration: session.duration,
                    price: session.price,
                    status: .paid,
                    sourceEventId: session.sourceEventId,
                    scheduledAt: session.scheduledAt,
                    paidAt: ISO8601DateFormatter().string(from: Date()),
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    cancelledAt: session.cancelledAt,
                    cancelReason: session.cancelReason,
                    chatEnabled: true,
                    reviewed: session.reviewed,
                    createdAt: session.createdAt,
                    otherUser: nil
                )
                coordinator?.showBuilderSession(session: session, asBuilder: false)
            }
        } catch {
            print("Payment confirmation error: \(error)")
        }
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    private func parseSession(_ data: [String: Any]) -> BuilderSession? {
        guard let id = data["id"] as? String,
              let builderId = data["builderId"] as? String,
              let clientId = data["clientId"] as? String,
              let categoryRaw = data["category"] as? String,
              let category = BuilderCategory(rawValue: categoryRaw),
              let duration = data["duration"] as? Int,
              let price = data["price"] as? Int,
              let statusRaw = data["status"] as? String,
              let status = SessionStatus(rawValue: statusRaw) else {
            return nil
        }

        return BuilderSession(
            id: id,
            builderId: builderId,
            clientId: clientId,
            category: category,
            duration: duration,
            price: price,
            status: status,
            sourceEventId: data["sourceEventId"] as? String,
            scheduledAt: data["scheduledAt"] as? String,
            paidAt: data["paidAt"] as? String,
            startedAt: data["startedAt"] as? String,
            completedAt: data["completedAt"] as? String,
            cancelledAt: data["cancelledAt"] as? String,
            cancelReason: data["cancelReason"] as? String,
            chatEnabled: data["chatEnabled"] as? Bool ?? false,
            reviewed: data["reviewed"] as? Bool ?? false,
            createdAt: data["createdAt"] as? String,
            otherUser: nil
        )
    }
}
