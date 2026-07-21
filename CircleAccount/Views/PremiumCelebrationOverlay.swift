//
//  PremiumCelebrationOverlay.swift
//  CircleAccount
//

import SwiftUI

struct PremiumCelebrationOverlay: View {
    let flashOpacity: Double

    @State private var auraPulse = false
    @State private var rainbowRotation = 0.0
    @State private var particlePhase = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .red, .orange, .yellow, .green,
                                .cyan, .blue, .purple, .red
                            ],
                            center: .center,
                            angle: .degrees(rainbowRotation)
                        ),
                        lineWidth: auraPulse ? 7 : 4
                    )
                    .blur(radius: auraPulse ? 3 : 1)
                    .opacity(auraPulse ? 0.95 : 0.55)
                    .scaleEffect(auraPulse ? 1.025 : 1.0)

                ForEach(0..<22, id: \.self) { index in
                    premiumParticle(index: index, size: proxy.size)
                }

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(flashOpacity))
                    .blendMode(.screen)
            }
        }
        .frame(maxWidth: 370)
        .onAppear {
            startContinuousAnimations()
        }
    }

    private func premiumParticle(
        index: Int,
        size: CGSize
    ) -> some View {
        let angle = Double(index) * 0.93 + particlePhase
        let horizontalRadius = max(size.width * 0.43, 1)
        let verticalRadius = max(size.height * 0.45, 1)
        let x = size.width / 2 + CGFloat(cos(angle)) * horizontalRadius
        let y = size.height / 2 + CGFloat(sin(angle * 1.27)) * verticalRadius
        let particleSize = CGFloat(5 + index % 5)
        let sparkle = index.isMultiple(of: 3)

        return Group {
            if sparkle {
                Image(systemName: "sparkle")
                    .font(.system(size: particleSize + 4, weight: .bold))
                    .foregroundStyle(
                        AngularGradient(
                            colors: [.yellow, .white, .cyan, .pink, .yellow],
                            center: .center,
                            angle: .degrees(
                                rainbowRotation + Double(index) * 18
                            )
                        )
                    )
            } else {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                .red, .yellow, .green, .cyan,
                                .blue, .purple, .red
                            ],
                            center: .center,
                            angle: .degrees(
                                rainbowRotation + Double(index) * 14
                            )
                        )
                    )
                    .frame(
                        width: particleSize,
                        height: particleSize
                    )
            }
        }
        .position(x: x, y: y)
        .opacity(auraPulse ? 1.0 : 0.48)
        .scaleEffect(auraPulse ? 1.18 : 0.82)
        .shadow(color: Color.white.opacity(0.75), radius: 5)
    }

    private func startContinuousAnimations() {
        withAnimation(
            .easeInOut(duration: 0.58)
                .repeatForever(autoreverses: true)
        ) {
            auraPulse = true
        }

        withAnimation(
            .linear(duration: 3.2)
                .repeatForever(autoreverses: false)
        ) {
            rainbowRotation = 360
        }

        withAnimation(
            .linear(duration: 5.2)
                .repeatForever(autoreverses: false)
        ) {
            particlePhase = .pi * 2
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PremiumCelebrationOverlay(
            flashOpacity: 0.18
        )
        .frame(height: 520)
        .padding()
    }
}
