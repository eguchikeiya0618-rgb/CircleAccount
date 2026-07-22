//
//  PayoutParticleLayer.swift
//  CircleAccount
//

import SwiftUI

struct PayoutParticleLayer: View {
    let presentation: PayoutRewardPresentation
    let progress: CGFloat
    let opacity: Double

    private let particleCount = 24

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    PayoutParticle(
                        index: index,
                        particleCount: particleCount,
                        presentation: presentation,
                        progress: progress,
                        opacity: opacity,
                        canvasSize: geometry.size
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .allowsHitTesting(false)
    }
}

private struct PayoutParticle: View {
    let index: Int
    let particleCount: Int
    let presentation: PayoutRewardPresentation
    let progress: CGFloat
    let opacity: Double
    let canvasSize: CGSize

    private var angle: Double {
        Double(index)
        / Double(max(particleCount, 1))
        * Double.pi
        * 2
    }

    private var distance: CGFloat {
        74 + CGFloat(index % 6) * 12
    }

    private var particleSize: CGFloat {
        5 + CGFloat(index % 4) * 2
    }

    private var xPosition: CGFloat {
        canvasSize.width / 2
        + CGFloat(cos(angle))
        * distance
        * progress
    }

    private var yPosition: CGFloat {
        canvasSize.height / 2
        + 30
        + CGFloat(sin(angle))
        * distance
        * progress
    }

    private var resolvedOpacity: Double {
        let fade = max(
            0,
            1 - Double(progress) * 0.55
        )

        return opacity * fade
    }

    var body: some View {
        Circle()
            .fill(presentation.color(at: index))
            .frame(
                width: particleSize,
                height: particleSize
            )
            .position(
                x: xPosition,
                y: yPosition
            )
            .opacity(resolvedOpacity)
    }
}
