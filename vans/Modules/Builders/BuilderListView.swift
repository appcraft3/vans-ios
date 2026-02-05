import SwiftUI
import Kingfisher

struct BuilderListView: View {
    @StateObject var viewModel: BuilderListViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Category Filter
                categoryFilterSection

                // Content
                if viewModel.isLoading && viewModel.builders.isEmpty {
                    loadingView
                } else if viewModel.builders.isEmpty {
                    emptyStateView
                } else {
                    buildersList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadBuilders()
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { viewModel.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Get Help")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("From trusted builders")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }

                ForEach(BuilderCategory.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
            Text("Finding trusted builders...")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textTertiary)

            VStack(spacing: 8) {
                Text("No builders found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.selectedCategory != nil
                    ? "No builders available for \(viewModel.selectedCategory!.displayName) yet.\nTry another category."
                    : "No builders available in your area yet.\nCheck back soon!")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    private var buildersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Info banner
                infoBanner

                ForEach(viewModel.builders) { builder in
                    BuilderCard(
                        builder: builder,
                        onTap: { viewModel.openBuilderProfile(builder) },
                        onBook: { viewModel.bookSession(with: builder) }
                    )
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkmark.fill")
                .font(.title2)
                .foregroundColor(AppTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Trusted peer help")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Builders are community members who've earned trust through events. Book a session to get help with your van build.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.accentDark.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.primary : AppTheme.surface)
            .cornerRadius(20)
        }
    }
}

// MARK: - Builder Card

struct BuilderCard: View {
    let builder: BuilderProfile
    let onTap: () -> Void
    let onBook: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header with profile info
            HStack(spacing: 12) {
                // Photo
                if let photoUrl = builder.profile?.photoUrl {
                    KFImage(URL(string: photoUrl))
                        .placeholder {
                            Circle()
                                .fill(AppTheme.surface)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.accent, lineWidth: 2))
                } else {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        )
                }

                // Name and info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(builder.profile?.firstName ?? "Builder")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        // Builder badge
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                    }

                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 4) {
                            Image(systemName: builder.rating >= 80 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.caption2)
                            Text(builder.ratingText)
                                .font(.caption)
                        }
                        .foregroundColor(builder.rating >= 80 ? AppTheme.accent : AppTheme.textSecondary)

                        Text("\u{2022}")
                            .foregroundColor(AppTheme.textTertiary)

                        // Sessions
                        Text("\(builder.completedSessions) sessions")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        if let sharedEvents = builder.sharedEventsCount, sharedEvents > 0 {
                            Text("\u{2022}")
                                .foregroundColor(AppTheme.textTertiary)

                            HStack(spacing: 2) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text("\(sharedEvents) shared")
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.secondary)
                        }
                    }
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text("from")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                    Text("$\(builder.sessionPrices.fifteenMin)")
                        .font(.headline)
                        .foregroundColor(AppTheme.primary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(builder.categories) { category in
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.surface)
                        .cornerRadius(12)
                    }
                }
            }

            // Bio preview
            Text(builder.bio)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Book button
            Button(action: onBook) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Book a Session")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.accent)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
    }
}
