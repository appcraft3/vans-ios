import SwiftUI

struct InviteCodeView: ActionableView {
    @ObservedObject var viewModel: InviteCodeViewModel
    @State private var showInviteCodeInput = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.accentDark)
                            .frame(width: 100, height: 100)

                        Image(systemName: viewModel.isOnWaitlist ? "clock.fill" : "person.3.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(AppTheme.accent)
                    }

                    Text(viewModel.isOnWaitlist ? "You're on the Waitlist" : "Join the Community")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(viewModel.isOnWaitlist
                         ? "We're reviewing your application. You'll be notified when approved!"
                         : "We're building a trusted community of van lifers. Join the waitlist and we'll review your application.")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    // Join Waitlist Button
                    Button(action: {
                        viewModel.joinWaitlist()
                    }) {
                        HStack {
                            if viewModel.isLoading && !showInviteCodeInput {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else if viewModel.isOnWaitlist {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accent)
                                Text("On Waitlist")
                                    .font(.headline)
                            } else {
                                Text("Join Waitlist")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isOnWaitlist ? AppTheme.card : AppTheme.accent)
                        .foregroundColor(viewModel.isOnWaitlist ? AppTheme.textPrimary : .black)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading || viewModel.isOnWaitlist)
                    .padding(.horizontal, 32)

                    // Have invite code button
                    Button(action: {
                        withAnimation {
                            showInviteCodeInput.toggle()
                        }
                    }) {
                        Text(showInviteCodeInput ? "Hide invite code" : "Have an invite code?")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Invite Code Input (expandable)
                    if showInviteCodeInput {
                        VStack(spacing: 16) {
                            TextField("", text: $viewModel.inviteCode)
                                .placeholder(when: viewModel.inviteCode.isEmpty) {
                                    Text("ENTER CODE")
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding()
                                .background(AppTheme.card)
                                .cornerRadius(12)

                            Button(action: {
                                viewModel.submitCode()
                            }) {
                                HStack {
                                    if viewModel.isLoading && showInviteCodeInput {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.textPrimary))
                                    } else {
                                        Text("Use Code")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(viewModel.inviteCode.isEmpty ? AppTheme.card : AppTheme.primary)
                                .foregroundColor(viewModel.inviteCode.isEmpty ? AppTheme.textSecondary : .black)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.inviteCode.isEmpty || viewModel.isLoading)
                        }
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                // Sign out option
                Button(action: {
                    viewModel.signOut()
                }) {
                    Text("Sign out")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Welcome!", isPresented: $viewModel.showSuccess) {
            Button("Continue", role: .cancel) {
                viewModel.continueToApp()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Waitlist", isPresented: $viewModel.showWaitlistSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.waitlistMessage)
        }
    }
}

// Placeholder modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    InviteCodeView(viewModel: InviteCodeViewModel(coordinator: nil))
}
