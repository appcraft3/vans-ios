import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        if let urlString = url, !urlString.isEmpty, let imageUrl = URL(string: urlString) {
            KFImage(imageUrl)
                .resizable()
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .fade(duration: 0.25)
                .aspectRatio(contentMode: contentMode)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
        }
    }
}

struct ProfilePlaceholder: View {
    let size: CGFloat

    private let green = Color(hex: "2D4A3E")

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [green.opacity(0.7), green.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundColor(Color.white.opacity(0.5))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct CachedProfileImage: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        if let urlString = url, !urlString.isEmpty, let imageUrl = URL(string: urlString) {
            KFImage(imageUrl)
                .resizable()
                .placeholder {
                    ProfilePlaceholder(size: size)
                }
                .fade(duration: 0.25)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            ProfilePlaceholder(size: size)
        }
    }
}
