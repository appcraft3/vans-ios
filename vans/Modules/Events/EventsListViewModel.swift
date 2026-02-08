import Foundation
import FirebaseFunctions
import MapKit

@MainActor
final class EventsListViewModel: ActionableViewModel {
    @Published var events: [VanEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canCreateEvents = false
    @Published var selectedLocation: LocationResult?

    private weak var coordinator: EventsCoordinating?
    private let functions = Functions.functions()

    init(coordinator: EventsCoordinating?) {
        self.coordinator = coordinator
        checkUserRole()
    }

    func clearLocationFilter() {
        selectedLocation = nil
        Task { await loadEvents() }
    }

    private func checkUserRole() {
        if let user = AuthManager.shared.currentUser {
            canCreateEvents = user.role == .admin || user.role == .moderator
        }
    }

    func loadEvents() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            var params: [String: Any] = ["limit": 30]

            if let location = selectedLocation {
                params["region"] = location.region
                params["country"] = location.country
            }

            let result = try await functions.httpsCallable("getEvents").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let eventsData = data["events"] as? [[String: Any]] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            events = eventsData.compactMap { parseEvent($0) }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshEvents() async {
        await loadEvents()
    }

    func openEventDetail(_ event: VanEvent) {
        coordinator?.showEventDetail(eventId: event.id)
    }

    func toggleInterest(for event: VanEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        let wasInterested = events[index].isInterested

        // Optimistic update — stays even if API fails, syncs on next load
        events[index].isInterested = !wasInterested
        events[index].attendeesCount += wasInterested ? -1 : 1

        Task {
            let functionName = wasInterested ? "leaveEvent" : "joinEvent"
            _ = try? await functions.httpsCallable(functionName).call(["eventId": event.id])
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
            isInterested: data["isInterested"] as? Bool ?? false,
            isAttending: data["isAttending"] as? Bool ?? false,
            hasBuilder: data["hasBuilder"] as? Bool ?? false,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double
        )
    }
}
