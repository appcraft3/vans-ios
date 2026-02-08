import SwiftUI

struct StoryProgressRing: View {
    let freshness: Double

    private let greenColor = Color(hex: "2E7D5A")
    private let orangeColor = Color(hex: "E8B86D")

    private var ringColor: Color {
        freshness > 0.5 ? greenColor : orangeColor
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2.5)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(max(freshness, 0.01)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
