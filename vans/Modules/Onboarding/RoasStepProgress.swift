//
//  RoasStepProgress.swift
//  vans
//
//  Created by Can Babaoğlu on 9.02.2026.
//

import SwiftUI

struct RoadLaneStepProgress: View {
    let total: Int
    let current: Int
    var accent: Color

    var segmentGap: CGFloat = 0
    var lineHeight: CGFloat = 2
    var laneSpacing: CGFloat = 15 // distance between top-middle-bottom
    var cornerRadius: CGFloat = 2

    var baseLineOpacity: Double = 0.35        // top/bottom
    var baseDashOpacity: Double = 0.25        // middle (unfilled)
    var filledDashOpacity: Double = 0.95      // middle (filled)

    var dashLength: CGFloat = 6
    var dashSpacing: CGFloat = 6
    var dashLineWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let segCount = max(total, 1)
            let safeGap = segmentGap
            let segmentWidth = (w - CGFloat(segCount - 1) * safeGap) / CGFloat(segCount)

            HStack(spacing: safeGap) {
                ForEach(0..<segCount, id: \.self) { index in
                    ZStack {
                        // TOP line (always base gray/white)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(baseLineOpacity))
                            .frame(height: lineHeight)
                            .offset(y: -laneSpacing)

                        // BOTTOM line (always base gray/white)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(baseLineOpacity))
                            .frame(height: lineHeight)
                            .offset(y: laneSpacing)

                        // MIDDLE dashed (base)
                        DashedLine(
                            dashLength: dashLength,
                            dashSpacing: dashSpacing,
                            lineWidth: dashLineWidth
                        )
                        .stroke(Color.white.opacity(baseDashOpacity), style: StrokeStyle(lineWidth: dashLineWidth, lineCap: .round, dash: [dashLength, dashSpacing]))
                        .frame(height: dashLineWidth)

                        // MIDDLE dashed (filled up to current)
                        if index <= current {
                            DashedLine(
                                dashLength: dashLength,
                                dashSpacing: dashSpacing,
                                lineWidth: dashLineWidth
                            )
                            .stroke(accent.opacity(filledDashOpacity), style: StrokeStyle(lineWidth: dashLineWidth, lineCap: .round, dash: [dashLength, dashSpacing]))
                            .frame(height: dashLineWidth)
                            .shadow(color: accent.opacity(0.35), radius: 6, y: 2)
                        }
                    }
                    .frame(width: segmentWidth, height: 22)
                }
            }
            .frame(width: w, height: 22)
            .animation(.easeOut(duration: 0.22), value: current)
        }
        .frame(height: 22)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

/// Just a helper shape that draws a horizontal line (dashed style comes from StrokeStyle)
private struct DashedLine: Shape {
    var dashLength: CGFloat
    var dashSpacing: CGFloat
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 28) {
            Text("Road Lane Progress")
                .foregroundColor(.white)
                .font(.headline)

            RoadLaneStepProgress(total: 5, current: 0, accent: Color(hex: "2E7D5A"))
                .padding(.horizontal, 24)

            RoadLaneStepProgress(total: 5, current: 1, accent: Color(hex: "2E7D5A"))
                .padding(.horizontal, 24)

            RoadLaneStepProgress(total: 5, current: 2, accent: Color(hex: "2E7D5A"))
                .padding(.horizontal, 24)

            RoadLaneStepProgress(total: 5, current: 3, accent: Color(hex: "2E7D5A"))
                .padding(.horizontal, 24)

            RoadLaneStepProgress(total: 5, current: 4, accent: Color(hex: "2E7D5A"))
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 40)
    }
}
