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

    private var mainColor: Color {
        switch mode {
        case .off:
            return Color(red: 0.08, green: 0.07, blue: 0.13)
        case .blue:
            return Color(red: 0.34, green: 0.77, blue: 1.00)
        case .gold:
            return Color(red: 1.00, green: 0.78, blue: 0.16)
        case .rainbow:
            return .white
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
        }
    }

    var body: some View {
        ZStack {
            aura
            chromeFrame
            glassBase
            illuminatedCore
            textLayer
            glassReflection
            revealFlash
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
            if mode == .rainbow {
                Ellipse()
                    .fill(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            angle: .degrees(rainbowRotation)
                        )
                    )
                    .frame(width: 138, height: 98)
                    .blur(radius: 20)
                    .opacity(mode.isLit ? (pulse ? 0.86 : 0.50) : 0)
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
                    mode == .rainbow
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
                        Color(red: 0.12, green: 0.08, blue: 0.22),
                        Color(red: 0.04, green: 0.035, blue: 0.08),
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

    @ViewBuilder
    private var illuminatedCore: some View {
        if mode == .rainbow {
            Ellipse()
                .fill(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        angle: .degrees(rainbowRotation)
                    )
                )
                .padding(9)
                .opacity(mode.isLit ? (pulse ? 0.80 : 0.60) : 0)
                .blur(radius: 0.5)
                .blendMode(.screen)

            Ellipse()
                .fill(Color.white.opacity(mode.isLit ? 0.18 : 0.01))
                .padding(14)
                .blendMode(.screen)
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
            color: .white.opacity(
                mode.isLit
                    ? (pulse ? 0.95 : 0.45)
                    : 0
            ),
            radius: pulse ? 2 : 1
        )

        .shadow(
            color: Color.yellow.opacity(
                mode.isLit
                    ? (pulse ? 1.0 : 0.7)
                    : 0
            ),
            radius: pulse ? 14 : 7
        )

        .shadow(
            color: Color.orange.opacity(
                mode.isLit
                    ? (pulse ? 0.9 : 0.5)
                    : 0
            ),
            radius: pulse ? 32 : 18
        )
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
                    colors: rainbowColors,
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
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20, height: proxy.size.height * 0.80)
                .rotationEffect(.degrees(18))
                .offset(
                    x: sweepOffset * proxy.size.width,
                    y: -4
                )
                .blur(radius: 0.8)
                .blendMode(.screen)
        }
        .clipShape(Ellipse())
        .padding(8)
        .allowsHitTesting(false)
    }

    private var revealFlash: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.98),
                        mainColor.opacity(0.84),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 82
                )
            )
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
        flashOpacity = 1
        revealScale = 0.80

        withAnimation(
            .spring(response: 0.34, dampingFraction: 0.48)
        ) {
            revealScale = 1.10
        }

        withAnimation(.easeOut(duration: 0.34)) {
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
