import SwiftUI

struct SplashView: ActionableView {

    @ObservedObject var viewModel: SplashViewModel

    var body: some View {
        ZStack {
            backgroundView
            ZStack {
                VStack(spacing: 24) {
                    Spacer()
                    logoView
                    appNameView
                    Spacer()
                    Spacer().frame(height: 60)
                }
                VStack {
                    Spacer()
                    loadingView
                    Spacer().frame(height: 60)
                }
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

//    private var backgroundView: some View {
//        LinearGradient(
//            gradient: Gradient(colors: [
//                Color(red: 0.1, green: 0.1, blue: 0.15),
//                Color(red: 0.05, green: 0.05, blue: 0.1)
//            ]),
//            startPoint: .top,
//            endPoint: .bottom
//        )
//        .ignoresSafeArea()
//    }

//    private var logoView: some View {
//        Image(.vanIcon2)
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .frame(width: 200, height: 200)
//            .foregroundColor(.white)
//    }
    
    private var logoView: some View {
        Image(.vanIcon2)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
            .shadow(color: Color(hex: "2E7D5A").opacity(0.22), radius: 24, y: 10)
    }
    

//    private var appNameView: some View {
//        Text("VANS")
//            .font(.system(size: 42, weight: .bold, design: .rounded))
//            .foregroundColor(.white)
//    }
    
    private var appNameView: some View {
        Text("VANS")
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .white.opacity(0.15), radius: 10, y: 2)
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
                    .foregroundColor(.accentPrimary)
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
    
    @State private var glow = false

    private var backgroundView: some View {
        ZStack {
            // Base gradient (seninki)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.13),
                    Color(red: 0.04, green: 0.04, blue: 0.09)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Green glow behind logo (center -> outward fade)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "2E7D5A").opacity(glow ? 0.35 : 0.22),
                    Color(hex: "2E7D5A").opacity(0.08),
                    Color.clear
                ]),
                center: .center,
                startRadius: 20,
                endRadius: glow ? 340 : 280
            )
            .blendMode(.screen)
            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: glow)

            // Soft vignette (dark edges)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.55)
                ]),
                center: .center,
                startRadius: 180,
                endRadius: 520
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear { glow = true }
    }

}

#Preview {
    SplashView(viewModel: SplashViewModel(coordinator: nil))
}
