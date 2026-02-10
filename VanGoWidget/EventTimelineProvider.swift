import WidgetKit

struct EventTimelineProvider: TimelineProvider {
    typealias Entry = EventWidgetEntry

    func placeholder(in context: Context) -> EventWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (EventWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        let events = SharedContainerManager.loadEvents()
        completion(EventWidgetEntry(date: Date(), events: events, isPlaceholder: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EventWidgetEntry>) -> Void) {
        let events = SharedContainerManager.loadEvents()
        let entry = EventWidgetEntry(date: Date(), events: events, isPlaceholder: false)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
