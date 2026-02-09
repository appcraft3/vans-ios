import Foundation
import FirebaseFunctions

@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published var event: VanEvent?
    @Published var attendees: [EventAttendee] = []
    @Published var isInterested = false
    @Published var isAttending = false
    @Published var canReview = false
    @Published var isAdmin = false
    @Published var checkInCode: String?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedAttendeeForReview: EventAttendee?

    // Interest system
    @Published var canSendInterests = false
    @Published var interestsCount = 0
    @Published var interestLimit = 5
    @Published var interestsRemaining = 5
    @Published var processingInterestFor: String? = nil

    let eventId: String
    private let functions = Functions.functions()
    private weak var coordinator: EventsCoordinating?

    init(eventId: String, coordinator: EventsCoordinating? = nil) {
        self.eventId = eventId
        self.coordinator = coordinator
    }

    var interestLimitText: String {
        "\(interestsCount)/\(interestLimit) interests"
    }

    func openUserProfile(_ attendee: EventAttendee) {
        coordinator?.showUserProfile(
            userId: attendee.id,
            profile: attendee.profile,
            trust: attendee.trust,
            isPremium: attendee.isPremium
        )
    }

    func loadEventDetails() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let result = try await functions.httpsCallable("getEventDetails").call(["eventId": eventId])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let eventData = data["event"] as? [String: Any] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            event = parseEvent(eventData)
            isInterested = data["isInterested"] as? Bool ?? false
            isAttending = data["isAttending"] as? Bool ?? false
            canReview = data["canReview"] as? Bool ?? false
            isAdmin = data["isAdmin"] as? Bool ?? false
            checkInCode = eventData["checkInCode"] as? String

            // Interest system fields
            canSendInterests = data["canSendInterests"] as? Bool ?? false
            interestsCount = data["interestsCount"] as? Int ?? 0
            interestLimit = data["interestLimit"] as? Int ?? 5
            interestsRemaining = data["interestsRemaining"] as? Int ?? 5

            if let attendeesData = data["attendees"] as? [[String: Any]] {
                attendees = attendeesData.compactMap { parseAttendee($0) }
            }

            // Update event with attendance info
            if var e = event {
                e.isInterested = isInterested
                e.isAttending = isAttending
                event = e
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func joinEvent() async {
        isProcessing = true

        do {
            let result = try await functions.httpsCallable("joinEvent").call(["eventId": eventId])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to join"])
            }

            isInterested = true
            if var e = event {
                e.isInterested = true
                e.attendeesCount += 1
                event = e
            }
            successMessage = "You're interested in this event!"
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func leaveEvent() async {
        isProcessing = true

        do {
            let result = try await functions.httpsCallable("leaveEvent").call(["eventId": eventId])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to leave"])
            }

            isInterested = false
            if var e = event {
                e.isInterested = false
                e.attendeesCount = max(0, e.attendeesCount - 1)
                event = e
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func checkIn(code: String) async {
        isProcessing = true

        do {
            let result = try await functions.httpsCallable("checkInToEvent").call([
                "eventId": eventId,
                "checkInCode": code
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid code"])
            }

            isAttending = true
            if var e = event {
                e.isAttending = true
                event = e
            }
            successMessage = data["message"] as? String ?? "You're now attending!"
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func enableCheckIn() async {
        isProcessing = true

        do {
            let result = try await functions.httpsCallable("enableEventCheckIn").call(["eventId": eventId])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed"])
            }

            if var e = event {
                e.checkInEnabled = true
                event = e
            }
            successMessage = "Check-in enabled! Event is now ongoing."
            await loadEventDetails()
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func completeEvent() async {
        isProcessing = true

        do {
            let result = try await functions.httpsCallable("completeEvent").call(["eventId": eventId])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed"])
            }

            successMessage = "Event completed! Attendees can now leave reviews."
            await loadEventDetails()
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func openReviewSheet(for attendee: EventAttendee) {
        selectedAttendeeForReview = attendee
    }

    func submitReview(for userId: String, reviewText: String) async {
        do {
            let result = try await functions.httpsCallable("submitEventReview").call([
                "eventId": eventId,
                "targetUserId": userId,
                "reviewText": reviewText
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed"])
            }

            // Remove from reviewable list
            attendees.removeAll { $0.id == userId }
            selectedAttendeeForReview = nil
            successMessage = "Review submitted!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseEvent(_ data: [String: Any]) -> VanEvent? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let activityType = data["activityType"] as? String,
              let region = data["region"] as? String,
              let statusString = data["status"] as? String,
              let status = VanEvent.EventStatus(rawValue: statusString) else {
            return nil
        }

        let dateString = data["date"] as? String ?? ""
        let endDateString = data["endDate"] as? String ?? dateString
        let createdAtString = data["createdAt"] as? String ?? ""

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = formatter.date(from: dateString) ?? Date()
        let endDate = formatter.date(from: endDateString) ?? date
        let createdAt = formatter.date(from: createdAtString) ?? Date()

        return VanEvent(
            id: id,
            title: title,
            description: data["description"] as? String ?? "",
            activityType: activityType,
            region: region,
            approximateArea: data["approximateArea"] as? String ?? "",
            date: date,
            endDate: endDate,
            maxAttendees: data["maxAttendees"] as? Int ?? 50,
            attendeesCount: data["attendeesCount"] as? Int ?? 0,
            createdBy: data["createdBy"] as? String ?? "",
            createdAt: createdAt,
            status: status,
            checkInEnabled: data["checkInEnabled"] as? Bool ?? false,
            allowCheckIn: data["allowCheckIn"] as? Bool ?? true,
            isInterested: false,
            isAttending: false,
            hasBuilder: data["hasBuilder"] as? Bool ?? false,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double
        )
    }

    private func parseAttendee(_ data: [String: Any]) -> EventAttendee? {
        guard let userId = data["odId"] as? String ?? data["userId"] as? String,
              let profileData = data["profile"] as? [String: Any],
              let firstName = profileData["firstName"] as? String,
              let photoUrl = profileData["photoUrl"] as? String,
              let age = profileData["age"] as? Int,
              let region = profileData["region"] as? String,
              let genderString = profileData["gender"] as? String else {
            return nil
        }

        let trustData = data["trust"] as? [String: Any] ?? [:]
        let activities = profileData["activities"] as? [String] ?? []

        let profile = UserProfile(
            firstName: firstName,
            photoUrl: photoUrl,
            age: age,
            gender: Gender(rawValue: genderString) ?? .male,
            vanLifeStatus: VanLifeStatus(rawValue: profileData["vanLifeStatus"] as? String ?? "") ?? .planning,
            region: region,
            activities: activities,
            bio: profileData["bio"] as? String
        )

        let trust = TrustInfo(
            level: trustData["level"] as? Int ?? 0,
            badges: trustData["badges"] as? [String] ?? [],
            eventsAttended: trustData["eventsAttended"] as? Int ?? 0,
            positiveReviews: trustData["positiveReviews"] as? Int ?? 0,
            negativeReviews: trustData["negativeReviews"] as? Int ?? 0,
            reviewCount: trustData["reviewCount"] as? Int ?? 0
        )

        return EventAttendee(
            id: userId,
            profile: profile,
            trust: trust,
            isPremium: data["isPremium"] as? Bool ?? false,
            checkedIn: data["checkedIn"] as? Bool ?? false,
            isInterestedIn: data["isInterestedIn"] as? Bool ?? false
        )
    }

    // MARK: - Interest Actions

    func sendInterest(to attendee: EventAttendee) async {
        guard canSendInterests, interestsRemaining > 0 else {
            errorMessage = "You've used all your interests for this event"
            return
        }

        processingInterestFor = attendee.id

        do {
            let result = try await functions.httpsCallable("sendEventInterest").call([
                "eventId": eventId,
                "targetUserId": attendee.id
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send interest"])
            }

            // Update local state
            if let remaining = data["interestsRemaining"] as? Int {
                interestsRemaining = remaining
                interestsCount = interestLimit - remaining
            }

            // Update attendee in list
            if let index = attendees.firstIndex(where: { $0.id == attendee.id }) {
                attendees[index].isInterestedIn = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        processingInterestFor = nil
    }

    func removeInterest(from attendee: EventAttendee) async {
        processingInterestFor = attendee.id

        do {
            let result = try await functions.httpsCallable("removeEventInterest").call([
                "eventId": eventId,
                "targetUserId": attendee.id
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove interest"])
            }

            // Update local state
            if let remaining = data["interestsRemaining"] as? Int {
                interestsRemaining = remaining
                interestsCount = interestLimit - remaining
            }

            // Update attendee in list
            if let index = attendees.firstIndex(where: { $0.id == attendee.id }) {
                attendees[index].isInterestedIn = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        processingInterestFor = nil
    }

    func toggleInterest(for attendee: EventAttendee) async {
        if attendee.isInterestedIn {
            await removeInterest(from: attendee)
        } else {
            await sendInterest(to: attendee)
        }
    }
}
