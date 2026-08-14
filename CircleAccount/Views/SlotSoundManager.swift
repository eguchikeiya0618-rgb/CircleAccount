import AVFoundation
import AudioToolbox

final class SlotSoundManager: NSObject {
    static let shared = SlotSoundManager()

    private let engine = AVAudioEngine()
    private let spinPlayer = AVAudioPlayerNode()
    private let accentPlayer = AVAudioPlayerNode()
    private let resultPlayer = AVAudioPlayerNode()
    private var typewriterPlayers: [AVAudioPlayer] = []
    private var nextTypewriterPlayerIndex = 0
    private var typewriterImpactPlayer: AVAudioPlayer?
    private var pushAppearPlayer: AVAudioPlayer?
    private var pushPressPlayer: AVAudioPlayer?
    private var firstStopPlayer: AVAudioPlayer?
    private var srStopPlayer: AVAudioPlayer?
    private var gekiatsuPlayer: AVAudioPlayer?
    private var vmovieStartPlayer: AVAudioPlayer?
    private var vmovieFollowPlayer: AVPlayer?
    private var vmovieFollowWorkItem: DispatchWorkItem?
    private var blackoutChargePlayer: AVAudioPlayer?
    private var leverPlayer: AVAudioPlayer?

    private var spinBuffer: AVAudioPCMBuffer?
    private var intenseSpinBuffer: AVAudioPCMBuffer?
    private var stopBuffer: AVAudioPCMBuffer?
    private var finalStopBuffer: AVAudioPCMBuffer?
    private var pushBuffer: AVAudioPCMBuffer?
    private var warningBuffer: AVAudioPCMBuffer?
    private var jackpotBuffer: AVAudioPCMBuffer?
    private var bellBuffer: AVAudioPCMBuffer?
    private var grapeBuffer: AVAudioPCMBuffer?
    private var sevenBuffer: AVAudioPCMBuffer?
    private var rainbowSevenBuffer: AVAudioPCMBuffer?
    private var rewardRevealBuffer: AVAudioPCMBuffer?

    private var isPrepared = false
    private var isSoundEnabled = true
    private var isDefaultJackpotSoundEnabled = true
    private var shouldSuppressNextFirstReelStopSound = false
    private var shouldSuppressNextPushSound = false
    private var masterVolume: Float = 0.80
    private var currentSpinBaseVolume: Float = 0.34

    private override init() {
        super.init()
    }

    // MARK: - Movie Audio

    func shouldMuteEmbeddedAudio(for movieName: String) -> Bool {
        movieName == "VMovie"
    }

    // MARK: - Prepare

    func prepare(enabled: Bool) {
        isSoundEnabled = enabled

        guard enabled else {
            stopAll()
            return
        }

        do {
            try configureAudioSession()
            prepareEngineIfNeeded()

            if !engine.isRunning {
                try engine.start()
            }

            if gekiatsuPlayer == nil {
                prepareGekiatsuPlayer()
            }

            if vmovieStartPlayer == nil {
                prepareVMovieStartPlayer()
            }

            if vmovieFollowPlayer == nil {
                prepareVMovieFollowPlayer()
            }

            if blackoutChargePlayer == nil {
                prepareBlackoutChargePlayer()
            }

            if leverPlayer == nil {
                prepareLeverPlayer()
            }

            if srStopPlayer == nil {
                prepareSRStopPlayer()
            }
        } catch {
            print(
                "SlotSoundManager prepare error: "
                + error.localizedDescription
            )
        }
    }

    // MARK: - Volume

    func setMasterVolume(_ value: Double) {
        masterVolume = Float(
            min(max(value, 0.0), 1.0)
        )

        if spinPlayer.isPlaying {
            spinPlayer.volume = adjustedVolume(
                currentSpinBaseVolume
            )
        }
    }

    // MARK: - Public Sound Methods

    func playLever() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if leverPlayer == nil {
            prepareLeverPlayer()
        }

        guard let leverPlayer else { return }

        leverPlayer.currentTime = 0
        leverPlayer.numberOfLoops = 0
        leverPlayer.volume = adjustedVolume(0.82)
        leverPlayer.play()
    }

    func startSpin() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        spinPlayer.stop()

        guard let spinBuffer else { return }

        spinPlayer.scheduleBuffer(
            spinBuffer,
            at: nil,
            options: [.loops],
            completionHandler: nil
        )

        currentSpinBaseVolume = 0.38
        spinPlayer.volume = adjustedVolume(
            currentSpinBaseVolume
        )
        spinPlayer.play()
    }

    func intensifySpin() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        spinPlayer.stop()

        guard let intenseSpinBuffer else { return }

        spinPlayer.scheduleBuffer(
            intenseSpinBuffer,
            at: nil,
            options: [.loops],
            completionHandler: nil
        )

        currentSpinBaseVolume = 0.42
        spinPlayer.volume = adjustedVolume(
            currentSpinBaseVolume
        )
        spinPlayer.play()
    }

    func playReelStop(
        index: Int,
        isFinal: Bool
    ) {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if index == 0,
           shouldSuppressNextFirstReelStopSound {
            shouldSuppressNextFirstReelStopSound = false
            return
        }

        if firstStopPlayer == nil {
            prepareFirstStopPlayer()
        }

        if let firstStopPlayer {
            firstStopPlayer.currentTime = 0
            firstStopPlayer.volume = adjustedVolume(0.88)
            firstStopPlayer.play()
        }

        if isFinal || index >= 2 {
            stopSpin()
        }
    }

    func playSRStop() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if srStopPlayer == nil {
            prepareSRStopPlayer()
        }

        guard let srStopPlayer else { return }

        srStopPlayer.currentTime = 0
        srStopPlayer.numberOfLoops = 0
        srStopPlayer.volume = adjustedVolume(0.90)
        srStopPlayer.play()
    }

    func playWarning() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        playOneShot(
            buffer: warningBuffer,
            volume: 0.72
        )
    }

    func playPush() {
        if shouldSuppressNextPushSound {
            shouldSuppressNextPushSound = false
            return
        }

        playPushPress()
    }

    func playPushPress() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if pushPressPlayer == nil {
            preparePushPressPlayer()
        }

        guard let pushPressPlayer else { return }

        pushPressPlayer.currentTime = 0
        pushPressPlayer.volume = adjustedVolume(0.88)
        pushPressPlayer.play()
    }

    func suppressNextPushSound() {
        shouldSuppressNextPushSound = true
    }

    func playPushAppear() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if pushAppearPlayer == nil {
            preparePushAppearPlayer()
        }

        guard let pushAppearPlayer else { return }

        pushAppearPlayer.currentTime = 0
        pushAppearPlayer.volume = adjustedVolume(0.88)
        pushAppearPlayer.play()
    }

    func playGekiatsu() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if gekiatsuPlayer == nil {
            prepareGekiatsuPlayer()
        }

        guard let gekiatsuPlayer else { return }

        gekiatsuPlayer.currentTime = 0
        gekiatsuPlayer.volume = adjustedVolume(0.92)
        gekiatsuPlayer.play()
    }

    func playVMovieSequenceSounds() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if vmovieStartPlayer == nil {
            prepareVMovieStartPlayer()
        }

        guard let vmovieStartPlayer else { return }

        if vmovieFollowPlayer == nil {
            prepareVMovieFollowPlayer()
        }

        if let vmovieFollowPlayer {
            vmovieFollowPlayer.pause()
            vmovieFollowPlayer.seek(to: .zero)
            vmovieFollowPlayer.volume = adjustedVolume(0.92)
            vmovieFollowPlayer.preroll(atRate: 1.0) { _ in }
        }

        vmovieFollowWorkItem?.cancel()
        vmovieFollowWorkItem = nil

        vmovieStartPlayer.currentTime = 0
        vmovieStartPlayer.numberOfLoops = 0
        vmovieStartPlayer.volume = adjustedVolume(0.92)
        vmovieStartPlayer.play()

        let followWorkItem = DispatchWorkItem { [weak self] in
            guard let self,
                  self.isSoundEnabled else {
                return
            }

            self.playVMovieFollow()
            self.vmovieFollowWorkItem = nil
        }

        // 開始音末尾の無音を避け、現在より1.75秒早く接続する。
        let followLeadTime = 1.75
        let followDelay = max(
            0,
            vmovieStartPlayer.duration - followLeadTime
        )

        vmovieFollowWorkItem = followWorkItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + followDelay,
            execute: followWorkItem
        )
    }

    func playBlackoutCharge() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if blackoutChargePlayer == nil {
            prepareBlackoutChargePlayer()
        }

        guard let blackoutChargePlayer else { return }

        blackoutChargePlayer.currentTime = 0
        blackoutChargePlayer.numberOfLoops = 0
        blackoutChargePlayer.volume = adjustedVolume(0.92)
        blackoutChargePlayer.play()
    }

    func stopBlackoutCharge() {
        blackoutChargePlayer?.stop()
        blackoutChargePlayer?.currentTime = 0
    }

    func playFirstStop() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if firstStopPlayer == nil {
            prepareFirstStopPlayer()
        }

        guard let firstStopPlayer else { return }

        shouldSuppressNextFirstReelStopSound = true
        firstStopPlayer.currentTime = 0
        firstStopPlayer.volume = adjustedVolume(0.88)
        firstStopPlayer.play()
    }

    func suppressNextSpinStartSound() {}

    func playTypewriter() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if typewriterPlayers.isEmpty {
            prepareTypewriterPlayers()
        }

        guard !typewriterPlayers.isEmpty else { return }

        let player = typewriterPlayers[nextTypewriterPlayerIndex]
        nextTypewriterPlayerIndex =
            (nextTypewriterPlayerIndex + 1)
            % typewriterPlayers.count

        player.currentTime = 0
        player.volume = adjustedVolume(0.86)
        player.play()
    }

    func playTypewriterImpact() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        if typewriterImpactPlayer == nil {
            prepareTypewriterImpactPlayer()
        }

        guard let typewriterImpactPlayer else { return }

        typewriterImpactPlayer.currentTime = 0
        typewriterImpactPlayer.volume = adjustedVolume(0.92)
        typewriterImpactPlayer.play()
    }

    func playJackpot() {
        guard isSoundEnabled,
              isDefaultJackpotSoundEnabled else { return }

        prepareIfNeeded()
        stopSpin()

        playOneShot(
            buffer: jackpotBuffer,
            volume: 0.86
        )
    }

    func setDefaultJackpotSoundEnabled(_ enabled: Bool) {
        isDefaultJackpotSoundEnabled = enabled
    }

    func playBell() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        playResultOneShot(
            buffer: bellBuffer,
            volume: 0.82
        )
    }

    func playGrape() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        playResultOneShot(
            buffer: grapeBuffer,
            volume: 0.78
        )
    }

    func playSeven() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        stopSpin()

        playResultOneShot(
            buffer: sevenBuffer,
            volume: 0.94
        )
    }

    func playRainbowSeven() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        stopSpin()

        playResultOneShot(
            buffer: rainbowSevenBuffer,
            volume: 0.98
        )
    }

    func playRewardReveal() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        stopSpin()

        // 低い衝撃音 → 金属的な上昇音 → 短い余韻。
        // 派手すぎるファンファーレではなく、筐体らしい高級感を優先。
        playResultOneShot(
            buffer: rewardRevealBuffer,
            volume: 0.84
        )
    }

    func stopSpin() {
        if spinPlayer.isPlaying {
            spinPlayer.stop()
        }
    }

    func stopAll() {
        spinPlayer.stop()
        accentPlayer.stop()
        resultPlayer.stop()
        typewriterPlayers.forEach { $0.stop() }
        typewriterImpactPlayer?.stop()
        pushAppearPlayer?.stop()
        pushPressPlayer?.stop()
        firstStopPlayer?.stop()
        srStopPlayer?.stop()
        gekiatsuPlayer?.stop()
        vmovieFollowWorkItem?.cancel()
        vmovieFollowWorkItem = nil
        vmovieStartPlayer?.stop()
        vmovieFollowPlayer?.pause()
        blackoutChargePlayer?.stop()
        leverPlayer?.stop()
        shouldSuppressNextFirstReelStopSound = false
        shouldSuppressNextPushSound = false

        if engine.isRunning {
            engine.pause()
        }
    }

    // MARK: - Audio Setup

    private func prepareIfNeeded() {
        guard isSoundEnabled else { return }

        do {
            try configureAudioSession()
            prepareEngineIfNeeded()

            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            print(
                "SlotSoundManager audio error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareTypewriterPlayers() {
        guard let url = Bundle.main.url(
            forResource: "typewriter",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: typewriter.mp3 not found")
            return
        }

        typewriterPlayers = (0..<8).compactMap { _ in
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                return player
            } catch {
                print(
                    "SlotSoundManager typewriter error: "
                    + error.localizedDescription
                )
                return nil
            }
        }

        nextTypewriterPlayerIndex = 0
    }

    private func prepareTypewriterImpactPlayer() {
        guard let url = Bundle.main.url(
            forResource: "typewriter_impact",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: typewriter_impact.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            typewriterImpactPlayer = player
        } catch {
            print(
                "SlotSoundManager typewriter impact error: "
                + error.localizedDescription
            )
        }
    }

    private func preparePushAppearPlayer() {
        guard let url = Bundle.main.url(
            forResource: "push_appear",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: push_appear.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            pushAppearPlayer = player
        } catch {
            print(
                "SlotSoundManager push appear error: "
                + error.localizedDescription
            )
        }
    }

    private func preparePushPressPlayer() {
        guard let url = Bundle.main.url(
            forResource: "push_press",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: push_press.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            pushPressPlayer = player
        } catch {
            print(
                "SlotSoundManager push press error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareFirstStopPlayer() {
        guard let url = Bundle.main.url(
            forResource: "first_stop",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: first_stop.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            firstStopPlayer = player
        } catch {
            print(
                "SlotSoundManager first stop error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareSRStopPlayer() {
        guard let url = Bundle.main.url(
            forResource: "stop_sr",
            withExtension: "wav"
        ) else {
            print("SlotSoundManager: stop_sr.wav not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            srStopPlayer = player
        } catch {
            print(
                "SlotSoundManager SR stop error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareGekiatsuPlayer() {
        guard let url = Bundle.main.url(
            forResource: "gekiatsu",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: gekiatsu.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            gekiatsuPlayer = player
        } catch {
            print(
                "SlotSoundManager gekiatsu error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareVMovieStartPlayer() {
        guard let url = Bundle.main.url(
            forResource: "vmovie_start",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: vmovie_start.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            vmovieStartPlayer = player
        } catch {
            print(
                "SlotSoundManager VMovie start error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareVMovieFollowPlayer() {
        guard let url = Bundle.main.url(
            forResource: "vmovie_follow",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: vmovie_follow.mp3 not found")
            return
        }

        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        vmovieFollowPlayer = player
    }

    private func playVMovieFollow() {
        guard isSoundEnabled else { return }

        if vmovieFollowPlayer == nil {
            prepareVMovieFollowPlayer()
        }

        guard let vmovieFollowPlayer else { return }

        vmovieFollowPlayer.volume = adjustedVolume(0.92)
        vmovieFollowPlayer.play()
    }

    private func prepareBlackoutChargePlayer() {
        guard let url = Bundle.main.url(
            forResource: "blackout_charge",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: blackout_charge.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            blackoutChargePlayer = player
        } catch {
            print(
                "SlotSoundManager blackout charge error: "
                + error.localizedDescription
            )
        }
    }

    private func prepareLeverPlayer() {
        guard let url = Bundle.main.url(
            forResource: "lever",
            withExtension: "mp3"
        ) else {
            print("SlotSoundManager: lever.mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            leverPlayer = player
        } catch {
            print(
                "SlotSoundManager lever error: "
                + error.localizedDescription
            )
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .ambient,
            mode: .default,
            options: [.mixWithOthers]
        )

        try session.setActive(true)
    }

    private func prepareEngineIfNeeded() {
        guard !isPrepared else { return }

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: 44_100,
            channels: 1
        ) else {
            return
        }

        engine.attach(spinPlayer)
        engine.attach(accentPlayer)
        engine.attach(resultPlayer)

        engine.connect(
            spinPlayer,
            to: engine.mainMixerNode,
            format: format
        )

        engine.connect(
            accentPlayer,
            to: engine.mainMixerNode,
            format: format
        )

        engine.connect(
            resultPlayer,
            to: engine.mainMixerNode,
            format: format
        )

        spinBuffer = makeSpinLoop(
            format: format,
            intense: false
        )

        intenseSpinBuffer = makeSpinLoop(
            format: format,
            intense: true
        )

        stopBuffer = makeStopSound(
            format: format,
            final: false
        )

        finalStopBuffer = makeStopSound(
            format: format,
            final: true
        )

        pushBuffer = makePushSound(
            format: format
        )

        warningBuffer = makeWarningSound(
            format: format
        )

        jackpotBuffer = makeJackpotSound(
            format: format
        )

        bellBuffer = makeBellSound(
            format: format
        )

        grapeBuffer = makeGrapeSound(
            format: format
        )

        sevenBuffer = makeSevenSound(
            format: format,
            rainbow: false
        )

        rainbowSevenBuffer = makeSevenSound(
            format: format,
            rainbow: true
        )

        rewardRevealBuffer = makeRewardRevealSound(
            format: format
        )

        engine.prepare()
        isPrepared = true
    }

    private func playOneShot(
        buffer: AVAudioPCMBuffer?,
        volume: Float
    ) {
        guard let buffer else { return }

        accentPlayer.stop()

        accentPlayer.scheduleBuffer(
            buffer,
            at: nil,
            options: [],
            completionHandler: nil
        )

        accentPlayer.volume = adjustedVolume(volume)
        accentPlayer.play()
    }

    private func playResultOneShot(
        buffer: AVAudioPCMBuffer?,
        volume: Float
    ) {
        guard let buffer else { return }

        resultPlayer.stop()

        resultPlayer.scheduleBuffer(
            buffer,
            at: nil,
            options: [],
            completionHandler: nil
        )

        resultPlayer.volume = adjustedVolume(volume)
        resultPlayer.play()
    }

    private func adjustedVolume(
        _ baseVolume: Float
    ) -> Float {
        min(
            max(baseVolume * masterVolume, 0),
            1
        )
    }

    private func makeRewardRevealSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: 1.18
        ) { t in
            let impactEnvelope = exp(-t * 15.0)
            let lowImpact =
                sin(2.0 * .pi * 58.0 * t)
                * impactEnvelope
                * 0.52

            let body =
                sin(2.0 * .pi * 116.0 * t)
                * exp(-t * 8.0)
                * 0.20

            let riseProgress = min(
                1.0,
                max(0.0, (t - 0.10) / 0.62)
            )

            let riseFrequency =
                620.0
                + 2_850.0
                * pow(riseProgress, 1.55)

            let riseEnvelope =
                t < 0.10
                ? 0.0
                : sin(.pi * min(1.0, riseProgress))
                  * exp(-max(0.0, t - 0.70) * 5.5)

            let metallicRise =
                sin(2.0 * .pi * riseFrequency * t)
                * riseEnvelope
                * 0.16

            let shimmerEnvelope =
                t < 0.42
                ? 0.0
                : exp(-(t - 0.42) * 4.2)

            let shimmer =
                (
                    sin(2.0 * .pi * 1_760.0 * t)
                    + sin(2.0 * .pi * 2_640.0 * t) * 0.62
                    + sin(2.0 * .pi * 3_520.0 * t) * 0.34
                )
                * shimmerEnvelope
                * 0.075

            return lowImpact + body + metallicRise + shimmer
        }
    }

    // MARK: - Spin Loop

    private func makeSpinLoop(
        format: AVAudioFormat,
        intense: Bool
    ) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = intense ? 1.20 : 1.36

        let frameCount = AVAudioFrameCount(
            sampleRate * duration
        )

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ),
            let channel = buffer.floatChannelData?[0]
        else {
            return nil
        }

        buffer.frameLength = frameCount

        var seed: UInt64 =
            intense ? 0xD1A6C4F2 : 0x7B31E2A9

        var filteredNoise = 0.0
        var phase1 = 0.0
        var phase2 = 0.0
        var phase3 = 0.0

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let loopPhase = t / duration

            let speedWobble =
                sin(2.0 * .pi * 1.35 * t) * 2.8
                + sin(2.0 * .pi * 4.7 * t) * 0.85

            let baseFrequency =
                (intense ? 126.0 : 108.0)
                + speedWobble

            phase1 += 2.0 * .pi * baseFrequency / sampleRate
            phase2 += 2.0 * .pi * baseFrequency * 2.03 / sampleRate
            phase3 += 2.0 * .pi * baseFrequency * 5.08 / sampleRate

            let motor =
                sin(phase1) * (intense ? 0.17 : 0.145)

            let harmonic =
                sin(phase2) * (intense ? 0.082 : 0.068)

            let upperMotor =
                sin(phase3) * (intense ? 0.030 : 0.023)

            // 3本のリールがわずかにずれながら回る機械音。
            var reelTexture = 0.0
            let reelRates: [Double] =
                intense
                ? [22.0, 23.3, 24.7]
                : [18.2, 19.4, 20.7]

            for (index, rate) in reelRates.enumerated() {
                let offset = Double(index) * 0.29
                let position =
                    loopPhase * rate + offset

                let fraction =
                    position - floor(position)

                let envelope =
                    exp(-fraction * 44.0)

                let frequency =
                    1_080.0 + Double(index) * 170.0

                reelTexture +=
                    sin(
                        2.0
                        * .pi
                        * frequency
                        * t
                    )
                    * envelope
                    * (intense ? 0.042 : 0.033)
            }

            seed =
                seed
                &* 6_364_136_223_846_793_005
                &+ 1

            let randomValue =
                Double((seed >> 33) & 0xFFFF)
                / 65_535.0

            let whiteNoise =
                randomValue * 2.0 - 1.0

            // ローパスした空気音で「シャー」という回転感を加える。
            filteredNoise =
                filteredNoise * 0.86
                + whiteNoise * 0.14

            let airNoise =
                filteredNoise
                * (intense ? 0.052 : 0.038)

            let bodyPulse =
                sin(
                    2.0
                    * .pi
                    * (intense ? 8.4 : 6.9)
                    * t
                )
                * 0.018

            // ループの継ぎ目を聞こえにくくする短いクロスフェード。
            let fadeFrames = 640.0

            let startFade =
                min(1.0, Double(frame) / fadeFrames)

            let endFade =
                min(
                    1.0,
                    Double(Int(frameCount) - frame)
                    / fadeFrames
                )

            let loopFade = min(startFade, endFade)

            let sample =
                (
                    motor
                    + harmonic
                    + upperMotor
                    + reelTexture
                    + airNoise
                    + bodyPulse
                )
                * loopFade

            channel[frame] = Float(
                max(-0.62, min(0.62, sample))
            )
        }

        return buffer
    }

    // MARK: - Reel Stop

    private func makeStopSound(
        format: AVAudioFormat,
        final: Bool
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: final ? 0.46 : 0.25
        ) { t in
            let bodyFrequency =
                final ? 104.0 : 138.0

            let body =
                sin(
                    2.0
                    * .pi
                    * bodyFrequency
                    * t
                )
                * exp(
                    -t
                    * (final ? 13.0 : 20.0)
                )
                * (final ? 0.74 : 0.55)

            let metal =
                sin(
                    2.0
                    * .pi
                    * (final ? 520.0 : 680.0)
                    * t
                )
                * exp(-t * 31.0)
                * 0.24

            let snap =
                sin(
                    2.0
                    * .pi
                    * 2_180.0
                    * t
                )
                * exp(-t * 64.0)
                * 0.12

            let tail =
                final
                ? sin(
                    2.0
                    * .pi
                    * 260.0
                    * t
                )
                * exp(-t * 10.0)
                * 0.18
                : 0.0

            return body + metal + snap + tail
        }
    }

    // MARK: - Push

    private func makePushSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: 0.60
        ) { t in
            let low =
                sin(
                    2.0
                    * .pi
                    * 58.0
                    * t
                )
                * exp(-t * 7.5)
                * 0.78

            let punch =
                sin(
                    2.0
                    * .pi
                    * 118.0
                    * t
                )
                * exp(-t * 14.0)
                * 0.44

            let attack =
                sin(
                    2.0
                    * .pi
                    * 1_280.0
                    * t
                )
                * exp(-t * 48.0)
                * 0.14

            return low + punch + attack
        }
    }

    // MARK: - Warning

    private func makeWarningSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: 1.45
        ) { t in
            let pulseIndex =
                floor(t / 0.29)

            let pulseTime =
                t - pulseIndex * 0.29

            let pulseEnvelope =
                exp(-pulseTime * 8.0)

            let sirenFrequency =
                540.0
                + 190.0
                * sin(
                    2.0
                    * .pi
                    * 1.8
                    * t
                )

            let siren =
                sin(
                    2.0
                    * .pi
                    * sirenFrequency
                    * t
                )
                * pulseEnvelope
                * 0.26

            let lowPulse =
                sin(
                    2.0
                    * .pi
                    * 82.0
                    * t
                )
                * pulseEnvelope
                * 0.22

            return siren + lowPulse
        }
    }

    // MARK: - Jackpot

    private func makeJackpotSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let notes: [Double] = [
            523.25,
            659.25,
            783.99,
            1_046.50,
            1_318.51
        ]

        return renderBuffer(
            format: format,
            duration: 2.85
        ) { t in
            var output = 0.0

            for (
                index,
                frequency
            ) in notes.enumerated() {
                let start =
                    Double(index) * 0.24

                let localTime =
                    t - start

                guard localTime >= 0 else {
                    continue
                }

                let envelope =
                    min(
                        1.0,
                        localTime * 18.0
                    )
                    * exp(
                        -localTime * 1.55
                    )

                output +=
                    sin(
                        2.0
                        * .pi
                        * frequency
                        * localTime
                    )
                    * envelope
                    * 0.13

                output +=
                    sin(
                        2.0
                        * .pi
                        * frequency
                        * 2.0
                        * localTime
                    )
                    * envelope
                    * 0.045
            }

            let sweepDuration = 1.75

            let sweepProgress = min(
                1.0,
                t / sweepDuration
            )

            let sweepFrequency =
                360.0
                + 2_650.0
                * pow(
                    sweepProgress,
                    1.8
                )

            let sweep =
                sin(
                    2.0
                    * .pi
                    * sweepFrequency
                    * t
                )
                * sin(
                    .pi
                    * min(
                        1.0,
                        t / 2.0
                    )
                )
                * 0.10

            let bass =
                sin(
                    2.0
                    * .pi
                    * 64.0
                    * t
                )
                * exp(-t * 1.8)
                * 0.22

            return output + sweep + bass
        }
    }

    // MARK: - Bell

    private func makeBellSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let frequencies = [
            1_046.50,
            1_318.51,
            1_568.00
        ]

        return renderBuffer(
            format: format,
            duration: 1.05
        ) { t in
            var output = 0.0

            for (index, frequency) in frequencies.enumerated() {
                let start = Double(index) * 0.10
                let localTime = t - start

                guard localTime >= 0 else { continue }

                let envelope =
                    min(1.0, localTime * 42.0)
                    * exp(-localTime * 4.6)

                output +=
                    sin(2.0 * .pi * frequency * localTime)
                    * envelope
                    * 0.20

                output +=
                    sin(2.0 * .pi * frequency * 2.01 * localTime)
                    * envelope
                    * 0.055
            }

            return output
        }
    }

    // MARK: - Grape payout

    private func makeGrapeSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        return renderBuffer(
            format: format,
            duration: 1.30
        ) { t in
            let tickRate = 17.0
            let tickPosition = t * tickRate
            let tickTime =
                tickPosition - floor(tickPosition)

            let tickEnvelope =
                exp(-tickTime * 34.0)

            let risingFrequency =
                720.0 + 520.0 * min(1.0, t / 1.05)

            let coin =
                sin(
                    2.0
                    * .pi
                    * risingFrequency
                    * t
                )
                * tickEnvelope
                * 0.14

            let shimmer =
                sin(
                    2.0
                    * .pi
                    * 2_240.0
                    * t
                )
                * tickEnvelope
                * 0.045

            let body =
                sin(
                    2.0
                    * .pi
                    * 120.0
                    * t
                )
                * exp(-t * 3.8)
                * 0.10

            return coin + shimmer + body
        }
    }

    // MARK: - Seven / Rainbow Seven

    private func makeSevenSound(
        format: AVAudioFormat,
        rainbow: Bool
    ) -> AVAudioPCMBuffer? {
        let duration = rainbow ? 3.15 : 2.20

        return renderBuffer(
            format: format,
            duration: duration
        ) { t in
            let sweepDuration =
                rainbow ? 2.15 : 1.38

            let progress =
                min(1.0, t / sweepDuration)

            let startFrequency =
                rainbow ? 430.0 : 520.0

            let endFrequency =
                rainbow ? 4_600.0 : 3_350.0

            let sweepFrequency =
                startFrequency
                + (endFrequency - startFrequency)
                * pow(progress, 1.72)

            let sweepEnvelope =
                sin(
                    .pi
                    * min(1.0, t / sweepDuration)
                )
                * exp(
                    -max(0.0, t - sweepDuration)
                    * 2.1
                )

            let sweep =
                sin(
                    2.0
                    * .pi
                    * sweepFrequency
                    * t
                )
                * sweepEnvelope
                * (rainbow ? 0.22 : 0.19)

            let sparkleRate =
                rainbow ? 15.0 : 11.0

            let sparklePosition =
                t * sparkleRate

            let sparkleTime =
                sparklePosition
                - floor(sparklePosition)

            let sparkleEnvelope =
                exp(-sparkleTime * 30.0)

            let sparkle =
                sin(
                    2.0
                    * .pi
                    * (rainbow ? 2_950.0 : 2_350.0)
                    * t
                )
                * sparkleEnvelope
                * (rainbow ? 0.075 : 0.050)

            let bass =
                sin(
                    2.0
                    * .pi
                    * (rainbow ? 68.0 : 82.0)
                    * t
                )
                * exp(-t * 2.4)
                * 0.18

            let rainbowChord: Double

            if rainbow {
                let notes = [
                    523.25,
                    659.25,
                    783.99,
                    1_046.50
                ]

                rainbowChord =
                    notes.enumerated().reduce(0.0) {
                        partial,
                        item in

                        let start =
                            1.20
                            + Double(item.offset)
                            * 0.18

                        let localTime = t - start

                        guard localTime >= 0 else {
                            return partial
                        }

                        let envelope =
                            min(1.0, localTime * 20.0)
                            * exp(-localTime * 1.65)

                        return partial
                            + sin(
                                2.0
                                * .pi
                                * item.element
                                * localTime
                            )
                            * envelope
                            * 0.10
                    }
            } else {
                rainbowChord = 0
            }

            return
                sweep
                + sparkle
                + bass
                + rainbowChord
        }
    }

    // MARK: - Renderer

    private func renderBuffer(
        format: AVAudioFormat,
        duration: Double,
        generator: (Double) -> Double
    ) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate

        let frameCount =
            AVAudioFrameCount(
                sampleRate * duration
            )

        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ),
            let channel =
                buffer.floatChannelData?[0]
        else {
            return nil
        }

        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let t =
                Double(frame) / sampleRate

            let sample =
                generator(t)

            channel[frame] = Float(
                max(
                    -0.92,
                    min(0.92, sample)
                )
            )
        }

        return buffer
    }
}
