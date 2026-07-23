import AVFoundation
import AudioToolbox

final class SlotSoundManager {
    static let shared = SlotSoundManager()

    private let engine = AVAudioEngine()
    private let spinPlayer = AVAudioPlayerNode()
    private let accentPlayer = AVAudioPlayerNode()
    private let resultPlayer = AVAudioPlayerNode()

    private var spinStartBuffer: AVAudioPCMBuffer?
    private var spinBuffer: AVAudioPCMBuffer?
    private var intenseSpinBuffer: AVAudioPCMBuffer?
    private var leverBuffer: AVAudioPCMBuffer?
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
    private var masterVolume: Float = 0.80
    private var currentSpinBaseVolume: Float = 0.34

    private init() {}

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
        playOneShot(
            buffer: leverBuffer,
            volume: 0.82
        )
    }

    func startSpin() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()

        // 実機風の「始動音」を先に鳴らしてから、
        // モーターとリールの回転ループへつなげる。
        playOneShot(
            buffer: spinStartBuffer,
            volume: 0.78
        )

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

        let selectedBuffer =
            isFinal ? finalStopBuffer : stopBuffer

        let selectedVolume: Float =
            isFinal ? 0.92 : 0.72

        playOneShot(
            buffer: selectedBuffer,
            volume: selectedVolume
        )

        if isFinal || index >= 2 {
            stopSpin()
        }
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
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        playOneShot(
            buffer: pushBuffer,
            volume: 0.88
        )
    }

    func playJackpot() {
        guard isSoundEnabled else { return }

        prepareIfNeeded()
        stopSpin()

        playOneShot(
            buffer: jackpotBuffer,
            volume: 0.86
        )
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

        spinStartBuffer = makeSpinStartSound(
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

        leverBuffer = makeLeverSound(
            format: format
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

    // MARK: - Spin Start / Loop

    private func makeSpinStartSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: 0.48
        ) { t in
            let progress = min(1.0, t / 0.48)

            // モーターが一気に立ち上がる低音。
            let motorFrequency =
                54.0
                + 118.0
                * pow(progress, 0.72)

            let motorEnvelope =
                min(1.0, t * 20.0)
                * exp(-max(0.0, t - 0.30) * 7.0)

            let motor =
                sin(
                    2.0
                    * .pi
                    * motorFrequency
                    * t
                )
                * motorEnvelope
                * 0.42

            // ベルト・ギアが噛み合う機械的な成分。
            let gearFrequency =
                620.0
                + 1_450.0
                * pow(progress, 1.20)

            let gear =
                sin(
                    2.0
                    * .pi
                    * gearFrequency
                    * t
                )
                * exp(-t * 4.8)
                * 0.13

            let clutch =
                sin(
                    2.0
                    * .pi
                    * 118.0
                    * t
                )
                * exp(-t * 18.0)
                * 0.34

            let highWhirr =
                sin(
                    2.0
                    * .pi
                    * (
                        1_100.0
                        + 2_400.0 * progress
                    )
                    * t
                )
                * min(1.0, t * 9.0)
                * exp(-t * 3.1)
                * 0.055

            return motor + gear + clutch + highWhirr
        }
    }

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

    // MARK: - Lever

    private func makeLeverSound(
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        renderBuffer(
            format: format,
            duration: 0.38
        ) { t in
            let mainKnock =
                sin(
                    2.0
                    * .pi
                    * 86.0
                    * t
                )
                * exp(-t * 18.0)
                * 0.82

            let lockBody =
                sin(
                    2.0
                    * .pi
                    * 154.0
                    * t
                )
                * exp(-t * 23.0)
                * 0.42

            let metal =
                sin(
                    2.0
                    * .pi
                    * 760.0
                    * t
                )
                * exp(-t * 31.0)
                * 0.18

            let latchTime = t - 0.105

            let latch =
                latchTime >= 0
                ? sin(
                    2.0
                    * .pi
                    * 1_680.0
                    * latchTime
                )
                * exp(-latchTime * 58.0)
                * 0.20
                : 0.0

            return
                mainKnock
                + lockBody
                + metal
                + latch
        }
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
