import SwiftUI

struct ExploreView: ActionableView {
    @ObservedObject var viewModel: ExploreViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Explore")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if viewModel.isLoading && viewModel.users.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.users.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("No users to explore yet")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.users) { user in
                                UserCard(user: user)
                                    .onTapGesture {
                                        viewModel.openUserProfile(user)
                                    }
                                    .onAppear {
                                        if user.id == viewModel.users.last?.id {
                                            viewModel.loadMoreUsers()
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)

                        if viewModel.isLoading && !viewModel.users.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                                .padding()
                        }
                    }
                    .refreshable {
                        viewModel.refreshUsers()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.users.isEmpty {
                viewModel.loadUsers()
            }
        }
    }
}

struct UserCard: View {
    let user: DiscoveryUser

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: user.profile.photoUrl)
                    .frame(height: 180)
                    .clipped()

                // Premium badge
                if user.isPremium {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                        .padding(6)
                        .background(AppTheme.surface.opacity(0.9))
                        .clipShape(Circle())
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(user.profile.firstName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text("\(user.profile.age)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(user.profile.region)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(AppTheme.textTertiary)

                // Trust level indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(trustColor(level: user.trust.level))
                        .frame(width: 8, height: 8)
                    Text("Trust \(user.trust.level)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(12)
        }
        .background(AppTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private func trustColor(level: Int) -> Color {
        if level >= 70 { return AppTheme.accent }
        if level >= 40 { return AppTheme.primary }
        return AppTheme.secondary
    }
}
