import SwiftUI
import Kingfisher
import PhotosUI

struct ProfileView: ActionableView {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection

                    // Trust Section
                    if let user = viewModel.user {
                        trustSection(user: user)
                    }

                    // Activities Section
                    if let activities = viewModel.user?.profile?.activities, !activities.isEmpty {
                        activitiesSection(activities: activities)
                    }

                    // Bio Section
                    if let bio = viewModel.user?.profile?.bio, !bio.isEmpty {
                        bioSection(bio: bio)
                    }

                    // Builder Section
                    builderSection

                    // Admin Section
                    if viewModel.isAdmin {
                        adminSection
                    }

                    // Settings Section
                    settingsSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadUser()
        }
    }

    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Photo with Edit
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if viewModel.isUploadingPhoto {
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                            )
                            .overlay(Circle().stroke(AppTheme.primary, lineWidth: 3))
                    } else {
                        CachedProfileImage(url: viewModel.user?.profile?.photoUrl, size: 120)
                            .overlay(Circle().stroke(AppTheme.primary, lineWidth: 3))
                    }

                    // Edit badge
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(AppTheme.primary)
                        .clipShape(Circle())
                        .offset(x: -5, y: -5)
                }
            }
            .disabled(viewModel.isUploadingPhoto)

            // Photo upload error
            if let error = viewModel.photoUploadError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
            }

            // Name and Age
            VStack(spacing: 4) {
                Text(viewModel.user?.profile?.firstName ?? "User")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                if let age = viewModel.user?.profile?.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Van Life Status
            if let status = viewModel.user?.profile?.vanLifeStatus {
                Text(status.displayName)
                    .font(.caption)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentDark)
                    .cornerRadius(16)
            }

            // Region
            if let region = viewModel.user?.profile?.region {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(region)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.textSecondary)
            }

            // Connections
            VStack(spacing: 4) {
                Text("\(viewModel.connectionsCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Connections")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 8)
        }
    }

    private func trustSection(user: UserData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Activity")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                // Badges
                if !user.trust.badgeList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(user.trust.badgeList, id: \.self) { badge in
                                HStack(spacing: 4) {
                                    Image(systemName: badge.icon)
                                        .font(.caption)
                                    Text(badge.displayName)
                                        .font(.caption)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.accentDark)
                                .cornerRadius(16)
                            }
                        }
                    }
                }

                // Stats
                HStack(spacing: 24) {
                    statItem(value: "\(user.trust.eventsAttended)", label: "Events")
                    statItem(value: "\(user.trust.positiveReviews)", label: "Positive")
                    statItem(value: "\(user.trust.negativeReviews)", label: "Negative")
                }
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
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

    private func activitiesSection(activities: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(activities, id: \.self) { activity in
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
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
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
    }

    // MARK: - Builder Section

    private var builderSection: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title2)
                .foregroundColor(AppTheme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Builder Mode")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.isBuilder ? "You're a Trusted Builder" : "Help others with van builds")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            if viewModel.isBuilder {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.accent)
            } else {
                Button(action: {
                    viewModel.openBecomeBuilder()
                }) {
                    Text("Enable")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
    }

    // MARK: - Admin Section

    private var adminSection: some View {
        Button(action: {
            viewModel.openWaitlistReview()
        }) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(AppTheme.primary)
                Text("Waitlist Review")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding()
            .background(AppTheme.primary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 12) {
            // Premium badge if applicable
            if viewModel.user?.isPremium == true {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppTheme.primary)
                    Text("Premium Member")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding()
                .background(AppTheme.primary.opacity(0.1))
                .cornerRadius(12)
            }

            // Sign Out Button
            Button(action: {
                viewModel.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.headline)
                .foregroundColor(AppTheme.error)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.error.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}
