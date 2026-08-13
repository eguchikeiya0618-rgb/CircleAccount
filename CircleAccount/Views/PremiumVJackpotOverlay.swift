//
//  PremiumVJackpotOverlay.swift
//  CircleAccount
//
//  PUSH押下後に再生する、Vエンブレム中心の超激化JACKPOT演出。
//  追加画像は不要。PremiumVEmblemだけで動作します。
//
//  必須Asset:
//  - PremiumVEmblem（背景透過PNG）
//

import SwiftUI
import UIKit

struct PremiumVJackpotOverlay: View {
    let trigger: Int
    let isRainbowJackpot: Bool

    @State private var sequenceToken = 0
    @State private var isVisible = false

    @State private var blackoutOpacity = 0.0
    @State private var whiteFlashOpacity = 0.0
    @State private var redFlashOpacity = 0.0
    @State private var goldFlashOpacity = 0.0

    @State private var explosionOpacity = 0.0
    @State private var explosionScale: CGFloat = 0.16

    @State private var lightningOpacity = 0.0
    @State private var lightningRotation = -22.0
    @State private var lightningScale: CGFloat = 0.62

    @State private var ringOpacity = 0.0
    @State private var ringScale: CGFloat = 0.14

    @State private var secondRingOpacity = 0.0
    @State private var secondRingScale: CGFloat = 0.16

    @State private var beamOpacity = 0.0
    @State private var beamScale: CGFloat = 0.30

    @State private var vOpacity = 0.0
    @State private var vScale: CGFloat = 0.08
    @State private var vRotation = -14.0
    @State private var vOffsetY: CGFloat = 54
    @State private var vGlowPulse = false
    @State private var vBreathing = false

    @State private var impactTextOpacity = 0.0
    @State private var impactTextScale: CGFloat = 2.2
    @State private var impactTextRotation = -8.0

    @State private var sevenOpacity = 0.0
    @State private var sevenScale: CGFloat = 0.42
    @State private var sevenOffsetY: CGFloat = 22

    @State private var jackpotOpacity = 0.0
    @State private var jackpotScale: CGFloat = 0.48
    @State private var jackpotOffsetY: CGFloat = 28

    @State private var particleProgress: CGFloat = 0
    @State private var particleOpacity = 0.0

    @State private var debrisProgress: CGFloat = 0
    @State private var debrisOpacity = 0.0

    @State private var rainbowOpacity = 0.0
    @State private var rainbowRotation = 0.0
    @State private var rainbowScale: CGFloat = 0.70

    @State private var crackOpacity = 0.0
    @State private var crackScale: CGFloat = 0.65

    @State private var shakeX: CGFloat = 0
    @State private var shakeY: CGFloat = 0
    @State private var wholeScale: CGFloat = 1
    @State private var wholeRotation = 0.0

    private let particleCount = 96
    private let debrisCount = 44
    private let lightningCount = 20
    private let beamCount = 32

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    Color.black
                        .opacity(blackoutOpacity)

                    backgroundHeat(size: proxy.size)
                    goldenBeamLayer
                    explosionLayer(size: proxy.size)
                    crackLayer
                    lightningLayer
                    shockwaveLayer
                    particleLayer(size: proxy.size)
                    debrisLayer(size: proxy.size)

                    if isRainbowJackpot {
                        rainbowAura
                    }

                    vEmblem(size: proxy.size)
                    impactText
                    resultText

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
                        .opacity(whiteFlashOpacity)
                        .blendMode(.plusLighter)

                    vignette
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(wholeScale)
            .rotationEffect(.degrees(wholeRotation))
            .offset(x: shakeX, y: shakeY)
            .clipped()
            .compositingGroup()
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            play()
        }
    }

    private func backgroundHeat(size: CGSize) -> some View {
        RadialGradient(
            colors: [
                Color.white.opacity(explosionOpacity * 0.54),
                Color.yellow.opacity(explosionOpacity * 0.58),
                Color.orange.opacity(explosionOpacity * 0.42),
                Color.red.opacity(explosionOpacity * 0.30),
                Color.black.opacity(0.20),
                Color.black.opacity(0.92)
            ],
            center: .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.76
        )
    }

    private var goldenBeamLayer: some View {
        ZStack {
            ForEach(0..<beamCount, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                index.isMultiple(of: 3) ? Color.yellow : Color.orange,
                                Color.red.opacity(0.62),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(132 + (index % 7) * 24),
                        height: index.isMultiple(of: 4) ? 8 : 3
                    )
                    .offset(x: 86)
                    .rotationEffect(
                        .degrees(Double(index) * (360.0 / Double(beamCount)))
                    )
                    .scaleEffect(beamScale)
                    .opacity(
                        beamOpacity * Double(index.isMultiple(of: 2) ? 1.0 : 0.64)
                    )
                    .shadow(color: .yellow, radius: 11)
                    .shadow(color: .orange, radius: 20)
                    .blendMode(.plusLighter)
            }
        }
    }

    private func explosionLayer(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color.yellow.opacity(0.92),
                    Color.orange.opacity(0.78),
                    Color.red.opacity(0.52),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.62
            )
            .scaleEffect(explosionScale)
            .opacity(explosionOpacity)
            .blendMode(.plusLighter)

            ForEach(0..<34, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white,
                                index.isMultiple(of: 2) ? .yellow : .orange,
                                .red.opacity(0.76),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(118 + (index % 7) * 20),
                        height: index.isMultiple(of: 4) ? 8 : 3
                    )
                    .offset(x: 82)
                    .rotationEffect(.degrees(Double(index) * (360.0 / 34.0)))
                    .scaleEffect(explosionScale)
                    .opacity(explosionOpacity)
                    .shadow(color: .orange, radius: 14)
                    .blendMode(.plusLighter)
            }
        }
    }

    private var crackLayer: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                CrackBranch(seed: index)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                index.isMultiple(of: 3) ? Color.purple : Color.red,
                                Color.orange,
                                Color.clear
                            ],
                            startPoint: .center,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: index.isMultiple(of: 3) ? 4.2 : 2.4,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 340, height: 420)
                    .scaleEffect(crackScale)
                    .opacity(
                        crackOpacity * Double(index.isMultiple(of: 2) ? 1.0 : 0.70)
                    )
                    .shadow(color: .red, radius: 8)
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
                                .white,
                                index.isMultiple(of: 3) ? .purple : .yellow,
                                .orange,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(120 + (index % 5) * 28),
                        height: index.isMultiple(of: 3) ? 7 : 3
                    )
                    .offset(x: 78)
                    .rotationEffect(.degrees(angle))
                    .scaleEffect(lightningScale)
                    .opacity(
                        lightningOpacity
                        * Double(index.isMultiple(of: 2) ? 1.0 : 0.70)
                    )
                    .shadow(color: .white, radius: 5)
                    .shadow(color: .yellow, radius: 12)
                    .shadow(color: .orange, radius: 20)
                    .blendMode(.plusLighter)
            }
        }
    }

    private var shockwaveLayer: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
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
                        lineWidth: CGFloat(13 - index * 2)
                    )
                    .frame(
                        width: CGFloat(166 + index * 50),
                        height: CGFloat(166 + index * 50)
                    )
                    .scaleEffect(
                        ringScale * (1 + CGFloat(index) * 0.10)
                    )
                    .opacity(
                        ringOpacity * Double(1.0 - Double(index) * 0.16)
                    )
                    .shadow(color: .yellow, radius: 18)
                    .blendMode(.plusLighter)
            }

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        isRainbowJackpot
                            ? AnyShapeStyle(
                                AngularGradient(
                                    colors: [
                                        .red, .orange, .yellow, .green,
                                        .cyan, .blue, .purple, .pink, .red
                                    ],
                                    center: .center
                                )
                            )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        .white, .yellow, .orange, .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                        lineWidth: CGFloat(9 - index * 2)
                    )
                    .frame(
                        width: CGFloat(148 + index * 58),
                        height: CGFloat(148 + index * 58)
                    )
                    .scaleEffect(
                        secondRingScale * (1 + CGFloat(index) * 0.12)
                    )
                    .opacity(
                        secondRingOpacity * Double(1.0 - Double(index) * 0.20)
                    )
                    .shadow(color: .white, radius: 14)
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
                    CGFloat(22 + (index % 16) * 11)
                    * particleProgress

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                particleColor(index),
                                Color.red.opacity(0.78),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(10 + index % 8 * 7),
                        height: index.isMultiple(of: 3) ? 4.2 : 2.2
                    )
                    .rotationEffect(.degrees(angle))
                    .position(
                        x: size.width / 2 + cos(radians) * distance,
                        y: size.height / 2 + sin(radians) * distance
                    )
                    .opacity(
                        particleOpacity
                        * max(0, 1 - Double(particleProgress) * 0.58)
                    )
                    .shadow(color: particleColor(index), radius: 9)
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
                    + Double(index % 6) * 4.0
                let radians = angle * .pi / 180
                let distance =
                    CGFloat(18 + (index % 11) * 15)
                    * debrisProgress

                RoundedRectangle(cornerRadius: 1.2)
                    .fill(particleColor(index))
                    .frame(
                        width: CGFloat(4 + index % 5 * 2),
                        height: CGFloat(10 + index % 6 * 4)
                    )
                    .rotationEffect(
                        .degrees(angle + Double(debrisProgress) * 280)
                    )
                    .position(
                        x: size.width / 2 + cos(radians) * distance,
                        y: size.height / 2 + sin(radians) * distance
                    )
                    .opacity(
                        debrisOpacity
                        * max(0, 1 - Double(debrisProgress) * 0.70)
                    )
                    .shadow(color: particleColor(index), radius: 7)
                    .blendMode(.plusLighter)
            }
        }
    }

    private func vEmblem(size: CGSize) -> some View {
        ZStack {
            Image("PremiumVEmblem")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 1.00, 390),
                    height: min(size.height * 0.78, 430)
                )
                .scaleEffect(vScale * 1.10)
                .rotationEffect(.degrees(vRotation))
                .offset(y: vOffsetY)
                .opacity(vOpacity * 0.74)
                .blur(radius: vGlowPulse ? 31 : 17)
                .brightness(0.48)
                .saturation(1.34)
                .blendMode(.plusLighter)

            Image("PremiumVEmblem")
                .resizable()
                .scaledToFit()
                .frame(
                    width: min(size.width * 0.94, 366),
                    height: min(size.height * 0.74, 410)
                )
                .scaleEffect(vScale * (vBreathing ? 1.025 : 0.99))
                .rotationEffect(.degrees(vRotation))
                .offset(y: vOffsetY)
                .opacity(vOpacity)
                .contrast(1.18)
                .saturation(1.22)
                .brightness(vGlowPulse ? 0.11 : 0)
                .shadow(color: .black.opacity(0.98), radius: 14, y: 11)
                .shadow(color: .orange.opacity(1.0), radius: 27)
                .shadow(color: .yellow.opacity(0.94), radius: 15)
                .shadow(color: .white.opacity(0.68), radius: 6)
        }
    }

    private var impactText: some View {
        Text("ドンッ!!")
            .font(
                .system(
                    size: 48,
                    weight: .black,
                    design: .rounded
                )
            )
            .italic()
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .white,
                        .yellow,
                        .orange,
                        .red
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .strokeText(color: .black, width: 2.8)
            .shadow(color: .red, radius: 18)
            .shadow(color: .yellow, radius: 8)
            .scaleEffect(impactTextScale)
            .rotationEffect(.degrees(impactTextRotation))
            .opacity(impactTextOpacity)
            .offset(x: 92, y: 118)
    }

    private var rainbowAura: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .red, .orange, .yellow, .green,
                            .cyan, .blue, .purple, .pink, .red
                        ],
                        center: .center,
                        angle: .degrees(rainbowRotation)
                    ),
                    lineWidth: 28
                )
                .frame(width: 286, height: 286)
                .scaleEffect(rainbowScale)
                .opacity(rainbowOpacity)
                .blur(radius: 4)
                .shadow(color: .white, radius: 18)
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.yellow.opacity(0.34),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(rainbowScale)
                .opacity(rainbowOpacity * 0.58)
                .blendMode(.plusLighter)
        }
    }

    private var resultText: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("777")
                .font(
                    .system(
                        size: 82,
                        weight: .black,
                        design: .serif
                    )
                )
                .italic()
                .tracking(-5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            .yellow,
                            .orange,
                            .red
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .strokeText(color: .black, width: 2.6)
                .shadow(color: .red, radius: 18)
                .shadow(color: .yellow, radius: 10)
                .scaleEffect(sevenScale)
                .offset(y: sevenOffsetY)
                .opacity(sevenOpacity)

            Text("JACKPOT")
                .font(
                    .system(
                        size: 38,
                        weight: .black,
                        design: .serif
                    )
                )
                .tracking(1.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            .yellow,
                            .orange,
                            .red
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .strokeText(color: .black, width: 2.0)
                .shadow(color: .orange, radius: 16)
                .shadow(color: .red, radius: 9)
                .scaleEffect(jackpotScale)
                .offset(y: jackpotOffsetY)
                .opacity(jackpotOpacity)

            Spacer()
                .frame(height: 18)
        }
    }

    private var vignette: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.clear,
                Color.black.opacity(0.70)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 360
        )
    }

    private func particleColor(_ index: Int) -> Color {
        if isRainbowJackpot {
            let colors: [Color] = [
                .red, .orange, .yellow, .green,
                .cyan, .blue, .purple, .pink
            ]
            return colors[index % colors.count]
        }

        if index.isMultiple(of: 4) {
            return .white
        }

        return index.isMultiple(of: 2) ? .yellow : .orange
    }

    private func play() {
        sequenceToken += 1
        let token = sequenceToken

        reset()
        isVisible = true

        // 0.00秒：完全暗転＋重い初撃
        blackoutOpacity = 1
        impact(.heavy, intensity: 1.0)
        playShake(intensity: 1.0)

        // 0.07秒：赤フラッシュ
        schedule(after: 0.07, token: token) {
            redFlashOpacity = 0.76

            withAnimation(.easeOut(duration: 0.09)) {
                redFlashOpacity = 0
            }
        }

        // 0.14秒：白フラッシュ
        schedule(after: 0.14, token: token) {
            whiteFlashOpacity = 1

            withAnimation(.easeOut(duration: 0.075)) {
                whiteFlashOpacity = 0
            }
        }

        // 0.24秒：画面亀裂＋稲妻
        schedule(after: 0.24, token: token) {
            crackOpacity = 1
            crackScale = 0.65
            lightningOpacity = 1
            lightningScale = 0.62
            lightningRotation = -22

            withAnimation(.easeOut(duration: 0.28)) {
                crackScale = 1.12
                lightningScale = 1.34
                lightningRotation = 22
            }

            withAnimation(.easeOut(duration: 0.34)) {
                crackOpacity = 0
                lightningOpacity = 0
            }

            impact(.rigid, intensity: 0.96)
        }

        // 0.42秒：超爆発＋火花＋破片
        schedule(after: 0.42, token: token) {
            explosionOpacity = 1
            explosionScale = 0.16

            ringOpacity = 1
            ringScale = 0.14

            beamOpacity = 1
            beamScale = 0.30

            particleOpacity = 1
            particleProgress = 0

            debrisOpacity = 1
            debrisProgress = 0

            goldFlashOpacity = 0.90

            withAnimation(.easeOut(duration: 0.48)) {
                explosionScale = 1.54
                explosionOpacity = 0.34

                ringScale = 2.02
                ringOpacity = 0

                beamScale = 1.48
                beamOpacity = 0.18

                particleProgress = 1
                debrisProgress = 1

                goldFlashOpacity = 0
            }

            playShake(intensity: 0.92)
            impact(.heavy, intensity: 1.0)
        }

        // 0.78秒：Vが奥から手前へ叩きつけ
        schedule(after: 0.78, token: token) {
            vOpacity = 1
            vScale = 0.08
            vRotation = -14
            vOffsetY = 54

            wholeScale = 1.05
            wholeRotation = -0.40

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.38
                )
            ) {
                vScale = 1.34
                vRotation = 2.8
                vOffsetY = -12

                wholeScale = 0.978
                wholeRotation = 0.32
            }

            impact(.heavy, intensity: 1.0)
            playShake(intensity: 0.82)
        }

        // 1.08秒：「ドンッ!!」
        schedule(after: 1.08, token: token) {
            impactTextOpacity = 1
            impactTextScale = 2.2
            impactTextRotation = -8

            whiteFlashOpacity = 0.76

            withAnimation(.easeOut(duration: 0.07)) {
                whiteFlashOpacity = 0
            }

            withAnimation(
                .spring(
                    response: 0.24,
                    dampingFraction: 0.42
                )
            ) {
                impactTextScale = 1
                impactTextRotation = 5
            }

            playShake(intensity: 0.72)
            impact(.rigid, intensity: 1.0)
        }

        // 1.28秒：巨大Vを中央へ固定＋第2衝撃波
        schedule(after: 1.28, token: token) {
            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.62
                )
            ) {
                vScale = 1.04
                vRotation = 0
                vOffsetY = -24

                wholeScale = 1
                wholeRotation = 0
            }

            secondRingOpacity = 1
            secondRingScale = 0.16

            withAnimation(.easeOut(duration: 0.44)) {
                secondRingScale = 2.12
                secondRingOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.18)) {
                impactTextOpacity = 0
            }

            withAnimation(
                .easeInOut(duration: 0.34)
                    .repeatForever(autoreverses: true)
            ) {
                vGlowPulse = true
                vBreathing = true
            }
        }

        // 1.62秒：虹オーラ
        schedule(after: 1.62, token: token) {
            if isRainbowJackpot {
                rainbowOpacity = 0.96
                rainbowScale = 0.70

                withAnimation(.spring(response: 0.34, dampingFraction: 0.52)) {
                    rainbowScale = 1.10
                }

                withAnimation(
                    .linear(duration: 0.90)
                        .repeatForever(autoreverses: false)
                ) {
                    rainbowRotation = 360
                }
            }

            secondImpact()
        }

        // 2.05秒：777
        schedule(after: 2.05, token: token) {
            sevenOpacity = 1
            sevenScale = 0.42
            sevenOffsetY = 22

            withAnimation(
                .spring(
                    response: 0.32,
                    dampingFraction: 0.44
                )
            ) {
                sevenScale = 1
                sevenOffsetY = 0
            }

            impact(.heavy, intensity: 1.0)
            playShake(intensity: 0.58)
        }

        // 2.44秒：JACKPOT
        schedule(after: 2.44, token: token) {
            jackpotOpacity = 1
            jackpotScale = 0.48
            jackpotOffsetY = 28

            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.48
                )
            ) {
                jackpotScale = 1
                jackpotOffsetY = 0
            }

            notification(.success)
            playShake(intensity: 0.48)
        }

        // 2.88秒：最終金フラッシュ
        schedule(after: 2.88, token: token) {
            goldFlashOpacity = 0.62
            impact(.heavy, intensity: 0.92)

            withAnimation(.easeOut(duration: 0.14)) {
                goldFlashOpacity = 0
            }
        }

        // 3.28秒：収束
        schedule(after: 3.28, token: token) {
            withAnimation(.easeOut(duration: 0.42)) {
                vOpacity = 0
                sevenOpacity = 0
                jackpotOpacity = 0
                rainbowOpacity = 0
                particleOpacity = 0
                debrisOpacity = 0
                beamOpacity = 0
                blackoutOpacity = 0
            }
        }

        // 3.76秒：終了
        schedule(after: 3.76, token: token) {
            isVisible = false
        }
    }

    private func reset() {
        blackoutOpacity = 0
        whiteFlashOpacity = 0
        redFlashOpacity = 0
        goldFlashOpacity = 0

        explosionOpacity = 0
        explosionScale = 0.16

        lightningOpacity = 0
        lightningRotation = -22
        lightningScale = 0.62

        ringOpacity = 0
        ringScale = 0.14

        secondRingOpacity = 0
        secondRingScale = 0.16

        beamOpacity = 0
        beamScale = 0.30

        vOpacity = 0
        vScale = 0.08
        vRotation = -14
        vOffsetY = 54
        vGlowPulse = false
        vBreathing = false

        impactTextOpacity = 0
        impactTextScale = 2.2
        impactTextRotation = -8

        sevenOpacity = 0
        sevenScale = 0.42
        sevenOffsetY = 22

        jackpotOpacity = 0
        jackpotScale = 0.48
        jackpotOffsetY = 28

        particleProgress = 0
        particleOpacity = 0

        debrisProgress = 0
        debrisOpacity = 0

        rainbowOpacity = 0
        rainbowRotation = 0
        rainbowScale = 0.70

        crackOpacity = 0
        crackScale = 0.65

        shakeX = 0
        shakeY = 0
        wholeScale = 1
        wholeRotation = 0
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

    private func playShake(intensity: CGFloat) {
        let sequence: [(CGFloat, CGFloat)] = [
            (-21, 6),
            (19, -6),
            (-16, 5),
            (14, -4),
            (-11, 3),
            (9, -3),
            (-7, 2),
            (5, -2),
            (-3, 1),
            (1, -1),
            (0, 0)
        ]

        for (index, value) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline:
                    .now()
                    + Double(index)
                    * 0.026
            ) {
                shakeX = value.0 * intensity
                shakeY = value.1 * intensity
            }
        }
    }

    private func secondImpact() {
        whiteFlashOpacity = 0.80
        playShake(intensity: 0.60)
        impact(.rigid, intensity: 0.94)

        withAnimation(.easeOut(duration: 0.08)) {
            whiteFlashOpacity = 0
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

private struct CrackBranch: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        let baseAngle =
            Double(seed)
            * (360.0 / 18.0)
            * .pi
            / 180.0

        path.move(to: center)

        var current = center

        for segment in 1...5 {
            let distance = CGFloat(segment) * 26
            let noise =
                sin(Double(seed * 17 + segment * 11))
                * 12

            let point = CGPoint(
                x:
                    center.x
                    + cos(baseAngle) * distance
                    + CGFloat(noise),
                y:
                    center.y
                    + sin(baseAngle) * distance
                    - CGFloat(noise * 0.45)
            )

            path.addLine(to: point)
            current = point
        }

        let branchAngle = baseAngle + (seed.isMultiple(of: 2) ? 0.48 : -0.42)

        path.move(to: current)

        path.addLine(
            to: CGPoint(
                x: current.x + cos(branchAngle) * 34,
                y: current.y + sin(branchAngle) * 34
            )
        )

        return path
    }
}

private extension View {
    func strokeText(color: Color, width: CGFloat) -> some View {
        self
            .shadow(color: color, radius: 0, x: width, y: 0)
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: 0, y: -width)
            .shadow(color: color, radius: 0, x: width * 0.7, y: width * 0.7)
            .shadow(color: color, radius: 0, x: -width * 0.7, y: width * 0.7)
            .shadow(color: color, radius: 0, x: width * 0.7, y: -width * 0.7)
            .shadow(color: color, radius: 0, x: -width * 0.7, y: -width * 0.7)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PremiumVJackpotOverlay(
            trigger: 1,
            isRainbowJackpot: true
        )
        .frame(width: 370, height: 520)
    }
}

