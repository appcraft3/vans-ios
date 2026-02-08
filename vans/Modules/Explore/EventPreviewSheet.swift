import SwiftUI

struct EventPreviewSheet: View {
    let event: VanEvent
    let onViewFull: () -> Void

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero image with green gradient
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: "https://picsum.photos/seed/\(event.id)/600/400")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle().fill(Color(hex: "1A2820"))
                        case .empty:
                            Rectangle().fill(Color(hex: "1A2820"))
                                .overlay(ProgressView().tint(.white.opacity(0.25)))
                        @unknown default:
                            Rectangle().fill(Color(hex: "1A2820"))
                        }
                    }
                    .frame(height: 220)
                    .clipped()

                    // Green gradient
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: accentGreen.opacity(0.5), location: 0.35),
                            .init(color: accentGreen.opacity(0.9), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 220)

                    // Title overlay
                    VStack(alignment: .leading, spacing: 6) {
                        StatusBadge(status: event.status)

                        Text(event.activityType.capitalized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(event.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .padding(20)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Info pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        sheetInfoPill(icon: "calendar", text: event.formattedDate)
                        sheetInfoPill(icon: "mappin", text: event.approximateArea.isEmpty ? event.region : event.approximateArea)
                        sheetInfoPill(icon: "person.2", text: "\(event.attendeesCount)/\(event.maxAttendees)")
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)

                // Description
                if !event.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text(event.description)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "9A9A9A"))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // View Full Event button
                Button(action: onViewFull) {
                    HStack(spacing: 8) {
                        Text("View Full Event")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accentGreen)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func sheetInfoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(accentGreen)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "9A9A9A"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
