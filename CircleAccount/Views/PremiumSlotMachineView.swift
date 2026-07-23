//
//  PremiumSlotMachineView.swift
//  CircleAccount
//

import SwiftUI
import UIKit

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
    let isFirstReelStopEnabled: Bool
    let cinematicPhase: SlotCinematicPhase
    let cinematicTrigger: Int
    let onFirstReelStop: () -> Void
    let onPush: () -> Void
    let onLeverChanged: (CGFloat) -> Void
    let onLeverReleased: () -> Void

    @AppStorage("slotSoundEnabled")
    private var slotSoundEnabled = true

    @AppStorage("slotSoundVolume")
    private var slotSoundVolume = 0.80

    @State private var lampPulse = false
    @State private var borderRotation = 0.0
    @State private var machinePulse = false
    @State private var machineShakeX: CGFloat = 0
    @State private var machineDropY: CGFloat = 0
    @State private var machineTiltDegrees = 0.0
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
    @State private var resultCelebrationTrigger = 0
    @State private var resultCelebrationKind: SlotResultCelebrationKind?
    @State private var isConfettiVisible = false
    @State private var confettiResetToken = 0
    @State private var enhancedStopFlashOpacity = 0.0
    @State private var enhancedStopFlashScale: CGFloat = 0.92
    @State private var enhancedStopFlashColor = Color.white
    @State private var enhancedStopFlashRotation = 0.0

    @State private var cabinetStrobeTrigger = 0
    @State private var cabinetStrobeColor = Color.cyan
    
    @State private var luckyLampMode: SlotLuckyLampMode = .off
    @State private var luckyLampTrigger = 0
    @State private var blackoutTrigger = 0
    @State private var pushChanceTrigger = 0
    @State private var pushPressTrigger = 0
    @State private var pushPressed = false

    @State private var resultPauseOpacity = 0.0
    @State private var resultPauseTextOpacity = 0.0
    @State private var resultPauseScale: CGFloat = 0.88
    @State private var finalResultSequenceToken = 0

    @State private var lcdPresentation: SlotLCDPresentation?
    @State private var lcdTrigger = 0
    @State private var spinEffectPlan = SlotSpinEffectPlan.normal
    @State private var effectSequenceToken = 0

    @State private var displaySymbols = ["⭐", "🏸", "💰"]

    private let reelPool = [
        "7",
        "BAR",
        "🔔",
        "🍇",
        "🍒",
        "🌈7"
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

    private var isSevenJackpot: Bool {
        safeSymbols == ["7", "7", "7"]
        || safeSymbols == ["🌈7", "🌈7", "🌈7"]
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

            authenticCabinetOverlay
                .zIndex(51)

            finalResultPauseOverlay
                .padding(.trailing, 46)
                .allowsHitTesting(false)
                .zIndex(52)

            EnhancedReelStopFlashOverlay(
                opacity: enhancedStopFlashOpacity,
                scale: enhancedStopFlashScale,
                color: enhancedStopFlashColor,
                rotation: enhancedStopFlashRotation
            )
            .padding(.trailing, 46)
            .allowsHitTesting(false)
            .zIndex(55)

            JackpotWhiteoutOverlay(
                opacity: jackpotWhiteoutOpacity
            )
            .allowsHitTesting(false)
            .zIndex(60)

            SlotLCDOverlayView(
                trigger: lcdTrigger,
                presentation: lcdPresentation
            )
            .padding(.trailing, 46)
            .allowsHitTesting(false)
            .zIndex(61)

            SlotBlackoutOverlay(
                trigger: blackoutTrigger
            )
            .padding(.trailing, 46)
            .allowsHitTesting(false)
            .zIndex(63)

            PremiumCinematicPachislotOverlay(
                phase: cinematicPhase,
                trigger: cinematicTrigger,
                glowColor: machineGlow
            )
            .padding(.trailing, 46)
            .allowsHitTesting(false)
            .zIndex(63.5)

            SlotPushChanceOverlay(
                isVisible: isPushVisible,
                isEnabled: isPushEnabled && !pushPressed,
                appearanceTrigger: pushChanceTrigger,
                pressTrigger: pushPressTrigger,
                isPremium: heatLevel == .premium,
                onPush: handlePremiumPush
            )
            .padding(.trailing, 46)
            .zIndex(64)

            PremiumBurstView(
                trigger: premiumBurstTrigger,
                glowColor: machineGlow
            )
            .zIndex(65)

            SlotResultCelebrationOverlay(
                trigger: resultCelebrationTrigger,
                kind: resultCelebrationKind
            )
            .padding(.trailing, 46)
            .zIndex(66)
            .allowsHitTesting(false)

            if isConfettiVisible {
                ConfettiView()
                    .id(confettiResetToken)
                    .padding(.trailing, 46)
                    .transition(.opacity)
                    .zIndex(67)
                    .allowsHitTesting(false)
            }

            if isSevenJackpot {
                RewardCardView(
                    isVisible: rewardCardVisible,
                    symbols: safeSymbols,
                    title: "JACKPOT",
                    subtitle: statusText.isEmpty ? "PREMIUM GET!" : statusText,
                    isPremium: true
                )
                .padding(.trailing, 46)
                .zIndex(68)
                .allowsHitTesting(false)
            }

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

            SlotSoundControlView(
                isEnabled: $slotSoundEnabled,
                volume: $slotSoundVolume,
                glowColor: machineGlow
            )
            .frame(
                maxWidth: 370,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(.trailing, 46)
            .padding(.top, 12)
            .padding(.leading, 12)
            .zIndex(90)

            PremiumLeverControl(
                progress: leverProgress,
                glowColor: machineGlow,
                enabled: !isSpinning,
                onChanged: onLeverChanged,
                onReleased: {
                    playLeverLaunchImpact()
                    onLeverReleased()
                }
            )
            .offset(x: 2, y: 82)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
        .scaleEffect(
            x: machinePulse ? 1.012 : 1.0,
            y: machinePulse ? 0.992 : 1.0,
            anchor: .center
        )
        .rotationEffect(.degrees(machineTiltDegrees))
        .offset(x: machineShakeX, y: machineDropY)
        .onAppear {
            prepareDisplaySymbols()
            startContinuousAnimations()
            SlotSoundManager.shared.setMasterVolume(
                slotSoundVolume
            )
            SlotSoundManager.shared.prepare(
                enabled: slotSoundEnabled
            )
        }
        .onDisappear {
            SlotSoundManager.shared.stopAll()
        }
        .onChange(of: slotSoundEnabled) { _, enabled in
            SlotSoundManager.shared.setMasterVolume(
                slotSoundVolume
            )
            SlotSoundManager.shared.prepare(
                enabled: enabled
            )
        }
        .onChange(of: slotSoundVolume) { _, volume in
            SlotSoundManager.shared.setMasterVolume(volume)
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                prepareDisplaySymbols()
                prepareSpinEffectPlan()
                machineDropY = 0
                machineTiltDegrees = 0
                cabinetStrobeColor = machineGlow
                cabinetStrobeTrigger += 1
                playSpinStartEffect()
            } else if stoppedReelCount == 0 {
                effectSequenceToken += 1
            }
        }
        .onChange(of: heatLevel) { _, newValue in
            pulseMachine()

            if newValue == .premium {
                playPremiumFlash()
                showLCD(.superHot)
            }
        }
        .onChange(of: isPushVisible) { _, visible in
            if visible {
                pushPressed = false
                pushChanceTrigger += 1
                showLCD(.push)
            } else {
                pushPressed = false
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
                    resultCelebrationKind = nil
                    isConfettiVisible = false
                    
                    luckyLampMode = .off
                    lcdPresentation = nil
                    spinEffectPlan = .normal
                    effectSequenceToken += 1
                    SlotSoundManager.shared.stopSpin()
                    
                    hideJackpot()
                }
                return
            }

            playStopImpact(stoppedCount: newValue)
            playEnhancedStopFlash(stoppedCount: newValue)
            playSparkBurst()
            playMachineFlash()
            playReachSequence(stoppedCount: newValue)

            if newValue == 1 {
                if let presentation =
                    spinEffectPlan.firstStopPresentation {
                    showLCD(presentation)
                }

                playFirstStopEffect()
            } else if newValue == 2 {
                if let presentation =
                    spinEffectPlan.secondStopPresentation {
                    showLCD(presentation)
                }

                playSecondStopEffect()
            }

            if newValue == 1 {
                lightLuckyLamp()
            }

            if newValue == 2,
               safeSymbols == ["🌈7", "🌈7", "🌈7"] {
                playBlackoutSequence()
            }

            if newValue >= 3 {
                playFinalResultSequence()
            }
        }
    }

    private var authenticCabinetOverlay: some View {
        AuthenticPachislotCabinetOverlay(
            trigger: cabinetStrobeTrigger,
            glowColor: cabinetStrobeColor,
            isSpinning: isSpinning,
            stoppedReelCount: stoppedReelCount
        )
        .padding(.trailing, 46)
        .allowsHitTesting(false)
    }

    private var finalResultPauseOverlay: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
            .fill(Color.black.opacity(0.72))
            .opacity(resultPauseOpacity)

            if isSevenJackpot {
                VStack(spacing: 8) {
                    Text("…")
                        .font(
                            .system(
                                size: 40,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.white)

                    Text(
                        heatLevel == .premium
                            ? "PREMIUM LOCK"
                            : "CHANCE"
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .tracking(2.0)
                    .foregroundStyle(
                        heatLevel == .premium
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        .red,
                                        .orange,
                                        .yellow,
                                        .green,
                                        .cyan,
                                        .blue,
                                        .purple
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(
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
                    )
                    .shadow(
                        color:
                            heatLevel == .premium
                                ? Color.purple.opacity(0.95)
                                : Color.yellow.opacity(0.95),
                        radius: 16
                    )
                }
                .scaleEffect(resultPauseScale)
                .opacity(resultPauseTextOpacity)
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

            // MovingMetalHighlight(
            //     sweepOffset: frameSweepOffset
            // )
            // .allowsHitTesting(false)

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
                HStack {
                    SlotLuckyLampView(
                        mode: luckyLampMode,
                        trigger: luckyLampTrigger
                    )

                    Spacer()
                }
                .frame(height: 78)
                reelHousing
                firstReelStopButton
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
            resultSymbols: safeSymbols,
            displaySymbols: displaySymbols,
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

    private var firstReelStopButton: some View {
        Button {
            guard isFirstReelStopEnabled else { return }

            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.prepare()
            impact.impactOccurred(intensity: 1.0)

            onFirstReelStop()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            isFirstReelStopEnabled
                                ? Color.red
                                : Color.white.opacity(0.12)
                        )
                        .frame(width: 38, height: 38)
                        .shadow(
                            color: isFirstReelStopEnabled
                                ? Color.red.opacity(0.85)
                                : .clear,
                            radius: 14
                        )

                    Text("1")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        isFirstReelStopEnabled
                            ? "LEFT REEL STOP"
                            : "FIRST STOP"
                    )
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.0)

                    Text(
                        isFirstReelStopEnabled
                            ? "好きなタイミングで押してください"
                            : "停止待機中"
                    )
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        isFirstReelStopEnabled
                            ? Color.yellow
                            : Color.white.opacity(0.25)
                    )
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        isFirstReelStopEnabled
                            ? Color.red.opacity(0.20)
                            : Color.white.opacity(0.055)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(
                                isFirstReelStopEnabled
                                    ? Color.red.opacity(0.90)
                                    : Color.white.opacity(0.10),
                                lineWidth: isFirstReelStopEnabled ? 2 : 1
                            )
                    }
            )
            .shadow(
                color: isFirstReelStopEnabled
                    ? Color.red.opacity(0.34)
                    : .clear,
                radius: 16,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!isFirstReelStopEnabled)
        .scaleEffect(isFirstReelStopEnabled && lampPulse ? 1.025 : 1.0)
        .animation(
            .easeInOut(duration: 0.35),
            value: lampPulse
        )
    }

    private var controlPanel: some View {
        MachineControlPanelView(
            isSpinning: isSpinning,
            stoppedReelCount: stoppedReelCount,
            flashingStopIndex: flashingStopIndex,
            heatLevel: heatLevel,
            machineGlow: machineGlow,
            isPushVisible: false,
            isPushEnabled: false,
            onPush: onPush,
            onImpact: { offset in
                withAnimation(.easeOut(duration: 0.10)) {
                    machineShakeX = offset
                }
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

    private func prepareSpinEffectPlan() {
        effectSequenceToken += 1

        spinEffectPlan = SlotEffectDirector.makePlan(
            heatLevel: heatLevel,
            resultSymbols: safeSymbols
        )
    }

    private func playSpinStartEffect() {
        let token = effectSequenceToken

        if let presentation =
            spinEffectPlan.startPresentation {
            showLCD(presentation)
        }

        if spinEffectPlan.usesWarningSound {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.12
            ) {
                guard token == effectSequenceToken,
                      isSpinning else {
                    return
                }

            }
        }

        if spinEffectPlan.intensifiesSpin {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.42
            ) {
                guard token == effectSequenceToken,
                      isSpinning else {
                    return
                }

                playMachineFlash()
            }
        }

        if spinEffectPlan.usesBlackoutTease {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.74
            ) {
                guard token == effectSequenceToken,
                      isSpinning,
                      stoppedReelCount == 0 else {
                    return
                }

                blackoutTrigger += 1

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.72
                ) {
                    guard token == effectSequenceToken,
                          isSpinning else {
                        return
                    }

                    showLCD(.blackoutReturn)
                }
            }
        }
    }

    private func playFirstStopEffect() {
        guard isSpinning else { return }

        if spinEffectPlan.level >= .hot {
            playMachineFlash()
        }

        if spinEffectPlan.usesFakePremiumTease {
            let token = effectSequenceToken

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.16
            ) {
                guard token == effectSequenceToken,
                      isSpinning,
                      stoppedReelCount == 1 else {
                    return
                }

                enhancedStopFlashColor = .purple
                enhancedStopFlashOpacity = 0.46
                enhancedStopFlashScale = 0.90

                withAnimation(.easeOut(duration: 0.28)) {
                    enhancedStopFlashOpacity = 0
                    enhancedStopFlashScale = 1.10
                }
            }
        }
    }

    private func playSecondStopEffect() {
        guard isSpinning else { return }

        if spinEffectPlan.level >= .hot {
            playPremiumBurst()
        }
    }

    private func showLCD(
        _ presentation: SlotLCDPresentation
    ) {
        lcdPresentation = presentation
        lcdTrigger += 1
    }

    private func prepareDisplaySymbols() {
        var candidates = reelPool.shuffled()

        while candidates.count < 3 {
            candidates.append(contentsOf: reelPool.shuffled())
        }

        var selected = Array(candidates.prefix(3))

        for index in 0..<3 {
            if selected[index] == safeSymbols[index],
               let replacement = reelPool.first(where: {
                   $0 != safeSymbols[index]
               }) {
                selected[index] = replacement
            }
        }

        if Set(selected).count == 1,
           reelPool.count > 1 {
            selected[1] = reelPool.first(where: {
                $0 != selected[0]
            }) ?? selected[1]
        }

        displaySymbols = selected
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

    private func playLeverLaunchImpact() {
        cabinetStrobeColor = heatLevel == .premium ? .purple : .cyan
        cabinetStrobeTrigger += 1

        let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpact.prepare()
        heavyImpact.impactOccurred(intensity: 0.92)

        machineDropY = 0
        machineTiltDegrees = 0
        machineFlashOpacity = max(machineFlashOpacity, 0.48)

        withAnimation(.easeOut(duration: 0.055)) {
            machineDropY = 8
            machineShakeX = -3.5
            machineTiltDegrees = -0.42
            machinePulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.055) {
            withAnimation(.easeInOut(duration: 0.065)) {
                machineDropY = -2.5
                machineShakeX = 3.0
                machineTiltDegrees = 0.28
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
            rigidImpact.prepare()
            rigidImpact.impactOccurred(intensity: 0.62)

            withAnimation(
                .spring(
                    response: 0.24,
                    dampingFraction: 0.56
                )
            ) {
                machineDropY = 0
                machineShakeX = 0
                machineTiltDegrees = 0
                machinePulse = false
            }

            withAnimation(.easeOut(duration: 0.20)) {
                machineFlashOpacity = 0
            }
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

        // 第三停止後の図柄・チャンス演出・告知ランプを
        // 十分に見せてから当たりチケットを表示する
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
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

    private func handlePremiumPush() {
        guard isPushVisible, isPushEnabled, !pushPressed else { return }

        pushPressed = true
        pushPressTrigger += 1
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred(intensity: 1.0)

        playJackpotWhiteout()
        playPremiumBurst()

        if safeSymbols == ["🌈7", "🌈7", "🌈7"] {
            luckyLampMode = .rainbow
            luckyLampTrigger += 1
            playRainbowFinalFlash()
        } else {
            luckyLampMode = .gold
            luckyLampTrigger += 1
            playGoldFinalFlash()
        }

        withAnimation(.easeOut(duration: 0.06)) {
            machineShakeX = -12
            machinePulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.easeInOut(duration: 0.07)) {
                machineShakeX = 12
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            onPush()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.56
                )
            ) {
                machineShakeX = 0
                machinePulse = false
            }
        }
    }

    private func playBlackoutSequence() {
        blackoutTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
            showLCD(.blackoutReturn)
        }

        withAnimation(.easeOut(duration: 0.06)) {
            machineShakeX = -5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.07)) {
                machineShakeX = 5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(
                .spring(
                    response: 0.26,
                    dampingFraction: 0.62
                )
            ) {
                machineShakeX = 0
            }
        }
    }

    private func lightLuckyLamp() {
        switch safeSymbols {

        // SSR
        case ["🌈7", "🌈7", "🌈7"]:
            luckyLampMode = .rainbow
            luckyLampTrigger += 1

        // SR
        case ["7", "7", "7"],
             ["7", "7", "BAR"],
             ["BAR", "BAR", "BAR"]:
            luckyLampMode = .gold
            luckyLampTrigger += 1

        // R・N
        default:
            luckyLampMode = .off
        }
    }
    private func playFinalResultSequence() {
        finalResultSequenceToken += 1
        let token = finalResultSequenceToken

        SlotSoundManager.shared.stopSpin()

        guard isSevenJackpot else {
            playResultSound()
            playResultCelebration()
            return
        }

        resultPauseOpacity = 0
        resultPauseTextOpacity = 0
        resultPauseScale = 0.88

        withAnimation(.easeOut(duration: 0.08)) {
            resultPauseOpacity = 0.58
            machineDropY = 3
            machineTiltDegrees = -0.18
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.10
        ) {
            guard token == finalResultSequenceToken else { return }

            withAnimation(
                .spring(
                    response: 0.22,
                    dampingFraction: 0.58
                )
            ) {
                resultPauseTextOpacity = 1
                resultPauseScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.32
        ) {
            guard token == finalResultSequenceToken else { return }

            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.prepare()
            impact.impactOccurred(intensity: 1.0)

            playResultSound()
            playJackpotWhiteout()
            playPremiumBurst()

            withAnimation(.easeOut(duration: 0.045)) {
                resultPauseOpacity = 0
                resultPauseTextOpacity = 0
                machineDropY = 10
                machineShakeX = -10
                machineTiltDegrees = -0.72
                machinePulse = true
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.385
        ) {
            guard token == finalResultSequenceToken else { return }

            let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
            rigidImpact.prepare()
            rigidImpact.impactOccurred(intensity: 0.78)

            withAnimation(.easeInOut(duration: 0.06)) {
                machineDropY = -3
                machineShakeX = 9
                machineTiltDegrees = 0.46
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.47
        ) {
            guard token == finalResultSequenceToken else { return }

            withAnimation(
                .spring(
                    response: 0.32,
                    dampingFraction: 0.52
                )
            ) {
                machineDropY = 0
                machineShakeX = 0
                machineTiltDegrees = 0
                machinePulse = false
            }

            playResultCelebration()
            playFreezeSequence()
        }
    }

    private func playResultSound() {
        switch safeSymbols {
        case ["🌈7", "🌈7", "🌈7"]:
            SlotSoundManager.shared.playRainbowSeven()

        case ["7", "7", "7"]:
            SlotSoundManager.shared.playSeven()

        case ["🔔", "🔔", "🔔"]:
            SlotSoundManager.shared.playBell()

        case ["🍇", "🍇", "🍇"]:
            SlotSoundManager.shared.playGrape()

        default:
            break
        }
    }

    private func playResultCelebration() {
        
        if safeSymbols == ["🌈7", "🌈7", "🌈7"] {
            showLCD(.rainbowJackpot)
            resultCelebrationKind = .rainbowSeven
            resultCelebrationTrigger += 1
            playConfetti(duration: 3.8)
            playJackpotWhiteout()
            playPremiumBurst()

            withAnimation(.easeOut(duration: 0.07)) {
                machineShakeX = -11
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeInOut(duration: 0.07)) {
                    machineShakeX = 11
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
                withAnimation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.54
                    )
                ) {
                    machineShakeX = 0
                }
            }
        } else if safeSymbols == ["7", "7", "7"] {
            showLCD(.redSeven)
            resultCelebrationKind = .redSeven
            resultCelebrationTrigger += 1
            playConfetti(duration: 3.0)
            playJackpotWhiteout()

            withAnimation(.easeOut(duration: 0.08)) {
                machineShakeX = -8
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeInOut(duration: 0.08)) {
                    machineShakeX = 8
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) {
                withAnimation(
                    .spring(
                        response: 0.28,
                        dampingFraction: 0.60
                    )
                ) {
                    machineShakeX = 0
                }
            }
        }
    }

    private func playConfetti(duration: Double) {
        confettiResetToken += 1
        isConfettiVisible = false

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.12)) {
                isConfettiVisible = true
            }
        }

        let currentToken = confettiResetToken

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard currentToken == confettiResetToken else { return }

            withAnimation(.easeOut(duration: 0.32)) {
                isConfettiVisible = false
            }
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

    private func playEnhancedStopFlash(
        stoppedCount: Int
    ) {
        let stoppedIndex = min(max(stoppedCount - 1, 0), 2)

        enhancedStopFlashRotation += 16

        switch stoppedIndex {
        case 0:
            enhancedStopFlashColor = .white
            enhancedStopFlashOpacity = 0.54
            enhancedStopFlashScale = 0.94

            withAnimation(.easeOut(duration: 0.18)) {
                enhancedStopFlashOpacity = 0
                enhancedStopFlashScale = 1.04
            }

        case 1:
            enhancedStopFlashColor = Color(
                red: 0.72,
                green: 0.90,
                blue: 1.00
            )
            enhancedStopFlashOpacity = 0.72
            enhancedStopFlashScale = 0.91

            withAnimation(.easeOut(duration: 0.24)) {
                enhancedStopFlashOpacity = 0
                enhancedStopFlashScale = 1.09
            }

        default:
            if safeSymbols == ["🌈7", "🌈7", "🌈7"] {
                playRainbowFinalFlash()
            } else if safeSymbols == ["7", "7", "7"] {
                playGoldFinalFlash()
            } else {
                enhancedStopFlashColor = .white
                enhancedStopFlashOpacity = 0.95
                enhancedStopFlashScale = 0.84

                withAnimation(.easeOut(duration: 0.34)) {
                    enhancedStopFlashOpacity = 0
                    enhancedStopFlashScale = 1.18
                }
            }
        }
    }

    private func playGoldFinalFlash() {
        enhancedStopFlashColor = Color.yellow
        enhancedStopFlashOpacity = 1
        enhancedStopFlashScale = 0.78

        withAnimation(.easeOut(duration: 0.15)) {
            enhancedStopFlashScale = 1.22
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.10
        ) {
            enhancedStopFlashColor = .white
            enhancedStopFlashOpacity = 0.96
            enhancedStopFlashScale = 0.90

            withAnimation(.easeOut(duration: 0.42)) {
                enhancedStopFlashOpacity = 0
                enhancedStopFlashScale = 1.30
            }
        }
    }

    private func playRainbowFinalFlash() {
        let rainbowColors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .cyan,
            .blue,
            .purple,
            .pink
        ]

        enhancedStopFlashOpacity = 1
        enhancedStopFlashScale = 0.76

        for (index, color) in rainbowColors.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now()
                + Double(index) * 0.055
            ) {
                enhancedStopFlashColor = color
                enhancedStopFlashScale =
                    index.isMultiple(of: 2)
                    ? 1.08
                    : 0.96
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.48
        ) {
            enhancedStopFlashColor = .white

            withAnimation(.easeOut(duration: 0.48)) {
                enhancedStopFlashOpacity = 0
                enhancedStopFlashScale = 1.34
            }
        }
    }

    private func playStopImpact(stoppedCount: Int) {
        let stoppedIndex = min(max(stoppedCount - 1, 0), 2)
        flashingStopIndex = stoppedIndex
        pulseMachine()

        switch stoppedIndex {
        case 0:
            cabinetStrobeColor = .white
        case 1:
            cabinetStrobeColor = heatLevel == .premium ? .purple : .cyan
        default:
            cabinetStrobeColor =
                safeSymbols == ["🌈7", "🌈7", "🌈7"]
                ? .pink
                : safeSymbols == ["7", "7", "7"]
                ? .yellow
                : .white
        }
        cabinetStrobeTrigger += 1

        let firstOffset: CGFloat
        let reboundOffset: CGFloat
        let settleOffset: CGFloat
        let firstDuration: Double
        let reboundDuration: Double
        let settleDuration: Double
        let flashPeak: Double
        let flashFadeDelay: Double
        let flashFadeDuration: Double

        switch stoppedIndex {
        case 0:
            firstOffset = 4.5
            reboundOffset = -3.0
            settleOffset = 1.2
            firstDuration = 0.045
            reboundDuration = 0.050
            settleDuration = 0.060
            flashPeak = 0.58
            flashFadeDelay = 0.10
            flashFadeDuration = 0.20

        case 1:
            firstOffset = -7.0
            reboundOffset = 5.0
            settleOffset = -2.0
            firstDuration = 0.040
            reboundDuration = 0.050
            settleDuration = 0.060
            flashPeak = 0.78
            flashFadeDelay = 0.11
            flashFadeDuration = 0.24

        default:
            firstOffset = 10.5
            reboundOffset = -8.0
            settleOffset = 4.0
            firstDuration = 0.032
            reboundDuration = 0.046
            settleDuration = 0.058
            flashPeak = 1.0
            flashFadeDelay = 0.14
            flashFadeDuration = 0.32
        }

        withAnimation(.easeOut(duration: firstDuration)) {
            machineShakeX = firstOffset
            stopLineFlashOpacity = flashPeak
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + firstDuration
        ) {
            withAnimation(.easeInOut(duration: reboundDuration)) {
                machineShakeX = reboundOffset
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + firstDuration + reboundDuration
        ) {
            withAnimation(.easeInOut(duration: settleDuration)) {
                machineShakeX = settleOffset
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now()
            + firstDuration
            + reboundDuration
            + settleDuration
        ) {
            withAnimation(
                .spring(
                    response: stoppedIndex == 2 ? 0.22 : 0.18,
                    dampingFraction: stoppedIndex == 2 ? 0.48 : 0.56
                )
            ) {
                machineShakeX = 0
            }
        }

        if stoppedIndex == 2 {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.085
            ) {
                withAnimation(.easeOut(duration: 0.045)) {
                    machinePulse = true
                }
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.19
            ) {
                withAnimation(
                    .spring(
                        response: 0.24,
                        dampingFraction: 0.58
                    )
                ) {
                    machinePulse = false
                }
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + flashFadeDelay
        ) {
            withAnimation(.easeOut(duration: flashFadeDuration)) {
                stopLineFlashOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.34
        ) {
            if flashingStopIndex == stoppedIndex {
                withAnimation(.easeOut(duration: 0.16)) {
                    flashingStopIndex = nil
                }
            }
        }
    }
}



private struct AuthenticPachislotCabinetOverlay: View {
    let trigger: Int
    let glowColor: Color
    let isSpinning: Bool
    let stoppedReelCount: Int

    @State private var flashOpacity = 0.0
    @State private var lampScale: CGFloat = 0.86
    @State private var scanOffset: CGFloat = -1.2
    @State private var vibrationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 筐体上部の告知ランプ
            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Capsule()
                            .fill(
                                index <= stoppedReelCount
                                    ? glowColor
                                    : Color.white.opacity(0.14)
                            )
                            .frame(width: 24, height: 6)
                            .shadow(
                                color: index <= stoppedReelCount
                                    ? glowColor
                                    : .clear,
                                radius: 9
                            )
                            .scaleEffect(lampScale)
                    }
                }
                .padding(.top, 8)

                Spacer()
            }

            // ブレーキ停止時の瞬間ストロボ
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(glowColor.opacity(flashOpacity), lineWidth: 7)
                .shadow(color: glowColor, radius: 24)
                .opacity(flashOpacity)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(flashOpacity * 0.72),
                            glowColor.opacity(flashOpacity * 0.34),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .blendMode(.screen)

            // CRT風の走査線
            GeometryReader { proxy in
                VStack(spacing: 5) {
                    ForEach(0..<70, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(isSpinning ? 0.035 : 0.018))
                            .frame(height: 1)
                    }
                }
                .offset(y: proxy.size.height * scanOffset)
                .mask(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                )
            }
            .blendMode(.screen)
        }
        .offset(x: vibrationOffset)
        .onAppear {
            startContinuousScan()
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            playStrobe()
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                playSpinVibration()
            } else {
                vibrationOffset = 0
            }
        }
    }

    private func startContinuousScan() {
        scanOffset = -1.2

        withAnimation(
            .linear(duration: 2.4)
                .repeatForever(autoreverses: false)
        ) {
            scanOffset = 1.2
        }

        withAnimation(
            .easeInOut(duration: 0.38)
                .repeatForever(autoreverses: true)
        ) {
            lampScale = 1.08
        }
    }

    private func playStrobe() {
        flashOpacity = 1
        lampScale = 1.22

        withAnimation(.easeOut(duration: 0.16)) {
            flashOpacity = 0
            lampScale = 0.94
        }

        let offsets: [CGFloat] = [-4, 4, -3, 3, -1.5, 1.5, 0]

        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.035
            ) {
                vibrationOffset = offset
            }
        }
    }

    private func playSpinVibration() {
        let offsets: [CGFloat] = [-1.2, 1.2, -0.8, 0.8, 0]

        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.045
            ) {
                vibrationOffset = offset
            }
        }
    }
}



private struct PremiumCinematicPachislotOverlay: View {
    let phase: SlotCinematicPhase
    let trigger: Int
    let glowColor: Color

    @State private var blackoutOpacity = 0.0
    @State private var messageOpacity = 0.0
    @State private var messageScale: CGFloat = 0.72
    @State private var doorProgress: CGFloat = 0
    @State private var flashOpacity = 0.0
    @State private var freezeLineOffset: CGFloat = -1
    @State private var ringScale: CGFloat = 0.35

    var body: some View {
        ZStack {
            Color.black
                .opacity(blackoutOpacity)

            if phase == .silentFreeze {
                freezeLayer
            }

            if phase == .doorOpen {
                doorLayer
            }

            if phase == .kyuiin {
                kyuiinLayer
            }

            if shouldShowMessage {
                messageLayer
            }

            Color.white
                .opacity(flashOpacity)
                .blendMode(.screen)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            playPhase()
        }
    }

    private var shouldShowMessage: Bool {
        switch phase {
        case .silentFreeze, .pushStandby, .finalSilence:
            return true
        case .idle, .leverBlackout, .delayedStart,
             .kyuiin, .doorOpen, .ticketReady:
            return false
        }
    }

    private var phaseText: String {
        switch phase {
        case .leverBlackout, .delayedStart:
            return ""
        case .silentFreeze:
            return "SILENT FREEZE"
        case .pushStandby:
            return "PUSH"
        case .finalSilence:
            return "…"
        case .ticketReady:
            return "TICKET GET"
        default:
            return ""
        }
    }

    private var messageLayer: some View {
        VStack(spacing: 8) {
            Text(phaseText)
                .font(
                    .system(
                        size: phase == .pushStandby ? 48 : 32,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(2.0)
                .foregroundStyle(
                    phase == .ticketReady
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [.white, .yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        : AnyShapeStyle(Color.white)
                )
                .shadow(
                    color: phase == .ticketReady ? .yellow : glowColor,
                    radius: 16
                )

            if phase == .pushStandby {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.red)
                    .shadow(color: .red, radius: 14)
            }
        }
        .scaleEffect(messageScale)
        .opacity(messageOpacity)
    }

    private var freezeLayer: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.78)

                VStack(spacing: 4) {
                    ForEach(0..<54, id: \.self) { index in
                        Rectangle()
                            .fill(
                                index.isMultiple(of: 3)
                                    ? Color.white.opacity(0.11)
                                    : glowColor.opacity(0.07)
                            )
                            .frame(height: 1)
                    }
                }
                .offset(y: proxy.size.height * freezeLineOffset)
                .blendMode(.screen)

                Image(systemName: "snowflake")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .shadow(color: .cyan, radius: 20)
            }
        }
    }

    private var kyuiinLayer: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .red, .orange, .yellow, .green,
                            .cyan, .blue, .purple, .pink, .red
                        ],
                        center: .center
                    ),
                    lineWidth: 12
                )
                .frame(width: 220, height: 220)
                .scaleEffect(ringScale)
                .shadow(color: .white, radius: 24)

            Text("キュイン!!")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .yellow, .pink, .cyan, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .pink, radius: 18)
        }
        .opacity(messageOpacity)
    }

    private var doorLayer: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.58)

                HStack(spacing: 0) {
                    doorPanel(
                        width: proxy.size.width / 2,
                        height: proxy.size.height,
                        isLeft: true
                    )
                    .offset(x: -doorProgress * proxy.size.width / 2)

                    doorPanel(
                        width: proxy.size.width / 2,
                        height: proxy.size.height,
                        isLeft: false
                    )
                    .offset(x: doorProgress * proxy.size.width / 2)
                }

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        glowColor.opacity(0.70),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 210
                )
                .scaleEffect(doorProgress)
                .opacity(Double(doorProgress))
                .blendMode(.screen)
            }
        }
    }

    private func doorPanel(
        width: CGFloat,
        height: CGFloat,
        isLeft: Bool
    ) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.16, green: 0.02, blue: 0.03),
                        Color.black
                    ],
                    startPoint: isLeft ? .leading : .trailing,
                    endPoint: isLeft ? .trailing : .leading
                )
            )
            .overlay {
                Rectangle()
                    .stroke(Color.red.opacity(0.75), lineWidth: 3)
                    .shadow(color: .red, radius: 12)
            }
            .frame(width: width, height: height)
    }

    private func playPhase() {
        blackoutOpacity = 0
        messageOpacity = 0
        messageScale = 0.72
        doorProgress = 0
        flashOpacity = 0
        freezeLineOffset = -1
        ringScale = 0.35

        switch phase {
        case .idle:
            break

        case .leverBlackout:
            withAnimation(.easeOut(duration: 0.08)) {
                blackoutOpacity = 0.96
                messageOpacity = 1
            }

        case .delayedStart:
            blackoutOpacity = 0.72
            withAnimation(
                .spring(response: 0.34, dampingFraction: 0.55)
            ) {
                messageOpacity = 1
                messageScale = 1
            }
            withAnimation(.easeOut(duration: 0.34).delay(0.18)) {
                blackoutOpacity = 0
            }

        case .silentFreeze:
            blackoutOpacity = 0.64
            messageOpacity = 1
            withAnimation(.linear(duration: 0.55)) {
                freezeLineOffset = 1
            }

        case .pushStandby:
            blackoutOpacity = 0.52
            withAnimation(
                .spring(response: 0.34, dampingFraction: 0.44)
            ) {
                messageOpacity = 1
                messageScale = 1.08
            }

        case .finalSilence:
            withAnimation(.easeOut(duration: 0.10)) {
                blackoutOpacity = 0.76
                messageOpacity = 1
                messageScale = 1
            }

        case .kyuiin:
            flashOpacity = 1
            messageOpacity = 1
            withAnimation(.easeOut(duration: 0.18)) {
                flashOpacity = 0
            }
            withAnimation(
                .spring(response: 0.44, dampingFraction: 0.45)
            ) {
                ringScale = 1.18
            }

        case .doorOpen:
            blackoutOpacity = 0.66
            flashOpacity = 0.75
            withAnimation(.easeOut(duration: 0.18)) {
                flashOpacity = 0
            }
            withAnimation(
                .easeInOut(duration: 0.95)
            ) {
                doorProgress = 1
            }

        case .ticketReady:
            blackoutOpacity = 0.36
            withAnimation(
                .spring(response: 0.42, dampingFraction: 0.52)
            ) {
                messageOpacity = 1
                messageScale = 1
            }
        }
    }
}

private struct EnhancedReelStopFlashOverlay: View {
    let opacity: Double
    let scale: CGFloat
    let color: Color
    let rotation: Double

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.96),
                        color.opacity(0.76),
                        color.opacity(0.24),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 255
                )
            )
            .blendMode(.screen)

            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.94),
                                color.opacity(0.76),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 185, height: 4)
                    .offset(x: 86)
                    .rotationEffect(
                        .degrees(
                            Double(index) * 30
                            + rotation
                        )
                    )
                    .blendMode(.screen)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .compositingGroup()
    }
}

private enum SlotResultCelebrationKind {
    case redSeven
    case rainbowSeven
}

private struct SlotResultCelebrationOverlay: View {
    let trigger: Int
    let kind: SlotResultCelebrationKind?

    @State private var progress: CGFloat = 1
    @State private var overlayOpacity = 0.0
    @State private var ringScale: CGFloat = 0.35
    @State private var ringOpacity = 0.0
    @State private var titleScale: CGFloat = 0.55

    private let particleCount = 52

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let kind {
                    celebrationBackground(kind: kind)

                    ForEach(0..<particleCount, id: \.self) { index in
                        particle(
                            index: index,
                            kind: kind,
                            size: proxy.size
                        )
                    }

                    Circle()
                        .stroke(
                            ringStyle(for: kind),
                            lineWidth: kind == .rainbowSeven ? 13 : 9
                        )
                        .frame(width: 205, height: 205)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .blur(radius: 0.5)
                        .blendMode(.screen)

                    VStack(spacing: 5) {
                        Text(
                            kind == .rainbowSeven
                                ? "🌈 PREMIUM 🌈"
                                : "777 JACKPOT"
                        )
                        .font(
                            .system(
                                size: kind == .rainbowSeven ? 27 : 31,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(1.2)
                        .foregroundStyle(titleStyle(for: kind))
                        .shadow(
                            color: kind == .rainbowSeven
                                ? Color.white
                                : Color.yellow,
                            radius: 14
                        )

                        Text(
                            kind == .rainbowSeven
                                ? "RAINBOW SEVEN"
                                : "RED SEVEN"
                        )
                        .font(
                            .system(
                                size: 10,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .tracking(2.6)
                        .foregroundStyle(Color.white.opacity(0.88))
                    }
                    .scaleEffect(titleScale)
                    .opacity(overlayOpacity)
                }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0, kind != nil else { return }
            play()
        }
    }

    @ViewBuilder
    private func celebrationBackground(
        kind: SlotResultCelebrationKind
    ) -> some View {
        if kind == .rainbowSeven {
            Rectangle()
                .fill(
                    AngularGradient(
                        colors: [
                            .red,
                            .orange,
                            .yellow,
                            .green,
                            .cyan,
                            .blue,
                            .purple,
                            .pink,
                            .red
                        ],
                        center: .center
                    )
                )
                .opacity(0.19 * overlayOpacity)
                .blendMode(.screen)
        } else {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.55 * overlayOpacity),
                    Color.yellow.opacity(0.28 * overlayOpacity),
                    Color.red.opacity(0.12 * overlayOpacity),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 245
            )
        }
    }

    private func particle(
        index: Int,
        kind: SlotResultCelebrationKind,
        size: CGSize
    ) -> some View {
        let fraction =
            CGFloat(index)
            / CGFloat(max(particleCount - 1, 1))

        let column =
            CGFloat(index % 13)
            / 12.0

        let wave =
            sin(
                Double(index) * 1.73
            )

        let startX =
            size.width * column

        let travelX =
            CGFloat(wave)
            * (28 + CGFloat(index % 5) * 9)

        let startY =
            -30 - CGFloat(index % 7) * 18

        let travelY =
            size.height
            + 95
            + CGFloat(index % 9) * 22

        let particleSize =
            5 + CGFloat(index % 5) * 1.8

        return Group {
            if kind == .rainbowSeven {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        rainbowColor(
                            at: fraction
                        )
                    )
                    .frame(
                        width: particleSize,
                        height: particleSize * 1.65
                    )
            } else {
                Circle()
                    .fill(
                        index.isMultiple(of: 3)
                            ? Color.white
                            : Color.yellow
                    )
                    .frame(
                        width: particleSize,
                        height: particleSize
                    )
            }
        }
        .rotationEffect(
            .degrees(
                Double(progress)
                * (360 + Double(index % 8) * 70)
            )
        )
        .position(
            x: startX + travelX * progress,
            y: startY + travelY * progress
        )
        .opacity(
            overlayOpacity
            * Double(
                max(
                    0,
                    1 - progress * 0.52
                )
            )
        )
    }

    private func ringStyle(
        for kind: SlotResultCelebrationKind
    ) -> AnyShapeStyle {
        if kind == .rainbowSeven {
            return AnyShapeStyle(
                AngularGradient(
                    colors: [
                        .red,
                        .orange,
                        .yellow,
                        .green,
                        .cyan,
                        .blue,
                        .purple,
                        .pink,
                        .red
                    ],
                    center: .center
                )
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white,
                    .yellow,
                    .orange,
                    .yellow,
                    .white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func titleStyle(
        for kind: SlotResultCelebrationKind
    ) -> AnyShapeStyle {
        if kind == .rainbowSeven {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .red,
                        .orange,
                        .yellow,
                        .green,
                        .cyan,
                        .blue,
                        .purple,
                        .pink
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }

        return AnyShapeStyle(
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
    }

    private func rainbowColor(
        at fraction: CGFloat
    ) -> Color {
        let colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .cyan,
            .blue,
            .purple,
            .pink
        ]

        let index =
            min(
                Int(
                    fraction
                    * CGFloat(colors.count)
                ),
                colors.count - 1
            )

        return colors[index]
    }

    private func play() {
        progress = 0
        overlayOpacity = 1
        ringScale = 0.35
        ringOpacity = 1
        titleScale = 0.55

        withAnimation(
            .easeOut(duration: 2.75)
        ) {
            progress = 1
        }

        withAnimation(
            .spring(
                response: 0.40,
                dampingFraction: 0.54
            )
        ) {
            ringScale = 1.35
            titleScale = 1
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.38
        ) {
            withAnimation(
                .easeOut(duration: 0.65)
            ) {
                ringOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.85
        ) {
            withAnimation(
                .easeOut(duration: 0.75)
            ) {
                overlayOpacity = 0
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
                isFirstReelStopEnabled: true,
                cinematicPhase: .doorOpen,
                cinematicTrigger: 1,
                onFirstReelStop: {},
                onPush: {},
                onLeverChanged: { _ in },
                onLeverReleased: {}
            )
            .padding()
        }
    }
}
