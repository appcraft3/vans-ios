import Foundation
import FirebaseFirestore
import Combine

struct MatchInfo {
    let connectionId: String
    let otherUserId: String
    let otherUserName: String
    let otherUserPhotoUrl: String?
    let eventName: String
}

final class MatchManager: ObservableObject {
    static let shared = MatchManager()

    @Published var currentMatch: MatchInfo?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var knownConnectionIds: Set<String> = []
    private var isInitialLoad = true

    private init() {}

    func startListening() {
        guard let userId = AuthManager.shared.currentUserId else { return }
        stopListening()

        isInitialLoad = true
        knownConnectionIds = []

        listener = db.collection("eventConnections")
            .whereField("userIds", arrayContains: userId)
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("MatchManager listener error: \(error)")
                    return
                }
                guard let snapshot else { return }

                if self.isInitialLoad {
                    self.knownConnectionIds = Set(snapshot.documents.map { $0.documentID })
                    self.isInitialLoad = false
                    return
                }

                for change in snapshot.documentChanges {
                    if change.type == .added && !self.knownConnectionIds.contains(change.document.documentID) {
                        self.knownConnectionIds.insert(change.document.documentID)
                        self.handleNewMatch(document: change.document, currentUserId: userId)
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func dismissMatch() {
        currentMatch = nil
    }

    private func handleNewMatch(document: QueryDocumentSnapshot, currentUserId: String) {
        let data = document.data()

        guard let userIds = data["userIds"] as? [String],
              let eventName = data["sourceEventName"] as? String else { return }

        let otherUserId = userIds.first { $0 != currentUserId } ?? ""

        var otherUserName = "Someone"
        var otherUserPhotoUrl: String?

        if let users = data["users"] as? [String: Any],
           let otherUserData = users[otherUserId] as? [String: Any] {
            otherUserName = otherUserData["firstName"] as? String ?? "Someone"
            otherUserPhotoUrl = otherUserData["photoUrl"] as? String
        }

        let match = MatchInfo(
            connectionId: document.documentID,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserPhotoUrl: otherUserPhotoUrl,
            eventName: eventName
        )

        DispatchQueue.main.async {
            self.currentMatch = match
        }
    }
}
