import SwiftUI

// MARK: - PremiumSlotMachineView
// Version 5 Ultimate の実機風スロット筐体です。
// 現在の GachaView への接続は、最後にまとめて行います。

struct PremiumSlotMachineView: View {
    let symbols: [String]
    let isSpinning: Bool
    let stoppedReelCount: Int
    let heatLevel: SlotHeatLevel
    let statusText: String
    let subStatusText: String
    let isPushVisible: Bool
    let isPushEnabled: Bool
    let leverProgress: CGFloat

    let onPush: () -> Void
    let onLeverChanged: (CGFloat) -> Void
    let onLeverReleased: () -> Void

    @State private var lampPhase = 0
    @State private var reflectionOffset: CGFloat = -260
    @State private var pulse = false

    var body: some View {
        ZStack {
            machineBackGlow

            VStack(spacing: 0) {
                topCrown
                upperDisplay
                reelCabinet
                controlPanel
                lowerCabinet
            }
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 10)
            .background(machineBody)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 34,
                    style: .continuous
                )
            )
            .overlay(machineRim)
            .overlay(glassReflection)
            .shadow(
                color: heatLevel.glowColor.opacity(
                    heatLevel == .normal ? 0.24 : 0.62
                ),
                radius: heatLevel == .normal ? 18 : 32,
                y: 12
            )
            .scaleEffect(pulse ? 1.012 : 1.0)
        }
        .padding(.horizontal, 8)
        .onAppear {
            startAmbientAnimations()
        }
        .onChange(of: isSpinning) { _, spinning in
            withAnimation(
                .easeInOut(duration: 0.34)
                .repeatCount(2, autoreverses: true)
            ) {
                pulse = spinning
            }

            if !spinning {
                pulse = false
            }
        }
    }

    // MARK: - Main body

    private var machineBody: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.055, green: 0.060, blue: 0.074),
                        Color(red: 0.015, green: 0.018, blue: 0.026),
                        Color(red: 0.085, green: 0.088, blue: 0.098),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.13),
                        Color.clear,
                        Color.black.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                Spacer()

                Rectangle()
                    .fill(Color.black.opacity(0.75))
                    .frame(height: 4)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 34,
                    style: .continuous
                )
            )
        }
    }

    private var machineRim: some View {
        RoundedRectangle(
            cornerRadius: 34,
            style: .continuous
        )
        .strokeBorder(
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.86, blue: 0.38),
                    Color(red: 0.48, green: 0.27, blue: 0.04),
                    Color(red: 1.00, green: 0.95, blue: 0.68),
                    Color(red: 0.36, green: 0.18, blue: 0.02),
                    Color(red: 0.95, green: 0.71, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 4
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 29,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
            .padding(6)
        }
    }

    private var machineBackGlow: some View {
        RoundedRectangle(
            cornerRadius: 42,
            style: .continuous
        )
        .fill(heatLevel.glowColor.opacity(0.27))
        .blur(radius: heatLevel == .normal ? 20 : 38)
        .scaleEffect(heatLevel == .premium ? 1.08 : 1.0)
    }

    // MARK: - Crown

    private var topCrown: some View {
        ZStack {
            PremiumCrownShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.09, blue: 0.01),
                            Color(red: 0.96, green: 0.71, blue: 0.16),
                            Color(red: 1.00, green: 0.94, blue: 0.57),
                            Color(red: 0.48, green: 0.25, blue: 0.02)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 74)
                .overlay {
                    PremiumCrownShape()
                        .stroke(Color.white.opacity(0.40), lineWidth: 1)
                }

            VStack(spacing: -1) {
                Text("SiRiUS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(4.5)
                    .foregroundStyle(Color.white.opacity(0.90))

                Text("LUCKY SLOT")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 1.00, green: 0.94, blue: 0.55),
                                Color(red: 1.00, green: 0.64, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black, radius: 2, y: 2)
            }

            HStack {
                crownGem
                Spacer()
                crownGem
            }
            .padding(.horizontal, 25)
        }
        .padding(.horizontal, 10)
    }

    private var crownGem: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        heatLevel.glowColor,
                        heatLevel.glowColor.opacity(0.20),
                        Color.black
                    ],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: 13
                )
            )
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: heatLevel.glowColor, radius: 9)
    }

    // MARK: - LCD display

    private var upperDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.11, blue: 0.14),
                            Color.black,
                            Color(red: 0.04, green: 0.05, blue: 0.07)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            heatLevel.displayColor.opacity(0.34),
                            Color.black.opacity(0.98)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .padding(7)

            PremiumScanLines()
                .clipShape(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .padding(8)
                .opacity(0.22)

            VStack(spacing: 4) {
                Text(statusText)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(heatLevel.displayColor)
                    .shadow(color: heatLevel.glowColor, radius: 10)

                Text(subStatusText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.70))
            }

            HStack {
                speakerColumn
                Spacer()
                speakerColumn
            }
            .padding(.horizontal, 15)
        }
        .frame(height: 94)
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color(red: 0.82, green: 0.57, blue: 0.12),
                            Color.black,
                            Color(red: 0.95, green: 0.78, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        }
        .padding(.horizontal, 14)
        .padding(.top, -4)
    }

    private var speakerColumn: some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(Color.black)
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.13), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Reel cabinet

    private var reelCabinet: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.68, green: 0.50, blue: 0.16),
                            Color(red: 0.15, green: 0.10, blue: 0.035),
                            Color.black,
                            Color(red: 0.74, green: 0.53, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
                .padding(5)

            VStack(spacing: 8) {
                marqueeRow

                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.91, green: 0.93, blue: 0.95),
                                    Color.white
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { index in
                            UltimateReelWindow(
                                symbol: symbol(at: index),
                                isSpinning: isSpinning && stoppedReelCount <= index,
                                reelIndex: index,
                                heatLevel: heatLevel
                            )
                        }
                    }
                    .padding(8)

                    payLine

                    reelGlass
                }
                .frame(height: 166)

                marqueeRow
            }
            .padding(11)

            machineScrews
        }
        .frame(height: 230)
        .padding(.horizontal, 7)
        .padding(.top, 8)
    }

    private var marqueeRow: some View {
        HStack(spacing: 7) {
            ForEach(0..<13, id: \.self) { index in
                let active =
                    heatLevel != .normal
                    || (index + lampPhase).isMultiple(of: 3)

                Circle()
                    .fill(
                        active
                        ? heatLevel.lampColor
                        : Color(red: 0.24, green: 0.16, blue: 0.04)
                    )
                    .frame(width: 8, height: 8)
                    .shadow(
                        color: active
                        ? heatLevel.glowColor
                        : Color.clear,
                        radius: active ? 7 : 0
                    )
            }
        }
    }

    private var payLine: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color.red)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.55),
                            Color.white,
                            Color.red,
                            Color.white,
                            Color.red.opacity(0.55)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .shadow(color: .red, radius: 5)

            Image(systemName: "arrowtriangle.left.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color.red)
        }
        .padding(.horizontal, 3)
    }

    private var reelGlass: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.clear,
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
    }

    private var machineScrews: some View {
        VStack {
            HStack {
                screw
                Spacer()
                screw
            }
            Spacer()
            HStack {
                screw
                Spacer()
                screw
            }
        }
        .padding(10)
    }

    private var screw: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white,
                        Color.gray,
                        Color.black
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 6
                )
            )
            .frame(width: 11, height: 11)
            .overlay {
                Rectangle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: 7, height: 1)
                    .rotationEffect(.degrees(-18))
            }
    }

    // MARK: - Control panel

    private var controlPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.17, blue: 0.19),
                            Color.black,
                            Color(red: 0.08, green: 0.09, blue: 0.11)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(spacing: 14) {
                leverControl

                Spacer(minLength: 4)

                pushButton

                Spacer(minLength: 4)

                premiumLamp
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 13)
        }
        .frame(height: 108)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.black,
                            Color(red: 0.83, green: 0.60, blue: 0.17)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }

    private var leverControl: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 18, height: 62)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.gray,
                                Color.black
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 9, height: 43)
                    .offset(y: 7 + leverProgress * 17)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                heatLevel.lampColor,
                                Color.black
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 20
                        )
                    )
                    .frame(width: 39, height: 39)
                    .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 1))
                    .shadow(color: heatLevel.glowColor, radius: 8)
                    .offset(y: leverProgress * 28)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = min(
                                    1,
                                    max(0, value.translation.height / 62)
                                )
                                onLeverChanged(progress)
                            }
                            .onEnded { _ in
                                onLeverReleased()
                            }
                    )
            }
            .frame(width: 48, height: 70)

            Text("LEVER")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.70))
        }
    }

    private var pushButton: some View {
        Button(action: onPush) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 74, height: 74)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: isPushVisible
                                ? [
                                    Color.white,
                                    heatLevel.lampColor,
                                    heatLevel.glowColor,
                                    Color.black
                                ]
                                : [
                                    Color(red: 0.28, green: 0.28, blue: 0.30),
                                    Color(red: 0.08, green: 0.08, blue: 0.10),
                                    Color.black
                                ],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 39
                            )
                        )
                        .frame(width: 63, height: 63)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(
                                        isPushVisible ? 0.70 : 0.18
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: isPushVisible
                            ? heatLevel.glowColor
                            : Color.clear,
                            radius: 15
                        )

                    VStack(spacing: -2) {
                        Text("PUSH")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                        Text("BUTTON")
                            .font(.system(size: 6, weight: .black, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundStyle(
                        isPushVisible
                        ? Color.white
                        : Color.white.opacity(0.32)
                    )
                }

                Text(isPushVisible ? "押せ！" : "STANDBY")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isPushVisible
                        ? heatLevel.lampColor
                        : Color.white.opacity(0.35)
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isPushEnabled)
        .scaleEffect(isPushVisible && isPushEnabled ? 1.04 : 1.0)
        .animation(
            isPushVisible
            ? .easeInOut(duration: 0.42).repeatForever(autoreverses: true)
            : .default,
            value: isPushVisible
        )
    }

    private var premiumLamp: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black)
                    .frame(width: 80, height: 68)

                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: heatLevel == .normal
                            ? [
                                Color(red: 0.10, green: 0.13, blue: 0.15),
                                Color.black
                            ]
                            : [
                                Color.white,
                                heatLevel.lampColor,
                                heatLevel.glowColor,
                                Color.black
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 45
                        )
                    )
                    .frame(width: 72, height: 59)
                    .shadow(
                        color: heatLevel == .normal
                        ? Color.clear
                        : heatLevel.glowColor,
                        radius: 16
                    )

                VStack(spacing: -4) {
                    Text("SIRIUS")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .tracking(1.5)

                    Text("LUCK!")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }
                .foregroundStyle(
                    heatLevel == .normal
                    ? Color.white.opacity(0.22)
                    : Color.white
                )
            }

            Text("PREMIUM LAMP")
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
        }
    }

    // MARK: - Lower cabinet

    private var lowerCabinet: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.12, blue: 0.14),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(spacing: 14) {
                lowerSpeaker

                VStack(spacing: 4) {
                    Text("SiRiUS PREMIUM")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 1.00, green: 0.81, blue: 0.29)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .frame(width: 112, height: 16)
                        .overlay {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.20),
                                            Color.black
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 96, height: 6)
                        }
                }

                lowerSpeaker
            }
        }
        .frame(height: 58)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        }
        .padding(.horizontal, 17)
        .padding(.top, 7)
    }

    private var lowerSpeaker: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 39, height: 39)

            VStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { column in
                            if (row + column).isMultiple(of: 2) {
                                Circle()
                                    .fill(Color.white.opacity(0.17))
                                    .frame(width: 3, height: 3)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.07))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reflection

    private var glassReflection: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.03),
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 90)
            .rotationEffect(.degrees(13))
            .offset(x: reflectionOffset)
            .onAppear {
                reflectionOffset = -120

                withAnimation(
                    .linear(duration: 4.2)
                    .repeatForever(autoreverses: false)
                ) {
                    reflectionOffset = proxy.size.width + 110
                }
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
        )
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func symbol(at index: Int) -> String {
        guard symbols.indices.contains(index) else {
            return "7"
        }

        return symbols[index]
    }

    private func startAmbientAnimations() {
        withAnimation(
            .linear(duration: 1.2)
            .repeatForever(autoreverses: false)
        ) {
            lampPhase = 12
        }
    }
}

// MARK: - Heat level

enum SlotHeatLevel: Equatable {
    case normal
    case chance
    case superChance
    case warning
    case premium

    var glowColor: Color {
        switch self {
        case .normal:
            return Color(red: 1.00, green: 0.67, blue: 0.13)
        case .chance:
            return Color(red: 1.00, green: 0.18, blue: 0.08)
        case .superChance:
            return Color(red: 1.00, green: 0.76, blue: 0.05)
        case .warning:
            return Color.red
        case .premium:
            return Color.purple
        }
    }

    var lampColor: Color {
        switch self {
        case .normal:
            return Color(red: 1.00, green: 0.76, blue: 0.19)
        case .chance:
            return Color.red
        case .superChance:
            return Color.yellow
        case .warning:
            return Color(red: 1.00, green: 0.05, blue: 0.02)
        case .premium:
            return Color.white
        }
    }

    var displayColor: Color {
        switch self {
        case .normal:
            return Color(red: 0.38, green: 1.00, blue: 0.75)
        case .chance:
            return Color.red
        case .superChance:
            return Color.yellow
        case .warning:
            return Color.white
        case .premium:
            return Color.white
        }
    }
}

// MARK: - Reel window

private struct UltimateReelWindow: View {
    let symbol: String
    let isSpinning: Bool
    let reelIndex: Int
    let heatLevel: SlotHeatLevel

    @State private var offset: CGFloat = 0
    @State private var blurAmount: CGFloat = 0
    @State private var displayedSymbols = [
        "🍒", "BAR", "🔔", "7", "⭐️", "💎", "🎟️", "👑"
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.92, green: 0.94, blue: 0.96),
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if isSpinning {
                    spinningStrip(height: proxy.size.height)
                        .offset(y: offset)
                        .blur(radius: blurAmount)
                        .onAppear {
                            startSpinning(height: proxy.size.height)
                        }
                } else {
                    stoppedStrip
                }

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.28),
                                Color.clear,
                                Color.clear,
                                Color.black.opacity(0.23)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        heatLevel == .normal
                        ? Color.black.opacity(0.30)
                        : heatLevel.glowColor.opacity(0.75),
                        lineWidth: heatLevel == .normal ? 1 : 2
                    )
            }
            .clipped()
        }
    }

    private func spinningStrip(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<18, id: \.self) { index in
                reelSymbol(
                    displayedSymbols[
                        (index + reelIndex * 2) % displayedSymbols.count
                    ]
                )
                .frame(height: height / 2.15)
            }
        }
    }

    private var stoppedStrip: some View {
        VStack(spacing: 0) {
            reelSymbol(previousSymbol)
                .frame(maxHeight: .infinity)

            Divider()
                .opacity(0.22)

            reelSymbol(symbol)
                .frame(maxHeight: .infinity)
                .scaleEffect(1.16)

            Divider()
                .opacity(0.22)

            reelSymbol(nextSymbol)
                .frame(maxHeight: .infinity)
        }
    }

    private func reelSymbol(_ value: String) -> some View {
        Group {
            if value == "BAR" {
                Text("BAR")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    )
            } else {
                Text(value)
                    .font(.system(size: value == "7" ? 40 : 32, weight: .black))
                    .foregroundStyle(
                        value == "7"
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color.red,
                                    Color.orange,
                                    Color.yellow
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        : AnyShapeStyle(Color.primary)
                    )
                    .shadow(
                        color: value == "7"
                        ? Color.red.opacity(0.25)
                        : Color.clear,
                        radius: 4
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previousSymbol: String {
        let index = displayedSymbols.firstIndex(of: symbol) ?? 3
        return displayedSymbols[
            (index - 1 + displayedSymbols.count) % displayedSymbols.count
        ]
    }

    private var nextSymbol: String {
        let index = displayedSymbols.firstIndex(of: symbol) ?? 3
        return displayedSymbols[(index + 1) % displayedSymbols.count]
    }

    private func startSpinning(height: CGFloat) {
        offset = 0
        blurAmount = 1.6

        withAnimation(
            .linear(duration: 0.52 + Double(reelIndex) * 0.04)
            .repeatForever(autoreverses: false)
        ) {
            offset = -(height * 4.65)
        }
    }
}

// MARK: - Shapes and texture

private struct PremiumCrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.07,
                y: rect.minY + rect.height * 0.43
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.23,
                y: rect.minY + rect.height * 0.61
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.midX,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.77,
                y: rect.minY + rect.height * 0.61
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - rect.width * 0.07,
                y: rect.minY + rect.height * 0.43
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY
            )
        )

        path.closeSubpath()
        return path
    }
}

private struct PremiumScanLines: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                var y: CGFloat = 0

                while y < size.height {
                    let rect = CGRect(
                        x: 0,
                        y: y,
                        width: size.width,
                        height: 1
                    )

                    context.fill(
                        Path(rect),
                        with: .color(Color.white.opacity(0.20))
                    )

                    y += 5
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ScrollView {
            PremiumSlotMachineView(
                symbols: ["7", "7", "7"],
                isSpinning: false,
                stoppedReelCount: 3,
                heatLevel: .premium,
                statusText: "PREMIUM",
                subStatusText: "ULTIMATE JACKPOT MODE",
                isPushVisible: true,
                isPushEnabled: true,
                leverProgress: 0,
                onPush: {},
                onLeverChanged: { _ in },
                onLeverReleased: {}
            )
            .padding(.vertical, 30)
        }
    }
}
