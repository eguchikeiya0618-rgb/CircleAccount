import SwiftUI
import Combine

enum SlotAnimationRoute: Equatable {
    case normal
    case chance
    case superChance
    case warning
    case reverse
    case premium
}

@MainActor
final class SlotAnimationController: ObservableObject {
    @Published var stage: SlotEffectStage = .idle
    @Published var heatLevel: SlotHeatLevel = .normal

    @Published var isSpinning = false
    @Published var stoppedReelCount = 3

    @Published var statusText = "READY"
    @Published var subStatusText = "PULL THE LEVER"

    @Published var isPushVisible = false
    @Published var isPushEnabled = false

    @Published var leverProgress: CGFloat = 0
    @Published var shouldReverseReels = false
    @Published var shouldShowResult = false

    @Published var resultTitle = ""
    @Published var resultSubtitle = ""
    @Published var currentRoute: SlotAnimationRoute = .normal

    private let sound = SlotSoundManager.shared

    private var animationTask: Task<Void, Never>?
    private var pushContinuation: CheckedContinuation<Void, Never>?
    private(set) var isSequenceRunning = false

    func prepare(soundEnabled: Bool) {
        sound.prepare(enabled: soundEnabled)
    }

    func setLeverProgress(_ progress: CGFloat) {
        guard !isSequenceRunning else { return }
        leverProgress = min(1, max(0, progress))
    }

    func returnLever() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.68)) {
            leverProgress = 0
        }
    }

    func start(
        soundEnabled: Bool,
        resultTitle: String,
        resultSubtitle: String,
        route: SlotAnimationRoute
    ) {
        guard !isSequenceRunning else { return }

        cancel()

        sound.prepare(enabled: soundEnabled)

        self.resultTitle = resultTitle
        self.resultSubtitle = resultSubtitle
        self.currentRoute = route

        animationTask = Task {
            await runSequence(route: route)
        }
    }

    func pressPush() {
        guard isPushVisible, isPushEnabled else { return }

        sound.playPush()
        isPushEnabled = false
        isPushVisible = false

        pushContinuation?.resume()
        pushContinuation = nil
    }

    func reset() {
        cancel()

        stage = .idle
        heatLevel = .normal
        isSpinning = false
        stoppedReelCount = 3
        statusText = "READY"
        subStatusText = "PULL THE LEVER"
        isPushVisible = false
        isPushEnabled = false
        leverProgress = 0
        shouldReverseReels = false
        shouldShowResult = false
        resultTitle = ""
        resultSubtitle = ""
        currentRoute = .normal
        isSequenceRunning = false
    }

    func cancel() {
        animationTask?.cancel()
        animationTask = nil

        pushContinuation?.resume()
        pushContinuation = nil

        sound.stopAll()
        isSequenceRunning = false
    }

    private func runSequence(route: SlotAnimationRoute) async {
        isSequenceRunning = true
        shouldShowResult = false
        shouldReverseReels = false

        withAnimation(.spring(response: 0.32, dampingFraction: 0.70)) {
            leverProgress = 1
        }

        sound.playLever()
        await sleep(0.34)

        withAnimation(.spring(response: 0.38, dampingFraction: 0.66)) {
            leverProgress = 0
        }

        setInitialHeat(for: route)

        stage = .idle
        statusText = "START"
        subStatusText = "REEL MOTOR ONLINE"
        isSpinning = true
        stoppedReelCount = 0

        sound.startSpin()
        await sleep(1.10)

        guard !Task.isCancelled else { return }

        switch route {
        case .normal:
            await runNormalRoute()
        case .chance:
            await runChanceRoute()
        case .superChance:
            await runSuperChanceRoute()
        case .warning:
            await runWarningRoute()
        case .reverse:
            await runReverseRoute()
        case .premium:
            await runPremiumRoute()
        }

        guard !Task.isCancelled else { return }
        isSequenceRunning = false
    }

    private func runNormalRoute() async {
        heatLevel = .normal
        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(3.20)
        await stopReels(intervals: [0.82, 0.94, 1.12])
        await showCardAndFinish()
    }

    private func runChanceRoute() async {
        heatLevel = .chance
        statusText = "CHANCE"
        subStatusText = "EXPECTATION RISING"

        await sleep(2.10)
        stage = .chance
        await sleep(1.65)

        stage = .idle
        sound.intensifySpin()
        statusText = "CHANCE MODE"
        subStatusText = "DO NOT LOOK AWAY"

        await sleep(2.05)
        await stopReels(intervals: [0.90, 1.05, 1.30])
        await showCardAndFinish()
    }

    private func runSuperChanceRoute() async {
        heatLevel = .superChance
        statusText = "SUPER CHANCE"
        subStatusText = "HIGH EXPECTATION"

        await sleep(1.75)
        stage = .superChance
        sound.playWarning()
        await sleep(2.15)

        stage = .idle
        sound.intensifySpin()
        statusText = "SUPER MODE"
        subStatusText = "FINAL PHASE"

        await sleep(2.25)
        await stopReels(intervals: [1.00, 1.20, 1.55])
        await showPushSequence()
        await showJackpot()
        await showCardAndFinish()
    }

    private func runWarningRoute() async {
        heatLevel = .warning
        statusText = "SYSTEM ERROR"
        subStatusText = "UNKNOWN SIGNAL"

        await sleep(1.65)
        stage = .blackout
        sound.stopSpin()
        await sleep(1.55)

        stage = .warning
        sound.playWarning()
        await sleep(2.20)

        stage = .idle
        sound.intensifySpin()
        statusText = "WARNING MODE"
        subStatusText = "MAXIMUM EXPECTATION"

        await sleep(2.45)
        await stopReels(intervals: [1.05, 1.35, 1.75])
        await showPushSequence()
        await showJackpot()
        await showCardAndFinish()
    }

    private func runReverseRoute() async {
        heatLevel = .premium
        statusText = "PREMIUM SIGNAL"
        subStatusText = "REVERSE LOCK DETECTED"

        await sleep(1.65)
        stage = .blackout
        sound.stopSpin()
        await sleep(1.35)

        stage = .reverse
        shouldReverseReels = true
        sound.playWarning()
        await sleep(2.45)

        shouldReverseReels = false
        stage = .superChance
        sound.intensifySpin()
        await sleep(1.85)

        stage = .idle
        statusText = "REVERSE MODE"
        subStatusText = "PREMIUM POSSIBILITY"

        await sleep(2.40)
        await stopReels(intervals: [1.10, 1.45, 1.90])
        await showPushSequence()
        await showJackpot()
        await showCardAndFinish()
    }

    private func runPremiumRoute() async {
        heatLevel = .premium
        statusText = "PREMIUM"
        subStatusText = "ULTIMATE MODE"

        await sleep(1.50)
        stage = .blackout
        sound.stopSpin()
        await sleep(1.50)

        stage = .warning
        sound.playWarning()
        await sleep(2.00)

        stage = .superChance
        await sleep(1.80)

        stage = .reverse
        shouldReverseReels = true
        sound.intensifySpin()
        await sleep(2.30)

        shouldReverseReels = false
        stage = .idle
        statusText = "PREMIUM LOCK"
        subStatusText = "JACKPOT APPROACHING"

        await sleep(2.65)
        await stopReels(intervals: [1.15, 1.55, 2.10])
        await showPushSequence()
        await showJackpot()
        await showCardAndFinish()
    }

    private func stopReels(intervals: [Double]) async {
        for index in 0..<3 {
            guard !Task.isCancelled else { return }

            await sleep(intervals[index])
            stoppedReelCount = index + 1
            sound.playReelStop(index: index, isFinal: index == 2)

            statusText = index == 2 ? "RESULT LOCKED" : "REEL \(index + 1) STOP"
            subStatusText = index == 2 ? "FINAL JUDGEMENT" : "NEXT REEL STANDBY"
        }

        isSpinning = false
        sound.stopSpin()
    }

    private func showPushSequence() async {
        stage = .push
        statusText = "PUSH"
        subStatusText = "DECIDE YOUR FATE"
        isPushVisible = true
        isPushEnabled = true

        await waitForPushOrTimeout(seconds: 5.0)

        guard !Task.isCancelled else { return }
        isPushEnabled = false
        isPushVisible = false
    }

    private func waitForPushOrTimeout(seconds: Double) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await withCheckedContinuation { continuation in
                    Task { @MainActor [weak self] in
                        self?.pushContinuation = continuation
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )
            }

            await group.next()
            group.cancelAll()

            await MainActor.run {
                self.pushContinuation?.resume()
                self.pushContinuation = nil
            }
        }
    }

    private func showJackpot() async {
        stage = .jackpot
        statusText = "JACKPOT"
        subStatusText = "PREMIUM WIN"
        sound.playJackpot()
        await sleep(3.15)
    }

    private func showCardAndFinish() async {
        stage = .cardReveal
        statusText = "PRIZE GET"
        subStatusText = "CONGRATULATIONS"

        await sleep(3.10)
        shouldShowResult = true
        await sleep(0.35)
        stage = .idle
    }

    private func setInitialHeat(for route: SlotAnimationRoute) {
        switch route {
        case .normal:
            heatLevel = .normal
        case .chance:
            heatLevel = .chance
        case .superChance:
            heatLevel = .superChance
        case .warning:
            heatLevel = .warning
        case .reverse, .premium:
            heatLevel = .premium
        }
    }

    private func sleep(_ seconds: Double) async {
        guard seconds > 0 else { return }

        try? await Task.sleep(
            nanoseconds: UInt64(seconds * 1_000_000_000)
        )
    }
}

