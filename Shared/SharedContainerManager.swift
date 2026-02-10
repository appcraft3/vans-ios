import Foundation

enum SharedContainerManager {
    static let appGroupID = "group.com.abtc.vans"
    static let eventsKey = "widget_events"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Write (called from main app)

    static func saveEvents(_ events: [WidgetEvent]) {
        let store = WidgetEventStore(events: events, lastUpdated: Date())
        guard let data = try? JSONEncoder().encode(store) else { return }
        sharedDefaults?.set(data, forKey: eventsKey)
    }

    // MARK: - Read (called from widget)

    static func loadEvents() -> [WidgetEvent] {
        guard let data = sharedDefaults?.data(forKey: eventsKey),
              let store = try? JSONDecoder().decode(WidgetEventStore.self, from: data) else {
            return []
        }
        return store.events
            .filter { $0.isUpcomingOrOngoing }
            .sorted { $0.date < $1.date }
    }
}
