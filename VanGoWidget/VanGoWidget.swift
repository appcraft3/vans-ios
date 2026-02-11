import WidgetKit
import SwiftUI

struct VanGoEventsWidget: Widget {
    let kind: String = "VanGoEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EventTimelineProvider()) { entry in
            VanGoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VanGo Events")
        .description("See upcoming events from the VanGo community.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct VanGoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: EventWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallEventWidgetView(entry: entry)
            case .systemMedium:
                MediumEventWidgetView(entry: entry)
            default:
                SmallEventWidgetView(entry: entry)
            }
        }
        .widgetBackground(WidgetTheme.surface)
    }
}

// MARK: - Container Background Compatibility

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.containerBackground(color, for: .widget)
        } else {
            return self.background(color)
        }
    }
}

// MARK: - Preview Data

enum WidgetPreviewData {
    static let surfEvent = WidgetEvent(
        id: "1",
        title: "Beach Sunset Surf",
        activityType: "surfing",
        region: "Algarve, Portugal",
        approximateArea: "Sagres Beach",
        date: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        attendeesCount: 8,
        maxAttendees: 20,
        status: "upcoming",
        firstPhotoURL: nil
    )

    static let hikeEvent = WidgetEvent(
        id: "2",
        title: "Mountain Trail Hike",
        activityType: "hiking",
        region: "Swiss Alps",
        approximateArea: "Grindelwald",
        date: Date().addingTimeInterval(86400),
        endDate: Date().addingTimeInterval(90000),
        attendeesCount: 12,
        maxAttendees: 25,
        status: "ongoing",
        firstPhotoURL: nil
    )

    static let yogaEvent = WidgetEvent(
        id: "3",
        title: "Yoga on the Lake",
        activityType: "yoga",
        region: "Lake Garda, Italy",
        approximateArea: "",
        date: Date().addingTimeInterval(172800),
        endDate: Date().addingTimeInterval(176400),
        attendeesCount: 5,
        maxAttendees: 15,
        status: "upcoming",
        firstPhotoURL: nil
    )

    static let singleEntry = EventWidgetEntry(
        date: Date(),
        events: [surfEvent],
        isPlaceholder: false
    )

    static let multiEntry = EventWidgetEntry(
        date: Date(),
        events: [surfEvent, hikeEvent, yogaEvent],
        isPlaceholder: false
    )
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Small — Upcoming", as: .systemSmall) {
    VanGoEventsWidget()
} timeline: {
    WidgetPreviewData.singleEntry
}

@available(iOS 17.0, *)
#Preview("Small — Empty", as: .systemSmall) {
    VanGoEventsWidget()
} timeline: {
    EventWidgetEntry.empty
}

@available(iOS 17.0, *)
#Preview("Medium — Events", as: .systemMedium) {
    VanGoEventsWidget()
} timeline: {
    WidgetPreviewData.multiEntry
}

@available(iOS 17.0, *)
#Preview("Medium — Empty", as: .systemMedium) {
    VanGoEventsWidget()
} timeline: {
    EventWidgetEntry.empty
}
