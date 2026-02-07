import Foundation
import FirebaseFunctions
import MapKit

@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var activityType = "hiking"
    @Published var selectedLocation: LocationResult?
    @Published var date = Date().addingTimeInterval(3600) // 1 hour from now
    @Published var endDate = Date().addingTimeInterval(7200) // 2 hours from now
    @Published var maxAttendees = 20
    @Published var allowCheckIn = true // If false, only interest marking is available

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activityType.isEmpty &&
        selectedLocation != nil &&
        date > Date() &&
        endDate > date
    }

    func createEvent() async -> Bool {
        guard isValid, let location = selectedLocation else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            let result = try await functions.httpsCallable("createEvent").call([
                "title": title.trimmingCharacters(in: .whitespaces),
                "description": description.trimmingCharacters(in: .whitespaces),
                "activityType": activityType,
                "region": location.region,
                "country": location.country,
                "approximateArea": location.name,
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "date": formatter.string(from: date),
                "endDate": formatter.string(from: endDate),
                "maxAttendees": maxAttendees,
                "allowCheckIn": allowCheckIn
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
            }

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
