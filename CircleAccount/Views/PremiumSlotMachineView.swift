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
    @State private var machineShakeX: CGFloat = 0
    @State private var stopLineFlashOpacity = 0.0
    @State private var flashingStopIndex: Int?
    @State private var premiumFlashOpacity = 0.0
    @State private var jackpotVisible = false
    @State private var sparkBurstProgress: CGFloat = 0
    @State private var sparkBurstOpacity = 0.0
    @State private var glassSweepOffset: CGFloat = -1.2
    @State private var machineFlashOpacity = 0.0
    @State private var jackpotWhiteoutOpacity = 0.0
    @State private var jackpotZoomScale: CGFloat = 1.0
    @State private var frameSweepOffset: CGFloat = -1.4
    @State private var risingLightOffset: CGFloat = 1.2
    @State private var reachPulse = false
    @State private var reachOverlayOpacity = 0.0
    @State private var reachOverlayScale: CGFloat = 0.78
    @State private var premiumBacklightPhase = 0.0
    @State private var premiumBurstTrigger = 0
    @State private var rewardCardVisible = false
    @State private var pseudoRepeatVisible = false
    @State private var pseudoRepeatCount = 0
    @State private var freezeEffectVisible = false
    @State private var freezeSequenceRunning = false

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

            if heatLevel == .premium {
                PremiumCelebrationOverlay(
                    flashOpacity: premiumFlashOpacity
                )
                .padding(.trailing, 46)
                .allowsHitTesting(false)
            }

            JackpotOverlay(
                isVisible: jackpotVisible,
                glowColor: machineGlow
            )
            .scaleEffect(jackpotZoomScale)
            .padding(.trailing, 46)
            .allowsHitTesting(false)

            MachineFlashOverlay(
                opacity: machineFlashOpacity,
                glowColor: machineGlow
            )
            .allowsHitTesting(false)
            .zIndex(50)

            JackpotWhiteoutOverlay(
                opacity: jackpotWhiteoutOpacity
            )
            .allowsHitTesting(false)
            .zIndex(60)

            PremiumBurstView(
                trigger: premiumBurstTrigger,
                glowColor: machineGlow
            )
            .zIndex(65)

            RewardCardView(
                isVisible: rewardCardVisible,
                symbols: safeSymbols,
                title: "JACKPOT",
                subtitle: statusText.isEmpty ? "PREMIUM GET!" : statusText,
                isPremium: heatLevel == .premium
            )
            .padding(.trailing, 46)
            .zIndex(68)
            .allowsHitTesting(false)

            PseudoRepeatOverlay(
                isVisible: pseudoRepeatVisible,
                repeatCount: pseudoRepeatCount,
                reelPool: safeSymbols,
                isPremium: heatLevel == .premium
            )
            .padding(.trailing, 46)
            .zIndex(69)
            .allowsHitTesting(false)

            FreezeEffectView(isVisible: freezeEffectVisible)
                .padding(.trailing, 46)
                .zIndex(70)
                .allowsHitTesting(false)

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
        .offset(x: machineShakeX)
        .onAppear {
            startContinuousAnimations()
        }
        .onChange(of: heatLevel) { _, newValue in
            pulseMachine()

            if newValue == .premium {
                playPremiumFlash()
            }
        }
        .onChange(of: stoppedReelCount) { oldValue, newValue in
            guard newValue > oldValue else {
                if newValue == 0 {
                    flashingStopIndex = nil
                    stopLineFlashOpacity = 0
                    pseudoRepeatVisible = false
                    freezeEffectVisible = false
                    freezeSequenceRunning = false
                    hideJackpot()
                }
                return
            }

            playStopImpact(stoppedCount: newValue)
            playSparkBurst()
            playMachineFlash()
            playReachSequence(stoppedCount: newValue)

            if newValue >= 3 && heatLevel == .premium {
                playPremiumBurst()
                playFreezeSequence()
            }
        }
    }

    private var machineBody: some View {
        ZStack {
            MachineOuterGlow(
                glowColor: machineGlow,
                isPulsing: lampPulse
            )

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

            MachineAnimatedBorder(
                heatLevel: heatLevel,
                glowColor: machineGlow,
                rotation: borderRotation
            )

            MovingMetalHighlight(
                sweepOffset: frameSweepOffset
            )
            .allowsHitTesting(false)

            RisingCabinetLight(
                glowColor: machineGlow,
                lightOffset: risingLightOffset
            )
            .allowsHitTesting(false)

            SideLEDView(
                heatLevel: heatLevel,
                machineGlow: machineGlow,
                isSpinning: isSpinning
            )

            VStack(spacing: 15) {
                MarqueeHeaderView(
                    heatLevel: heatLevel,
                    machineGlow: machineGlow
                )

                SlotStatusPanelView(
                    statusText: statusText,
                    subStatusText: subStatusText,
                    heatLevel: heatLevel,
                    machineGlow: machineGlow
                )
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

    private var reelHousing: some View {
        ReelHousingView(
            symbols: safeSymbols,
            reelPool: reelPool,
            isSpinning: isSpinning,
            stoppedReelCount: stoppedReelCount,
            heatLevel: heatLevel,
            machineGlow: machineGlow,
            stopLineFlashOpacity: stopLineFlashOpacity,
            glassSweepOffset: glassSweepOffset,
            sparkBurstProgress: sparkBurstProgress,
            sparkBurstOpacity: sparkBurstOpacity,
            premiumBacklightPhase: premiumBacklightPhase,
            reachPulse: reachPulse,
            reachOverlayOpacity: reachOverlayOpacity,
            reachOverlayScale: reachOverlayScale
        )
    }

    private var controlPanel: some View {
        HStack(spacing: 13) {
            ForEach(0..<3, id: \.self) { index in
                StopLampView(
                    index: index,
                    isSpinning: isSpinning,
                    stoppedReelCount: stoppedReelCount,
                    flashingStopIndex: flashingStopIndex,
                    heatLevel: heatLevel
                )
            }

            Spacer(minLength: 3)

            PushButtonView(
                isVisible: isPushVisible,
                isEnabled: isPushEnabled,
                heatLevel: heatLevel,
                machineGlow: machineGlow,
                onPush: onPush,
                onImpact: { offset in
                    withAnimation(.easeOut(duration: 0.10)) {
                        machineShakeX = offset
                    }
                }
            )
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

        withAnimation(
            .linear(duration: 3.2)
                .repeatForever(autoreverses: false)
        ) {
            glassSweepOffset = 1.6
        }

        withAnimation(
            .linear(duration: 4.6)
                .repeatForever(autoreverses: false)
        ) {
            frameSweepOffset = 1.65
        }

        withAnimation(
            .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: false)
        ) {
            risingLightOffset = -0.45
        }

        withAnimation(
            .linear(duration: 1.18)
                .repeatForever(autoreverses: false)
        ) {
            premiumBacklightPhase = .pi * 2
        }

        withAnimation(
            .easeInOut(duration: 0.26)
                .repeatForever(autoreverses: true)
        ) {
            reachPulse = true
        }

    }

    private func playSparkBurst() {
        sparkBurstProgress = 0
        sparkBurstOpacity = 1

        withAnimation(.easeOut(duration: 0.34)) {
            sparkBurstProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.24)) {
                sparkBurstOpacity = 0
            }
        }
    }

    private func playFreezeSequence() {
        guard !freezeSequenceRunning else { return }

        freezeSequenceRunning = true
        freezeEffectVisible = false

        machineShakeX = 0
        pseudoRepeatVisible = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            freezeEffectVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 0.08)) {
                machineShakeX = -4
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.08)) {
                machineShakeX = 4
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeOut(duration: 0.10)) {
                machineShakeX = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.72) {
            freezeEffectVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.88) {
            freezeSequenceRunning = false
            playPseudoRepeatSequence()
        }
    }

    private func playPseudoRepeatSequence() {
        pseudoRepeatCount += 1
        pseudoRepeatVisible = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            pseudoRepeatVisible = false
            playJackpot()
        }
    }

    private func playRewardCardReveal() {
        rewardCardVisible = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            rewardCardVisible = false
        }
    }

    private func playJackpot() {
        playJackpotWhiteout()
        jackpotVisible = true

        withAnimation(.easeOut(duration: 0.08)) {
            premiumFlashOpacity = 1
            machineShakeX = -9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.48
                )
            ) {
                machineShakeX = 8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            playRewardCardReveal()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeOut(duration: 0.30)) {
                premiumFlashOpacity = 0
                machineShakeX = 0
            }
        }
    }

    private func hideJackpot() {
        guard jackpotVisible else { return }
        jackpotVisible = false
    }

    private func playPremiumFlash() {
        premiumFlashOpacity = 0

        withAnimation(.easeOut(duration: 0.06)) {
            premiumFlashOpacity = 0.92
            machineShakeX = -6
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.easeInOut(duration: 0.06)) {
                machineShakeX = 6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.32)) {
                premiumFlashOpacity = 0
                machineShakeX = 0
            }
        }
    }

    private func playReachSequence(stoppedCount: Int) {
        guard isSpinning else { return }

        switch stoppedCount {
        case 1:
            reachOverlayScale = 0.82
            reachOverlayOpacity = 0.38

            withAnimation(.easeOut(duration: 0.18)) {
                reachOverlayScale = 1.0
            }

            withAnimation(.easeOut(duration: 0.34)) {
                reachOverlayOpacity = 0
            }

        case 2:
            reachOverlayScale = 0.76
            reachOverlayOpacity = heatLevel == .premium ? 1.0 : 0.72

            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.48
                )
            ) {
                reachOverlayScale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.easeOut(duration: 0.28)) {
                    reachOverlayOpacity = 0
                }
            }

        default:
            reachOverlayOpacity = 0
        }
    }

    private func playPremiumBurst() {
        premiumBurstTrigger += 1
    }

    private func playMachineFlash() {
        machineFlashOpacity = 0.88

        withAnimation(.easeOut(duration: 0.20)) {
            machineFlashOpacity = 0
        }
    }

    private func playJackpotWhiteout() {
        jackpotWhiteoutOpacity = 1
        jackpotZoomScale = 0.88

        withAnimation(.easeOut(duration: 0.18)) {
            jackpotWhiteoutOpacity = 0
        }

        withAnimation(
            .spring(
                response: 0.42,
                dampingFraction: 0.52
            )
        ) {
            jackpotZoomScale = 1.08
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.68
                )
            ) {
                jackpotZoomScale = 1.0
            }
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

    private func playStopImpact(stoppedCount: Int) {
        let stoppedIndex = min(max(stoppedCount - 1, 0), 2)
        flashingStopIndex = stoppedIndex
        pulseMachine()

        withAnimation(.easeOut(duration: 0.035)) {
            machineShakeX = stoppedIndex == 1 ? -7 : 7
            stopLineFlashOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) {
            withAnimation(.easeInOut(duration: 0.045)) {
                machineShakeX = stoppedIndex == 1 ? 5 : -5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.095) {
            withAnimation(.easeInOut(duration: 0.055)) {
                machineShakeX = 3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.52)) {
                machineShakeX = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.24)) {
                stopLineFlashOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            if flashingStopIndex == stoppedIndex {
                withAnimation(.easeOut(duration: 0.16)) {
                    flashingStopIndex = nil
                }
            }
        }
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
