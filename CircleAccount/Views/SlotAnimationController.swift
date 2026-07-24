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

enum SlotExpectationLevel: Int, Equatable {
    case normal = 0
    case chance = 1
    case hot = 2
    case gekiatsu = 3
    case premium = 4

    var slipIntensity: CGFloat {
        switch self {
        case .normal: return 0.20
        case .chance: return 0.38
        case .hot: return 0.58
        case .gekiatsu: return 0.82
        case .premium: return 1.0
        }
    }
}

enum SlotCinematicPhase: Equatable {
    case idle
    case leverBlackout
    case delayedStart
    case silentFreeze
    case pushStandby
    case finalSilence
    case kyuiin
    case doorOpen
    case ticketReady
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
    @Published var canStopFirstReel = false

    @Published var resultTitle = ""
    @Published var resultSubtitle = ""
    @Published var currentRoute: SlotAnimationRoute = .normal

    @Published var cinematicPhase: SlotCinematicPhase = .idle
    @Published var cinematicTrigger = 0

    @Published var expectationLevel: SlotExpectationLevel = .normal
    @Published var reelSlipTrigger = 0
    @Published var reelSlipIndex = -1
    @Published var reelSlipIntensity: CGFloat = 0

    private let sound = SlotSoundManager.shared

    private var animationTask: Task<Void, Never>?
    private var pushContinuation:
        CheckedContinuation<Void, Never>?

    private var firstReelStopContinuation:
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
        expectationLevel = expectationLevel(for: route)

        animationTask = Task {
            await runSequence(
                route: route
            )
        }
    }

    // MARK: - First Reel Stop

    func stopFirstReel() {
        guard
            isSpinning,
            stoppedReelCount == 0,
            canStopFirstReel
        else {
            return
        }

        canStopFirstReel = false

        firstReelStopContinuation?.resume()
        firstReelStopContinuation = nil
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
        canStopFirstReel = false

        resultTitle = ""
        resultSubtitle = ""
        currentRoute = .normal
        cinematicPhase = .idle
        cinematicTrigger = 0
        expectationLevel = .normal
        reelSlipTrigger = 0
        reelSlipIndex = -1
        reelSlipIntensity = 0

        isSequenceRunning = false
    }

    func cancel() {
        animationTask?.cancel()
        animationTask = nil

        pushContinuation?.resume()
        pushContinuation = nil

        firstReelStopContinuation?.resume()
        firstReelStopContinuation = nil
        canStopFirstReel = false

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

        // 前回の暗転・PUSH・告知表示を必ず消してから次の回転を始める
        stage = .idle
        cinematicPhase = .idle
        isPushVisible = false
        isPushEnabled = false
        statusText = "READY"
        subStatusText = "PULL THE LEVER"

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

        // 暗転・遅れは毎回出さず、ルートに応じて抽選する。
        // 文字は表示せず、無音と始動タイミングだけで気付かせる。
        // プレミアム演出確認中は旧スタート暗転を無効化。
        let startupCinematic = false

        if startupCinematic {
            cinematicPhase = .leverBlackout
            cinematicTrigger += 1
            stage = .blackout
            statusText = ""
            subStatusText = ""

            sound.stopSpin()
            await sleep(
                startupDelayDuration(
                    for: route
                )
            )

            guard !Task.isCancelled else {
                finishCancelledSequence()
                return
            }

            cinematicPhase = .delayedStart
            cinematicTrigger += 1
            stage = .idle

            await sleep(0.24)

            guard !Task.isCancelled else {
                finishCancelledSequence()
                return
            }
        } else {
            cinematicPhase = .idle
            stage = .idle
            await sleep(0.10)
        }

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

    private func shouldUseStartupCinematic(
        for route: SlotAnimationRoute
    ) -> Bool {
        let roll = Int.random(in: 0..<100)

        switch route {
        case .normal:
            return roll < 4
        case .chance:
            return roll < 18
        case .superChance:
            return roll < 46
        case .warning:
            return roll < 72
        case .reverse:
            return roll < 88
        case .premium:
            return true
        }
    }

    private func startupDelayDuration(
        for route: SlotAnimationRoute
    ) -> Double {
        switch route {
        case .normal:
            return 0.22
        case .chance:
            return 0.32
        case .superChance:
            return 0.45
        case .warning:
            return 0.58
        case .reverse:
            return 0.72
        case .premium:
            return 0.92
        }
    }

    // MARK: - Normal Route

    private func runNormalRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(3.20)

        await stopReels(
            intervals: [
                0.68,
                0.26,
                0.36
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
                0.78,
                0.30,
                0.42
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
                0.88,
                0.34,
                0.50
            ]
        )

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
                0.98,
                0.38,
                0.58
            ]
        )

        guard !Task.isCancelled else { return }

        await showSSRPushAndAlignment()

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
                1.04,
                0.42,
                0.66
            ]
        )

        guard !Task.isCancelled else { return }

        await showSSRPushAndAlignment()

        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Premium Route

    private func runPremiumRoute() async {
        heatLevel = .normal
        stage = .idle
        cinematicPhase = .idle
        statusText = "SPINNING"
        subStatusText = "PREMIUM TEST"

        await sleep(2.50)
        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "STOP READY"
        subStatusText = "PRESS LEFT STOP"

        await stopReels(intervals: [1.20, 1.50, 0.60])
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

        statusText = "STOP READY"
        subStatusText = "PRESS LEFT STOP"
        canStopFirstReel = true
        await waitForFirstReelStopOrTimeout(seconds: 10.0)

        guard !Task.isCancelled else { sound.stopSpin(); return }
        canStopFirstReel = false
        await performSlipIfNeeded(index: 0)
        guard !Task.isCancelled else { sound.stopSpin(); return }

        stopReel(index: 0)
        statusText = "LEFT REEL STOP"
        subStatusText = "..."
        await sleep(1.20)

        guard !Task.isCancelled else { sound.stopSpin(); return }
        await performSlipIfNeeded(index: 1)
        guard !Task.isCancelled else { sound.stopSpin(); return }

        stopReel(index: 1)
        statusText = "MIDDLE REEL STOP"
        subStatusText = "LAST REEL SPINNING"
        await sleep(1.55)

        guard !Task.isCancelled else { sound.stopSpin(); return }

        if usesCinematicReveal {
            statusText = ""
            subStatusText = ""

            // 第2リール停止後の筐体振動
            let warningImpact = UIImpactFeedbackGenerator(style: .rigid)
            warningImpact.prepare()
            warningImpact.impactOccurred(intensity: 0.72)
            await sleep(0.42)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            // CRT電源OFF：画面が縦に潰れ、横線、点、暗転へ
            cinematicPhase = .silentFreeze
            cinematicTrigger += 1
            await sleep(1.20)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            // 完全暗転・無音
            sound.stopSpin()
            cinematicPhase = .finalSilence
            cinematicTrigger += 1
            await sleep(2.00)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            // 先にPUSHを有効化し、CRT復帰直後から押せるようにする
            isPushVisible = true
            isPushEnabled = true

            // CRT電源ON：点、横線、通常画面へ復帰
            cinematicPhase = .pushStandby
            cinematicTrigger += 1

            // 右リールだけ回転中
            sound.startSpin()
            sound.intensifySpin()

            statusText = "LAST REEL"
            subStatusText = "PUSH TO STOP"

            // 復帰演出を見せる
            await sleep(1.05)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            // PUSHを押すまで絶対に進まない
            await waitForPush()

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            isPushEnabled = false
            isPushVisible = false
            statusText = ""
            subStatusText = ""

            // PUSHの重い衝撃
            let pushImpact = UIImpactFeedbackGenerator(style: .heavy)
            pushImpact.prepare()
            pushImpact.impactOccurred(intensity: 1.0)
            await sleep(0.42)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            // PUSHを押した瞬間に最後の右リールを停止
            await performSlipIfNeeded(index: 2)

            guard !Task.isCancelled else {
                sound.stopSpin()
                return
            }

            stopReel(index: 2)
            isSpinning = false
            sound.stopSpin()

            await sleep(1.80)

            guard !Task.isCancelled else {
                return
            }

            // 777停止後にキュイン
            cinematicPhase = .kyuiin
            cinematicTrigger += 1
            sound.playJackpot()
            await sleep(2.10)
        } else {
            await sleep(intervals[2])
            guard !Task.isCancelled else { sound.stopSpin(); return }
            await performSlipIfNeeded(index: 2)
            stopReel(index: 2)
            isSpinning = false
            sound.stopSpin()
            playResultSound()
        }
    }

    private var usesCinematicReveal: Bool {
        // SSR（rarity 5以上）に割り当てられる3ルートだけで
        // CRT暗転 → 復帰 → PUSHで右リール停止を実行する。
        //
        // GachaView側の割り当て:
        // SSR      → .warning / .reverse / .premium
        // SR以下   → .superChance / .chance / .normal
        switch currentRoute {
        case .warning, .reverse, .premium:
            return true

        case .normal, .chance, .superChance:
            return false
        }
    }

    private func expectationLevel(
        for route: SlotAnimationRoute
    ) -> SlotExpectationLevel {
        switch route {
        case .normal:
            return .normal
        case .chance:
            return .chance
        case .superChance:
            return .hot
        case .warning:
            return .gekiatsu
        case .reverse, .premium:
            return .premium
        }
    }

    private func performSlipIfNeeded(
        index: Int
    ) async {
        let chance: Int

        switch expectationLevel {
        case .normal:
            chance = index == 2 ? 12 : 5
        case .chance:
            chance = index == 2 ? 34 : 16
        case .hot:
            chance = index == 2 ? 62 : 32
        case .gekiatsu:
            chance = index == 2 ? 86 : 52
        case .premium:
            chance = index == 2 ? 100 : 72
        }

        guard Int.random(in: 0..<100) < chance else {
            return
        }

        reelSlipIndex = index
        reelSlipIntensity = expectationLevel.slipIntensity
        reelSlipTrigger += 1

        let duration =
            0.12
            + Double(expectationLevel.rawValue) * 0.055
            + Double(index) * 0.025

        await sleep(duration)
    }

    private func stopReel(
        index: Int
    ) {
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
        } else if index == 0 {
            statusText = "LEFT REEL STOP"
            subStatusText = "MIDDLE REEL AUTO"
        } else {
            statusText = "MIDDLE REEL STOP"
            subStatusText = "FINAL REEL AUTO"
        }
    }

    private func waitForFirstReelStopOrTimeout(
        seconds: Double
    ) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await withCheckedContinuation { continuation in
                    Task { @MainActor [weak self] in
                        self?.firstReelStopContinuation = continuation
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        seconds * 1_000_000_000
                    )
                )
            }

            await group.next()
            group.cancelAll()

            await MainActor.run {
                self.firstReelStopContinuation?.resume()
                self.firstReelStopContinuation = nil
                self.canStopFirstReel = false
            }
        }
    }

    // MARK: - Haptics

    private func playStopHaptic(
        index: Int,
        isFinal: Bool
    ) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        let intensity: CGFloat

        switch index {
        case 0:
            style = .light
            intensity = 0.68

        case 1:
            style = .medium
            intensity = 0.84

        default:
            style = .heavy
            intensity = 1.0
        }

        let impact = UIImpactFeedbackGenerator(style: style)
        impact.prepare()
        impact.impactOccurred(intensity: intensity)

        guard isFinal else { return }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.085
        ) {
            let lockImpact = UIImpactFeedbackGenerator(style: .rigid)
            lockImpact.prepare()
            lockImpact.impactOccurred(intensity: 0.72)
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.18
        ) {
            switch self.resultTitle {
            case "参加費無料券",
                 "ガット張り工賃無料券":
                let notification = UINotificationFeedbackGenerator()
                notification.prepare()
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

    // MARK: - SSR Physical PUSH

    private func showSSRPushAndAlignment() async {
        cinematicPhase = .pushStandby
        cinematicTrigger += 1
        stage = .idle

        statusText = ""
        subStatusText = ""

        isPushVisible = true
        isPushEnabled = true

        // 右下の実機風PUSHを待つ。放置時のみ10秒で自動進行。
        await waitForPushOrTimeout(
            seconds: 10.0
        )

        guard !Task.isCancelled else { return }

        isPushEnabled = false
        isPushVisible = false

        await performSSRAlignmentSpin()
    }

    private func performSSRAlignmentSpin() async {
        // PUSHで3リールを短く再始動させ、SSR図柄を完成させる
        cinematicPhase = .idle
        stage = .idle
        statusText = ""
        subStatusText = ""

        isSpinning = true
        stoppedReelCount = 0
        shouldReverseReels = true

        sound.startSpin()
        sound.intensifySpin()

        await sleep(0.48)

        guard !Task.isCancelled else {
            sound.stopSpin()
            return
        }

        shouldReverseReels = false

        await performSlipIfNeeded(index: 0)
        stopReel(index: 0)

        await sleep(0.18)

        guard !Task.isCancelled else {
            sound.stopSpin()
            return
        }

        await performSlipIfNeeded(index: 1)
        stopReel(index: 1)

        await sleep(0.22)

        guard !Task.isCancelled else {
            sound.stopSpin()
            return
        }

        await performSlipIfNeeded(index: 2)
        stopReel(index: 2)

        isSpinning = false
        sound.stopSpin()

        cinematicPhase = .kyuiin
        cinematicTrigger += 1
        statusText = ""
        subStatusText = ""

        sound.playJackpot()

        await sleep(1.05)
    }

    private func waitForPush() async {
        await withCheckedContinuation { continuation in
            pushContinuation = continuation
        }
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

    private func shouldUseFinalPushChallenge() -> Bool {
        Int.random(in: 0..<100) < 70
    }

    // MARK: - Jackpot

    private func showJackpot() async {
        cinematicPhase = .doorOpen
        cinematicTrigger += 1
        stage = .idle

        statusText = ""
        subStatusText = ""

        sound.playJackpot()

        await sleep(2.50)
    }

    // MARK: - Result

    private func showCardAndFinish() async {
        cinematicPhase = .ticketReady
        cinematicTrigger += 1
        stage = .cardReveal

        statusText = "PRIZE GET"
        subStatusText = "CONGRATULATIONS"

        sound.playRewardReveal()

        // 筐体内の当たり演出とチケットカードを見せてから
        // 全画面の獲得結果へ移動する
        await sleep(4.20)

        guard !Task.isCancelled else { return }

        shouldShowResult = true

        await sleep(0.35)

        guard !Task.isCancelled else { return }

        stage = .idle
        cinematicPhase = .idle
        isPushVisible = false
        isPushEnabled = false
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
        cinematicPhase = .idle
        canStopFirstReel = false
        firstReelStopContinuation?.resume()
        firstReelStopContinuation = nil
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
