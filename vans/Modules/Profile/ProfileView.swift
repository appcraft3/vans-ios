import SwiftUI
import Kingfisher
import PhotosUI

struct ProfileView: ActionableView {
    @ObservedObject var viewModel: ProfileViewModel

    private let accentGreen = Color(hex: "2E7D5A")

    private let activityIcons: [String: String] = [
        "hiking": "figure.hiking",
        "surfing": "figure.surfing",
        "climbing": "figure.climbing",
        "cycling": "figure.outdoor.cycle",
        "kayaking": "figure.rowing",
        "photography": "camera",
        "yoga": "figure.yoga",
        "cooking": "fork.knife",
        "stargazing": "star",
        "remote_work": "laptopcomputer",
        "music": "music.note",
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            // Background depth elements
            backgroundElements

            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        profilePhotoSection
                        VStack {
                            profileHeaderBar
                            Spacer()
                        }
                    }
                   
                    nameInfoSection

                    if let user = viewModel.user {
                        trustSection(user: user)
                    }

                    if let activities = viewModel.user?.profile?.activities, !activities.isEmpty {
                        activitiesSection(activities: activities)
                    }

                    if let bio = viewModel.user?.profile?.bio, !bio.isEmpty {
                        bioSection(bio: bio)
                    }

                    // Instagram Section
                    if let instagram = viewModel.user?.profile?.instagramUsername, !instagram.isEmpty {
                        instagramSection(username: instagram)
                    }

                    // Builder Section
                    builderSection

                    // Reviews Section
                    reviewsButton

                    if viewModel.isAdmin {
                        adminSection
                    }

                    settingsSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadUser()
        }
        .fullScreenCover(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Background

    private var backgroundElements: some View {
        ZStack {
            // Star dots
//            GeometryReader { geo in
//                let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
//                    (0.15, 0.08, 1.5, 0.10),
//                    (0.72, 0.05, 1.2, 0.08),
//                    (0.88, 0.12, 1.8, 0.12),
//                    (0.35, 0.15, 1.0, 0.06),
//                    (0.55, 0.03, 1.4, 0.09),
//                    (0.08, 0.22, 1.2, 0.07),
//                    (0.92, 0.25, 1.6, 0.10),
//                    (0.45, 0.10, 1.0, 0.08),
//                    (0.25, 0.28, 1.3, 0.06),
//                    (0.78, 0.18, 1.1, 0.09),
//                ]
//
//                ForEach(0..<stars.count, id: \.self) { i in
//                    Circle()
//                        .fill(Color.white.opacity(stars[i].opacity))
//                        .frame(width: stars[i].size, height: stars[i].size)
//                        .position(
//                            x: geo.size.width * stars[i].x,
//                            y: geo.size.height * stars[i].y
//                        )
//                }
//            }
            
            StarfieldBackground(starCount: 60, twinkleCount: 225)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .blendMode(.screen)

            // Mountain silhouette
            VStack {
                Spacer()
                MountainSilhouette()
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 200)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Header Bar

    private var profileHeaderBar: some View {
        HStack {

            Spacer()

            if viewModel.isPro {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("VanGo Pro")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(accentGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(accentGreen.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(accentGreen.opacity(0.4), lineWidth: 1)
                )
            } else {
                Button {
                    viewModel.openPaywall()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 12))
                        Text("Go Pro")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(accentGreen)
                    )
                }
            }
        }
    }

    // MARK: - Profile Photo

    private var profilePhotoSection: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if viewModel.isUploadingPhoto {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                                    .tint(accentGreen)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen, accentGreen.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                    } else {
                        CachedProfileImage(url: viewModel.user?.profile?.photoUrl, size: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen, accentGreen.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: accentGreen.opacity(0.3), radius: 12)
                    }

                    // Camera badge
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(accentGreen)
                        .clipShape(Circle())
                        .offset(x: -5, y: -5)
                }
            }
            .disabled(viewModel.isUploadingPhoto)

            if let error = viewModel.photoUploadError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
            }
        }
    }

    // MARK: - Name & Info

    private var nameInfoSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(viewModel.user?.profile?.firstName ?? "User")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                if viewModel.isPro {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Pro")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(accentGreen.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(accentGreen.opacity(0.4), lineWidth: 1)
                    )
                }
            }

            if let age = viewModel.user?.profile?.age {
                Text("\(age) years old")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Van Life status badge
            if let status = viewModel.user?.profile?.vanLifeStatus {
                Text(status.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentGreen.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(accentGreen.opacity(0.4), lineWidth: 1)
                    )
            }

            // Region
            if let region = viewModel.user?.profile?.region {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                        .foregroundColor(accentGreen)
                    Text(region)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Connections pill
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11))
                    .foregroundColor(accentGreen)
                Text("\(viewModel.connectionsCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Connections")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.top, 4)
        }
    }

    // MARK: - Trust / Community Activity

    private func trustSection(user: UserData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Community Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            // Badges
            if !user.trust.badgeList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(user.trust.badgeList, id: \.self) { badge in
                            HStack(spacing: 4) {
                                Image(systemName: badge.icon)
                                    .font(.system(size: 11))
                                Text(badge.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(accentGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(accentGreen.opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }

            // Stats pills
            HStack(spacing: 8) {
                statPill(value: "\(user.trust.eventsAttended)", label: "Events")
                statPill(value: "\(user.trust.reviewCount)", label: "Reviews")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Interests

    private func activitiesSection(activities: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(activities, id: \.self) { activity in
                    HStack(spacing: 5) {
                        if let icon = activityIcons[activity.lowercased()] {
                            Image(systemName: icon)
                                .font(.system(size: 11))
                        }
                        Text(activity.capitalized)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(accentGreen.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Bio

    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text(bio)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func instagramSection(username: String) -> some View {
        Button(action: {
            if let url = URL(string: "https://instagram.com/\(username)") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                Image("instagram_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Instagram")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("@\(username)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding()
            .background(AppTheme.card)
            .cornerRadius(16)
        }
    }

    private var builderSection: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title2)
                .foregroundColor(accentGreen)

            VStack(alignment: .leading, spacing: 4) {
                Text("Builder Mode")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.isBuilder ? "You're a Trusted Builder" : "Help others with van builds")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            if viewModel.isBuilder {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(accentGreen)
            } else {
                Button {
                    viewModel.openBecomeBuilder()
                } label: {
                    Text("Enable")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(accentGreen)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Reviews

    private var reviewsButton: some View {
        Button {
            viewModel.openMyReviews()
        } label: {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.title2)
                    .foregroundColor(accentGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reviews")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("See what others say about you")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Admin

    private var adminSection: some View {
        Button {
            viewModel.openWaitlistReview()
        } label: {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(accentGreen)
                Text("Waitlist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentGreen.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentGreen.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Button {
            viewModel.signOut()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppTheme.error)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.error.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.error.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Mountain Silhouette Shape

struct MountainSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h))

        // Left slope
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.65))
        // Main peak
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.30))
        // Second peak
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.10))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.40))
        // Small hill
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.50))
        // Right slope
        path.addLine(to: CGPoint(x: w, y: h * 0.45))
        path.addLine(to: CGPoint(x: w, y: h))

        path.closeSubpath()
        return path
    }
}

