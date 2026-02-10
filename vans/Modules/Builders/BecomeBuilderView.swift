import SwiftUI

struct BecomeBuilderView: View {
    @StateObject var viewModel: BecomeBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.isAlreadyBuilder {
                alreadyBuilderView
            } else {
                applicationForm
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.checkIfAlreadyBuilder()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var alreadyBuilderView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primary)

            VStack(spacing: 8) {
                Text("You're a Trusted Builder!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Others can now book sessions with you to get help with their van builds.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { dismiss() }) {
                Text("Got it")
                    .themedButton(.primary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var applicationForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Title
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primary)

                    Text("Become a Builder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Help fellow van-lifers with your expertise")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                // Categories
                categoriesSection

                // Bio
                bioSection

                // Error/Success
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

                // Submit
                submitButton

                // Disclaimer
                Text("By becoming a builder, you agree to provide helpful advice to fellow community members. This is peer help, not professional services.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What can you help with?")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(BuilderCategory.allCases) { category in
                    CategoryToggle(
                        category: category,
                        isSelected: viewModel.selectedCategories.contains(category)
                    ) {
                        viewModel.toggleCategory(category)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("About your experience")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text(viewModel.bioCharacterCount)
                    .font(.caption)
                    .foregroundColor(viewModel.bio.count >= 20 ? AppTheme.accent : AppTheme.textTertiary)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.bio.isEmpty {
                    Text("Tell us about your van build experience...")
                        .foregroundColor(Color.white.opacity(0.35))
                        .font(.system(size: 15))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                }
                TextEditor(text: $viewModel.bio)
                    .foregroundColor(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
            }
            .background(AppTheme.inputBackground)
            .cornerRadius(12)

            Text("Describe your van build experience and what you can help with")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal)
    }

    private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitApplication()
            }
        }) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Become a Builder")
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSubmit ? AppTheme.accent : AppTheme.divider)
            .cornerRadius(14)
        }
        .disabled(!viewModel.canSubmit)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct CategoryToggle: View {
    let category: BuilderCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                Text(category.displayName)
                    .font(.subheadline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
            .padding()
            .background(isSelected ? AppTheme.primary : AppTheme.card)
            .cornerRadius(12)
        }
    }
}

