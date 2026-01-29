import SwiftUI

struct HomeView: ActionableView {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Welcome to Vans")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .navigationBarHidden(true)
    }
}
