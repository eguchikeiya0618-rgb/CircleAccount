//
//  PremiumBurstView.swift
//  CircleAccount
//
//  BONUS確定・プレミアムバースト完成版
//
//  必須Assets:
//  - PremiumBonusExplosion  : 爆発背景
//  - PremiumBonusConfirmed  : BONUS確定ロゴ（背景透過推奨）
//
//  呼び出し側は従来どおり
//  PremiumBurstView(trigger: ..., glowColor: ...)
//  のまま使えます。
//

import SwiftUI
import UIKit

struct PremiumBurstView: View {
    let trigger: Int
    let glowColor: Color

    @State private var playbackTask: Task<Void, Never>?
    @State private var sequenceToken = 0
    @State private var isVisible = false

    @State private var blackoutOpacity = 0.0
    @State private var whiteFlashOpacity = 0.0
    @State private var goldFlashOpacity = 0.0

    @State private var backgroundOpacity = 0.0
    @State private var backgroundScale: CGFloat = 0.70
    @State private var backgroundRotation = -2.4
    @State private var backgroundBlur: CGFloat = 14

    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 1.75
    @State private var logoRotation = -4.5
    @State private var logoOffsetY: CGFloat = 38
    @State private var logoBlur: CGFloat = 22
    @State private var logoSaturation: Double = 0.35
    @State private var logoContrast: Double = 1.45

    @State private var glowOpacity = 0.0
    @State private var glowScale: CGFloat = 0.26

    @State private var ringOpacity = 0.0
    @State private var ringScale: CGFloat = 0.16
    @State private var ringRotation = -28.0

    @State private var particleOpacity = 0.0
    @State private var particleProgress: CGFloat = 0

    @State private var flareOpacity = 0.0
    @State private var flareOffset: CGFloat = -1.4

    @State private var screenOffset = CGSize.zero
    @State private var screenScale: CGFloat = 1
    @State private var screenRotation = 0.0
    @State private var screenOpacity = 1.0

    private let particleCount = 56

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    Color.black
                        .opacity(blackoutOpacity)
                        .ignoresSafeArea()

                    explosionBackground(size: proxy.size)
                    radialGlow(size: proxy.size)
                    shockRings(size: proxy.size)
                    particles(size: proxy.size)
                    bonusLogo(size: proxy.size)
                    lensFlare(size: proxy.size)

                    Color.orange
                        .opacity(goldFlashOpacity)
                        .blendMode(.plusLighter)
                        .ignoresSafeArea()

                    Color.white
                        .opacity(whiteFlashOpacity)
                        .blendMode(.plusLighter)
                        .ignoresSafeArea()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(screenScale)
            .rotationEffect(.degrees(screenRotation))
            .offset(screenOffset)
            .opacity(screenOpacity)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            play()
        }
        .onDisappear {
            playbackTask?.cancel()
            playbackTask = nil
        }
    }

    // MARK: - Background

    private func explosionBackground(size: CGSize) -> some View {
        Group {
            if let image = UIImage(named: "PremiumBonusExplosion") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackExplosion
            }
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(backgroundScale)
        .rotationEffect(.degrees(backgroundRotation))
        .blur(radius: backgroundBlur)
        .opacity(backgroundOpacity)
        .saturation(1.22)
        .contrast(1.08)
        .clipped()
    }

    private var fallbackExplosion: some View {
        ZStack {
            RadialGradient(
                colors: [
                    .white,
                    .yellow,
                    .orange,
                    .red,
                    glowColor.opacity(0.86),
                    .black
                ],
                center: .center,
                startRadius: 0,
                endRadius: 380
            )

            ForEach(0..<30, id: \.self) { index in
                Capsule()
                    .fill(
                        index.isMultiple(of: 4)
                        ? glowColor.opacity(0.70)
                        : Color.orange.opacity(0.84)
                    )
                    .frame(width: 5, height: 300)
                    .offset(y: -170)
                    .rotationEffect(
                        .degrees(Double(index) * 12)
                    )
                    .blendMode(.plusLighter)
            }
        }
    }

    // MARK: - Glow

    private func radialGlow(size: CGSize) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(1.0),
                        .yellow.opacity(0.92),
                        .orange.opacity(0.48),
                        glowColor.opacity(0.20),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: min(size.width, size.height) * 0.48
                )
            )
            .frame(
                width: min(size.width, size.height) * 0.98,
                height: min(size.width, size.height) * 0.98
            )
            .scaleEffect(glowScale)
            .opacity(glowOpacity)
            .blendMode(.plusLighter)
    }

    // MARK: - Shock Rings

    private func shockRings(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .white,
                                .yellow,
                                .orange,
                                glowColor,
                                .cyan,
                                .white
                            ],
                            center: .center,
                            angle: .degrees(
                                ringRotation + Double(index) * 32
                            )
                        ),
                        lineWidth: CGFloat(8 - index * 2)
                    )
                    .padding(CGFloat(index * 18))
                    .opacity(
                        ringOpacity
                        * (1 - Double(index) * 0.18)
                    )
                    .shadow(
                        color: glowColor.opacity(0.86),
                        radius: 16
                    )
            }
        }
        .frame(
            width: min(size.width, size.height) * 0.76,
            height: min(size.width, size.height) * 0.76
        )
        .scaleEffect(ringScale)
        .blendMode(.plusLighter)
    }

    // MARK: - Particles

    private func particles(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle =
                    Double(index)
                    * (360.0 / Double(particleCount))

                let radians = angle * .pi / 180

                let distance =
                    CGFloat(38 + (index * 31) % 230)
                    * particleProgress

                let x = cos(radians) * distance
                let y = sin(radians) * distance

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        index.isMultiple(of: 6)
                        ? Color.white
                        : (
                            index.isMultiple(of: 2)
                            ? Color.yellow
                            : Color.orange
                        )
                    )
                    .frame(
                        width: CGFloat(3 + index % 4),
                        height: CGFloat(7 + index % 8)
                    )
                    .rotationEffect(
                        .degrees(angle + Double(index * 11))
                    )
                    .offset(x: x, y: y)
                    .opacity(
                        particleOpacity
                        * Double(
                            max(
                                0,
                                1 - particleProgress * 0.55
                            )
                        )
                    )
                    .shadow(
                        color: index.isMultiple(of: 6)
                        ? Color.white
                        : glowColor,
                        radius: 7
                    )
                    .blendMode(.plusLighter)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Logo

    private func bonusLogo(size: CGSize) -> some View {
        Group {
            if let image = UIImage(named: "PremiumBonusConfirmed") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackLogo
            }
        }
        .frame(
            width: min(size.width * 0.95, 650),
            height: min(size.height * 0.55, 440)
        )
        .scaleEffect(logoScale)
        .rotationEffect(.degrees(logoRotation))
        .offset(y: logoOffsetY)
        .opacity(logoOpacity)
        .blur(radius: logoBlur)
        .saturation(logoSaturation)
        .contrast(logoContrast)
        .shadow(
            color: Color.white.opacity(0.90),
            radius: 10
        )
        .shadow(
            color: Color.yellow.opacity(0.95),
            radius: 20
        )
        .shadow(
            color: glowColor.opacity(0.92),
            radius: 38
        )
    }

    private var fallbackLogo: some View {
        VStack(spacing: -8) {
            Text("BONUS")
                .font(
                    .system(
                        size: 82,
                        weight: .black,
                        design: .rounded
                    )
                )

            Text("確定")
                .font(
                    .system(
                        size: 112,
                        weight: .black,
                        design: .rounded
                    )
                )
        }
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
    }

    // MARK: - Lens Flare

    private func lensFlare(size: CGSize) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.96),
                        .yellow.opacity(0.75),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: size.width * 0.30,
                height: size.height * 1.30
            )
            .rotationEffect(.degrees(18))
            .offset(x: flareOffset * size.width)
            .opacity(flareOpacity)
            .blur(radius: 3)
            .blendMode(.plusLighter)
    }

    // MARK: - Playback

    private func play() {
        playbackTask?.cancel()
        playbackTask = nil

        sequenceToken += 1
        let token = sequenceToken

        reset()
        isVisible = true

        playbackTask = Task { @MainActor in
            await runSequence(token: token)
        }
    }

    @MainActor
    private func runSequence(token: Int) async {
        blackoutOpacity = 0.88

        // 777停止後の溜め
        guard await wait(0.48, token: token) else { return }

        // 一発目の白フラッシュ
        whiteFlashOpacity = 1
        impact(.heavy, intensity: 1.0)

        withAnimation(.easeOut(duration: 0.14)) {
            whiteFlashOpacity = 0
        }

        // 爆発背景・衝撃波・粒子
        backgroundOpacity = 1
        backgroundScale = 0.70
        backgroundRotation = -2.4
        backgroundBlur = 14

        glowOpacity = 1
        glowScale = 0.24

        ringOpacity = 1
        ringScale = 0.16
        ringRotation = -28

        particleOpacity = 1
        particleProgress = 0

        withAnimation(.easeOut(duration: 0.44)) {
            backgroundScale = 1.18
            backgroundRotation = 1.4
            backgroundBlur = 0

            glowScale = 1.26
            glowOpacity = 0.50

            ringScale = 1.72
            ringOpacity = 0
            ringRotation = 86

            particleProgress = 1
        }

        playHeavyShake()

        guard await wait(0.10, token: token) else { return }

        // 画面を一瞬だけ押し潰して、ロゴ出現の衝撃を作る
        withAnimation(.easeIn(duration: 0.055)) {
            screenScale = 0.92
        }

        guard await wait(0.055, token: token) else { return }

        // 光の中から輪郭だけが見え、奥から飛び出す
        logoOpacity = 0.18
        logoScale = 4.20
        logoRotation = -2.0
        logoOffsetY = 4
        logoBlur = 24
        logoSaturation = 0.15
        logoContrast = 1.70

        glowOpacity = 1
        glowScale = 0.42
        goldFlashOpacity = 0.78

        withAnimation(.easeOut(duration: 0.085)) {
            screenScale = 1.04
            logoOpacity = 0.58
            logoScale = 1.68
            logoBlur = 8
            logoSaturation = 0.72
            glowScale = 0.86
            goldFlashOpacity = 0.18
        }

        guard await wait(0.085, token: token) else { return }

        // 完全なBONUS確定ロゴが着地
        withAnimation(
            .interpolatingSpring(
                mass: 0.58,
                stiffness: 310,
                damping: 17,
                initialVelocity: 10
            )
        ) {
            screenScale = 1
            logoOpacity = 1
            logoScale = 1
            logoRotation = 0
            logoOffsetY = 0
            logoBlur = 0
            logoSaturation = 1.18
            logoContrast = 1.08
            glowScale = 1.20
            glowOpacity = 0.48
            goldFlashOpacity = 0
        }

        impact(.heavy, intensity: 1.0)
        playLogoImpactShake()

        guard await wait(0.22, token: token) else { return }

        // 二段目の金フラッシュ
        goldFlashOpacity = 0.62

        withAnimation(.easeOut(duration: 0.20)) {
            goldFlashOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.12)) {
            screenScale = 1.045
        }

        withAnimation(
            .spring(
                response: 0.26,
                dampingFraction: 0.52
            )
        ) {
            screenScale = 1
        }

        guard await wait(0.18, token: token) else { return }

        // ロゴを横切るレンズフレア
        flareOpacity = 0.94
        flareOffset = -1.4

        withAnimation(.easeInOut(duration: 0.78)) {
            flareOffset = 1.4
        }

        guard await wait(0.78, token: token) else { return }

        withAnimation(.easeOut(duration: 0.20)) {
            flareOpacity = 0
        }

        // ロゴをしっかり見せる
        guard await wait(1.32, token: token) else { return }

        // 終了前の白金フラッシュ
        whiteFlashOpacity = 0.48

        withAnimation(.easeOut(duration: 0.18)) {
            whiteFlashOpacity = 0
        }

        withAnimation(.easeIn(duration: 0.32)) {
            screenOpacity = 0
            screenScale = 1.035
        }

        guard await wait(0.34, token: token) else { return }
        guard token == sequenceToken, !Task.isCancelled else {
            return
        }

        isVisible = false
        playbackTask = nil
    }

    @MainActor
    private func wait(
        _ seconds: Double,
        token: Int
    ) async -> Bool {
        do {
            try await Task.sleep(
                nanoseconds: UInt64(
                    max(0, seconds)
                    * 1_000_000_000
                )
            )
        } catch {
            return false
        }

        return token == sequenceToken && !Task.isCancelled
    }

    // MARK: - Shake / Haptics

    private func playHeavyShake() {
        let values: [CGSize] = [
            .init(width: -14, height: 7),
            .init(width: 12, height: -6),
            .init(width: -10, height: 5),
            .init(width: 8, height: -4),
            .init(width: -6, height: 3),
            .init(width: 4, height: -2),
            .init(width: -2, height: 1),
            .zero
        ]

        for (index, value) in values.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now()
                    + Double(index) * 0.038
            ) {
                screenOffset = value
                screenRotation =
                    Double(index.isMultiple(of: 2) ? -1 : 1)
                    * 0.34
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.32
        ) {
            screenOffset = .zero
            screenRotation = 0
        }
    }

    private func playLogoImpactShake() {
        let values: [CGSize] = [
            .init(width: -9, height: 3),
            .init(width: 8, height: -3),
            .init(width: -6, height: 2),
            .init(width: 4, height: -1),
            .zero
        ]

        for (index, value) in values.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.032
            ) {
                screenOffset = value
            }
        }
    }

    private func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator =
            UIImpactFeedbackGenerator(style: style)

        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    // MARK: - Reset

    private func reset() {
        blackoutOpacity = 0
        whiteFlashOpacity = 0
        goldFlashOpacity = 0

        backgroundOpacity = 0
        backgroundScale = 0.70
        backgroundRotation = -2.4
        backgroundBlur = 14

        logoOpacity = 0
        logoScale = 1.75
        logoRotation = -4.5
        logoOffsetY = 38
        logoBlur = 22
        logoSaturation = 0.35
        logoContrast = 1.45

        glowOpacity = 0
        glowScale = 0.26

        ringOpacity = 0
        ringScale = 0.16
        ringRotation = -28

        particleOpacity = 0
        particleProgress = 0

        flareOpacity = 0
        flareOffset = -1.4

        screenOffset = .zero
        screenScale = 1
        screenRotation = 0
        screenOpacity = 1
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PremiumBurstView(
            trigger: 1,
            glowColor: .purple
        )
    }
}

