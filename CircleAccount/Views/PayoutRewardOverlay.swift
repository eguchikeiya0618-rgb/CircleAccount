//
//  PayoutRewardOverlay.swift
//  CircleAccount
//

import SwiftUI

struct PayoutRewardOverlay: View {
    let trigger: Int
    let presentation: PayoutRewardPresentation?

    @State private var isVisible = false
    @State private var cardOffsetY: CGFloat = 150
    @State private var cardScale: CGFloat = 0.68
    @State private var cardOpacity = 0.0
    @State private var glowScale: CGFloat = 0.72
    @State private var glowOpacity = 0.0
    @State private var shineOffset: CGFloat = -1.4
    @State private var particleProgress: CGFloat = 0
    @State private var particleOpacity = 0.0
    @State private var animationToken = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isVisible,
                   let presentation {
                    backgroundLayer

                    PayoutParticleLayer(
                        presentation: presentation,
                        progress: particleProgress,
                        opacity: particleOpacity
                    )

                    PayoutRewardCardView(
                        presentation: presentation,
                        cardOffsetY: cardOffsetY,
                        cardScale: cardScale,
                        cardOpacity: cardOpacity,
                        glowScale: glowScale,
                        glowOpacity: glowOpacity,
                        shineOffset: shineOffset
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard
                newValue > 0,
                presentation != nil
            else {
                return
            }

            play()
        }
    }

    private var backgroundLayer: some View {
        Color.black
            .opacity(0.18 * cardOpacity)
            .ignoresSafeArea()
    }

    private func play() {
        animationToken += 1
        let currentToken = animationToken

        resetAnimationState()
        isVisible = true

        withAnimation(
            .spring(
                response: 0.50,
                dampingFraction: 0.58
            )
        ) {
            cardOffsetY = 20
            cardScale = 1
            cardOpacity = 1
            glowScale = 1
            glowOpacity = 1
        }

        withAnimation(
            .easeOut(duration: 0.85)
        ) {
            particleProgress = 1
        }

        withAnimation(
            .easeInOut(duration: 0.72)
                .delay(0.18)
        ) {
            shineOffset = 1.5
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.65
        ) {
            guard currentToken == animationToken else {
                return
            }

            withAnimation(
                .easeInOut(duration: 0.28)
            ) {
                glowScale = 1.13
                glowOpacity = 0.45
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.15
        ) {
            guard currentToken == animationToken else {
                return
            }

            withAnimation(
                .easeIn(duration: 0.42)
            ) {
                cardOffsetY = -110
                cardScale = 0.90
                cardOpacity = 0
                particleOpacity = 0
                glowOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.62
        ) {
            guard currentToken == animationToken else {
                return
            }

            isVisible = false
        }
    }

    private func resetAnimationState() {
        cardOffsetY = 150
        cardScale = 0.68
        cardOpacity = 0
        glowScale = 0.72
        glowOpacity = 0
        shineOffset = -1.4
        particleProgress = 0
        particleOpacity = 1
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PayoutRewardOverlay(
            trigger: 1,
            presentation: .from(
                symbols: ["🔔", "🔔", "🔔"]
            )
        )
    }
}
