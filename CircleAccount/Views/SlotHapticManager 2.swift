import CoreHaptics
import UIKit

@MainActor
final class SlotHapticManager {
    static let shared = SlotHapticManager()

    enum LampRank {
        case sr
        case ssr
        case lr
    }

    private var engine: CHHapticEngine?
    private var lastLeverTime: CFTimeInterval = 0
    private var lastStopTimes = Array(repeating: CFTimeInterval(0), count: 3)
    private var pushHoldTimer: Timer?
    private var moviePulseTimer: Timer?
    private var moviePulseStep = 0

    private init() {
        prepare()
    }

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            if engine == nil {
                let newEngine = try CHHapticEngine()
                newEngine.playsHapticsOnly = true
                newEngine.isAutoShutdownEnabled = true
                newEngine.resetHandler = { [weak self] in
                    Task { @MainActor in
                        try? self?.engine?.start()
                    }
                }
                engine = newEngine
            }
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func leverLock() {
        let now = CACurrentMediaTime()
        guard now - lastLeverTime > 0.18 else { return }
        lastLeverTime = now

        play(
            events: [
                transient(time: 0, intensity: 0.48, sharpness: 0.82),
                transient(time: 0.055, intensity: 0.24, sharpness: 0.58)
            ],
            fallback: { impact(.rigid, intensity: 0.62) }
        )
    }

    func reelStop(index: Int, isFinal: Bool) {
        let safeIndex = min(max(index, 0), 2)
        let now = CACurrentMediaTime()
        guard now - lastStopTimes[safeIndex] > 0.16 else { return }
        lastStopTimes[safeIndex] = now

        let base = Float(0.42 + Double(safeIndex) * 0.10)
        var events = [transient(time: 0, intensity: base, sharpness: 0.92)]
        if isFinal {
            events.append(transient(time: 0.070, intensity: 0.72, sharpness: 0.62))
            events.append(transient(time: 0.155, intensity: 0.24, sharpness: 0.28))
        }
        play(events: events) {
            impact(isFinal ? .rigid : .light, intensity: CGFloat(base))
        }
    }

    func lampIgnition(rank: LampRank) {
        let events: [CHHapticEvent]
        switch rank {
        case .sr:
            events = [
                transient(time: 0, intensity: 0.42, sharpness: 0.40),
                continuous(time: 0.035, duration: 0.16, intensity: 0.22, sharpness: 0.18)
            ]
        case .ssr:
            events = [
                transient(time: 0, intensity: 0.54, sharpness: 0.48),
                continuous(time: 0.025, duration: 0.24, intensity: 0.32, sharpness: 0.22),
                transient(time: 0.25, intensity: 0.28, sharpness: 0.34)
            ]
        case .lr:
            events = [
                transient(time: 0, intensity: 0.30, sharpness: 0.72),
                continuous(time: 0.055, duration: 0.34, intensity: 0.52, sharpness: 0.30),
                transient(time: 0.39, intensity: 0.88, sharpness: 0.58),
                transient(time: 0.49, intensity: 0.30, sharpness: 0.22)
            ]
        }
        play(events: events) { notification(.success) }
    }

    func push() {
        play(
            events: [
                transient(time: 0, intensity: 0.74, sharpness: 0.76),
                transient(time: 0.075, intensity: 0.34, sharpness: 0.42)
            ],
            fallback: { impact(.heavy, intensity: 0.88) }
        )
    }

    func regularStopPushClick() {
        play(
            events: [
                transient(time: 0, intensity: 0.34, sharpness: 0.92),
                transient(time: 0.052, intensity: 0.15, sharpness: 0.58)
            ],
            fallback: { impact(.light, intensity: 0.42) }
        )
    }

    func regularStopPushPress() {
        play(
            events: [
                transient(time: 0, intensity: 0.76, sharpness: 0.88),
                continuous(time: 0.025, duration: 0.78, intensity: 0.44, sharpness: 0.30),
                transient(time: 0.14, intensity: 0.62, sharpness: 0.58),
                transient(time: 0.29, intensity: 0.54, sharpness: 0.48),
                transient(time: 0.46, intensity: 0.42, sharpness: 0.38),
                transient(time: 0.64, intensity: 0.28, sharpness: 0.24),
                transient(time: 0.79, intensity: 0.14, sharpness: 0.14)
            ],
            fallback: { impact(.rigid, intensity: 0.78) }
        )
    }

    func premiumFinalPush() {
        endPushHold()
        play(
            events: [
                transient(time: 0, intensity: 1.0, sharpness: 0.82),
                continuous(time: 0.018, duration: 1.12, intensity: 0.70, sharpness: 0.36),
                transient(time: 0.12, intensity: 0.70, sharpness: 0.52),
                transient(time: 0.25, intensity: 0.82, sharpness: 0.60),
                transient(time: 0.39, intensity: 0.92, sharpness: 0.66),
                transient(time: 0.53, intensity: 0.70, sharpness: 0.48),
                transient(time: 0.68, intensity: 0.86, sharpness: 0.60),
                transient(time: 0.84, intensity: 0.62, sharpness: 0.42),
                transient(time: 1.00, intensity: 0.44, sharpness: 0.30),
                transient(time: 1.14, intensity: 0.22, sharpness: 0.16)
            ],
            fallback: { impact(.heavy, intensity: 1.0) }
        )
    }

    func pushEject() {
        play(
            events: [
                transient(time: 0, intensity: 0.92, sharpness: 0.76),
                transient(time: 0.075, intensity: 0.58, sharpness: 0.48),
                continuous(time: 0.02, duration: 0.20, intensity: 0.38, sharpness: 0.30)
            ],
            fallback: { impact(.heavy, intensity: 0.92) }
        )
    }

    func beginPushHold() {
        guard pushHoldTimer == nil else { return }
        push()

        let timer = Timer(timeInterval: 0.10, repeats: true) { _ in
            Task { @MainActor in
                SlotHapticManager.shared.playHoldPulse()
            }
        }
        timer.tolerance = 0.018
        pushHoldTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func endPushHold() {
        pushHoldTimer?.invalidate()
        pushHoldTimer = nil
    }

    func beginMoviePulse() {
        endMoviePulse()
        moviePulseStep = 0

        let timer = Timer(timeInterval: 0.22, repeats: true) { _ in
            Task { @MainActor in
                SlotHapticManager.shared.playMoviePulseStep()
            }
        }
        timer.tolerance = 0.025
        moviePulseTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func endMoviePulse() {
        moviePulseTimer?.invalidate()
        moviePulseTimer = nil
        moviePulseStep = 0
    }

    func movieLogoImpact() {
        bonusLock(isLR: true)
    }

    func movieVCompletionImpact() {
        play(
            events: [
                continuous(time: 0, duration: 0.28, intensity: 0.66, sharpness: 0.38),
                transient(time: 0.10, intensity: 0.78, sharpness: 0.62),
                transient(time: 0.28, intensity: 1.0, sharpness: 0.54),
                transient(time: 0.39, intensity: 0.42, sharpness: 0.24)
            ],
            fallback: { notification(.success) }
        )
    }

    func bonusLock(isLR: Bool) {
        play(
            events: isLR
                ? [
                    transient(time: 0, intensity: 1.0, sharpness: 0.55),
                    continuous(time: 0.025, duration: 0.22, intensity: 0.45, sharpness: 0.22),
                    transient(time: 0.27, intensity: 0.54, sharpness: 0.38)
                ]
                : [
                    transient(time: 0, intensity: 0.86, sharpness: 0.62),
                    transient(time: 0.095, intensity: 0.40, sharpness: 0.32)
                ],
            fallback: { notification(.success) }
        )
    }

    private func play(
        events: [CHHapticEvent],
        fallback: () -> Void
    ) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            fallback()
            return
        }

        prepare()
        guard let engine else {
            fallback()
            return
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: 0)
        } catch {
            fallback()
        }
    }

    private func playHoldPulse() {
        play(
            events: [transient(time: 0, intensity: 0.20, sharpness: 0.34)],
            fallback: { impact(.soft, intensity: 0.24) }
        )
    }

    private func playMoviePulseStep() {
        moviePulseStep += 1
        let cycle = moviePulseStep % 16

        // 映像の呼吸に合わせ、弱い床振動の中へ節目のアクセントを置く。
        // 暗転区間に相当する周期では無振動にして静寂を残す。
        guard ![0, 1, 8].contains(cycle) else { return }

        let intensity: Float
        let sharpness: Float
        switch cycle {
        case 6, 7:
            intensity = 0.42
            sharpness = 0.48
        case 14, 15:
            intensity = 0.58
            sharpness = 0.62
        default:
            intensity = 0.16
            sharpness = 0.24
        }

        play(
            events: [transient(time: 0, intensity: intensity, sharpness: sharpness)],
            fallback: { impact(.soft, intensity: CGFloat(intensity)) }
        )
    }

    private func transient(
        time: TimeInterval,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private func continuous(
        time: TimeInterval,
        duration: TimeInterval,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
