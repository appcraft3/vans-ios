import SwiftUI
import AuthenticationServices

struct SignInView: ActionableView {

    @ObservedObject var viewModel: SignInViewModel

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)

                    Text("Welcome to VANS")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Sign in to continue")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
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
                    .cornerRadius(12)
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
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }

                    // Anonymous Sign In
                    Button(action: {
                        viewModel.signInAnonymously()
                    }) {
                        Text("Continue without signing in")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)
            }

            // Loading overlay
            if viewModel.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SignInView(viewModel: SignInViewModel(coordinator: nil))
}
