import SwiftUI

struct ExploreView: ActionableView {
    @ObservedObject var viewModel: ExploreViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Explore")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Discover new content")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .navigationBarHidden(true)
    }
}
