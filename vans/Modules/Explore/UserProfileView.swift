import SwiftUI
import Kingfisher

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss

    let userId: String

    init(user: DiscoveryUser) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user))
        self.userId = user.id
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with back button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Profile Photo
                    profilePhotoSection

                    // Name and Basic Info
                    nameSection

                    // Connection Section
                    connectionSection

                    // Trust Section
                    trustSection

                    // Activities Section
                    if !viewModel.displayProfile.activities.isEmpty {
                        activitiesSection
                    }

                    // Bio Section
                    if let bio = viewModel.displayProfile.bio, !bio.isEmpty {
                        bioSection(bio: bio)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadProfile()
        }
    }

    private var profilePhotoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedProfileImage(url: viewModel.displayProfile.photoUrl, size: 150)
                .overlay(Circle().stroke(AppTheme.primary, lineWidth: 3))

            if viewModel.displayIsPremium {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)
                    .padding(8)
                    .background(AppTheme.surface)
                    .clipShape(Circle())
                    .offset(x: -5, y: -5)
            }
        }
    }

    private var nameSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(viewModel.displayProfile.firstName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(viewModel.displayProfile.age)")
                    .font(.title2)
                    .foregroundColor(AppTheme.textSecondary)

                // Builder badge
                if viewModel.displayTrust.badges.contains("trusted_builder") {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption)
                        Text("Builder")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primary.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            // Van Life Status
            Text(viewModel.displayProfile.vanLifeStatus.displayName)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.accentDark)
                .cornerRadius(20)

            // Region
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                Text(viewModel.displayProfile.region)
                    .font(.subheadline)
            }
            .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var connectionSection: some View {
        VStack(spacing: 16) {
            // Connections Count
            VStack(spacing: 4) {
                Text("\(viewModel.connectionsCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Event Connections")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            // How to connect info
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect at events")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Attend the same event and mark interest.\nIf mutual, you'll match after!")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()
            }
            .padding()
            .background(AppTheme.accentDark.opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var trustSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Activity")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                // Badges
                if !viewModel.displayTrust.badgeList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.displayTrust.badgeList, id: \.self) { badge in
                                HStack(spacing: 4) {
                                    Image(systemName: badge.icon)
                                        .font(.caption)
                                    Text(badge.displayName)
                                        .font(.caption)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.accentDark)
                                .cornerRadius(20)
                            }
                        }
                    }
                }

                // Stats
                HStack(spacing: 32) {
                    statItem(value: "\(viewModel.displayTrust.eventsAttended)", label: "Events")
                    statItem(value: "\(viewModel.displayTrust.positiveReviews)", label: "Positive")
                    statItem(value: "\(viewModel.displayTrust.negativeReviews)", label: "Negative")
                }
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(viewModel.displayProfile.activities, id: \.self) { activity in
                    Text(activity)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.accentDark)
                        .cornerRadius(16)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text(bio)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
