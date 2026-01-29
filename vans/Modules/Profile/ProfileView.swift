import SwiftUI

struct ProfileView: ActionableView {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if let user = viewModel.user {
                    Text(user.displayName ?? user.email ?? "User")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: {
                    viewModel.signOut()
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding(.top, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadUser()
        }
    }
}
