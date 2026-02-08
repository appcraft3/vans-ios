import SwiftUI
import Kingfisher

struct StoryViewerView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Story photo
            if let url = URL(string: story.photoUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        ProgressView()
                            .tint(accentGreen)
                    }
                    .fade(duration: 0.25)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Top bar
            VStack {
                HStack(spacing: 12) {
                    CachedProfileImage(url: story.user.photoUrl, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(story.user.firstName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text(timeAgoText)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()
            }
        }
        .statusBarHidden(true)
        .onTapGesture {
            dismiss()
        }
    }

    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(story.createdAt)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}
