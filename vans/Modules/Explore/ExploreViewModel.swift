import Foundation
import Combine
import MapKit
import CoreLocation
import FirebaseFunctions

// MARK: - Discovery Models (used by UserProfileView, EventsCoordinator)

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

// MARK: - Explore ViewModel

@MainActor
final class ExploreViewModel: ActionableViewModel {
    // Map state
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @Published var annotations: [EventAnnotation] = []
    @Published var selectedAnnotation: EventAnnotation?

    // Events
    @Published var events: [VanEvent] = []
    @Published var isLoading = false

    // Preview / detail state
    @Published var previewEvent: VanEvent?
    @Published var showEventDetailSheet = false
    @Published var detailEvent: VanEvent?

    // Filters
    @Published var selectedActivityFilter: String?
    @Published var showLocationSearch = false

    // Location
    @Published var hasLocationPermission = false

    private weak var coordinator: ExploreCoordinating?
    private let functions = Functions.functions()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    private var geocodeCache: [String: CLLocationCoordinate2D] = [:]

    let activityTypes: [(key: String, label: String, icon: String)] = [
        ("hiking", "Hiking", "figure.hiking"),
        ("surfing", "Surfing", "figure.surfing"),
        ("climbing", "Climbing", "figure.climbing"),
        ("cycling", "Cycling", "figure.outdoor.cycle"),
        ("kayaking", "Kayaking", "figure.rowing"),
        ("photography", "Photo", "camera"),
        ("yoga", "Yoga", "figure.yoga"),
        ("cooking", "Cooking", "fork.knife"),
        ("stargazing", "Stars", "star"),
        ("remote_work", "Cowork", "laptopcomputer"),
    ]

    init(coordinator: ExploreCoordinating?) {
        self.coordinator = coordinator
        setupLocationObserver()
    }

    // MARK: - Location

    private func setupLocationObserver() {
        LocationManager.shared.$userLocation
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.mapRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
                )
            }
            .store(in: &cancellables)

        LocationManager.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.hasLocationPermission = (status == .authorizedWhenInUse || status == .authorizedAlways)
            }
            .store(in: &cancellables)
    }

    func requestLocationPermission() {
        LocationManager.shared.requestPermission()
    }

    func centerOnUserLocation() {
        guard let loc = LocationManager.shared.userLocation else { return }
        mapRegion = MKCoordinateRegion(
            center: loc,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    }

    // MARK: - Events

    func loadEvents() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let params: [String: Any] = ["limit": 50]
            let result = try await functions.httpsCallable("getEvents").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool, success,
                  let eventsData = data["events"] as? [[String: Any]] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            events = eventsData.compactMap { parseEvent($0) }
            await buildAnnotations()
        } catch {
            print("Failed to load events: \(error)")
        }

        isLoading = false
    }

    // MARK: - Annotations

    private func buildAnnotations() async {
        var result: [EventAnnotation] = []

        for event in filteredEvents {
            if let coord = event.coordinate {
                result.append(EventAnnotation(event: event, coordinate: coord))
            } else {
                let key = event.approximateArea.isEmpty ? event.region : event.approximateArea
                if key.isEmpty { continue }

                if let cached = geocodeCache[key] {
                    result.append(EventAnnotation(event: event, coordinate: cached))
                } else if let coord = await geocodeString(key) {
                    geocodeCache[key] = coord
                    result.append(EventAnnotation(event: event, coordinate: coord))
                }
            }
        }

        annotations = result
    }

    private func geocodeString(_ string: String) async -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(string)
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }

    var filteredEvents: [VanEvent] {
        guard let filter = selectedActivityFilter else { return events }
        return events.filter { $0.activityType == filter }
    }

    // MARK: - Interaction

    func selectAnnotation(_ annotation: EventAnnotation) {
        selectedAnnotation = annotation
        previewEvent = annotation.event
    }

    func dismissPreview() {
        selectedAnnotation = nil
        previewEvent = nil
    }

    func showFullDetail(for event: VanEvent) {
        detailEvent = event
        showEventDetailSheet = true
    }

    func openEventDetail(_ event: VanEvent) {
        showEventDetailSheet = false
        coordinator?.showEventDetail(eventId: event.id)
    }

    func toggleActivityFilter(_ type: String) {
        if selectedActivityFilter == type {
            selectedActivityFilter = nil
        } else {
            selectedActivityFilter = type
        }
        dismissPreview()
        Task { await buildAnnotations() }
    }

    func moveMapTo(_ coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    }

    // MARK: - Parse Event

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
