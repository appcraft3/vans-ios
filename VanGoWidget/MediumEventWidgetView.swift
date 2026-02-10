import SwiftUI
import WidgetKit

struct MediumEventWidgetView: View {
    let entry: EventWidgetEntry

    private var displayEvents: [WidgetEvent] {
        Array(entry.events.prefix(3))
    }

    var body: some View {
        if displayEvents.isEmpty {
            emptyState
        } else {
            ZStack {
                WidgetTheme.surface

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Upcoming Events")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(WidgetTheme.textPrimary)

                        Spacer()

                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(WidgetTheme.accent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    // Event rows
                    ForEach(Array(displayEvents.enumerated()), id: \.element.id) { index, event in
                        if index > 0 {
                            Rectangle()
                                .fill(WidgetTheme.textTertiary.opacity(0.2))
                                .frame(height: 0.5)
                                .padding(.horizontal, 14)
                        }

                        eventRow(event)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func eventRow(_ event: WidgetEvent) -> some View {
        Link(destination: URL(string: "vango://event/\(event.id)") ?? URL(string: "vango://")!) {
            HStack(spacing: 10) {
                // Activity icon
                Image(systemName: event.activityIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(WidgetTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(WidgetTheme.accentDark.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WidgetTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Label(event.shortDate, systemImage: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(WidgetTheme.primary)

                        if !event.displayLocation.isEmpty {
                            Label(event.displayLocation, systemImage: "mappin")
                                .font(.system(size: 10))
                                .foregroundColor(WidgetTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Attendee count
                VStack(spacing: 1) {
                    Text("\(event.attendeesCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(WidgetTheme.textPrimary)
                    Image(systemName: "person.2")
                        .font(.system(size: 9))
                        .foregroundColor(WidgetTheme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        ZStack {
            WidgetTheme.surface

            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(WidgetTheme.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("No upcoming events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WidgetTheme.textSecondary)
                    Text("Open VanGo to discover events")
                        .font(.system(size: 11))
                        .foregroundColor(WidgetTheme.textTertiary)
                }
            }
            .padding()
        }
    }
}
