import SwiftUI

struct JackpotOverlay: View {
    let isVisible: Bool
    let glowColor: Color

    @State private var scale: CGFloat = 0.55
    @State private var opacity = 0.0
    @State private var rayRotation = 0.0
    @State private var glowPulse = false
    @State private var rainbowRotation = 0.0

    @State private var confettiProgress: CGFloat = 0
    @State private var confettiBurstScale: CGFloat = 0.35
    @State private var confettiOpacity = 0.0

    @State private var lightningOpacity = 0.0
    @State private var lightningScale: CGFloat = 0.72
    @State private var lightningRotation = 0.0

    @State private var coinRainProgress: CGFloat = 0
    @State private var coinRainOpacity = 0.0
    @State private var coinSpin = 0.0

    var body: some View {
        Group {
            if isVisible {
                GeometryReader { proxy in
                    ZStack {
                        Color.black
                            .opacity(0.58 * opacity)
                            .ignoresSafeArea()

                        ForEach(0..<48, id: \.self) { index in
                            confetti(index: index, size: proxy.size)
                        }

                        lightningOverlay(size: proxy.size)

                        ForEach(0..<30, id: \.self) { index in
                            coin(index: index, size: proxy.size)
                        }

                        ForEach(0..<16, id: \.self) { index in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            index.isMultiple(of: 2)
                                                ? Color.yellow.opacity(0.92)
                                                : glowColor.opacity(0.92),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: 12,
                                    height: max(proxy.size.height * 0.62, 180)
                                )
                                .offset(
                                    y: -max(proxy.size.height * 0.18, 45)
                                )
                                .rotationEffect(
                                    .degrees(
                                        rayRotation
                                            + Double(index) * (360.0 / 16.0)
                                    ),
                                    anchor: .bottom
                                )
                                .opacity(0.54 * opacity)
                                .blur(radius: 1)
                        }

                        jackpotTitle
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                }
                .transition(.opacity)
                .onAppear {
                    play()
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                play()
            } else {
                reset()
            }
        }
    }

    private var jackpotTitle: some View {
        VStack(spacing: 5) {
            Text("JACKPOT")
                .font(
                    .system(
                        size: 50,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(1.3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.yellow,
                            Color.orange,
                            Color.white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Text("JACKPOT")
                        .font(
                            .system(
                                size: 50,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(1.3)
                        .foregroundStyle(Color.clear)
                        .strokeText(
                            color: Color.red.opacity(0.92),
                            width: 2.2
                        )
                }
                .shadow(
                    color: Color.yellow,
                    radius: glowPulse ? 22 : 10
                )
                .shadow(
                    color: Color.red.opacity(0.88),
                    radius: 8
                )

            Text("PREMIUM WIN")
                .font(
                    .system(
                        size: 13,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(4)
                .foregroundStyle(Color.white)
                .shadow(color: glowColor, radius: 8)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("CONGRATULATIONS")
                Image(systemName: "sparkles")
            }
            .font(
                .system(
                    size: 9,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(1.2)
            .foregroundStyle(Color.yellow.opacity(0.95))
            .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(Color.black.opacity(0.72))
            .overlay {
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .stroke(
                    AngularGradient(
                        colors: [
                            .red, .orange, .yellow, .green,
                            .cyan, .blue, .purple, .red
                        ],
                        center: .center,
                        angle: .degrees(rainbowRotation)
                    ),
                    lineWidth: 4
                )
            }
        )
    }

    private func coin(index: Int, size: CGSize) -> some View {
        let seed = Double(index)
        let column = CGFloat(index % 10)
        let row = CGFloat(index / 10)

        let startX =
            (size.width / 10) * (column + 0.5)
            + CGFloat(sin(seed * 1.37)) * 14

        let startY = -40 - row * 70
        let fallDistance = size.height + 150

        let drift =
            CGFloat(
                sin(
                    seed * 2.13
                    + Double(coinRainProgress) * 6.2
                )
            ) * 26

        let x = startX + drift
        let y = startY + fallDistance * coinRainProgress

        let coinSize = CGFloat(18 + index % 4 * 3)
        let delayFactor = CGFloat(index % 7) * 0.035

        let localProgress = max(
            0,
            min(
                1,
                (coinRainProgress - delayFactor)
                / max(1 - delayFactor, 0.01)
            )
        )

        let flipScale = max(
            0.16,
            abs(
                cos(
                    (coinSpin + seed * 27)
                    * .pi / 180
                )
            )
        )

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.yellow,
                            Color.orange
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: coinSize
                    )
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.85),
                    lineWidth: 1.4
                )

            Text("S")
                .font(
                    .system(
                        size: coinSize * 0.42,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(Color.orange.opacity(0.92))
        }
        .frame(width: coinSize, height: coinSize)
        .scaleEffect(x: flipScale, y: 1)
        .rotationEffect(
            .degrees(
                seed * 19
                + Double(localProgress) * 160
            )
        )
        .position(x: x, y: y)
        .opacity(
            coinRainOpacity
            * Double(localProgress)
            * opacity
        )
        .shadow(
            color: Color.yellow.opacity(0.82),
            radius: 5
        )
    }

    private func lightningOverlay(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "bolt.fill")
                    .font(
                        .system(
                            size: CGFloat(
                                34 + (index % 3) * 10
                            ),
                            weight: .black
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                index.isMultiple(of: 2)
                                    ? Color.orange
                                    : Color.cyan
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white, radius: 8)
                    .shadow(
                        color: index.isMultiple(of: 2)
                            ? Color.yellow.opacity(0.95)
                            : Color.cyan.opacity(0.95),
                        radius: 16
                    )
                    .rotationEffect(
                        .degrees(
                            lightningRotation
                            + Double(index) * 45
                        )
                    )
                    .offset(
                        x: cos(Double(index) * .pi / 4)
                            * max(size.width * 0.33, 90),
                        y: sin(Double(index) * .pi / 4)
                            * max(size.height * 0.25, 70)
                    )
            }

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .white, .yellow, .orange, .white,
                            .cyan, .blue, .white
                        ],
                        center: .center,
                        angle: .degrees(lightningRotation)
                    ),
                    lineWidth: 5
                )
                .frame(
                    width: min(size.width * 0.82, 290),
                    height: min(size.width * 0.82, 290)
                )
                .blur(radius: 1.5)
        }
        .scaleEffect(lightningScale)
        .opacity(lightningOpacity * opacity)
        .blendMode(.screen)
    }

    private func confetti(
        index: Int,
        size: CGSize
    ) -> some View {
        let seed = Double(index)
        let startX = size.width * 0.5
        let startY = size.height * 0.42

        let direction =
            index.isMultiple(of: 2)
                ? 1.0
                : -1.0

        let spread = CGFloat(
            direction
            * (
                35.0
                + (
                    seed.truncatingRemainder(
                        dividingBy: 11.0
                    ) * 13.0
                )
            )
        )

        let drift = CGFloat(sin(seed * 1.73)) * 34

        let fallDistance =
            size.height
            * (
                0.58
                + CGFloat(
                    seed.truncatingRemainder(
                        dividingBy: 7.0
                    )
                ) * 0.055
            )

        let arc =
            sin(Double(confettiProgress) * .pi)
            * (
                72
                + seed.truncatingRemainder(
                    dividingBy: 5
                ) * 13
            )

        let x =
            startX
            + (spread + drift) * confettiProgress

        let y =
            startY
            + fallDistance * confettiProgress
            - CGFloat(arc)

        let rotation =
            Double(confettiProgress)
            * (540 + seed * 19)

        let width = CGFloat(5 + index % 5)
        let height = CGFloat(10 + index % 4 * 3)

        let colors: [Color] = [
            .yellow, .orange, .red, .pink,
            .purple, .blue, .cyan, .green, .white
        ]

        let color = colors[index % colors.count]

        return RoundedRectangle(
            cornerRadius: 1.5,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    color,
                    Color.white.opacity(0.9),
                    color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: width, height: height)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(confettiBurstScale)
        .position(x: x, y: y)
        .opacity(confettiOpacity * opacity)
        .shadow(
            color: color.opacity(0.75),
            radius: 3
        )
    }

    private func play() {
        reset()

        withAnimation(
            .easeOut(duration: 0.08)
        ) {
            opacity = 1
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.08
        ) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.48
                )
            ) {
                scale = 1
                confettiBurstScale = 1
                lightningOpacity = 1
                lightningScale = 1
            }

            withAnimation(.easeOut(duration: 1.65)) {
                confettiProgress = 1
            }

            withAnimation(.easeOut(duration: 0.72)) {
                lightningRotation = 16
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.22
        ) {
            withAnimation(.easeInOut(duration: 0.07)) {
                lightningOpacity = 0.28
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.31
        ) {
            withAnimation(.easeOut(duration: 0.10)) {
                lightningOpacity = 1
                lightningScale = 1.08
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.48
        ) {
            withAnimation(.easeOut(duration: 0.34)) {
                lightningOpacity = 0
                lightningScale = 1.18
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.24
        ) {
            withAnimation(.linear(duration: 2.25)) {
                coinRainProgress = 1
                coinSpin = 1080
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.20
        ) {
            withAnimation(.easeOut(duration: 0.45)) {
                confettiOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.95
        ) {
            withAnimation(.easeOut(duration: 0.42)) {
                coinRainOpacity = 0
            }
        }

        withAnimation(
            .linear(duration: 4.2)
                .repeatForever(autoreverses: false)
        ) {
            rayRotation = 360
        }

        withAnimation(
            .easeInOut(duration: 0.46)
                .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }

        withAnimation(
            .linear(duration: 3.2)
                .repeatForever(autoreverses: false)
        ) {
            rainbowRotation = 360
        }
    }

    private func reset() {
        scale = 0.55
        opacity = 0
        rayRotation = 0
        glowPulse = false
        rainbowRotation = 0

        confettiProgress = 0
        confettiBurstScale = 0.35
        confettiOpacity = 1

        lightningOpacity = 0
        lightningScale = 0.72
        lightningRotation = -12

        coinRainProgress = 0
        coinRainOpacity = 1
        coinSpin = 0
    }
}

private extension View {
    func strokeText(
        color: Color,
        width: CGFloat
    ) -> some View {
        self
            .shadow(
                color: color,
                radius: 0,
                x: width,
                y: 0
            )
            .shadow(
                color: color,
                radius: 0,
                x: -width,
                y: 0
            )
            .shadow(
                color: color,
                radius: 0,
                x: 0,
                y: width
            )
            .shadow(
                color: color,
                radius: 0,
                x: 0,
                y: -width
            )
            .shadow(
                color: color,
                radius: 0,
                x: width * 0.7,
                y: width * 0.7
            )
            .shadow(
                color: color,
                radius: 0,
                x: -width * 0.7,
                y: width * 0.7
            )
            .shadow(
                color: color,
                radius: 0,
                x: width * 0.7,
                y: -width * 0.7
            )
            .shadow(
                color: color,
                radius: 0,
                x: -width * 0.7,
                y: -width * 0.7
            )
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        JackpotOverlay(
            isVisible: true,
            glowColor: .purple
        )
    }
}
