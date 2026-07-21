//
//  PremiumSlotMachineView.swift
//  CircleAccount
//

import SwiftUI

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

    @State private var lampPulse = false
    @State private var borderRotation = 0.0
    @State private var machinePulse = false

    private let reelPool = [
        "7", "⭐", "🎁", "🏸", "💰",
        "🚀", "🎾", "🧹", "🔥", "💎"
    ]

    private var machineGlow: Color {
        heatLevel.glowColor
    }

    private var safeSymbols: [String] {
        [
            symbols.indices.contains(0) ? symbols[0] : "7",
            symbols.indices.contains(1) ? symbols[1] : "7",
            symbols.indices.contains(2) ? symbols[2] : "7"
        ]
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            machineBody
                .padding(.trailing, 46)

            PremiumLeverControl(
                progress: leverProgress,
                glowColor: machineGlow,
                enabled: !isSpinning,
                onChanged: onLeverChanged,
                onReleased: onLeverReleased
            )
            .offset(x: 2, y: 82)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
        .scaleEffect(machinePulse ? 1.012 : 1.0)
        .onAppear {
            startContinuousAnimations()
        }
        .onChange(of: heatLevel) { _, _ in
            pulseMachine()
        }
        .onChange(of: stoppedReelCount) { _, newValue in
            if newValue > 0 {
                pulseMachine()
            }
        }
    }

    private var machineBody: some View {
        ZStack {
            outerGlow

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.11, blue: 0.15),
                            Color(red: 0.025, green: 0.027, blue: 0.038),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            animatedBorder

            VStack(spacing: 15) {
                marqueeHeader
                statusPanel
                reelHousing
                controlPanel
                brandFooter
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: 370)
        .shadow(color: Color.black.opacity(0.72), radius: 22, y: 15)
        .shadow(color: machineGlow.opacity(0.32), radius: 26)
    }

    private var outerGlow: some View {
        RoundedRectangle(cornerRadius: 38, style: .continuous)
            .fill(machineGlow.opacity(lampPulse ? 0.17 : 0.08))
            .blur(radius: 20)
            .scaleEffect(lampPulse ? 1.035 : 1.0)
    }

    private var animatedBorder: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(
                AngularGradient(
                    colors: [
                        machineGlow.opacity(0.25),
                        Color.white.opacity(0.80),
                        heatLevel.lampColor,
                        machineGlow,
                        Color.white.opacity(0.35),
                        machineGlow.opacity(0.25)
                    ],
                    center: .center,
                    angle: .degrees(borderRotation)
                ),
                lineWidth: heatLevel == .premium ? 4 : 2.5
            )
            .overlay {
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    .padding(7)
            }
    }

    private var marqueeHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? heatLevel.lampColor
                                : machineGlow
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse
                                ? machineGlow
                                : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 1.0 : 0.48)
                }
            }

            VStack(spacing: -2) {
                Text("SiRiUS")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(Color.white.opacity(0.82))

                Text("LUCKY SLOT")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                heatLevel.lampColor,
                                machineGlow,
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: machineGlow, radius: 9)
            }

            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? machineGlow
                                : heatLevel.lampColor
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse
                                ? heatLevel.lampColor
                                : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 0.82 : 0.42)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(machineGlow.opacity(0.58), lineWidth: 1.5)
                }
        )
    }

    private var statusPanel: some View {
        VStack(spacing: 4) {
            Text(statusText)
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .tracking(1.3)
                .foregroundStyle(heatLevel.displayColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .shadow(color: machineGlow, radius: 6)

            Text(subStatusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            machineGlow.opacity(0.10),
                            Color.black
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                }
        )
    }

    private var reelHousing: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.34, green: 0.35, blue: 0.39),
                            Color(red: 0.07, green: 0.075, blue: 0.095),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.black)
                .padding(8)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    PremiumReelColumn(
                        finalSymbol: safeSymbols[index],
                        symbolPool: reelPool,
                        isSpinning: isSpinning && stoppedReelCount <= index,
                        isStopped: stoppedReelCount > index,
                        reelIndex: index,
                        glowColor: machineGlow
                    )
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 15)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            machineGlow.opacity(0.44),
                            Color.white.opacity(0.70),
                            machineGlow.opacity(0.44),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .allowsHitTesting(false)
        }
        .frame(height: 154)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.gray.opacity(0.25),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
        }
    }

    private var controlPanel: some View {
        HStack(spacing: 13) {
            ForEach(0..<3, id: \.self) { index in
                stopLamp(index: index)
            }

            Spacer(minLength: 3)
            pushButton
        }
        .frame(height: 74)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.13, blue: 0.17),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
        )
    }

    private func stopLamp(index: Int) -> some View {
        let isStopped = stoppedReelCount > index

        return VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isStopped
                                ? [Color.white, heatLevel.lampColor, machineGlow]
                                : [Color.gray.opacity(0.52), Color.black],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 34, height: 34)

                Circle()
                    .stroke(Color.white.opacity(0.30), lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
            .shadow(
                color: isStopped ? machineGlow : Color.clear,
                radius: 9
            )

            Text(["LEFT", "CENTER", "RIGHT"][index])
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
        }
    }

    private var pushButton: some View {
        Button(action: onPush) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isPushVisible
                                ? [Color.white, heatLevel.lampColor, machineGlow, Color.black]
                                : [Color.gray.opacity(0.52), Color.black],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 42
                        )
                    )

                Circle()
                    .stroke(
                        isPushVisible
                            ? Color.white.opacity(0.78)
                            : Color.white.opacity(0.20),
                        lineWidth: 3
                    )

                VStack(spacing: -2) {
                    Text("PUSH")
                        .font(.system(size: 13, weight: .black, design: .rounded))
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
            .frame(width: 59, height: 59)
            .scaleEffect(isPushVisible && lampPulse ? 1.08 : 1.0)
            .shadow(
                color: isPushVisible
                    ? machineGlow.opacity(0.95)
                    : Color.clear,
                radius: 14
            )
        }
        .buttonStyle(.plain)
        .disabled(!isPushEnabled)
        .accessibilityLabel("PUSHボタン")
    }

    private var brandFooter: some View {
        HStack {
            Label("PREMIUM DIGITAL REEL", systemImage: "sparkles")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1.1)

            Spacer()

            Text("100 PT / PLAY")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.8)
        }
        .foregroundStyle(Color.white.opacity(0.42))
        .padding(.horizontal, 4)
    }

    private func startContinuousAnimations() {
        withAnimation(
            .easeInOut(duration: 0.62)
                .repeatForever(autoreverses: true)
        ) {
            lampPulse = true
        }

        withAnimation(
            .linear(duration: 7.5)
                .repeatForever(autoreverses: false)
        ) {
            borderRotation = 360
        }
    }

    private func pulseMachine() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.42)) {
            machinePulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.66)) {
                machinePulse = false
            }
        }
    }
}

private struct PremiumReelColumn: View {
    let finalSymbol: String
    let symbolPool: [String]
    let isSpinning: Bool
    let isStopped: Bool
    let reelIndex: Int
    let glowColor: Color

    @State private var stopBounce = false

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 0.055)) { context in
                let symbol = displayedSymbol(at: context.date)

                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.90, green: 0.91, blue: 0.94),
                                    Color.white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    VStack(spacing: 0) {
                        Text(previousSymbol(for: symbol))
                            .font(.system(size: 24))
                            .frame(maxHeight: .infinity)
                            .opacity(isSpinning ? 0.30 : 0.14)
                            .blur(radius: isSpinning ? 1.4 : 0)

                        Divider().opacity(0.12)

                        Text(symbol)
                            .font(.system(size: isSpinning ? 42 : 48))
                            .frame(maxHeight: .infinity)
                            .scaleEffect(stopBounce ? 1.15 : 1.0)
                            .blur(radius: isSpinning ? 0.85 : 0)
                            .shadow(
                                color: isStopped
                                    ? glowColor.opacity(0.55)
                                    : Color.clear,
                                radius: 7
                            )

                        Divider().opacity(0.12)

                        Text(nextSymbol(for: symbol))
                            .font(.system(size: 24))
                            .frame(maxHeight: .infinity)
                            .opacity(isSpinning ? 0.30 : 0.14)
                            .blur(radius: isSpinning ? 1.4 : 0)
                    }
                    .padding(.vertical, 4)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.25),
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .allowsHitTesting(false)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .onChange(of: isStopped) { _, stopped in
            guard stopped else { return }

            withAnimation(.spring(response: 0.20, dampingFraction: 0.38)) {
                stopBounce = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.65)) {
                    stopBounce = false
                }
            }
        }
    }

    private func displayedSymbol(at date: Date) -> String {
        guard isSpinning, !symbolPool.isEmpty else {
            return finalSymbol
        }

        let speed = 19.0 + Double(reelIndex) * 3.2
        let value = date.timeIntervalSinceReferenceDate * speed
        let index = abs(Int(value.rounded(.down)) + reelIndex * 3)
            % symbolPool.count

        return symbolPool[index]
    }

    private func previousSymbol(for symbol: String) -> String {
        guard let index = symbolPool.firstIndex(of: symbol),
              !symbolPool.isEmpty else {
            return "⭐"
        }

        let previous = (index - 1 + symbolPool.count) % symbolPool.count
        return symbolPool[previous]
    }

    private func nextSymbol(for symbol: String) -> String {
        guard let index = symbolPool.firstIndex(of: symbol),
              !symbolPool.isEmpty else {
            return "🎁"
        }

        return symbolPool[(index + 1) % symbolPool.count]
    }
}

private struct PremiumLeverControl: View {
    let progress: CGFloat
    let glowColor: Color
    let enabled: Bool
    let onChanged: (CGFloat) -> Void
    let onReleased: () -> Void

    @State private var dragStartProgress: CGFloat?

    private var clampedProgress: CGFloat {
        min(1, max(0, progress))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.48),
                                Color.gray,
                                Color.black
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 18, height: 128)

                Capsule()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 6, height: 112)
                    .padding(.top, 8)

                leverKnob
                    .offset(y: clampedProgress * 82)
            }
            .frame(width: 60, height: 150)

            Text("LEVER")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard enabled else { return }

                    if dragStartProgress == nil {
                        dragStartProgress = clampedProgress
                    }

                    let startingProgress = dragStartProgress ?? 0
                    let nextProgress =
                        startingProgress + value.translation.height / 96

                    onChanged(min(1, max(0, nextProgress)))
                }
                .onEnded { _ in
                    guard enabled else {
                        dragStartProgress = nil
                        return
                    }

                    dragStartProgress = nil
                    onReleased()
                }
        )
        .accessibilityLabel("スロットレバー")
        .accessibilityHint("下に引いてガチャを開始します")
    }

    private var leverKnob: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.red,
                            Color(red: 0.43, green: 0.0, blue: 0.0)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 32
                    )
                )
                .frame(width: 52, height: 52)

            Circle()
                .stroke(Color.white.opacity(0.45), lineWidth: 2)
                .frame(width: 52, height: 52)

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 14, height: 8)
                .offset(x: -10, y: -11)
                .blur(radius: 1)
        }
        .shadow(color: Color.red.opacity(0.65), radius: 10)
        .shadow(color: glowColor.opacity(0.55), radius: 14)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.05, green: 0.02, blue: 0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
            PremiumSlotMachineView(
                symbols: ["🎁", "🎁", "🎁"],
                isSpinning: true,
                stoppedReelCount: 1,
                heatLevel: .premium,
                statusText: "PREMIUM LOCK",
                subStatusText: "JACKPOT APPROACHING",
                isPushVisible: true,
                isPushEnabled: true,
                leverProgress: 0.25,
                onPush: {},
                onLeverChanged: { _ in },
                onLeverReleased: {}
            )
            .padding()
        }
    }
}
