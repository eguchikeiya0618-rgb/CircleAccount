import SwiftUI
import Combine
import UIKit

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
    private var pushContinuation:
        CheckedContinuation<Void, Never>?

    private(set) var isSequenceRunning = false

    // MARK: - Prepare

    func prepare(soundEnabled: Bool) {
        sound.prepare(enabled: soundEnabled)
    }

    // MARK: - Lever

    func setLeverProgress(
        _ progress: CGFloat
    ) {
        guard !isSequenceRunning else { return }

        leverProgress = min(
            1,
            max(0, progress)
        )
    }

    func returnLever() {
        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.68
            )
        ) {
            leverProgress = 0
        }
    }

    // MARK: - Start

    func start(
        soundEnabled: Bool,
        resultTitle: String,
        resultSubtitle: String,
        route: SlotAnimationRoute
    ) {
        guard !isSequenceRunning else { return }

        cancel()

        sound.prepare(
            enabled: soundEnabled
        )

        self.resultTitle = resultTitle
        self.resultSubtitle = resultSubtitle
        self.currentRoute = route

        animationTask = Task {
            await runSequence(
                route: route
            )
        }
    }

    // MARK: - Push

    func pressPush() {
        guard
            isPushVisible,
            isPushEnabled
        else {
            return
        }

        sound.playPush()

        isPushEnabled = false
        isPushVisible = false

        pushContinuation?.resume()
        pushContinuation = nil
    }

    // MARK: - Reset

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

    // MARK: - Main Sequence

    private func runSequence(
        route: SlotAnimationRoute
    ) async {
        isSequenceRunning = true
        shouldShowResult = false
        shouldReverseReels = false

        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.70
            )
        ) {
            leverProgress = 1
        }

        sound.playLever()
        await sleep(0.34)

        guard !Task.isCancelled else {
            finishCancelledSequence()
            return
        }

        withAnimation(
            .spring(
                response: 0.38,
                dampingFraction: 0.66
            )
        ) {
            leverProgress = 0
        }

        setInitialHeat(
            for: route
        )

        stage = .idle
        statusText = "START"
        subStatusText = "REEL MOTOR ONLINE"

        isSpinning = true
        stoppedReelCount = 0

        sound.startSpin()

        await sleep(1.10)

        guard !Task.isCancelled else {
            finishCancelledSequence()
            return
        }

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

        guard !Task.isCancelled else {
            finishCancelledSequence()
            return
        }

        isSequenceRunning = false
    }

    // MARK: - Normal Route

    private func runNormalRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(3.20)

        await stopReels(
            intervals: [
                0.82,
                0.94,
                1.12
            ]
        )

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Chance Route

    private func runChanceRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(2.10)

        guard !Task.isCancelled else { return }

        heatLevel = .chance
        statusText = "CHANCE"
        subStatusText = "EXPECTATION RISING"
        stage = .chance

        await sleep(1.65)

        guard !Task.isCancelled else { return }

        stage = .idle

        sound.intensifySpin()

        statusText = "CHANCE MODE"
        subStatusText = "DO NOT LOOK AWAY"

        await sleep(2.05)

        await stopReels(
            intervals: [
                0.90,
                1.05,
                1.30
            ]
        )

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Super Chance Route

    private func runSuperChanceRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.75)

        guard !Task.isCancelled else { return }

        heatLevel = .superChance
        statusText = "SUPER CHANCE"
        subStatusText = "HIGH EXPECTATION"
        stage = .superChance
        sound.playWarning()

        await sleep(2.15)

        guard !Task.isCancelled else { return }

        stage = .idle
        sound.intensifySpin()

        statusText = "SUPER MODE"
        subStatusText = "FINAL PHASE"

        await sleep(2.25)

        await stopReels(
            intervals: [
                1.00,
                1.20,
                1.55
            ]
        )

        guard !Task.isCancelled else { return }

        await showPushSequence()

        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Warning Route

    private func runWarningRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.65)

        guard !Task.isCancelled else { return }

        heatLevel = .warning
        statusText = "SYSTEM ERROR"
        subStatusText = "UNKNOWN SIGNAL"
        stage = .blackout
        sound.stopSpin()

        await sleep(1.55)

        guard !Task.isCancelled else { return }

        stage = .warning
        sound.playWarning()

        await sleep(2.20)

        guard !Task.isCancelled else { return }

        stage = .idle
        sound.intensifySpin()

        statusText = "WARNING MODE"
        subStatusText = "MAXIMUM EXPECTATION"

        await sleep(2.45)

        await stopReels(
            intervals: [
                1.05,
                1.35,
                1.75
            ]
        )

        guard !Task.isCancelled else { return }

        await showPushSequence()

        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Reverse Route

    private func runReverseRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.65)

        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "PREMIUM SIGNAL"
        subStatusText = "REVERSE LOCK DETECTED"
        stage = .blackout
        sound.stopSpin()

        await sleep(1.35)

        guard !Task.isCancelled else { return }

        stage = .reverse
        shouldReverseReels = true
        sound.playWarning()

        await sleep(2.45)

        guard !Task.isCancelled else { return }

        shouldReverseReels = false
        stage = .superChance

        sound.intensifySpin()

        await sleep(1.85)

        guard !Task.isCancelled else { return }

        stage = .idle

        statusText = "REVERSE MODE"
        subStatusText = "PREMIUM POSSIBILITY"

        await sleep(2.40)

        await stopReels(
            intervals: [
                1.10,
                1.45,
                1.90
            ]
        )

        guard !Task.isCancelled else { return }

        await showPushSequence()

        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Premium Route

    private func runPremiumRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.50)

        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "PREMIUM"
        subStatusText = "ULTIMATE MODE"
        stage = .blackout
        sound.stopSpin()

        await sleep(1.50)

        guard !Task.isCancelled else { return }

        stage = .warning
        sound.playWarning()

        await sleep(2.00)

        guard !Task.isCancelled else { return }

        stage = .superChance

        await sleep(1.80)

        guard !Task.isCancelled else { return }

        stage = .reverse
        shouldReverseReels = true

        sound.intensifySpin()

        await sleep(2.30)

        guard !Task.isCancelled else { return }

        shouldReverseReels = false
        stage = .idle

        statusText = "PREMIUM LOCK"
        subStatusText = "JACKPOT APPROACHING"

        await sleep(2.65)

        await stopReels(
            intervals: [
                1.15,
                1.55,
                2.10
            ]
        )

        guard !Task.isCancelled else { return }

        await showPushSequence()

        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Reel Stop

    private func stopReels(
        intervals: [Double]
    ) async {
        guard intervals.count >= 3 else {
            isSpinning = false
            sound.stopSpin()
            return
        }

        for index in 0..<3 {
            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            await sleep(
                intervals[index]
            )

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            stoppedReelCount = index + 1

            sound.playReelStop(
                index: index,
                isFinal: index == 2
            )

            playStopHaptic(
                index: index,
                isFinal: index == 2
            )

            if index == 2 {
                statusText = "RESULT LOCKED"
                subStatusText = "FINAL JUDGEMENT"

                await sleep(0.24)

                guard !Task.isCancelled else {
                    sound.stopSpin()
                    return
                }

                playResultSound()
            } else {
                statusText =
                    "REEL \(index + 1) STOP"

                subStatusText =
                    "NEXT REEL STANDBY"
            }
        }

        isSpinning = false
        sound.stopSpin()
    }

    // MARK: - Haptics

    private func playStopHaptic(
        index: Int,
        isFinal: Bool
    ) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle

        switch index {
        case 0:
            style = .light

        case 1:
            style = .medium

        default:
            style = .heavy
        }

        let impact = UIImpactFeedbackGenerator(style: style)
        impact.prepare()
        impact.impactOccurred(
            intensity: isFinal ? 1.0 : 0.82
        )

        guard isFinal else { return }

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.10
        ) {
            switch self.resultTitle {
            case "参加費無料券",
                 "ガット張り工賃無料券":
                notification.notificationOccurred(.success)

            default:
                break
            }
        }
    }

    // MARK: - Result Sound

    private func playResultSound() {
        switch resultTitle {
        case "参加費無料券":
            sound.playRainbowSeven()

        case "ガット張り工賃無料券":
            sound.playSeven()

        case "対戦指名券":
            sound.playBell()

        case "優先ゲーム券":
            sound.playGrape()

        default:
            break
        }
    }

    // MARK: - Push Sequence

    private func showPushSequence() async {
        stage = .push

        statusText = "PUSH"
        subStatusText = "DECIDE YOUR FATE"

        isPushVisible = true
        isPushEnabled = true

        await waitForPushOrTimeout(
            seconds: 5.0
        )

        guard !Task.isCancelled else { return }

        isPushEnabled = false
        isPushVisible = false
    }

    private func waitForPushOrTimeout(
        seconds: Double
    ) async {
        await withTaskGroup(
            of: Void.self
        ) { group in
            group.addTask { [weak self] in
                await withCheckedContinuation {
                    continuation in

                    Task { @MainActor [weak self] in
                        self?.pushContinuation =
                            continuation
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        seconds
                        * 1_000_000_000
                    )
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

    // MARK: - Jackpot

    private func showJackpot() async {
        stage = .jackpot

        statusText = "JACKPOT"
        subStatusText = "PREMIUM WIN"

        sound.playJackpot()

        await sleep(3.15)
    }

    // MARK: - Result

    private func showCardAndFinish() async {
        stage = .cardReveal

        statusText = "PRIZE GET"
        subStatusText = "CONGRATULATIONS"

        await sleep(3.10)

        guard !Task.isCancelled else { return }

        shouldShowResult = true

        await sleep(0.35)

        guard !Task.isCancelled else { return }

        stage = .idle
    }

    // MARK: - Heat Level

    private func setInitialHeat(
        for route: SlotAnimationRoute
    ) {
        // 回転開始直後は、抽選結果に関係なく必ず通常表示にする。
        // 当たりルートの色・文字・演出は、回転が始まってから段階的に公開する。
        heatLevel = .normal
    }

    // MARK: - Cancel Handling

    private func finishCancelledSequence() {
        sound.stopAll()

        isSpinning = false
        isPushVisible = false
        isPushEnabled = false
        shouldReverseReels = false
        isSequenceRunning = false
    }

    // MARK: - Sleep

    private func sleep(
        _ seconds: Double
    ) async {
        guard seconds > 0 else { return }

        do {
            try await Task.sleep(
                nanoseconds: UInt64(
                    seconds
                    * 1_000_000_000
                )
            )
        } catch {
            return
        }
    }
}
