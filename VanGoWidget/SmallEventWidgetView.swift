import SwiftUI
import WidgetKit

struct SmallEventWidgetView: View {
    let entry: EventWidgetEntry

    var body: some View {
        if let event = entry.events.first {
            VStack(alignment: .leading, spacing: 6) {
                // Top: activity icon + status
                HStack {
                    Image(systemName: event.activityIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WidgetTheme.accent)
                        .frame(width: 26, height: 26)
                        .background(WidgetTheme.accentDark.opacity(0.5))
                        .clipShape(Circle())

                    Spacer()

                    Text(event.status.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(
                            event.status == "ongoing"
                                ? WidgetTheme.accent
                                : WidgetTheme.secondary
                        )
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(
                                event.status == "ongoing"
                                    ? WidgetTheme.accent.opacity(0.15)
                                    : WidgetTheme.secondary.opacity(0.15)
                            )
                        )
                }

                Spacer()

                // Title
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WidgetTheme.textPrimary)
                    .lineLimit(2)

                // Date
                Label(event.shortDate, systemImage: "calendar")
                    .font(.system(size: 10))
                    .foregroundColor(WidgetTheme.primary)

                // Location
                if !event.displayLocation.isEmpty {
                    Label(event.displayLocation, systemImage: "mappin")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .widgetURL(URL(string: "vango://event/\(event.id)"))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 28))
                    .foregroundColor(WidgetTheme.textTertiary)

                Text("No events")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WidgetTheme.textSecondary)

                Text("Open VanGo to explore")
                    .font(.system(size: 10))
                    .foregroundColor(WidgetTheme.textTertiary)
            }
        }
    }
}
