import WidgetKit

struct EventWidgetEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
    let isPlaceholder: Bool

    static var placeholder: EventWidgetEntry {
        EventWidgetEntry(
            date: Date(),
            events: [
                WidgetEvent(
                    id: "placeholder-1",
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
                ),
                WidgetEvent(
                    id: "placeholder-2",
                    title: "Mountain Trail Hike",
                    activityType: "hiking",
                    region: "Swiss Alps",
                    approximateArea: "Grindelwald",
                    date: Date().addingTimeInterval(86400),
                    endDate: Date().addingTimeInterval(90000),
                    attendeesCount: 12,
                    maxAttendees: 25,
                    status: "upcoming",
                    firstPhotoURL: nil
                ),
                WidgetEvent(
                    id: "placeholder-3",
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
            ],
            isPlaceholder: true
        )
    }

    static var empty: EventWidgetEntry {
        EventWidgetEntry(date: Date(), events: [], isPlaceholder: false)
    }
}
