//
//  SlotLuckyLampView.swift
//  CircleAccount
//

import SwiftUI

enum SlotLuckyLampMode: Equatable {
    case off
    case blue
    case gold
    case rainbow
    case premium

    var isLit: Bool {
        self != .off
    }
}

struct SlotLuckyLampView: View {
    let mode: SlotLuckyLampMode
    let trigger: Int

    @State private var pulse = false
    @State private var revealScale: CGFloat = 1.0
    @State private var flashOpacity = 0.0
    @State private var sweepOffset: CGFloat = -1.4
    @State private var rainbowRotation = 0.0
    @State private var starPulse = false
    @State private var blackoutOpacity = 0.0
    @State private var innerBreath: CGFloat = 0.84
    @State private var leakOpacity = 0.0

    private var mainColor: Color {
        switch mode {
        case .off:
            return Color(red: 0.08, green: 0.07, blue: 0.13)
        case .blue:
            return Color(red: 0.34, green: 0.77, blue: 1.00)
        case .gold:
            return Color(red: 1.00, green: 0.78, blue: 0.16)
        case .rainbow, .premium:
            return Color(red: 1.00, green: 0.62, blue: 0.12)
        }
    }

    private var secondaryColor: Color {
        switch mode {
        case .off:
            return Color(red: 0.04, green: 0.03, blue: 0.08)
        case .blue:
            return Color(red: 0.26, green: 0.16, blue: 0.95)
        case .gold:
            return Color(red: 1.00, green: 0.28, blue: 0.04)
        case .rainbow:
            return .pink
        case .premium:
            return Color(red: 0.58, green: 0.22, blue: 1.0)
        }
    }

    var body: some View {
        ZStack {
            aura
            cabinetLeak
            chromeFrame
            glassBase
            internalReflector
            internalLEDArray
            illuminatedCore
            lensVignette
            textLayer
            glassReflection
            revealFlash
            Color.black
                .clipShape(Ellipse())
                .padding(5)
                .opacity(blackoutOpacity)
        }
        .frame(width: 132, height: 92)
        .scaleEffect(revealScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("SiRiUS LUCKY CHANCEランプ")
        .accessibilityValue(mode.isLit ? "点灯中" : "消灯中")
        .onAppear {
            startAnimations()
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            playReveal()
        }
    }

    private var aura: some View {
        Group {
            if mode == .rainbow || mode == .premium {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.32),
                                Color(red: 1.0, green: 0.44, blue: 0.04).opacity(0.16),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 76
                        )
                    )
                    .frame(width: 138, height: 98)
                    .blur(radius: 15)
                    .opacity(mode.isLit ? (pulse ? (mode == .premium ? 0.74 : 0.58) : 0.38) : 0)
                    .blendMode(.screen)
            } else {
                Ellipse()
                    .fill(mainColor)
                    .frame(width: 136, height: 96)
                    .blur(radius: 21)
                    .opacity(mode.isLit ? (pulse ? 0.82 : 0.42) : 0)
                    .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }

    private var cabinetLeak: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.orange.opacity(mode.isLit ? 0.28 : 0),
                        Color(red: 0.92, green: 0.38, blue: 0.03).opacity(mode.isLit ? 0.20 : 0),
                        Color.yellow.opacity(mode.isLit ? 0.08 : 0),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 84
                )
            )
            .frame(width: 154, height: 112)
            .blur(radius: 18)
            .opacity(leakOpacity)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    private var chromeFrame: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color(red: 0.20, green: 0.22, blue: 0.28),
                            Color.black,
                            Color(red: 0.30, green: 0.31, blue: 0.37),
                            Color.white.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            Color.white.opacity(0.16),
                            Color.black.opacity(0.92),
                            Color.white.opacity(0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.2
                )

            Ellipse()
                .stroke(
                    mode == .rainbow || mode == .premium
                    ? AnyShapeStyle(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center
                        )
                    )
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                mainColor.opacity(mode.isLit ? 0.92 : 0.08),
                                secondaryColor.opacity(mode.isLit ? 0.65 : 0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                    lineWidth: 1.3
                )
                .padding(4)
        }
        .shadow(color: .black.opacity(0.85), radius: 10, y: 7)
        .overlay {

            Ellipse()
                .stroke(
                    mainColor.opacity(
                        mode.isLit
                            ? (pulse ? 0.65 : 0.22)
                            : 0
                    ),
                    lineWidth: 2
                )
                .blur(radius: 3)

        }
    }

    private var glassBase: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.12, green: 0.055, blue: 0.025),
                        Color(red: 0.035, green: 0.022, blue: 0.018),
                        Color.black
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 72
                )
            )
            .overlay {
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.19),
                                Color.purple.opacity(0.20),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
            }
            .padding(7)
    }

    private var internalReflector: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.10, blue: 0.025).opacity(mode.isLit ? 0.72 : 0.18),
                            Color(red: 0.07, green: 0.028, blue: 0.018).opacity(0.92),
                            Color.black.opacity(0.98)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 61
                    )
                )

            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.70, blue: 0.20).opacity(mode.isLit ? 0.20 : 0.055),
                                Color.purple.opacity(mode.isLit ? 0.12 : 0.035),
                                Color.black.opacity(0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .padding(CGFloat(11 + index * 7))
            }
        }
        .padding(8)
        .clipShape(Ellipse())
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var illuminatedCore: some View {
        if mode == .rainbow || mode == .premium {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.30).opacity(0.78),
                            Color.orange.opacity(0.52),
                            Color(red: 0.42, green: 0.08, blue: 0.12).opacity(0.26),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 61
                    )
                )
                .padding(12)
                .opacity(mode.isLit ? (pulse ? 0.86 : 0.68) : 0)
                .blur(radius: 2.2)
                .blendMode(.screen)

            Ellipse()
                .stroke(
                    AngularGradient(
                        colors: rainbowColors.map { $0.opacity(0.48) },
                        center: .center,
                        angle: .degrees(rainbowRotation)
                    ),
                    lineWidth: 2
                )
                .padding(13)
                .blendMode(.screen)

            if mode == .premium {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.cyan.opacity(0.48),
                                Color.purple.opacity(0.58),
                                Color.orange.opacity(0.42),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 92, height: 7)
                    .rotationEffect(.degrees(rainbowRotation * 0.08 - 12))
                    .blur(radius: 1.4)
                    .blendMode(.screen)
            }
        } else {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(mode.isLit ? 1.00 : 0.02),
                            mainColor.opacity(mode.isLit ? 0.95 : 0.03),
                            secondaryColor.opacity(mode.isLit ? 0.72 : 0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 74
                    )
                )
                .padding(9)
                .opacity(mode.isLit ? (pulse ? 1.0 : 0.80) : 1)
                .blendMode(.screen)
        }
    }

    private var internalLEDArray: some View {
        HStack(spacing: 7) {
            ForEach(0..<9, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.88, blue: 0.50).opacity(mode.isLit ? 0.88 : 0.08),
                                Color.orange.opacity(mode.isLit ? 0.74 : 0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 7
                        )
                    )
                    .frame(width: index == 4 ? 9 : 6, height: index == 4 ? 9 : 6)
                    .shadow(
                        color: mode.isLit ? mainColor.opacity(0.95) : .clear,
                        radius: 7
                    )
                    .opacity(mode.isLit ? (index == 4 ? 0.88 : 0.34 + Double(index % 2) * 0.10) : 0.075)
            }
        }
        .scaleEffect(innerBreath)
        .blur(radius: mode.isLit ? 0.35 : 1.1)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private var lensVignette: some View {
        Ellipse()
            .strokeBorder(
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.10),
                        Color.black.opacity(0.78)
                    ],
                    center: .center,
                    startRadius: 22,
                    endRadius: 65
                ),
                lineWidth: 10
            )
            .padding(8)
            .allowsHitTesting(false)
    }

    private var starDecorations: some View {
        ZStack {
            star("", size: 15, x: -46, y: -17)
            star("", size: 12, x: 47, y: -15)
            star("", size: 10, x: -50, y: 17)
            star("", size: 9, x: 49, y: 18)
        }
    }

    private func star(
        _ value: String,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Text(value)
            .font(.system(size: size, weight: .black))
            .foregroundStyle(
                mode.isLit
                ? Color.yellow
                : Color.white.opacity(0.08)
            )
            .shadow(
                color: mode.isLit ? Color.yellow.opacity(0.95) : .clear,
                radius: starPulse ? 8 : 3
            )
            .scaleEffect(starPulse ? 1.08 : 0.94)
            .offset(x: x, y: y)
    }

    private var textLayer: some View {
        VStack(spacing: 1) {
            Text("SiRiUS")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(3)

            Text("PREMIUM")
                .font(.system(size: 22,
                              weight: .heavy))
                .italic()
                .tracking(0.5
                )

            Text("CHANCE")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(3.5)
        }
        .foregroundStyle(textStyle)
        .shadow(
            color: Color.black.opacity(0.82),
            radius: 1,
            y: 1
        )
        .shadow(
            color: Color.yellow.opacity(
                mode.isLit
                    ? (pulse ? 0.58 : 0.36)
                    : 0
            ),
            radius: pulse ? 6 : 3
        )
        .shadow(
            color: Color.orange.opacity(
                mode.isLit
                    ? (pulse ? 0.38 : 0.22)
                    : 0
            ),
            radius: pulse ? 13 : 8
        )
        .overlay {
            VStack(spacing: 1) {
                Color.clear.frame(height: 10)
                Capsule()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.34).opacity(mode.isLit ? 0.28 : 0.04))
                    .frame(width: 72, height: 1)
                    .blur(radius: 0.25)
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .opacity(mode.isLit ? 1.0 : 0.12)
    }

    private var textStyle: AnyShapeStyle {
        switch mode {
        case .off:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.20),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .blue:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .white,
                        Color(red: 0.70, green: 0.96, blue: 1.00),
                        Color(red: 0.26, green: 0.58, blue: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .gold:
            return AnyShapeStyle(
                Color.white
            )
        case .rainbow:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.94, blue: 0.72),
                        Color(red: 1.0, green: 0.68, blue: 0.16),
                        Color(red: 1.0, green: 0.88, blue: 0.50)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .premium:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 1.0, green: 0.78, blue: 0.22),
                        Color(red: 0.72, green: 0.48, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    private var glassReflection: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 5, height: proxy.size.height * 0.58)
                .rotationEffect(.degrees(18))
                .offset(
                    x: sweepOffset * proxy.size.width,
                    y: -4
                )
                .blur(radius: 0.45)
                .blendMode(.screen)
        }
        .clipShape(Ellipse())
        .padding(8)
        .allowsHitTesting(false)
    }

    private var revealFlash: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.90, blue: 0.58).opacity(0.82),
                        Color.orange.opacity(0.44),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 28
                )
            )
            .frame(width: 56, height: 56)
            .blur(radius: 2)
            .opacity(flashOpacity)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    private var rainbowColors: [Color] {
        [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red]
    }

    private func startAnimations() {
        withAnimation(
            .easeInOut(duration: 0.74)
                .repeatForever(autoreverses: true)
        ) {
            pulse = true
            innerBreath = 1.06
            leakOpacity = 1
        }

        withAnimation(
            .easeInOut(duration: 0.56)
                .repeatForever(autoreverses: true)
        ) {
            starPulse = true
        }

        withAnimation(
            .linear(duration: 2.0)
                .repeatForever(autoreverses: false)
        ) {
            rainbowRotation = 360
        }

        withAnimation(
            .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            sweepOffset = 1.55
        }
    }

    private func playReveal() {
        blackoutOpacity = 0.96
        flashOpacity = 0
        revealScale = mode == .premium ? 0.72 : 0.80

        DispatchQueue.main.asyncAfter(deadline: .now() + (mode == .premium ? 0.12 : 0.075)) {
            flashOpacity = 1
            withAnimation(.easeOut(duration: 0.15)) {
                blackoutOpacity = 0
            }
        }

        withAnimation(
            .spring(response: 0.34, dampingFraction: 0.48)
        ) {
            revealScale = 1.10
        }

        withAnimation(.easeOut(duration: 0.38).delay(0.075)) {
            flashOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(
                .spring(response: 0.30, dampingFraction: 0.72)
            ) {
                revealScale = 1.0
            }
        }
    }
}

#Preview("OFF") {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotLuckyLampView(mode: .off, trigger: 0)
    }
}

#Preview("BLUE") {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotLuckyLampView(mode: .blue, trigger: 1)
    }
}

#Preview("GOLD") {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotLuckyLampView(mode: .gold, trigger: 1)
    }
}

#Preview("RAINBOW") {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotLuckyLampView(mode: .rainbow, trigger: 1)
    }
}

#Preview("PREMIUM") {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotLuckyLampView(mode: .premium, trigger: 1)
    }
}
