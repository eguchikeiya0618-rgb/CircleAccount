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

    private var isSRResult: Bool {
        resultTitle == "参加費半額券"
    }

    private var animationTask: Task<Void, Never>?
    private var pushContinuation:
        CheckedContinuation<Void, Never>?

    private var firstReelStopContinuation:
        CheckedContinuation<Void, Never>?

    private(set) var isSequenceRunning = false

    // MARK: - Prepare

    func prepare(soundEnabled: Bool) {
        sound.prepare(enabled: soundEnabled)
        SlotHapticManager.shared.prepare()
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

    // MARK: - Reel Stop Input

    func requestReelStop(index: Int) {
        guard
            isSpinning,
            stoppedReelCount < 3,
            index == stoppedReelCount,
            canStopFirstReel
        else {
            return
        }

        canStopFirstReel = false

        firstReelStopContinuation?.resume()
        firstReelStopContinuation = nil
    }

    // 既存の呼び出し元との互換性を保ち、
    // 画面タップとSTOPボタンを同じ停止要求へ集約する。
    func stopFirstReel() {
        requestReelStop(index: stoppedReelCount)
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

    func finishPremiumSequence() {
        guard currentRoute == .premium,
              !shouldShowResult else {
            return
        }

        cinematicPhase = .ticketReady
        cinematicTrigger += 1
        stage = .cardReveal

        sound.playRewardReveal()
        statusText = "PRIZE GET"
        subStatusText = "CONGRATULATIONS"
        shouldShowResult = true
        isPushVisible = false
        isPushEnabled = false
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

        SlotSoundManager.shared.playLever()

        // レバーONと同じフレームで筐体を維持したままリールだけ始動する。
        cinematicPhase = .idle
        stage = .idle
        statusText = "START"
        subStatusText = "REEL MOTOR ONLINE"
        isSpinning = true
        stoppedReelCount = 0
        sound.startSpin()

        await sleep(0.18)

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
        }

        await sleep(0.55)

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

        await sleep(2.05)

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

        await sleep(1.36)

        guard !Task.isCancelled else { return }

        heatLevel = .chance
        statusText = "CHANCE"
        subStatusText = "EXPECTATION RISING"
        stage = .chance

        await sleep(1.07)

        guard !Task.isCancelled else { return }

        stage = .idle

        if !isSRResult {
            sound.intensifySpin()
        }

        statusText = "CHANCE MODE"
        subStatusText = "DO NOT LOOK AWAY"

        await sleep(1.33)

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
        if isSRResult {
            await runSRWithSSRPresentation()
            return
        }

        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.14)

        guard !Task.isCancelled else { return }

        heatLevel = .superChance
        statusText = "SUPER CHANCE"
        subStatusText = "HIGH EXPECTATION"
        // 旧SUPER CHANCE全画面表示は使わない。
        stage = .idle
        if !isSRResult {
            sound.playWarning()
        }

        await sleep(1.40)

        guard !Task.isCancelled else { return }

        stage = .idle
        if !isSRResult {
            sound.intensifySpin()
        }

        statusText = "SUPER MODE"
        subStatusText = "FINAL PHASE"

        await sleep(1.46)

        await stopReels(
            intervals: [
                0.88,
                0.34,
                0.50
            ]
        )

        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    /// SSR Premiumルートと同じ上部表示・色・切替タイミングをSRへ適用する。
    /// SSR本体は呼び替えず、SRだけがこの共通仕様を参照する。
    private func runSRWithSSRPresentation() async {
        heatLevel = .normal
        stage = .idle
        cinematicPhase = .idle
        statusText = "SPINNING"
        subStatusText = "PREMIUM TEST"

        await sleep(1.62)
        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "STOP READY"
        subStatusText = "PRESS LEFT STOP"

        await stopReels(intervals: [1.20, 1.50, 0.60])
        guard !Task.isCancelled else { return }

        await showCardAndFinish()
    }

    // MARK: - Warning Route

    private func runWarningRoute() async {
        heatLevel = .normal

        statusText = "SPINNING"
        subStatusText = "GOOD LUCK"

        await sleep(1.07)

        guard !Task.isCancelled else { return }

        heatLevel = .warning
        statusText = "SYSTEM ERROR"
        subStatusText = "UNKNOWN SIGNAL"
        stage = .idle
        sound.stopSpin()

        await sleep(1.01)

        guard !Task.isCancelled else { return }

        // 旧WARNING／激アツ全画面表示は使わない。
        stage = .idle
        sound.playWarning()

        await sleep(1.43)

        guard !Task.isCancelled else { return }

        stage = .idle
        sound.intensifySpin()

        statusText = "WARNING MODE"
        subStatusText = "MAXIMUM EXPECTATION"

        await sleep(1.59)

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

        await sleep(1.07)

        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "PREMIUM SIGNAL"
        subStatusText = "REVERSE LOCK DETECTED"
        stage = .idle
        sound.stopSpin()

        await sleep(0.88)

        guard !Task.isCancelled else { return }

        // 旧REVERSE全画面表示は使わず、逆回転だけ残す。
        stage = .idle
        shouldReverseReels = true
        sound.playWarning()

        await sleep(1.59)

        guard !Task.isCancelled else { return }

        shouldReverseReels = false
        stage = .idle

        sound.intensifySpin()

        await sleep(1.20)

        guard !Task.isCancelled else { return }

        stage = .idle

        statusText = "REVERSE MODE"
        subStatusText = "PREMIUM POSSIBILITY"

        await sleep(1.56)

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

        await sleep(1.62)
        guard !Task.isCancelled else { return }

        heatLevel = .premium
        statusText = "STOP READY"
        subStatusText = "PRESS LEFT STOP"

        await stopReels(intervals: [1.20, 1.50, 0.60])
        guard !Task.isCancelled else { return }

        await showJackpot()

        guard !Task.isCancelled else { return }
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
        await waitForReelTap()

        guard !Task.isCancelled else { sound.stopSpin(); return }
        canStopFirstReel = false
        await performSlipIfNeeded(index: 0)
        guard !Task.isCancelled else { sound.stopSpin(); return }

        stopReel(index: 0)
        statusText = ""
        subStatusText = "..."
        await sleep(1.20)

        guard !Task.isCancelled else { sound.stopSpin(); return }

        statusText = "STOP READY"
        subStatusText = "TAP REELS FOR MIDDLE STOP"
        canStopFirstReel = true
        await waitForReelTap()

        guard !Task.isCancelled else { sound.stopSpin(); return }
        canStopFirstReel = false
        await performSlipIfNeeded(index: 1)
        guard !Task.isCancelled else { sound.stopSpin(); return }

        stopReel(index: 1)
        statusText = ""
        subStatusText = ""
        await sleep(1.55)

        guard !Task.isCancelled else { sound.stopSpin(); return }

        if isSRResult {
            statusText = ""
            subStatusText = ""

            // SSRと同じ激アツの余韻を残してからCRTを落とす。
            let warningImpact = UIImpactFeedbackGenerator(style: .rigid)
            warningImpact.prepare()
            warningImpact.impactOccurred(intensity: 0.72)
            await sleep(0.42)

            guard !Task.isCancelled else { sound.stopSpin(); return }

            cinematicPhase = .silentFreeze
            cinematicTrigger += 1
            await sleep(1.20)

            guard !Task.isCancelled else { sound.stopSpin(); return }

            sound.stopSpin()
            cinematicPhase = .finalSilence
            cinematicTrigger += 1

            // SSRと同じタイプライターを最後まで表示する。
            await sleep(6.55)

            guard !Task.isCancelled else { sound.stopSpin(); return }

            // SSRと同じCRT復帰を完了してから第3リールを止める。
            sound.playPushAppear()
            cinematicPhase = .pushStandby
            cinematicTrigger += 1

            // SSRのCRT復帰時と同じ回転音・復帰音を使用する。
            sound.startSpin()
            sound.intensifySpin()

            statusText = "STOP READY"
            subStatusText = "TAP REELS FOR RIGHT STOP"
            await sleep(1.05)

            guard !Task.isCancelled else { sound.stopSpin(); return }

            // SRの第3リールは自動停止せず、ユーザーのSTOP入力を待つ。
            canStopFirstReel = true
            await waitForReelTap()

            guard !Task.isCancelled else { sound.stopSpin(); return }

            canStopFirstReel = false
            await performSlipIfNeeded(index: 2)

            guard !Task.isCancelled else { sound.stopSpin(); return }

            stopReel(index: 2)
            isSpinning = false
            sound.stopSpin()

            // 停止図柄と停止演出を見せてからカードへ進む。
            await sleep(3.0)

            guard !Task.isCancelled else { return }
        } else if usesCinematicReveal {
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

            // 本格タイプライター次回予告を最後まで見せてから
            // CRT復帰・PUSH待機へ進む。
            await sleep(6.55)

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

            // 第3リールはPUSH入力まで回転状態を維持する。
            sound.startSpin()
            sound.intensifySpin()

            statusText = ""
            subStatusText = "PUSH FOR BONUS"

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

            // PUSH入力を唯一のトリガーとして第3リールを停止する。
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
            statusText = "STOP READY"
            subStatusText = "TAP REELS FOR RIGHT STOP"
            canStopFirstReel = true
            await waitForReelTap()

            guard !Task.isCancelled else { sound.stopSpin(); return }
            canStopFirstReel = false
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

        if index == 2,
           resultTitle == "参加費半額券" {
            sound.playSRStop()
        } else {
            sound.playReelStop(
                index: index,
                isFinal: index == 2
            )
        }

        playStopHaptic(
            index: index,
            isFinal: index == 2
        )

        if index == 2 {
            statusText = "RESULT LOCKED"
            subStatusText = "FINAL JUDGEMENT"
        } else if index == 0 {
            statusText = ""
            subStatusText = "MIDDLE REEL AUTO"
        } else {
            statusText = ""
            subStatusText = "FINAL REEL AUTO"
        }
    }

    private func waitForReelTap() async {
        await withCheckedContinuation { continuation in
            firstReelStopContinuation = continuation
        }
    }

    // MARK: - Haptics

    private func playStopHaptic(
        index: Int,
        isFinal: Bool
    ) {
        SlotHapticManager.shared.reelStop(index: index, isFinal: isFinal)
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

        // 始動SEなしでリール回転ループのみ開始
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
        stage = isSRResult ? .idle : .cardReveal

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
