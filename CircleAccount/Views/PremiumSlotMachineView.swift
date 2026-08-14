//
//  PremiumSlotMachineView.swift
//  CircleAccount
//

import SwiftUI
import UIKit

struct PremiumSlotMachineView: View {
    let symbols: [String]
    let resultTitle: String
    let resultSubtitle: String
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
    let expectationLevel: SlotExpectationLevel
    let reelSlipTrigger: Int
    let reelSlipIndex: Int
    let reelSlipIntensity: CGFloat
    let onFirstReelStop: () -> Void
    let onPush: () -> Void
    let onPremiumSequenceFinished: () -> Void
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
    @State private var pressedStopIndex: Int?
    @State private var premiumFlashOpacity = 0.0
    @State private var sparkBurstProgress: CGFloat = 0
    @State private var sparkBurstOpacity = 0.0
    @State private var glassSweepOffset: CGFloat = -1.2
    @State private var machineFlashOpacity = 0.0
    @State private var jackpotWhiteoutOpacity = 0.0
    @State private var frameSweepOffset: CGFloat = -1.4
    @State private var risingLightOffset: CGFloat = 1.2
    @State private var premiumBacklightPhase = 0.0
    @State private var premiumBurstTrigger = 0
    @State private var pseudoRepeatVisible = false
    @State private var isPremiumTypewriterVisible = false
    @State private var isVMovieVisible = false
    
    @State private var isGekiAtsuVisible = false
    @State private var isBonusLogoVisible = false
    @State private var premiumTicketVisible = false
    @State private var hasStartedMovieSequence = false
    @State private var hasPremiumTypewriterFinished = false
    @State private var hasStartedVMovie = false
    @State private var hasActivePremiumSpin = false
    @State private var pseudoRepeatCount = 0
    @State private var freezeEffectVisible = false
    @State private var freezeSequenceRunning = false
    @State private var resultCelebrationTrigger = 0
    @State private var isConfettiVisible = false
    @State private var confettiResetToken = 0
    
    @State private var cabinetStrobeTrigger = 0
    @State private var cabinetStrobeColor = Color.cyan
    @State private var cabinetLightingEnabled = true
    
    @State private var luckyLampMode: SlotLuckyLampMode = .off
    @State private var luckyLampTrigger = 0
    @State private var blackoutTrigger = 0
    @State private var hasPlayedBlackoutCharge = false
    @State private var pushChanceTrigger = 0
    @State private var pushPressTrigger = 0
    @State private var nextEpisodePreviewTrigger = 0
    @State private var pushPressed = false
    @State private var cabinetPushPressed = false
    @State private var cabinetPushTracking = false
    
    // SSR最終リールPUSH待機演出
    @State private var pushEmphasisPulse = false
    @State private var pushTextPulse = false
    @State private var pushRingPulse = false
    @State private var pushPromptEntrance: CGFloat = 0
    @State private var pushPromptGlow = false
    @State private var pushPromptSweep: CGFloat = -1.2
    @State private var pushButtonDepth: CGFloat = 0
    @State private var pushButtonSweep: CGFloat = -1.2
    @State private var pushEnergyRotation = 0.0
    
    // 実機風PUSH待機演出
    @State private var pushCameraBreath = false
    @State private var pushMicroVibration: CGFloat = 0
    @State private var pushImpactFlashOpacity = 0.0
    @State private var pushImpactRingScale: CGFloat = 0.55
    @State private var pushImpactRingOpacity = 0.0
    @State private var pushFlameBurstScale: CGFloat = 1.0
    @State private var pushFlameBurstOpacity = 0.0
    @State private var pushRevealBlackoutOpacity = 0.0
    @State private var pushLaunchFlashOpacity = 0.0
    @State private var pushEjectProgress: CGFloat = 0
    @State private var pushEjectScale: CGFloat = 1
    @State private var pushEjectOffsetY: CGFloat = 0
    @State private var pushIdlePulse = false
    @State private var pushLaunchReady = false
    @State private var pushLaunchToken = 0
    
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
    
    private var isRainbowJackpot: Bool {
        safeSymbols == ["🌈7", "🌈7", "🌈7"]
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            machineBody
            
            // 筐体Overlayは常駐させ、レバーON時にView階層を入れ替えない。
            authenticCabinetOverlay
                .zIndex(51)
            
            premiumCRTBlackoutOverlay
                .allowsHitTesting(false)
                .zIndex(4000)
            
            if isGekiAtsuVisible || isPremiumTypewriterVisible || isVMovieVisible || premiumTicketVisible || isBonusLogoVisible {
                premiumEffectArea
                    .allowsHitTesting(false)
                    .zIndex(5000)
            }
            
            
            if isPushVisible && isPushEnabled && !pushPressed && pushLaunchReady {
                PremiumPushEmphasisOverlay(
                    textPulse: pushTextPulse,
                    ringPulse: pushRingPulse,
                    entranceProgress: pushPromptEntrance,
                    glowPulse: pushPromptGlow,
                    sweepProgress: pushPromptSweep
                )
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.82)))
                .offset(x: 18)
                .zIndex(6001)
            }

            // 既存のPUSHは一つだけ。暗転・演出より常に手前で描画する。
            cabinetPushHitArea
                .zIndex(6002)

            SlotSoundControlView(
                isEnabled: $slotSoundEnabled,
                volume: $slotSoundVolume,
                glowColor: .orange
            )
            .frame(
                maxWidth: 370,
                maxHeight: .infinity,
                alignment: .topLeading
            )
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .trailing
            )
            .offset(x: -10, y: -11)
            
            // 最終右リール停止専用PUSH。
            // 最前面に独立したButtonを置き、装飾Overlayにタップを奪われないようにする。
            if false && isPushVisible {
                Button(action: handlePremiumPush) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(pushImpactFlashOpacity))
                            .frame(width: 176, height: 176)
                            .blur(radius: 2)
                            .blendMode(.screen)
                        
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white,
                                        .yellow,
                                        .orange,
                                        .red,
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 10
                            )
                            .frame(width: 170, height: 170)
                            .scaleEffect(pushImpactRingScale)
                            .opacity(pushImpactRingOpacity)
                            .shadow(color: .red, radius: 22)
                            .blendMode(.screen)
                        
                        ForEach(0..<2, id: \.self) { index in
                            Circle()
                                .stroke(
                                    index == 0
                                    ? Color.red.opacity(0.90)
                                    : Color.orange.opacity(0.72),
                                    lineWidth: index == 0 ? 5 : 3
                                )
                                .frame(
                                    width: index == 0 ? 154 : 136,
                                    height: index == 0 ? 154 : 136
                                )
                                .scaleEffect(
                                    pushRingPulse
                                    ? (index == 0 ? 1.48 : 1.34)
                                    : 0.86
                                )
                                .opacity(pushRingPulse ? 0 : 0.52)
                        }
                        
                        ZStack {
                            // 炎とボタン本体だけを独立して動かす。
                            ZStack {
                                ZStack {
                                    Image("PremiumPushFlame")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 166, height: 166)
                                        .rotationEffect(.degrees(pushEnergyRotation))
                                        .scaleEffect(
                                            pushEmphasisPulse ? 1.045 : 0.985
                                        )
                                        .opacity(
                                            pushPromptGlow ? 1.0 : 0.78
                                        )
                                        .brightness(
                                            pushPromptGlow ? 0.12 : 0
                                        )
                                        .shadow(
                                            color: Color.red.opacity(0.96),
                                            radius: pushPromptGlow ? 22 : 13
                                        )
                                        .shadow(
                                            color: Color.orange.opacity(0.74),
                                            radius: pushPromptGlow ? 30 : 18
                                        )
                                        .blendMode(.screen)
                                    
                                    Image("PremiumPushFlame")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 154, height: 154)
                                        .rotationEffect(
                                            .degrees(-pushEnergyRotation * 0.62)
                                        )
                                        .opacity(
                                            pushPromptGlow ? 0.72 : 0.44
                                        )
                                        .blur(radius: 1.2)
                                        .blendMode(.screen)
                                }
                                .offset(y: -15)
                                .scaleEffect(
                                    x: pushFlameBurstScale,
                                    y: 0.94 * pushFlameBurstScale
                                )
                                .opacity(
                                    max(
                                        pushFlameBurstOpacity,
                                        pushPromptGlow ? 1.0 : 0.84
                                    )
                                )
                                .mask {
                                    ZStack {
                                        Circle()
                                            .stroke(lineWidth: 52)
                                            .frame(width: 158, height: 158)
                                        
                                        Circle()
                                            .stroke(lineWidth: 30)
                                            .frame(width: 138, height: 138)
                                    }
                                }
                                
                                Image("PremiumPushButtonCore")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 152, height: 152)
                                    .offset(
                                        y: -4 + pushButtonDepth * 9
                                    )
                                    .scaleEffect(
                                        x: 1.0,
                                        y: 1.0 - pushButtonDepth * 0.11,
                                        anchor: .bottom
                                    )
                                    .scaleEffect(
                                        pushEmphasisPulse ? 1.03 : 0.99
                                    )
                                    .brightness(
                                        pushButtonDepth > 0 ? -0.12 :
                                            (pushPromptGlow ? 0.07 : 0)
                                    )
                                    .shadow(
                                        color: Color.red.opacity(0.90),
                                        radius: pushPromptGlow ? 14 : 8
                                    )
                                
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.66),
                                        .yellow.opacity(0.42),
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(width: 78, height: 28)
                                .rotationEffect(.degrees(-24))
                                .offset(
                                    x: pushButtonSweep * 72,
                                    y: -5 + pushButtonSweep * 16
                                )
                                .blur(radius: 3)
                                .blendMode(.screen)
                                .mask(
                                    Circle()
                                        .frame(width: 138, height: 138)
                                        .offset(y: -4)
                                )
                            }
                            .scaleEffect(0.54 + pushEjectProgress * 0.56)
                            .offset(y: 46 - pushEjectProgress * 46)
                            .rotation3DEffect(
                                .degrees(Double((1 - pushEjectProgress) * 28)),
                                axis: (x: 1, y: 0, z: 0),
                                perspective: 0.72
                            )
                        }
                        .frame(width: 196, height: 178)
                    }
                    .shadow(
                        color: Color.black.opacity(0.92),
                        radius: 12 + pushEjectProgress * 18,
                        y: 8 + pushEjectProgress * 12
                    )
                    .shadow(color: Color.red.opacity(0.90), radius: 20)
                    .shadow(color: Color.purple.opacity(0.72), radius: 12)
                    .opacity(Double(pushEjectProgress))
                    .contentShape(
                        RoundedRectangle(
                            cornerRadius: 42,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isPushEnabled || !pushLaunchReady || pushPressed)
                .allowsHitTesting(isPushEnabled && pushLaunchReady && !pushPressed)
                .accessibilityLabel("最後の右リールを止めるPUSHボタン")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard isPushEnabled else { return }
                            SlotHapticManager.shared.beginPushHold()
                        }
                        .onEnded { _ in
                            SlotHapticManager.shared.endPushHold()
                        }
                )
                .offset(x: -18, y: 180)
                .zIndex(250)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
        .scaleEffect(
            x:
                machinePulse
            ? 1.012
            : 1.0,
            y:
                machinePulse
            ? 0.992
            : 1.0,
            anchor: .center
        )
        .rotationEffect(.degrees(machineTiltDegrees))
        .offset(
            x: machineShakeX,
            y: machineDropY
        )
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
            resetLightingEffects(resumeForSpin: false)
            SlotHapticManager.shared.endPushHold()
            SlotHapticManager.shared.endMoviePulse()
            SlotSoundManager.shared.setDefaultJackpotSoundEnabled(true)
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
                resetLightingEffects(resumeForSpin: true)
                SlotSoundManager.shared.setDefaultJackpotSoundEnabled(
                    !isRainbowJackpot
                )
                hasActivePremiumSpin = true
                isGekiAtsuVisible = false
                isPremiumTypewriterVisible = false
                isVMovieVisible = false
                
                isBonusLogoVisible = false
                premiumTicketVisible = false
                hasStartedMovieSequence = false
                hasPremiumTypewriterFinished = false
                hasStartedVMovie = false
                hasPlayedBlackoutCharge = false
                
                prepareDisplaySymbols()
                machineDropY = 0
                machineTiltDegrees = 0
            } else if stoppedReelCount == 0 {
                effectSequenceToken += 1
                resetLightingEffects(resumeForSpin: false)
            }
        }
        .onChange(of: blackoutTrigger) { _, newTrigger in
            guard newTrigger > 0 else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                guard blackoutTrigger == newTrigger else { return }
                SlotSoundManager.shared.playGekiatsu()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.50) {
                guard isRainbowJackpot,
                      hasActivePremiumSpin,
                      !hasPlayedBlackoutCharge else {
                    return
                }
                
                hasPlayedBlackoutCharge = true
                SlotSoundManager.shared.playBlackoutCharge()
            }
        }
        .onChange(of: isPushVisible) { _, visible in
            if visible {
                pushPressed = false
                SlotSoundManager.shared.playPushAppear()
                pushChanceTrigger += 1
                startPushEmphasis()
            } else {
                pushPressed = false
                stopPushEmphasis()
            }
        }
        .onChange(of: cinematicPhase) { _, phase in
            switch phase {
            case .kyuiin:
                if safeSymbols == ["🌈7", "🌈7", "🌈7"] {
                    luckyLampMode = .premium
                    luckyLampTrigger += 1
                    
                } else {
                    luckyLampMode = .gold
                    luckyLampTrigger += 1
                }
                
            case .pushStandby:
                playPushStandbyCabinetShake()
                
            case .silentFreeze:
                SlotSoundManager.shared.playBlackoutCharge()
                
            case .finalSilence:
                if isRainbowJackpot,
                   hasActivePremiumSpin,
                   !hasStartedMovieSequence {
                    hasStartedMovieSequence = true
                    isPremiumTypewriterVisible = true
                } else if !isRainbowJackpot {
                    nextEpisodePreviewTrigger += 1
                }
                
            case .doorOpen:
                guard isRainbowJackpot,
                      hasActivePremiumSpin,
                      hasPremiumTypewriterFinished,
                      !hasStartedVMovie else {
                    break
                }
                
                hasStartedVMovie = true
                hideInitialEffectsForVMovie()
                isVMovieVisible = true
                SlotHapticManager.shared.beginMoviePulse()
                SlotSoundManager.shared.playVMovieSequenceSounds()
                
            case .idle:
                SlotHapticManager.shared.endMoviePulse()
                SlotSoundManager.shared.stopBlackoutCharge()
                isGekiAtsuVisible = false
                isPremiumTypewriterVisible = false
                isVMovieVisible = false
                
                isBonusLogoVisible = false
                premiumTicketVisible = false
                hasPremiumTypewriterFinished = false
                hasStartedVMovie = false
                
            default:
                break
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
                    isConfettiVisible = false
                    
                    luckyLampMode = .off
                    lcdPresentation = nil
                    spinEffectPlan = .normal
                    effectSequenceToken += 1
                    SlotSoundManager.shared.stopSpin()
                    
                }
                return
            }
            
            playStopImpact(stoppedCount: newValue)
            if newValue == 1 {
                lightLuckyLamp()
            }
            
            if newValue == 2,
               isRainbowJackpot {
                playGekiAtsuSequence()
            }
            
            if newValue >= 3 {
                if isRainbowJackpot {
                    return
                }
                
                playFinalResultSequence()
            }
        }
    }
    
    private var authenticCabinetOverlay: some View {
        AuthenticPachislotCabinetOverlay(
            trigger: cabinetStrobeTrigger,
            glowColor: cabinetStrobeColor,
            isSpinning: isSpinning,
            stoppedReelCount: stoppedReelCount,
            lightingEnabled: cabinetLightingEnabled
        )
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
    
    private var premiumStatusTextOnly: some View {
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
        .transaction { transaction in
            transaction.animation = nil
        }
    }
    
    
    private var premiumCRTBlackoutOverlay: some View {
        PremiumCRTBlackoutOverlay(
            phase: cinematicPhase,
            trigger: cinematicTrigger,
            glowColor: machineGlow
        )
        .frame(width: 370, height: 320)
        .mask {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 348, height: 300)
                .offset(x: -5, y: 10)
        }
        .offset(y: -5)
    }
    private var premiumEffectArea: some View {
        GeometryReader { geometry in
            let displaySize = premiumLCDDisplaySize(in: geometry)
            let displayOffset = premiumLCDDisplayOffset

            ZStack {
                Color.black
                
                if isGekiAtsuVisible {
                    EguchiCustomGekiAtsuView()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .transition(.opacity)
                }
                
                if isPremiumTypewriterVisible {
                    PremiumTypewriterOverlay {
                        guard isPremiumTypewriterVisible else { return }

                        isPremiumTypewriterVisible = false
                        SlotSoundManager.shared.suppressNextSpinStartSound()
                        hasPremiumTypewriterFinished = true
                    }
                    .frame(
                        width: displaySize.width,
                        height: displaySize.height
                    )
                    .mask {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(
                                width: displaySize.width,
                                height: displaySize.height - 20
                            )
                            .offset(y: 20)
                    }
                }
                
                if isVMovieVisible {
                    premiumCabinetMovieOverlay
                }
                
                if premiumTicketVisible {
                    premiumTicketContent(in: geometry)
                        .transition(.opacity)
                }

                if isBonusLogoVisible {
                    PremiumBonusConfirmedOverlay {
                        guard isBonusLogoVisible else { return }

                        withAnimation(.easeOut(duration: 0.25)) {
                            isBonusLogoVisible = false
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            guard premiumTicketVisible else { return }
                            onPremiumSequenceFinished()
                        }
                    }
                    .onAppear {
                        premiumTicketVisible = true
                    }
                }
            }
            .frame(
                width: displaySize.width,
                height: displaySize.height
            )
            .mask {
                premiumLCDDisplayMask(in: geometry)
            }
            .clipped()
            .offset(displayOffset)
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .frame(
            width: 370,
            height: 326
        )
        .offset(
            x: 0,
            y: 11
        )
    }
    
    
    private func premiumLCDDisplayMask(
        in geometry: GeometryProxy
    ) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .frame(
                width: premiumLCDDisplaySize(in: geometry).width,
                height: premiumLCDDisplaySize(in: geometry).height
            )
            .offset(y: 10)
    }

    private func premiumLCDDisplaySize(
        in geometry: GeometryProxy
    ) -> CGSize {
        let videoRightMaskAdjustment: CGFloat = 10
        let videoBottomMaskAdjustment: CGFloat = 12
        let videoTopMaskAdjustment: CGFloat = 12

        return CGSize(
            width: geometry.size.width - 12 - videoRightMaskAdjustment,
            height: geometry.size.height
                - 12
                - videoBottomMaskAdjustment
                + videoTopMaskAdjustment
        )
    }

    private var premiumLCDDisplayOffset: CGSize {
        let videoRightMaskAdjustment: CGFloat = 10
        let videoBottomMaskAdjustment: CGFloat = 12
        let videoTopMaskAdjustment: CGFloat = 12

        return CGSize(
            width: -videoRightMaskAdjustment / 2,
            height: -(videoBottomMaskAdjustment + videoTopMaskAdjustment) / 2
        )
    }
    
    private func premiumTicketContent(
        in geometry: GeometryProxy
    ) -> some View {
        let cardDesignWidth: CGFloat = 320
        let cardDesignHeight: CGFloat = 410
        let contentInset: CGFloat = 12
        let availableWidth = max(
            0,
            geometry.size.width - contentInset * 2
        )
        let availableHeight = max(
            0,
            geometry.size.height - contentInset * 2
        )
        let rewardCardScale = min(
            availableWidth / cardDesignWidth,
            availableHeight / cardDesignHeight
        )
        
        return ZStack {
            Color.black
            
            SlotEffectsView(
                stage: .cardReveal,
                heatLevel: .premium,
                resultTitle: resultTitle,
                resultSubtitle: resultSubtitle,
                showsParticles: false
            )
            .frame(
                width: cardDesignWidth,
                height: cardDesignHeight
            )
            .scaleEffect(rewardCardScale)
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
    }
    
    private var premiumCabinetMovieOverlay: some View {
        BundleMovieOverlay(
            movieName: "VMovie",
            fadeDuration: 0,
            contentMode: .fill,
            isOpaquePresentation: true,
            onFinished: {
                SlotHapticManager.shared.endMoviePulse()
                SlotHapticManager.shared.movieVCompletionImpact()
                guard isVMovieVisible else { return }
                isVMovieVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    guard hasActivePremiumSpin, !premiumTicketVisible else { return }
                    withAnimation(.easeIn(duration: 0.20)) {
                        premiumTicketVisible = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.20) {
                        guard hasActivePremiumSpin, premiumTicketVisible else { return }
                        onPremiumSequenceFinished()
                    }
                }
            }
        )
        .compositingGroup()
        .allowsHitTesting(false)
    }
    
    private var machineBody: some View {
        ZStack {
            Image("PremiumCabinet")
                .resizable()
                .frame(width: 384, height: 576)
                .scaleEffect(1.0)
                .offset(x: -2, y: 22)
                .allowsHitTesting(false)

            

            premiumStatusTextOnly
                .frame(width: 300)
                .offset(y: -101)

            SlotLuckyLampView(
                mode: isSpinning && stoppedReelCount == 0
                    ? .off
                    : luckyLampMode,
                trigger: luckyLampTrigger
            )
            .scaleEffect(x: 0.78, y: 0.56)
            .offset(x: -113, y: -58)

            reelHousing
                .frame(width: 280, height: 162)
                .offset(x: -21, y: 62)
                .contentShape(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .onTapGesture {
                    handleReelAreaTap()
                }
                .accessibilityLabel("リール停止エリア")
                .accessibilityHint("タップするたびに左、中、右の順で停止します")

            stopButtonInputOverlay

        }
        .frame(width: 370, height: 520)
        .shadow(color: Color.black.opacity(0.72), radius: 22, y: 15)
    }

    private func playGekiAtsuSequence() {
        SlotSoundManager.shared.playGekiatsu()
        withAnimation(.easeIn(duration: 0.08)) {
            isGekiAtsuVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation(.easeOut(duration: 0.18)) {
                isGekiAtsuVisible = false
            }
        }
    }

    private func hideInitialEffectsForVMovie() {
        machineFlashOpacity = 0
        jackpotWhiteoutOpacity = 0
        premiumFlashOpacity = 0
        sparkBurstOpacity = 0
        stopLineFlashOpacity = 0
        pseudoRepeatVisible = false
        freezeEffectVisible = false
        freezeSequenceRunning = false
        isConfettiVisible = false
        resultPauseOpacity = 0
        resultPauseTextOpacity = 0
        lcdPresentation = nil
    }

    private func playPushStandbyCabinetShake() {
        machineShakeX = 0
        withAnimation(.linear(duration: 0.055)) { machineShakeX = -5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.linear(duration: 0.055)) { machineShakeX = 5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.linear(duration: 0.07)) { machineShakeX = -3 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) { machineShakeX = 0 }
        }
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
                reelSlipTrigger: reelSlipTrigger,
            reelSlipIndex: reelSlipIndex,
            reelSlipIntensity: reelSlipIntensity,
            showsHousingDecoration: false
        )
    }

    private var stopButtonInputOverlay: some View {
        HStack(spacing: 23) {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    handleStopInput(index: index)
                } label: {
                    Circle()
                        .fill(
                            Color.white.opacity(0.001)
                        )
                        .frame(width: 54, height: 54)
                        .scaleEffect(
                            pressedStopIndex == index ? 0.86 : 1.0
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isStopInputEnabled(index: index))
                .accessibilityLabel(
                    ["左リール停止", "中リール停止", "右リール停止"][index]
                )
            }
        }
        .frame(width: 208, height: 60)
        .offset(x: -40, y: 178)
    }

    private func isStopInputEnabled(index: Int) -> Bool {
        isSpinning
            && isFirstReelStopEnabled
            && stoppedReelCount == index
            && index < 3
    }

    private func handleReelAreaTap() {
        handleStopInput(index: stoppedReelCount)
    }

    // 筐体画像に元から描かれている紫PUSH専用の透明Hit Area。
    // 通常時は完全透明で、別ボタンの外観は一切描画しない。
    private var cabinetPushHitArea: some View {
        let bonusPushPresented = isPushVisible && isPushEnabled
        let bonusPushReady = bonusPushPresented && pushLaunchReady
        let regularPushReady = isStopInputEnabled(index: stoppedReelCount)
        return Circle()
            .fill(Color.clear)
            .frame(width: 94, height: 64)
            .contentShape(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                ZStack {
                    Image("push_button_premium")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 62)
                        .clipped()
                        .offset(x: 17, y: 4)
                        .opacity(
                            bonusPushPresented
                                ? Double(1 - pushEjectProgress)
                                : 1
                        )

                    Image("PremiumPushButtonCore")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 94, height: 64)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .offset(
                            x: 17,
                            y: 6 + (bonusPushPresented
                                ? (1 - pushEjectProgress) * 14 - 12
                                : 14)
                        )
                        .opacity(
                            bonusPushPresented && pushEjectProgress > 0
                                ? 1
                                : 0
                        )
                        .zIndex(1)
                }
                    .brightness(cabinetPushPressed ? -0.13 : 0)
                    .contrast(1.0)
                    .shadow(
                        color: Color.black.opacity(0.52),
                        radius: 5,
                        y: 3
                    )
                    .shadow(
                        color: bonusPushPresented
                            ? Color.white.opacity(
                                pushLaunchReady
                                    ? (pushIdlePulse ? 0.22 : 0.14)
                                    : 0.18 * sin(Double(pushEjectProgress) * .pi)
                            )
                            : .clear,
                        radius: pushLaunchReady
                            ? (pushIdlePulse ? 8 : 5)
                            : 2 + CGFloat(
                                5 * sin(Double(pushEjectProgress) * .pi)
                            )
                    )
                    .opacity(1)
                    .allowsHitTesting(false)
            }
            .scaleEffect(
                cabinetPushPressed
                    ? 0.90
                    : 1.0
            )
            .offset(
                x: 101,
                y: 178
                    + (cabinetPushPressed ? 2 : 0)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard (regularPushReady || bonusPushReady),
                              !cabinetPushTracking else {
                            return
                        }

                        cabinetPushTracking = true
                        withAnimation(.easeOut(duration: 0.055)) {
                            cabinetPushPressed = true
                        }
                        if bonusPushReady {
                            SlotHapticManager.shared.beginPushHold()
                        } else {
                            SlotHapticManager.shared.regularStopPushPress()
                        }
                    }
                    .onEnded { _ in
                        let shouldActivate = cabinetPushTracking
                        SlotHapticManager.shared.endPushHold()

                        cabinetPushTracking = false
                        withAnimation(
                            .spring(response: 0.20, dampingFraction: 0.62)
                        ) {
                            cabinetPushPressed = false
                        }

                        guard shouldActivate else { return }
                        if bonusPushReady {
                            handlePremiumPush()
                        } else if regularPushReady {
                            handleStopInput(index: stoppedReelCount)
                        }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("紫PUSH リール停止")
            .accessibilityAddTraits(.isButton)
    }

    private func handleStopInput(index: Int) {
        guard isStopInputEnabled(index: index) else {
            return
        }

        playStopButtonPressAnimation(index: index)

        if index == 0 {
            SlotSoundManager.shared.playFirstStop()
        }

        onFirstReelStop()
    }

    private func playStopButtonPressAnimation(index: Int) {
        withAnimation(.easeOut(duration: 0.06)) {
            pressedStopIndex = index
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            guard pressedStopIndex == index else { return }

            withAnimation(
                .spring(response: 0.20, dampingFraction: 0.58)
            ) {
                pressedStopIndex = nil
            }
        }
    }

    private var firstReelStopButton: some View {
        Button {
            guard isFirstReelStopEnabled else { return }
            
            SlotSoundManager.shared.playFirstStop()
            
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
            expectationLevel: expectationLevel,
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
        guard presentation != .reach else { return }

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

    }

    private func playLeverLaunchImpact() {
        cabinetStrobeColor = heatLevel == .premium ? .purple : .cyan
        cabinetStrobeTrigger += 1
        SlotHapticManager.shared.leverLock()

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

    private func playJackpot() {
        playJackpotWhiteout()

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeOut(duration: 0.30)) {
                premiumFlashOpacity = 0
                machineShakeX = 0
            }
        }
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

    private func handlePremiumPush() {
        guard isPushVisible,
              isPushEnabled,
              !pushPressed else {
            return
        }

        pushPressed = true

        SlotSoundManager.shared.playPushPress()
        SlotSoundManager.shared.suppressNextPushSound()
        SlotHapticManager.shared.premiumFinalPush()

        withAnimation(.easeIn(duration: 0.085)) {
            pushButtonDepth = 1
            pushMicroVibration = -1.4
        }

        // ほんの一瞬だけ「溜め」を作る
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            pushImpactFlashOpacity = 1
            pushImpactRingOpacity = 1
            pushImpactRingScale = 0.58
            pushFlameBurstScale = 0.96
            pushFlameBurstOpacity = 1

            withAnimation(.easeOut(duration: 0.16)) {
                pushImpactFlashOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.34)) {
                pushImpactRingScale = 1.75
                pushImpactRingOpacity = 0
                pushFlameBurstScale = 1.26
                pushFlameBurstOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(
                .spring(
                    response: 0.22,
                    dampingFraction: 0.46
                )
            ) {
                pushButtonDepth = 0
            }
        }

        stopPushEmphasis()
        pushPressTrigger += 1

        
        
        withAnimation(.easeOut(duration: 0.045)) {
            machineShakeX = -16
            machineDropY = 7
            machinePulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.055) {
            withAnimation(.easeInOut(duration: 0.055)) {
                machineShakeX = 14
                machineDropY = -3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.060)) {
                machineShakeX = -8
                machineDropY = 2
            }
        }

        // 押し込みを見せてからControllerへ通知。
        // この通知で初めて最後の右リールが停止する。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onPush()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.56
                )
            ) {
                machineShakeX = 0
                machineDropY = 0
                machinePulse = false
            }
        }
    }

    private func startPushEmphasis() {
        pushLaunchToken += 1
        let launchToken = pushLaunchToken

        pushEmphasisPulse = false
        pushTextPulse = false
        pushRingPulse = false
        pushPromptEntrance = 0
        pushPromptGlow = false
        pushPromptSweep = -1.2
        pushButtonDepth = 0
        pushButtonSweep = -1.2
        pushEnergyRotation = 0
        pushCameraBreath = false
        pushMicroVibration = 0
        pushImpactFlashOpacity = 0
        pushImpactRingScale = 0.55
        pushImpactRingOpacity = 0
        pushFlameBurstScale = 1.0
        pushFlameBurstOpacity = 0
        pushRevealBlackoutOpacity = 0
        pushLaunchFlashOpacity = 0
        pushEjectProgress = 0
        pushEjectScale = 1
        pushEjectOffsetY = 0
        pushIdlePulse = false
        pushLaunchReady = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            guard launchToken == pushLaunchToken,
                  isPushVisible,
                  isPushEnabled else {
                return
            }

            withAnimation(.easeOut(duration: 0.36)) {
                pushEjectProgress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                guard launchToken == pushLaunchToken,
                      isPushVisible,
                      isPushEnabled else {
                    return
                }
                pushLaunchReady = true
            }
        }

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.warning)

        withAnimation(
            .easeInOut(duration: 0.46)
                .repeatForever(autoreverses: true)
        ) {
            pushEmphasisPulse = true
        }

        withAnimation(
            .easeInOut(duration: 0.28)
                .repeatForever(autoreverses: true)
        ) {
            pushTextPulse = true
        }

        withAnimation(
            .easeOut(duration: 0.92)
                .repeatForever(autoreverses: false)
        ) {
            pushRingPulse = true
        }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.54)) {
            pushPromptEntrance = 1
        }

        withAnimation(
            .easeInOut(duration: 0.48)
                .repeatForever(autoreverses: true)
        ) {
            pushPromptGlow = true
        }

        withAnimation(
            .linear(duration: 1.25)
                .repeatForever(autoreverses: false)
        ) {
            pushPromptSweep = 1.2
        }

        withAnimation(.linear(duration: 1.10).repeatForever(autoreverses: false)) {
            pushButtonSweep = 1.2
        }

        withAnimation(.linear(duration: 2.20).repeatForever(autoreverses: false)) {
            pushEnergyRotation = 360
        }

        withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
            pushCameraBreath = true
        }

        cabinetStrobeColor = .red
        cabinetStrobeTrigger += 1
    }

    private func stopPushEmphasis() {
        pushLaunchToken += 1
        withAnimation(.easeOut(duration: 0.16)) {
            pushEmphasisPulse = false
            pushTextPulse = false
            pushRingPulse = false
            pushPromptEntrance = 0
            pushPromptGlow = false
            pushPromptSweep = -1.2
            pushButtonDepth = 0
            pushButtonSweep = -1.2
            pushEnergyRotation = 0
            pushCameraBreath = false
            pushMicroVibration = 0
            pushImpactFlashOpacity = 0
            pushImpactRingScale = 0.55
            pushImpactRingOpacity = 0
            pushFlameBurstScale = 1.0
            pushFlameBurstOpacity = 0
            pushRevealBlackoutOpacity = 0
            pushLaunchFlashOpacity = 0
            pushEjectProgress = 0
            pushEjectScale = 1
            pushEjectOffsetY = 0
            pushIdlePulse = false
            pushLaunchReady = false
        }
    }

    private func resetLightingEffects(resumeForSpin: Bool) {
        effectSequenceToken += 1
        finalResultSequenceToken += 1
        pushLaunchToken += 1
        confettiResetToken += 1

        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            lampPulse = false
            borderRotation = 0
            luckyLampMode = .off
            premiumFlashOpacity = 0
            sparkBurstProgress = 0
            sparkBurstOpacity = 0
            glassSweepOffset = -1.2
            machineFlashOpacity = 0
            jackpotWhiteoutOpacity = 0
            stopLineFlashOpacity = 0
            flashingStopIndex = nil
            frameSweepOffset = -1.4
            risingLightOffset = 1.2
            premiumBacklightPhase = 0
            pushImpactFlashOpacity = 0
            pushImpactRingOpacity = 0
            pushFlameBurstOpacity = 0
            pushRevealBlackoutOpacity = 0
            pushLaunchFlashOpacity = 0
            isConfettiVisible = false
            cabinetPushPressed = false
            cabinetPushTracking = false
        }
        stopPushEmphasis()

        if resumeForSpin {
            startContinuousAnimations()
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
        // LUCKYランプは最初の左リールを止めた瞬間に点灯。
        switch safeSymbols {
        case ["🌈7", "🌈7", "🌈7"]:
            luckyLampMode = .premium
            luckyLampTrigger += 1
            SlotHapticManager.shared.lampIgnition(rank: .lr)

        case ["7", "7", "7"]:
            luckyLampMode = expectationLevel == .premium ? .rainbow : .gold
            luckyLampTrigger += 1
            SlotHapticManager.shared.lampIgnition(
                rank: expectationLevel == .premium ? .ssr : .sr
            )

        default:
            // プレミアムルートのその他図柄は金色。
            if expectationLevel == .premium {
                luckyLampMode = .rainbow
                luckyLampTrigger += 1
                SlotHapticManager.shared.lampIgnition(rank: .ssr)
            } else {
                luckyLampMode = .off
            }
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
            deadline: .now() + 0.58
        ) {
            guard token == finalResultSequenceToken else { return }

            SlotHapticManager.shared.bonusLock(isLR: isRainbowJackpot)

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
            deadline: .now() + 0.655
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
            deadline: .now() + 0.74
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
            // VMovie終了後のRewardCard経路で演出するため、
            // ここでは何もしない。
            return
        }
       
         else if safeSymbols == ["7", "7", "7"] {
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
        guard !isRainbowJackpot else { return }
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

        withAnimation(.easeOut(duration: 0.18)) {
            jackpotWhiteoutOpacity = 0
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





private struct PremiumPushEmphasisOverlay: View {
    let textPulse: Bool
    let ringPulse: Bool
    let entranceProgress: CGFloat
    let glowPulse: Bool
    let sweepProgress: CGFloat

    private let arrowCount = 3

    var body: some View {
        GeometryReader { proxy in
            let promptWidth = min(proxy.size.width * 0.78, 294)
            let promptHeight = min(proxy.size.height * 0.38, 198)

            // 矢印画像だけをPUSH文字より小さく表示する。
            // Assets側の余白を考慮し、横幅・高さを独立して調整。
            let arrowWidth = promptWidth * 0.31
            let arrowHeight = promptHeight * 0.28
            let arrowOffsetX = proxy.size.width * 0.29
            let arrowOffsetY = proxy.size.height * 0.20 + 6

            ZStack {
                Color.black.opacity(textPulse ? 0.48 : 0.40)

                RadialGradient(
                    colors: [
                        Color.white.opacity(textPulse ? 0.13 : 0.06),
                        Color(red: 0.80, green: 0.62, blue: 0.20)
                            .opacity(0.07),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.70, y: 0.76),
                    startRadius: 2,
                    endRadius: 170
                )
                .blendMode(.screen)

                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color(red: 0.92, green: 0.76, blue: 0.34),
                                    Color.white.opacity(0.20),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: CGFloat(3 - index)
                        )
                        .frame(
                            width: CGFloat(146 + index * 24),
                            height: CGFloat(146 + index * 24)
                        )
                        .scaleEffect(ringPulse ? 1.46 : 0.66)
                        .opacity(
                            ringPulse
                                ? 0
                                : Double(0.30 - Double(index) * 0.08)
                        )
                }

                ZStack {
                    // 「押せ！PUSH!!」本体。文字には強い白スイープを掛けず、
                    // 赤と金の質感をそのまま残す。
                    Image("PremiumPushPrompt")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: promptWidth,
                            height: promptHeight
                        )
                        .shadow(color: Color.black.opacity(0.46), radius: 8, y: 3)

                    // 矢印の常時点灯レイヤー。
                    Image("PremiumPushArrows")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: arrowWidth,
                            height: arrowHeight
                        )
                        .offset(x: arrowOffsetX, y: arrowOffsetY)
                        .opacity(glowPulse ? 0.76 : 0.54)
                        .brightness(glowPulse ? 0.10 : 0.02)
                        .shadow(color: Color.white.opacity(0.18), radius: 3)
                        .blendMode(.screen)

                    // 左→中央→右へLEDが走る実機風アニメーション。
                    TimelineView(
                        .animation(
                            minimumInterval: 1.0 / 30.0,
                            paused: false
                        )
                    ) { context in
                        let time = context.date.timeIntervalSinceReferenceDate

                        ZStack {
                            ForEach(0..<arrowCount, id: \.self) { index in
                                animatedArrowSegment(
                                    index: index,
                                    time: time,
                                    width: arrowWidth,
                                    height: arrowHeight
                                )
                            }

                            // 矢印だけを横切る鋭いハイライト。
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.98),
                                    Color(red: 0.95, green: 0.78, blue: 0.36),
                                    .white.opacity(0.82),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: 44, height: arrowHeight * 0.82)
                            .rotationEffect(.degrees(18))
                            .offset(x: movingArrowSweepX(time: time, width: arrowWidth))
                            .blur(radius: 2.2)
                            .blendMode(.screen)
                            .mask {
                                Image("PremiumPushArrows")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(
                                        width: arrowWidth,
                                        height: arrowHeight
                                    )
                            }
                        }
                    }
                    .frame(
                        width: arrowWidth,
                        height: arrowHeight
                    )
                    .offset(x: arrowOffsetX, y: arrowOffsetY)

                    // 中央から下へ落ちる衝撃光。矢印がPUSHを促すように見せる。
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(textPulse ? 0.88 : 0.48),
                                    Color.white.opacity(textPulse ? 0.24 : 0.10),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: arrowWidth * 0.48, height: 34)
                        .offset(
                            x: arrowOffsetX,
                            y: arrowOffsetY + arrowHeight * 0.32
                        )
                        .blur(radius: 8)
                        .opacity(textPulse ? 0.72 : 0.34)
                        .blendMode(.screen)
                }
                .scaleEffect(
                    0.56
                    + entranceProgress * 0.36
                    + (textPulse ? 0.035 : -0.008)
                )
                .opacity(Double(entranceProgress))
                .brightness(glowPulse ? 0.05 : 0)
                .shadow(
                    color: Color(red: 0.92, green: 0.76, blue: 0.34)
                        .opacity(glowPulse ? 0.72 : 0.28),
                    radius: glowPulse ? 14 : 7
                )
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * 0.54
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func animatedArrowSegment(
        index: Int,
        time: Double,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let cycleDuration = 0.84
        let stagger = cycleDuration / Double(arrowCount)
        let localTime = positiveRemainder(
            time - Double(index) * stagger,
            cycleDuration
        )
        let progress = localTime / cycleDuration

        // 0付近で鋭く点灯し、その後ゆっくり減衰。
        let pulse = pow(max(0, 1 - progress), 2.8)
        let secondaryPulse = max(
            0,
            sin(progress * .pi)
        )

        let scale = 0.96 + CGFloat(pulse) * 0.16
        let verticalDrop = CGFloat(secondaryPulse) * 7
        let segmentOpacity = 0.30 + pulse * 0.70

        return Image("PremiumPushArrows")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .mask {
                ZStack {
                    Color.clear

                    Rectangle()
                        .frame(
                            width: width / CGFloat(arrowCount),
                            height: height
                        )
                        .offset(
                            x:
                                (CGFloat(index) - 1)
                                * width
                                / CGFloat(arrowCount)
                        )
                }
                .frame(width: width, height: height)
            }
            .scaleEffect(scale, anchor: .center)
            .offset(y: verticalDrop)
            .opacity(segmentOpacity)
            .brightness(0.10 + pulse * 0.44)
            .contrast(1.08 + pulse * 0.26)
            .shadow(
                color: Color.white.opacity(0.42 + pulse * 0.58),
                radius: 2 + pulse * 8
            )
            .shadow(
                color: Color.yellow.opacity(0.58 + pulse * 0.42),
                radius: 7 + pulse * 14
            )
            .shadow(
                color: Color.red.opacity(0.60 + pulse * 0.36),
                radius: 12 + pulse * 20
            )
            .blendMode(.screen)
    }

    private func movingArrowSweepX(
        time: Double,
        width: CGFloat
    ) -> CGFloat {
        let duration = 1.16
        let progress = positiveRemainder(time, duration) / duration
        return -width * 0.62 + width * 1.24 * CGFloat(progress)
    }

    private func positiveRemainder(
        _ value: Double,
        _ divisor: Double
    ) -> Double {
        guard divisor > 0 else { return 0 }
        let remainder = value.truncatingRemainder(dividingBy: divisor)
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

private struct AuthenticPachislotCabinetOverlay: View {
    let trigger: Int
    let glowColor: Color
    let isSpinning: Bool
    let stoppedReelCount: Int
    let lightingEnabled: Bool

    @State private var flashOpacity = 0.0
    @State private var scanOffset: CGFloat = -1.2
    @State private var vibrationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // ブレーキ停止時の瞬間ストロボ
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(glowColor.opacity(lightingEnabled ? flashOpacity * 0.42 : 0), lineWidth: 3)
                .shadow(color: lightingEnabled ? glowColor.opacity(0.58) : .clear, radius: 10)
                .opacity(lightingEnabled ? flashOpacity : 0)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(lightingEnabled ? flashOpacity * 0.12 : 0),
                            glowColor.opacity(lightingEnabled ? flashOpacity * 0.055 : 0),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 155
                    )
                )
                .blendMode(.screen)

            // CRT風の走査線
            GeometryReader { proxy in
                VStack(spacing: 5) {
                    ForEach(0..<70, id: \.self) { _ in
                        Rectangle()
                            .fill(
                                Color.white.opacity(
                                    lightingEnabled
                                        ? (isSpinning ? 0.035 : 0.018)
                                        : 0
                                )
                            )
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
            guard lightingEnabled, newValue > 0 else { return }
            playStrobe()
        }
        .onChange(of: lightingEnabled) { _, enabled in
            guard !enabled else { return }
            flashOpacity = 0
            vibrationOffset = 0
            scanOffset = -1.2
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

    }

    private func playStrobe() {
        flashOpacity = 0.56

        withAnimation(.easeOut(duration: 0.16)) {
            flashOpacity = 0
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




private struct PremiumCRTBlackoutOverlay: View {
    let phase: SlotCinematicPhase
    let trigger: Int
    let glowColor: Color

    @State private var blackOpacity = 0.0
    @State private var flashOpacity = 0.0
    @State private var screenScaleX: CGFloat = 1
    @State private var screenScaleY: CGFloat = 1
    @State private var screenOpacity = 0.0
    @State private var lineScaleX: CGFloat = 1
    @State private var lineOpacity = 0.0
    @State private var dotOpacity = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(blackOpacity)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.98),
                                glowColor.opacity(0.78),
                                Color.white.opacity(0.94)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height + 20
                    )
                    .offset(y: 20)
                    .scaleEffect(
                        x: screenScaleX,
                        y: screenScaleY,
                        anchor: .center
                    )
                    .opacity(screenOpacity)
                    .blendMode(.screen)
                    .shadow(color: .white, radius: 22)
                    .shadow(color: glowColor, radius: 34)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white,
                                glowColor,
                                .white,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * 0.96,
                        height: 5
                    )
                    .scaleEffect(x: lineScaleX)
                    .opacity(lineOpacity)
                    .shadow(color: .white, radius: 12)
                    .shadow(color: glowColor, radius: 24)

                Circle()
                    .fill(Color.white)
                    .frame(width: 9, height: 9)
                    .opacity(dotOpacity)
                    .shadow(color: .white, radius: 14)
                    .shadow(color: glowColor, radius: 26)

                Color.white
                    .opacity(flashOpacity)
                    .blendMode(.screen)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .allowsHitTesting(false)
        .onAppear { playCurrentPhase() }
        .onChange(of: phase) { _, _ in playCurrentPhase() }
        .onChange(of: trigger) { _, _ in playCurrentPhase() }
    }

    private func reset() {
        blackOpacity = 0
        flashOpacity = 0
        screenScaleX = 1
        screenScaleY = 1
        screenOpacity = 0
        lineScaleX = 1
        lineOpacity = 0
        dotOpacity = 0
    }

    private func playCurrentPhase() {
        switch phase {
        case .silentFreeze:
            playCRTOff()

        case .finalSilence:
            blackOpacity = 1
            flashOpacity = 0
            screenOpacity = 0
            lineOpacity = 0
            dotOpacity = 0

        case .pushStandby:
            playCRTOn()

        default:
            reset()
        }
    }

    private func playCRTOff() {
        reset()
        flashOpacity = 1
        screenOpacity = 0.98
        blackOpacity = 0

        withAnimation(.easeOut(duration: 0.10)) {
            flashOpacity = 0
        }

        withAnimation(.easeIn(duration: 0.42).delay(0.08)) {
            screenScaleY = 0.012
            blackOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.08).delay(0.48)) {
            lineOpacity = 1
        }

        withAnimation(.easeIn(duration: 0.22).delay(0.64)) {
            lineScaleX = 0.018
            screenScaleX = 0.018
            screenOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.05).delay(0.84)) {
            lineOpacity = 0
            dotOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.13).delay(0.98)) {
            dotOpacity = 0
        }
    }

    private func playCRTOn() {
        blackOpacity = 1
        flashOpacity = 0
        screenScaleX = 0.018
        screenScaleY = 0.012
        screenOpacity = 0
        lineScaleX = 0.018
        lineOpacity = 0
        dotOpacity = 1

        withAnimation(.easeOut(duration: 0.08).delay(0.04)) {
            dotOpacity = 0
            lineOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.28).delay(0.10)) {
            lineScaleX = 1
            screenScaleX = 1
        }

        withAnimation(.easeOut(duration: 0.62).delay(0.36)) {
            screenScaleY = 1.08
            screenOpacity = 0.90
            blackOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.18).delay(0.90)) {
            lineOpacity = 0
            screenOpacity = 0
        }
    }
}

private struct PremiumBonusConfirmedOverlay: View {
    let onFinished: () -> Void

    @State private var backgroundOpacity = 0.0
    @State private var flashOpacity = 0.0
    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 0.48
    @State private var animationToken = 0

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.yellow.opacity(0.90),
                    Color.orange.opacity(0.58),
                    Color.red.opacity(0.30),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 340
            )
            .opacity(logoOpacity)
            .blendMode(.screen)
            .ignoresSafeArea()

            Image("PremiumBonusConfirmed")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: 340)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .shadow(color: .yellow.opacity(0.92), radius: 22)
                .shadow(color: .red.opacity(0.72), radius: 38)

            Color.white
                .opacity(flashOpacity)
                .blendMode(.screen)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .onAppear {
            play()
        }
        .onDisappear {
            animationToken += 1
        }
    }

    private func play() {
        animationToken += 1
        let token = animationToken

        backgroundOpacity = 0
        flashOpacity = 1
        logoOpacity = 0
        logoScale = 0.48

        withAnimation(.easeOut(duration: 0.10)) {
            backgroundOpacity = 0.55
            flashOpacity = 0
        }

        withAnimation(
            .spring(
                response: 0.38,
                dampingFraction: 0.56
            )
            .delay(0.08)
        ) {
            logoOpacity = 1
            logoScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            guard token == animationToken else { return }

            withAnimation(.easeOut(duration: 0.20)) {
                backgroundOpacity = 0
                logoOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            guard token == animationToken else { return }
            onFinished()
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
                resultTitle: "参加費無料券",
                resultSubtitle: "次回の活動で使用できます",
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
                expectationLevel: .premium,
                reelSlipTrigger: 1,
                reelSlipIndex: 2,
                reelSlipIntensity: 1.0,
                onFirstReelStop: {},
                onPush: {},
                onPremiumSequenceFinished: {},
                onLeverChanged: { _ in },
                onLeverReleased: {}
            )
            .padding()
        }
    }
}
