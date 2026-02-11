import SwiftUI
import Kingfisher

struct WaitlistReviewView: View {
    @ObservedObject var viewModel: WaitlistReviewViewModel
    @Environment(\.dismiss) private var dismiss

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

                    Text("Waitlist")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: { viewModel.refreshWaitlist() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding()

                if viewModel.isLoading && viewModel.waitlistUsers.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.waitlistUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.accent)
                        Text("No pending users")
                            .font(.title2)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("All caught up!")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.waitlistUsers) { user in
                                WaitlistUserCard(
                                    user: user,
                                    isProcessing: viewModel.processingUserId == user.id,
                                    onApprove: { viewModel.approveUser(user) },
                                    onReject: { viewModel.rejectUser(user) }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct WaitlistUserCard: View {
    let user: WaitlistUser
    let isProcessing: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Photo
                CachedProfileImage(url: user.profile?.photoUrl, size: 70)

                VStack(alignment: .leading, spacing: 6) {
                    Text(user.profile?.firstName ?? "Unknown")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    if let age = user.profile?.age {
                        Text("\(age) years old")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    if let region = user.profile?.region {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(region)
                                .font(.subheadline)
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }

                    if let status = user.profile?.vanLifeStatus {
                        Text(status.displayName)
                            .font(.caption)
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.accentDark)
                            .cornerRadius(12)
                    }
                }

                Spacer()
            }

            // Bio
            if let bio = user.profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(3)
            }

            // Activities
            if let activities = user.profile?.activities, !activities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activities, id: \.self) { activity in
                            Text(activity)
                                .font(.caption)
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accentDark)
                                .cornerRadius(16)
                        }
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 16) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.error.opacity(0.15))
                    .cornerRadius(12)
                }
                .disabled(isProcessing)

                Button(action: onApprove) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accent))
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Approve")
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent.opacity(0.15))
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}
