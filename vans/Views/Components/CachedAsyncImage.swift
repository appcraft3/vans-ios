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

struct CachedProfileImage: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        if let urlString = url, !urlString.isEmpty, let imageUrl = URL(string: urlString) {
            KFImage(imageUrl)
                .resizable()
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .fade(duration: 0.25)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.gray)
                )
        }
    }
}
