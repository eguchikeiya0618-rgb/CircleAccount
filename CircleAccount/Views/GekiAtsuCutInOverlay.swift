//
//  GekiAtsuCutInOverlay.swift
//  CircleAccount
//
//  実機風・高コントラスト版「激アツ」カットイン
//
//  使用Assets:
//  - GekiAtsuExplosion
//  - GekiAtsuLogo
//

import SwiftUI
import UIKit

struct EguchiCustomGekiAtsuView: View {
    @State private var sequenceToken = 0

    @State private var curtainOpacity = 0.0
    @State private var vignetteOpacity = 0.0

    @State private var explosionOpacity = 0.0
    @State private var explosionScale: CGFloat = 0.20
    @State private var explosionRotation = -10.0
    @State private var explosionBrightness = 0.0

    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 2.4
    @State private var logoRotation = -8.0
    @State private var logoOffsetY: CGFloat = 28

    @State private var glowOpacity = 0.0
    @State private var glowScale: CGFloat = 0.72

    @State private var shockwaveScale: CGFloat = 0.22
    @State private var shockwaveOpacity = 0.0

    @State private var secondShockwaveScale: CGFloat = 0.24
    @State private var secondShockwaveOpacity = 0.0

    @State private var flashOpacity = 0.0
    @State private var redFlashOpacity = 0.0
    @State private var goldFlashOpacity = 0.0

    @State private var lightningOpacity = 0.0
    @State private var lightningScale: CGFloat = 0.78
    @State private var lightningRotation = -14.0

    @State private var particleProgress: CGFloat = 0
    @State private var particleOpacity = 0.0

    @State private var debrisProgress: CGFloat = 0
    @State private var debrisOpacity = 0.0

    @State private var shakeX: CGFloat = 0
    @State private var shakeY: CGFloat = 0
    @State private var wholeScale: CGFloat = 1.0
    @State private var wholeRotation = 0.0

    @State private var subtitleOpacity = 0.0
    @State private var subtitleScale: CGFloat = 0.72
    @State private var subtitleOffsetY: CGFloat = 26

    @State private var logoPulse = false
    @State private var glowPulse = false
    @State private var scanTravel = false
    @State private var heatPulse = false

    private let particleCount = 66
    private let debrisCount = 30
    private let lightningCount = 12

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(curtainOpacity)

                backgroundHeat(size: proxy.size)

                scanLines(size: proxy.size)

                explosionLayer(size: proxy.size)

                shockwaveLayer

                lightningLayer

                particleLayer(size: proxy.size)

                debrisLayer(size: proxy.size)

                logoGlow(size: proxy.size)

                logo(size: proxy.size)

                subtitle(size: proxy.size)

                Color.red
                    .opacity(redFlashOpacity)
                    .blendMode(.plusLighter)

                Color(
                    red: 1.0,
                    green: 0.42,
                    blue: 0.0
                )
                .opacity(goldFlashOpacity)
                .blendMode(.plusLighter)

                Color.white
                    .opacity(flashOpacity)
                    .blendMode(.plusLighter)

                vignette
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
            .scaleEffect(wholeScale)
            .rotationEffect(.degrees(wholeRotation))
            .offset(x: shakeX, y: shakeY)
            .clipped()
            .compositingGroup()
        }
        .allowsHitTesting(false)
        .onAppear {
            play()
        }
    }

    private func backgroundHeat(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.white.opacity(explosionOpacity * 0.18),
                    Color.yellow.opacity(explosionOpacity * 0.32),
                    Color.orange.opacity(explosionOpacity * 0.24),
                    Color.red.opacity(explosionOpacity * 0.20),
                    Color.black.opacity(0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.68
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.62),
                    Color.red.opacity(heatPulse ? 0.20 : 0.08),
                    Color.black.opacity(0.14),
                    Color.black.opacity(0.56)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func scanLines(size: CGSize) -> some View {
        VStack(spacing: 5) {
            ForEach(0..<64, id: \.self) { index in
                Rectangle()
                    .fill(
                        index.isMultiple(of: 8)
                            ? Color.white.opacity(0.040)
                            : Color.white.opacity(0.014)
                    )
                    .frame(height: 1)
            }
        }
        .offset(y: scanTravel ? size.height * 0.08 : -size.height * 0.08)
        .blendMode(.screen)
        .opacity(0.38)
    }

    private func explosionLayer(size: CGSize) -> some View {
        ZStack {
            Image("GekiAtsuExplosion")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 1.16, 450),
                    height: min(size.height * 0.86, 450)
                )
                .scaleEffect(explosionScale)
                .rotationEffect(.degrees(explosionRotation))
                .opacity(explosionOpacity)
                .brightness(explosionBrightness)
                .contrast(1.20)
                .saturation(1.35)
                .shadow(color: Color.red.opacity(0.95), radius: 24)
                .shadow(color: Color.orange.opacity(0.82), radius: 16)
                .blendMode(.screen)

            Image("GekiAtsuExplosion")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 0.96, 380),
                    height: min(size.height * 0.72, 380)
                )
                .scaleEffect(explosionScale * 0.96)
                .rotationEffect(.degrees(-explosionRotation * 0.60))
                .opacity(explosionOpacity * 0.32)
                .blur(radius: 8)
                .brightness(0.18)
                .blendMode(.plusLighter)
        }
        .offset(y: -6)
    }

    private var shockwaveLayer: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .clear,
                                .red,
                                .orange,
                                .yellow,
                                .white,
                                .yellow,
                                .orange,
                                .red,
                                .clear
                            ],
                            center: .center
                        ),
                        lineWidth: CGFloat(9 - index * 2)
                    )
                    .frame(
                        width: CGFloat(158 + index * 44),
                        height: CGFloat(158 + index * 44)
                    )
                    .scaleEffect(
                        shockwaveScale
                        * (1 + CGFloat(index) * 0.10)
                    )
                    .opacity(
                        shockwaveOpacity
                        * Double(1.0 - Double(index) * 0.18)
                    )
                    .blur(radius: CGFloat(index) * 0.6)
                    .shadow(color: Color.orange, radius: 14)
                    .blendMode(.plusLighter)
            }

            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                Color.orange,
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: CGFloat(6 - index * 2)
                    )
                    .frame(
                        width: CGFloat(142 + index * 60),
                        height: CGFloat(142 + index * 60)
                    )
                    .scaleEffect(
                        secondShockwaveScale
                        * (1 + CGFloat(index) * 0.12)
                    )
                    .opacity(
                        secondShockwaveOpacity
                        * Double(1.0 - Double(index) * 0.22)
                    )
                    .shadow(color: Color.yellow, radius: 12)
                    .blendMode(.plusLighter)
            }
        }
    }

    private var lightningLayer: some View {
        ZStack {
            ForEach(0..<lightningCount, id: \.self) { index in
                let angle =
                    Double(index)
                    * (360.0 / Double(lightningCount))
                    + lightningRotation

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                Color.orange,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(102 + (index % 4) * 24),
                        height: index.isMultiple(of: 3) ? 5.0 : 2.7
                    )
                    .offset(x: 68)
                    .rotationEffect(.degrees(angle))
                    .scaleEffect(lightningScale)
                    .opacity(
                        lightningOpacity
                        * Double(index.isMultiple(of: 2) ? 1.0 : 0.68)
                    )
                    .shadow(color: Color.white, radius: 4)
                    .shadow(color: Color.yellow, radius: 10)
                    .shadow(color: Color.orange, radius: 15)
                    .blendMode(.plusLighter)
            }
        }
    }

    private func particleLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle =
                    Double(index)
                    * (360.0 / Double(particleCount))

                let radians = angle * .pi / 180

                let distance =
                    CGFloat(20 + (index % 12) * 10)
                    * particleProgress

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                index.isMultiple(of: 2)
                                    ? Color.yellow
                                    : Color.orange,
                                Color.red.opacity(0.76),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(9 + index % 7 * 6),
                        height: index.isMultiple(of: 3) ? 3.4 : 2.0
                    )
                    .rotationEffect(.degrees(angle))
                    .position(
                        x:
                            size.width / 2
                            + cos(radians) * distance,
                        y:
                            size.height / 2
                            + sin(radians) * distance
                    )
                    .opacity(
                        particleOpacity
                        * max(
                            0,
                            1 - Double(particleProgress) * 0.66
                        )
                    )
                    .shadow(color: Color.orange, radius: 7)
                    .blendMode(.plusLighter)
            }
        }
    }

    private func debrisLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<debrisCount, id: \.self) { index in
                let angle =
                    Double(index)
                    * (360.0 / Double(debrisCount))
                    + Double(index % 6) * 4

                let radians = angle * .pi / 180

                let distance =
                    CGFloat(14 + (index % 9) * 14)
                    * debrisProgress

                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        index.isMultiple(of: 4)
                            ? Color.white
                            : (
                                index.isMultiple(of: 2)
                                    ? Color.yellow
                                    : Color.red
                            )
                    )
                    .frame(
                        width: CGFloat(4 + index % 4 * 2),
                        height: CGFloat(8 + index % 5 * 3)
                    )
                    .rotationEffect(
                        .degrees(
                            angle
                            + Double(debrisProgress) * 230
                        )
                    )
                    .position(
                        x:
                            size.width / 2
                            + cos(radians) * distance,
                        y:
                            size.height / 2
                            + sin(radians) * distance
                    )
                    .opacity(
                        debrisOpacity
                        * max(
                            0,
                            1 - Double(debrisProgress) * 0.76
                        )
                    )
                    .shadow(color: Color.orange, radius: 5)
                    .blendMode(.plusLighter)
            }
        }
    }

    private func logoGlow(size: CGSize) -> some View {
        ZStack {
            Image("GekiAtsuLogo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 0.94, 360),
                    height: min(size.height * 0.44, 220)
                )
                .scaleEffect(glowScale)
                .offset(y: logoOffsetY)
                .opacity(glowOpacity)
                .blur(radius: glowPulse ? 24 : 16)
                .brightness(0.30)
                .saturation(1.36)
                .blendMode(.plusLighter)

            Image("GekiAtsuLogo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 0.90, 345),
                    height: min(size.height * 0.42, 210)
                )
                .scaleEffect(glowScale * 1.04)
                .offset(y: logoOffsetY)
                .opacity(glowOpacity * 0.62)
                .blur(radius: 8)
                .brightness(0.22)
                .blendMode(.screen)
        }
    }

    private func logo(size: CGSize) -> some View {
        Image("GekiAtsuLogo")
            .resizable()
            .scaledToFit()
            .frame(
                width: min(size.width * 0.92, 352),
                height: min(size.height * 0.44, 220)
            )
            .scaleEffect(
                logoScale
                * (logoPulse ? 1.025 : 0.992)
            )
            .rotationEffect(.degrees(logoRotation))
            .offset(y: logoOffsetY)
            .opacity(logoOpacity)
            .contrast(1.18)
            .saturation(1.22)
            .brightness(logoPulse ? 0.055 : 0)
            .shadow(
                color: Color.black.opacity(0.98),
                radius: 10,
                y: 8
            )
            .shadow(
                color: Color.red.opacity(0.95),
                radius: logoPulse ? 22 : 16
            )
            .shadow(
                color: Color.orange.opacity(0.88),
                radius: logoPulse ? 14 : 9
            )
    }

    private func subtitle(size: CGSize) -> some View {
        VStack(spacing: 8) {
            Spacer()

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .red,
                            .yellow,
                            .white,
                            .yellow,
                            .red,
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: min(size.width * 0.70, 266),
                    height: 2
                )
                .shadow(color: Color.orange, radius: 9)

            Text("PREMIUM CHANCE")
                .font(
                    .system(
                        size: 14,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(4.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            .yellow,
                            .orange
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.red, radius: 10)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .red,
                            .yellow,
                            .white,
                            .yellow,
                            .red,
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: min(size.width * 0.70, 266),
                    height: 2
                )
                .shadow(color: Color.orange, radius: 9)

            Spacer()
                .frame(
                    height: max(
                        54,
                        size.height * 0.17
                    )
                )
        }
        .scaleEffect(subtitleScale)
        .offset(y: subtitleOffsetY)
        .opacity(subtitleOpacity)
    }

    private var vignette: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.clear,
                Color.black.opacity(vignetteOpacity)
            ],
            center: .center,
            startRadius: 110,
            endRadius: 360
        )
    }

    private func play() {
        sequenceToken += 1
        let token = sequenceToken

        resetState()

        withAnimation(.easeOut(duration: 0.12)) {
            curtainOpacity = 0.90
            vignetteOpacity = 0.48
            explosionOpacity = 1
            explosionScale = 1.26
            explosionRotation = 1.5
            explosionBrightness = 0.14
        }

        withAnimation(.easeOut(duration: 0.34)) {
            shockwaveScale = 1.72
            shockwaveOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.50)) {
            particleProgress = 1
            debrisProgress = 1
        }

        withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: true)) {
            scanTravel = true
        }

        schedule(after: 0.03, token: token) {
            flashOpacity = 0.96
            redFlashOpacity = 0.48

            withAnimation(.easeOut(duration: 0.06)) {
                flashOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.13)) {
                redFlashOpacity = 0
            }
        }

        schedule(after: 0.09, token: token) {
            impact(.heavy, intensity: 1.0)
            playShake(intensity: 1.0)

            lightningOpacity = 0.92
            lightningScale = 0.78
            lightningRotation = -14

            withAnimation(.easeOut(duration: 0.20)) {
                lightningScale = 1.18
                lightningRotation = 16
            }

            withAnimation(.easeOut(duration: 0.22)) {
                lightningOpacity = 0
            }
        }

        schedule(after: 0.14, token: token) {
            logoOpacity = 1
            glowOpacity = 1
            goldFlashOpacity = 0.76

            withAnimation(.easeOut(duration: 0.10)) {
                goldFlashOpacity = 0
            }

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.40
                )
            ) {
                logoScale = 0.88
                logoRotation = 2.0
                logoOffsetY = -5
                glowScale = 1.18
                wholeScale = 1.018
                wholeRotation = -0.22
            }
        }

        schedule(after: 0.28, token: token) {
            impact(.rigid, intensity: 0.82)
            playShake(intensity: 0.66)

            withAnimation(
                .spring(
                    response: 0.24,
                    dampingFraction: 0.46
                )
            ) {
                logoScale = 1.06
                logoRotation = -0.9
                logoOffsetY = 2
                wholeScale = 0.995
                wholeRotation = 0.18
            }
        }

        schedule(after: 0.40, token: token) {
            secondShockwaveOpacity = 0.92
            secondShockwaveScale = 0.24

            withAnimation(.easeOut(duration: 0.38)) {
                secondShockwaveScale = 1.76
                secondShockwaveOpacity = 0
            }

            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.58
                )
            ) {
                logoScale = 1.0
                logoRotation = 0
                logoOffsetY = 0
                glowScale = 1.0
                wholeScale = 1
                wholeRotation = 0
            }

            withAnimation(.easeOut(duration: 0.22)) {
                glowOpacity = 0.42
            }
        }

        schedule(after: 0.48, token: token) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.62
                )
            ) {
                subtitleOpacity = 1
                subtitleScale = 1
                subtitleOffsetY = 0
            }
        }

        schedule(after: 0.62, token: token) {
            notification(.warning)
            playShake(intensity: 0.34)
        }

        schedule(after: 0.70, token: token) {
            withAnimation(
                .easeInOut(duration: 0.28)
                    .repeatForever(autoreverses: true)
            ) {
                logoPulse = true
                glowPulse = true
                heatPulse = true
            }
        }

        schedule(after: 0.82, token: token) {
            withAnimation(.easeOut(duration: 0.46)) {
                explosionBrightness = -0.06
                explosionOpacity = 0.54
                explosionScale = 1.36
                curtainOpacity = 0.76
                vignetteOpacity = 0.66
            }
        }

        schedule(after: 0.96, token: token) {
            withAnimation(.easeOut(duration: 0.62)) {
                particleOpacity = 0
                debrisOpacity = 0
            }
        }
    }

    private func resetState() {
        curtainOpacity = 0
        vignetteOpacity = 0

        explosionOpacity = 0
        explosionScale = 0.20
        explosionRotation = -10
        explosionBrightness = 0

        logoOpacity = 0
        logoScale = 2.4
        logoRotation = -8
        logoOffsetY = 28

        glowOpacity = 0
        glowScale = 0.72

        shockwaveScale = 0.22
        shockwaveOpacity = 1

        secondShockwaveScale = 0.24
        secondShockwaveOpacity = 0

        flashOpacity = 0
        redFlashOpacity = 0
        goldFlashOpacity = 0

        lightningOpacity = 0
        lightningScale = 0.78
        lightningRotation = -14

        particleProgress = 0
        particleOpacity = 1

        debrisProgress = 0
        debrisOpacity = 1

        shakeX = 0
        shakeY = 0
        wholeScale = 1
        wholeRotation = 0

        subtitleOpacity = 0
        subtitleScale = 0.72
        subtitleOffsetY = 26

        logoPulse = false
        glowPulse = false
        scanTravel = false
        heatPulse = false
    }

    private func schedule(
        after delay: Double,
        token: Int,
        action: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) {
            guard token == sequenceToken else { return }
            action()
        }
    }

    private func playShake(
        intensity: CGFloat
    ) {
        let sequence: [(CGFloat, CGFloat)] = [
            (-15, 4),
            (13, -4),
            (-10, 3),
            (8, -2),
            (-6, 2),
            (4, -1),
            (-2, 1),
            (0, 0)
        ]

        for (index, value) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline:
                    .now()
                    + Double(index) * 0.032
            ) {
                shakeX = value.0 * intensity
                shakeY = value.1 * intensity
            }
        }
    }

    private func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private func notification(
        _ type: UINotificationFeedbackGenerator.FeedbackType
    ) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        EguchiCustomGekiAtsuView()
            .frame(
                width: 370,
                height: 520
            )
    }
}

