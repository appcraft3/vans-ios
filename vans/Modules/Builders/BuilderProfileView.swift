import SwiftUI
import Kingfisher

struct BuilderProfileView: View {
    @StateObject var viewModel: BuilderProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with back button
                    headerSection

                    // Profile Photo
                    profilePhotoSection

                    // Name and Rating
                    nameSection

                    // Categories
                    categoriesSection

                    // Stats
                    statsSection

                    // Bio
                    bioSection

                    // Pricing
                    pricingSection

                    // Availability
                    availabilitySection

                    // Trust Info
                    trustSection

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }

            // Book Button (floating)
            VStack {
                Spacer()
                bookButton
            }
        }
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()

            // Builder badge
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.caption)
                Text("Trusted Builder")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.2))
            .cornerRadius(12)

            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal)
    }

    private var profilePhotoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if let photoUrl = viewModel.builder.profile?.photoUrl {
                KFImage(URL(string: photoUrl))
                    .placeholder {
                        Circle()
                            .fill(AppTheme.surface)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.accent, lineWidth: 3))
            } else {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textSecondary)
                    )
            }

            // Tool badge
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title3)
                .foregroundColor(.black)
                .padding(8)
                .background(AppTheme.primary)
                .clipShape(Circle())
                .offset(x: -5, y: -5)
        }
    }

    private var nameSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.builder.profile?.firstName ?? "Builder")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            // Rating badge
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.subheadline)
                    Text("\(viewModel.builder.rating)% positive")
                        .font(.subheadline)
                }
                .foregroundColor(viewModel.builder.rating >= 80 ? AppTheme.accent : AppTheme.textSecondary)

                if viewModel.builder.completedSessions > 0 {
                    Text("\u{2022}")
                        .foregroundColor(AppTheme.textTertiary)

                    Text("\(viewModel.builder.completedSessions) sessions")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Region
            if let region = viewModel.builder.profile?.region {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(region)
                        .font(.subheadline)
                }
                .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expertise")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.builder.categories) { category in
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 50, height: 50)
                                .background(AppTheme.primary.opacity(0.2))
                                .clipShape(Circle())

                            Text(category.displayName)
                                .font(.caption)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppTheme.card)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 32) {
            statItem(value: "\(viewModel.builder.completedSessions)", label: "Sessions")
            statItem(value: "\(viewModel.builder.positiveReviews)", label: "Positive")
            statItem(value: "\(viewModel.builder.trust?.eventsAttended ?? 0)", label: "Events")
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

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text(viewModel.builder.bio)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Pricing")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 16) {
                pricingOption(
                    duration: "15 min",
                    price: viewModel.builder.sessionPrices.fifteenMin,
                    description: "Quick questions"
                )

                pricingOption(
                    duration: "30 min",
                    price: viewModel.builder.sessionPrices.thirtyMin,
                    description: "In-depth help"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func pricingOption(duration: String, price: Int, description: String) -> some View {
        VStack(spacing: 8) {
            Text(duration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)

            Text("$\(price)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(12)
    }

    private var availabilitySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(AppTheme.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Availability")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.builder.availability)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var trustSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Activity")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                trustItem(
                    icon: "checkmark.shield.fill",
                    title: "Community Builder",
                    subtitle: "Verified community member offering help"
                )

                trustItem(
                    icon: "calendar.badge.checkmark",
                    title: "\(viewModel.builder.trust?.eventsAttended ?? 0) Events Attended",
                    subtitle: "Active community member"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func trustItem(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var bookButton: some View {
        Button(action: { viewModel.bookSession() }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                Text("Book a Session")
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent)
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [AppTheme.background.opacity(0), AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }
}
