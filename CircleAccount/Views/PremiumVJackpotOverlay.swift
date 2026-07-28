//
//  PremiumVJackpotOverlay.swift
//  CircleAccount
//
//  ゆっくり読める実機風V突入 → BONUS確定
//  旧演出とは完全分離して再生します。
//
//  必須Assets:
//  PremiumVEmblem
//  PremiumVTrail
//  PremiumImpactFlash
//  PremiumShockRing
//  PremiumGoldDust
//  PremiumBonusConfirmed
//

import SwiftUI
import UIKit

struct PremiumVJackpotOverlay: View {

    let trigger: Int
    let isRainbowJackpot: Bool
    let onFinished: () -> Void

    private enum Phase {
        case hidden
        case blackout
        case trail
        case vEnter
        case vImpact
        case vHold
        case transition
        case bonusEnter
        case bonusHold
        case fadeOut
    }

    @State private var phase: Phase = .hidden
    @State private var token = 0

    @State private var trailScale: CGFloat = 0.46
    @State private var trailOffsetX: CGFloat = -150
    @State private var trailBlur: CGFloat = 7

    @State private var vScale: CGFloat = 0.56
    @State private var vOffsetY: CGFloat = 14
    @State private var vRotation = -3.5

    @State private var impactScale: CGFloat = 0.42
    @State private var impactOpacity = 0.0
    @State private var ringScale: CGFloat = 0.34
    @State private var ringOpacity = 0.0

    @State private var dustScale: CGFloat = 0.70
    @State private var dustOffsetY: CGFloat = 44
    @State private var dustOpacity = 0.0

    @State private var bonusScale: CGFloat = 0.68
    @State private var bonusOffsetY: CGFloat = 18
    @State private var bonusRotation = -1.5

    @State private var whiteFlashOpacity = 0.0
    @State private var goldFlashOpacity = 0.0

    @State private var cameraScale: CGFloat = 1
    @State private var shakeX: CGFloat = 0
    @State private var shakeY: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if phase != .hidden {
                    Color.black
                        .ignoresSafeArea()

                    backgroundGlow(size: proxy.size)

                    if phase == .trail {
                        trailLayer(size: proxy.size)
                    }

                    if phase == .vEnter || phase == .vImpact || phase == .vHold {
                        vLayer(size: proxy.size)
                    }

                    if phase == .vImpact {
                        impactLayer(size: proxy.size)
                    }

                    if phase == .vHold ||
                        phase == .transition ||
                        phase == .bonusEnter ||
                        phase == .bonusHold ||
                        phase == .fadeOut {
                        dustLayer(size: proxy.size)
                    }

                    if phase == .bonusEnter ||
                        phase == .bonusHold ||
                        phase == .fadeOut {
                        bonusLayer(size: proxy.size)
                    }

                    ZStack {
                        Color.orange.opacity(goldFlashOpacity)
                        Color.white.opacity(whiteFlashOpacity)
                    }
                    .blendMode(.plusLighter)
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.78)],
                        center: .center,
                        startRadius: 110,
                        endRadius: 390
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(cameraScale)
            .offset(x: shakeX, y: shakeY)
            .opacity(phase == .fadeOut ? 0 : 1)
            .animation(.easeOut(duration: 0.65), value: phase == .fadeOut)
            .clipped()
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, value in
            guard value > 0 else { return }
            play()
        }
    }

    private func backgroundGlow(size: CGSize) -> some View {
        RadialGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.yellow.opacity(0.17),
                Color.orange.opacity(0.12),
                Color.red.opacity(0.06),
                .clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.64
        )
    }

    private func trailLayer(size: CGSize) -> some View {
        image("PremiumVTrail")
            .frame(width: size.width * 1.34, height: size.height * 0.86)
            .scaleEffect(trailScale)
            .offset(x: trailOffsetX)
            .blur(radius: trailBlur)
            .blendMode(.plusLighter)
    }

    private func vLayer(size: CGSize) -> some View {
        ZStack {
            image("PremiumVEmblem")
                .frame(
                    width: min(size.width * 1.02, 398),
                    height: min(size.height * 0.80, 438)
                )
                .scaleEffect(vScale * 1.07)
                .rotationEffect(.degrees(vRotation))
                .offset(y: vOffsetY)
                .blur(radius: 14)
                .brightness(0.44)
                .opacity(0.36)
                .blendMode(.plusLighter)

            image("PremiumVEmblem")
                .frame(
                    width: min(size.width * 0.95, 370),
                    height: min(size.height * 0.74, 408)
                )
                .scaleEffect(vScale)
                .rotationEffect(.degrees(vRotation))
                .offset(y: vOffsetY)
                .contrast(1.13)
                .saturation(1.16)
                .shadow(color: .black.opacity(0.96), radius: 12, y: 9)
                .shadow(color: .orange.opacity(0.80), radius: 15)
        }
    }

    private func impactLayer(size: CGSize) -> some View {
        ZStack {
            image("PremiumImpactFlash")
                .frame(width: size.width * 1.54, height: size.height * 1.34)
                .scaleEffect(impactScale)
                .opacity(impactOpacity)
                .blendMode(.plusLighter)

            image("PremiumShockRing")
                .frame(width: size.width * 1.58, height: size.height * 1.24)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blendMode(.plusLighter)
        }
    }

    private func dustLayer(size: CGSize) -> some View {
        image("PremiumGoldDust")
            .frame(width: size.width * 1.28, height: size.height * 1.24)
            .scaleEffect(dustScale)
            .offset(y: dustOffsetY)
            .opacity(dustOpacity)
            .blendMode(.plusLighter)
    }

    private func bonusLayer(size: CGSize) -> some View {
        ZStack {
            image("PremiumBonusConfirmed")
                .frame(
                    width: min(size.width * 1.10, 410),
                    height: min(size.height * 0.68, 370)
                )
                .scaleEffect(bonusScale * 1.07)
                .rotationEffect(.degrees(bonusRotation))
                .offset(y: bonusOffsetY)
                .blur(radius: 16)
                .brightness(0.44)
                .opacity(0.44)
                .blendMode(.plusLighter)

            image("PremiumBonusConfirmed")
                .frame(
                    width: min(size.width * 1.02, 392),
                    height: min(size.height * 0.64, 348)
                )
                .scaleEffect(bonusScale)
                .rotationEffect(.degrees(bonusRotation))
                .offset(y: bonusOffsetY)
                .contrast(1.12)
                .saturation(1.16)
                .shadow(color: .black.opacity(0.96), radius: 15, y: 10)
                .shadow(color: .red.opacity(0.90), radius: 18)
                .shadow(color: .orange.opacity(0.78), radius: 10)
        }
    }

    private func image(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
    }

    private func play() {
        token += 1
        let current = token
        reset()

        // 0.00〜0.40 暗転
        phase = .blackout
        impact(.heavy, intensity: 0.78)

        // 0.40〜1.30 V接近
        schedule(0.45, current) {
            phase = .trail

            withAnimation(.easeIn(duration: 1.00)) {
                trailScale = 1.02
                trailOffsetX = 6
                trailBlur = 1
            }

            impact(.rigid, intensity: 0.76)
        }

        // 1.30〜1.85 V突入
        schedule(1.45, current) {
            phase = .vEnter

            withAnimation(.easeIn(duration: 0.70)) {
                vScale = 1.08
                vOffsetY = -10
                vRotation = 1.5
                cameraScale = 1.025
            }

            shake(0.36)
        }

        // 1.85〜2.25 衝撃
        schedule(2.10, current) {
            phase = .vImpact
            whiteFlashOpacity = 1
            goldFlashOpacity = 0.46
            impactOpacity = 1
            ringOpacity = 1

            withAnimation(.easeOut(duration: 0.09)) {
                whiteFlashOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.36)) {
                impactScale = 1.28
                impactOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.40)) {
                ringScale = 2.05
                ringOpacity = 0
            }

            withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                vScale = 1
                vOffsetY = -18
                vRotation = 0
                cameraScale = 1
            }

            withAnimation(.easeOut(duration: 0.15)) {
                goldFlashOpacity = 0
            }

            shake(1)
            impact(.heavy, intensity: 1)
        }

        // 2.25〜4.05 Vを約1.8秒しっかり見せる
        schedule(2.55, current) {
            phase = .vHold
            dustOpacity = 0.68

            withAnimation(.easeOut(duration: 2.00)) {
                dustScale = 1.10
                dustOffsetY = -14
                dustOpacity = 0.34
            }

            withAnimation(.easeInOut(duration: 0.70)) {
                vScale = 1.035
            }
        }

        schedule(3.45, current) {
            withAnimation(.easeInOut(duration: 0.70)) {
                vScale = 0.985
            }
        }

        // 4.05 VをView階層から完全削除
        schedule(4.55, current) {
            phase = .transition
            dustOpacity = 0.72
            dustScale = 0.94
            dustOffsetY = 20

            withAnimation(.easeOut(duration: 0.70)) {
                dustScale = 1.20
                dustOffsetY = -20
                dustOpacity = 0.46
            }
        }

        // 4.05〜4.65 金粉だけの間
        // 4.65〜5.25 BONUS確定出現
        schedule(6.70, current) {
            phase = .bonusEnter
            bonusScale = 0.68
            bonusOffsetY = 18
            bonusRotation = -1.5

            withAnimation(.spring(response: 0.38, dampingFraction: 0.54)) {
                bonusScale = 1.16
                bonusOffsetY = -2
                bonusRotation = 1.2
            }

            whiteFlashOpacity = 0.82
            withAnimation(.easeOut(duration: 0.09)) {
                whiteFlashOpacity = 0
            }

            shake(0.72)
            impact(.heavy, intensity: 1)
        }

        schedule(6.40, current) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                bonusScale = 1
                bonusRotation = 0
            }
        }

        // 5.25〜6.55 BONUS確定を見せる
        schedule(6.70, current) {
            phase = .bonusHold
            dustOpacity = 1
            dustScale = 0.86
            dustOffsetY = 28

            withAnimation(.easeOut(duration: 1.60)) {
                dustScale = 1.28
                dustOffsetY = -30
                dustOpacity = 0.50
            }

            goldFlashOpacity = 0.34
            withAnimation(.easeOut(duration: 0.16)) {
                goldFlashOpacity = 0
            }

            notification(.success)
        }

        schedule(6.18, current) {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.76)) {
                bonusScale = 1.045
            }
        }

        schedule(6.40, current) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                bonusScale = 1
            }
        }

        schedule(6.70, current) {
            guard isRainbowJackpot else { return }
            goldFlashOpacity = 0.22
            withAnimation(.easeOut(duration: 0.12)) {
                goldFlashOpacity = 0
            }
        }

        // 6.55〜7.20 フェード
        schedule(7.55, current) {
            phase = .fadeOut
        }

        schedule(8.22, current) {
            phase = .hidden
            onFinished()
        }
    }

    private func reset() {
        phase = .hidden

        trailScale = 0.46
        trailOffsetX = -150
        trailBlur = 7

        vScale = 0.56
        vOffsetY = 14
        vRotation = -3.5

        impactScale = 0.42
        impactOpacity = 0
        ringScale = 0.34
        ringOpacity = 0

        dustScale = 0.70
        dustOffsetY = 44
        dustOpacity = 0

        bonusScale = 0.68
        bonusOffsetY = 18
        bonusRotation = -1.5

        whiteFlashOpacity = 0
        goldFlashOpacity = 0

        cameraScale = 1
        shakeX = 0
        shakeY = 0
    }

    private func schedule(
        _ delay: Double,
        _ current: Int,
        action: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard current == token else { return }
            action()
        }
    }

    private func shake(_ intensity: CGFloat) {
        let steps: [(CGFloat, CGFloat)] = [
            (-18, 6), (16, -5), (-13, 4), (11, -4),
            (-8, 3), (6, -2), (-4, 1), (2, -1), (0, 0)
        ]

        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.032
            ) {
                shakeX = step.0 * intensity
                shakeY = step.1 * intensity
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
        Color.black.ignoresSafeArea()

        PremiumVJackpotOverlay(
            trigger: 1,
            isRainbowJackpot: true,
            onFinished: {}
        )
        .frame(width: 370, height: 520)
    }
}

