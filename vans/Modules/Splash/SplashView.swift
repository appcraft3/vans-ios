import SwiftUI

struct SplashView: ActionableView {

    @ObservedObject var viewModel: SplashViewModel

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 24) {
                Spacer()
                logoView
                appNameView
                Spacer()
                loadingView
                Spacer().frame(height: 60)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Retry") { viewModel.retry() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .overlay {
            if viewModel.state == .forceUpdate {
                forceUpdateOverlay
            }
        }
        .onAppear {
            viewModel.onAppear()
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

    private var logoView: some View {
        Image(systemName: "car.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .foregroundColor(.white)
    }

    private var appNameView: some View {
        Text("VANS")
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }

    private var loadingView: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
            case .forceUpdate:
                EmptyView()
            }
        }
    }

    private var forceUpdateOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Update Required")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Please update to the latest version to continue.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: { viewModel.openAppStore() }) {
                    Text("Update Now")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    SplashView(viewModel: SplashViewModel(coordinator: nil))
}
