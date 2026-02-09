import SwiftUI
import Kingfisher
import FirebaseFunctions

struct MyReviewsView: View {
    @StateObject private var viewModel = MyReviewsViewModel()
    @Environment(\.dismiss) private var dismiss

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Text("Reviews")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // Balance spacer
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .hidden()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                if viewModel.isLoading && viewModel.reviews.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(accentGreen)
                    Spacer()
                } else if viewModel.reviews.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("No reviews yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Reviews from event attendees will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.reviews) { review in
                                reviewCard(review)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadReviews()
        }
    }

    private func reviewCard(_ review: UserReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CachedProfileImage(url: review.reviewerPhotoUrl, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerFirstName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    if !review.eventTitle.isEmpty {
                        Text(review.eventTitle)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()
            }

            Text(review.reviewText)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

@MainActor
final class MyReviewsViewModel: ObservableObject {
    @Published var reviews: [UserReview] = []
    @Published var isLoading = false

    func loadReviews() async {
        guard !isLoading else { return }
        isLoading = true

        defer { isLoading = false }

        guard let userId = AuthManager.shared.currentUser?.id ?? UserManager.shared.currentUser?.id else {
            print("MyReviews: No current user ID found")
            return
        }

        do {
            let result = try await Functions.functions().httpsCallable("getUserReviews").call(["userId": userId])
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool, success,
                  let reviewsData = data["reviews"] as? [[String: Any]] else {
                print("MyReviews: Invalid response format")
                return
            }

            self.reviews = reviewsData.map { d in
                UserReview(
                    id: d["id"] as? String ?? UUID().uuidString,
                    reviewerFirstName: d["reviewerFirstName"] as? String ?? "Anonymous",
                    reviewerPhotoUrl: d["reviewerPhotoUrl"] as? String ?? "",
                    eventTitle: d["eventTitle"] as? String ?? "",
                    reviewText: d["reviewText"] as? String ?? "",
                    createdAt: d["createdAt"] as? String
                )
            }
        } catch {
            print("MyReviews: Failed to load reviews: \(error)")
        }
    }
}
