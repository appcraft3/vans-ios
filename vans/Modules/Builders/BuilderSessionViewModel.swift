import Foundation
import FirebaseFunctions

@MainActor
final class BuilderSessionViewModel: ObservableObject {
    @Published var session: BuilderSession
    @Published var messages: [BuilderSessionMessage] = []
    @Published var messageText: String = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var showCompleteAlert = false
    @Published var showReviewSheet = false

    let asBuilder: Bool
    private let functions = Functions.functions()
    private weak var coordinator: BuildersCoordinating?

    init(session: BuilderSession, asBuilder: Bool, coordinator: BuildersCoordinating?) {
        self.session = session
        self.asBuilder = asBuilder
        self.coordinator = coordinator
    }

    var canSendMessage: Bool {
        session.chatEnabled && !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var otherUserName: String {
        session.otherUser?.profile?.firstName ?? (asBuilder ? "Client" : "Builder")
    }

    var statusText: String {
        switch session.status {
        case .pendingPayment:
            return "Awaiting payment"
        case .paid:
            return "Session active"
        case .inProgress:
            return "Session in progress"
        case .completed:
            return "Session completed - Chat is read-only"
        case .cancelled:
            return "Session cancelled"
        case .refunded:
            return "Session refunded"
        }
    }

    func loadMessages() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let result = try await functions.httpsCallable("getBuilderSessionMessages").call([
                "sessionId": session.id,
                "limit": 100
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load messages"])
            }

            if let messagesData = data["messages"] as? [[String: Any]] {
                messages = messagesData.compactMap { parseMessage($0) }
            }

            // Update session status from response
            if let statusRaw = data["sessionStatus"] as? String,
               let status = SessionStatus(rawValue: statusRaw) {
                session = BuilderSession(
                    id: session.id,
                    builderId: session.builderId,
                    clientId: session.clientId,
                    category: session.category,
                    duration: session.duration,
                    price: session.price,
                    status: status,
                    sourceEventId: session.sourceEventId,
                    scheduledAt: session.scheduledAt,
                    paidAt: session.paidAt,
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    cancelledAt: session.cancelledAt,
                    cancelReason: session.cancelReason,
                    chatEnabled: data["chatEnabled"] as? Bool ?? session.chatEnabled,
                    reviewed: session.reviewed,
                    createdAt: session.createdAt,
                    otherUser: session.otherUser
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSending = true
        let tempText = messageText
        messageText = ""

        do {
            let result = try await functions.httpsCallable("sendBuilderSessionMessage").call([
                "sessionId": session.id,
                "content": content
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                messageText = tempText
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send message"])
            }

            // Reload messages to get the new one with server timestamp
            await loadMessages()
        } catch {
            errorMessage = error.localizedDescription
            messageText = tempText
        }

        isSending = false
    }

    func completeSession() async {
        do {
            let result = try await functions.httpsCallable("completeBuilderSession").call([
                "sessionId": session.id
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to complete session"])
            }

            // Update local session state
            session = BuilderSession(
                id: session.id,
                builderId: session.builderId,
                clientId: session.clientId,
                category: session.category,
                duration: session.duration,
                price: session.price,
                status: .completed,
                sourceEventId: session.sourceEventId,
                scheduledAt: session.scheduledAt,
                paidAt: session.paidAt,
                startedAt: session.startedAt,
                completedAt: ISO8601DateFormatter().string(from: Date()),
                cancelledAt: session.cancelledAt,
                cancelReason: session.cancelReason,
                chatEnabled: false,
                reviewed: session.reviewed,
                createdAt: session.createdAt,
                otherUser: session.otherUser
            )

            // Show review sheet if client
            if !asBuilder {
                showReviewSheet = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitReview(isPositive: Bool) async {
        do {
            let result = try await functions.httpsCallable("submitBuilderReview").call([
                "sessionId": session.id,
                "isPositive": isPositive
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to submit review"])
            }

            // Update session as reviewed
            session = BuilderSession(
                id: session.id,
                builderId: session.builderId,
                clientId: session.clientId,
                category: session.category,
                duration: session.duration,
                price: session.price,
                status: session.status,
                sourceEventId: session.sourceEventId,
                scheduledAt: session.scheduledAt,
                paidAt: session.paidAt,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                cancelledAt: session.cancelledAt,
                cancelReason: session.cancelReason,
                chatEnabled: session.chatEnabled,
                reviewed: true,
                createdAt: session.createdAt,
                otherUser: session.otherUser
            )

            showReviewSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    private func parseMessage(_ data: [String: Any]) -> BuilderSessionMessage? {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String else {
            return nil
        }

        return BuilderSessionMessage(
            id: id,
            senderId: senderId,
            content: content,
            createdAt: data["createdAt"] as? String,
            read: data["read"] as? Bool ?? false
        )
    }
}
