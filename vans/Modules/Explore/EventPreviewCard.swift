import SwiftUI

struct EventPreviewCard: View {
    let event: VanEvent
    let onTap: () -> Void
    let onDismiss: () -> Void

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Activity icon
                Image(systemName: event.activityIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Label(shortDate, systemImage: "calendar")
                        Label(event.approximateArea.isEmpty ? event.region : event.approximateArea, systemImage: "mappin")
                            .lineLimit(1)
                        Label("\(event.attendeesCount)/\(event.maxAttendees)", systemImage: "person.2")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "9A9A9A"))
                }

                Spacer(minLength: 4)

                // Dismiss
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "636366"))
                        .padding(7)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: event.date)
    }
}
