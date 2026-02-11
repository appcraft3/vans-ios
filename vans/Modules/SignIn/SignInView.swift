import SwiftUI
import AuthenticationServices

struct SignInView: ActionableView {

    @ObservedObject var viewModel: SignInViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo and Title
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.accentDark)
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 2)
                            )

                        Image(systemName: "car.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(AppTheme.accent)
                    }

                    Text("Welcome to VanGo")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Connect with the van-life community")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Sign In Buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { _ in }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(14)
                    .overlay(
                        Button(action: {
                            viewModel.signInWithApple()
                        }) {
                            Color.clear
                        }
                    )

                    // Google Sign In
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.secondary)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)
            }

            // Loading overlay
            if viewModel.isLoading {
                AppTheme.background.opacity(0.8)
                    .ignoresSafeArea()

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
    }
}

#Preview {
    SignInView(viewModel: SignInViewModel(coordinator: nil))
}
