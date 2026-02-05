import SwiftUI
import Kingfisher

struct BookSessionView: View {
    @StateObject var viewModel: BookSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Handle
                    Capsule()
                        .fill(AppTheme.divider)
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)

                    // Header
                    headerSection

                    // Builder Info
                    builderInfoSection

                    // Category Selection
                    categorySection

                    // Duration Selection
                    durationSection

                    // Price Summary
                    priceSummarySection

                    // Disclaimer
                    disclaimerSection

                    // Error/Success Messages
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.error)
                            .padding()
                            .background(AppTheme.error.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                            .padding()
                            .background(AppTheme.accent.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Book Button
                    bookButton

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Book a Session")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            Text("Get help from a trusted community builder")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var builderInfoSection: some View {
        HStack(spacing: 12) {
            if let photoUrl = viewModel.builder.profile?.photoUrl {
                KFImage(URL(string: photoUrl))
                    .placeholder {
                        Circle().fill(AppTheme.surface)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(viewModel.builder.profile?.firstName ?? "Builder")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.caption2)
                    Text("\(viewModel.builder.rating)%")
                        .font(.caption)
                    Text("\u{2022}")
                    Text("\(viewModel.builder.completedSessions) sessions")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What do you need help with?")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.builder.categories) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Duration")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 12) {
                DurationCard(
                    duration: 15,
                    price: viewModel.builder.sessionPrices.fifteenMin,
                    description: "Quick help",
                    isSelected: viewModel.selectedDuration == 15
                ) {
                    viewModel.selectDuration(15)
                }

                DurationCard(
                    duration: 30,
                    price: viewModel.builder.sessionPrices.thirtyMin,
                    description: "In-depth session",
                    isSelected: viewModel.selectedDuration == 30
                ) {
                    viewModel.selectDuration(30)
                }
            }
        }
    }

    private var priceSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Session")
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("$\(viewModel.currentPrice)")
                    .foregroundColor(AppTheme.textPrimary)
            }
            .font(.subheadline)

            Divider()
                .background(AppTheme.divider)

            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("$\(viewModel.currentPrice)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private var disclaimerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(AppTheme.info)

            VStack(alignment: .leading, spacing: 4) {
                Text("How it works")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("After booking, a private session chat opens. Share photos and details about your van build issue. The builder will respond within their availability window.")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(12)
    }

    private var bookButton: some View {
        Button(action: {
            Task {
                await viewModel.bookSession()
            }
        }) {
            HStack {
                if viewModel.isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Image(systemName: "creditcard.fill")
                    Text("Pay $\(viewModel.currentPrice) & Start Session")
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canBook ? AppTheme.accent : AppTheme.divider)
            .cornerRadius(14)
        }
        .disabled(!viewModel.canBook)
    }
}

// MARK: - Category Selection Card

struct CategorySelectionCard: View {
    let category: BuilderCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : AppTheme.primary)

                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.primary : AppTheme.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Duration Card

struct DurationCard: View {
    let duration: Int
    let price: Int
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(duration) min")
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)

                Text("$\(price)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .black : AppTheme.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.accent : AppTheme.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}
