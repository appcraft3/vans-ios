//
//  StarfieldBackground.swift
//  vans
//
//  Created by Can Babaoğlu on 9.02.2026.
//

import SwiftUI

struct StarfieldBackground: View {
    let starCount: Int
    let twinkleCount: Int

    @State private var twinkleActive = false

    init(starCount: Int = 80, twinkleCount: Int = 20) {
        self.starCount = starCount
        self.twinkleCount = twinkleCount
    }

    private struct StarData: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
        let isTwinkle: Bool
        let twinkleDuration: Double
    }

    private var stars: [StarData] {
        var rng = SeededRNG(seed: 12345)
        var result: [StarData] = []

        let twinkleSet = Set((0..<starCount).shuffled(using: &rng).prefix(twinkleCount))

        for i in 0..<starCount {
            let x = rng.nextCGFloat()
            let yBiased = pow(rng.nextCGFloat(), 1.6)
            let y = yBiased * 0.55

            let v = rng.nextCGFloat()
            let r: CGFloat
            if v < 0.55 { r = 1.3 }
            else if v < 0.82 { r = 1.8 }
            else { r = 2.4 }

            let opacity = 0.15 + Double(rng.nextCGFloat()) * 0.35

            let duration = 1.5 + Double(rng.nextCGFloat()) * 2.5

            result.append(StarData(
                id: i,
                x: x,
                y: y,
                radius: r,
                opacity: opacity,
                isTwinkle: twinkleSet.contains(i),
                twinkleDuration: duration
            ))
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.radius * 2, height: star.radius * 2)
                        .opacity(star.isTwinkle
                            ? (twinkleActive ? star.opacity : star.opacity * 0.2)
                            : star.opacity
                        )
                        .animation(
                            star.isTwinkle
                                ? .easeInOut(duration: star.twinkleDuration).repeatForever(autoreverses: true)
                                : nil,
                            value: twinkleActive
                        )
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                }
            }
        }
        .onAppear {
            twinkleActive = true
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Seeded RNG

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }

    mutating func nextCGFloat() -> CGFloat {
        CGFloat(Double(next() % 10_000) / 10_000.0)
    }
}
