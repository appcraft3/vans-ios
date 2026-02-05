import SwiftUI

struct WaitlistView: ActionableView {

    @ObservedObject var viewModel: WaitlistViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primary)

                        Text("Join Our Community")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)

                        Text(viewModel.statusMessage)
                            .font(.body)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // Status indicator
                    if viewModel.reviewStatus == .pending {
                        waitlistStatusView
                    }

                    // Community values
                    communityValuesView

                    // Trust explanation
                    trustExplanationView

                    // Actions
                    VStack(spacing: 16) {
                        if viewModel.canSubmitToWaitlist {
                            Button(action: { viewModel.submitToWaitlist() }) {
                                Text("Submit for Review")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent)
                                    .cornerRadius(12)
                            }
                        }

                        // Invite code section
                        if viewModel.showInviteCodeInput {
                            inviteCodeInputView
                        } else {
                            Button(action: { viewModel.showInviteCodeInput = true }) {
                                Text("Have an invite code?")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
            }

            if viewModel.isLoading {
                AppTheme.background.opacity(0.8).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var waitlistStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.primary)
                Text("Application Pending")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
            }

            if let position = viewModel.position {
                Text("Position: #\(position) of \(viewModel.totalPending)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Text("We review applications daily to ensure a trusted community.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppTheme.primary.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private var communityValuesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Our Values")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                valueRow(icon: "shield.fill", title: "Trust First", description: "We prioritize trust over growth")
                valueRow(icon: "person.2.fill", title: "Real Connections", description: "Authentic community, not just matches")
                valueRow(icon: "hand.raised.fill", title: "Safety Always", description: "Your safety is our priority")
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func valueRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var trustExplanationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How Trust Works")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                trustRow(number: "1", title: "Join Events", description: "Attend community gatherings to build trust")
                trustRow(number: "2", title: "Get Reviews", description: "Receive positive reviews from other members")
                trustRow(number: "3", title: "Earn Badges", description: "Unlock badges as your trust grows")
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func trustRow(number: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.headline)
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(AppTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var inviteCodeInputView: some View {
        VStack(spacing: 12) {
            TextField("Enter invite code", text: $viewModel.inviteCode)
                .textFieldStyle(OnboardingTextFieldStyle())
                .textInputAutocapitalization(.characters)

            Button(action: { viewModel.useInviteCode() }) {
                Text("Use Code")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(12)
            }

            Button(action: { viewModel.showInviteCodeInput = false }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
    }
}
