import AVFoundation
import AudioToolbox

final class SlotSoundManager {
    static let shared = SlotSoundManager()

    private let engine = AVAudioEngine()
    private let spinPlayer = AVAudioPlayerNode()
    private let accentPlayer = AVAudioPlayerNode()
    private let resultPlayer = AVAudioPlayerNode()

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

    private var isPrepared = false
    private var isSoundEnabled = true

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
        spinPlayer.stop()

        guard let spinBuffer else { return }

        spinPlayer.scheduleBuffer(
            spinBuffer,
            at: nil,
            options: [.loops],
            completionHandler: nil
        )

        spinPlayer.volume = 0.34
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

        spinPlayer.volume = 0.42
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

        accentPlayer.volume = volume
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

        resultPlayer.volume = volume
        resultPlayer.play()
    }

    // MARK: - Spin Loop

    private func makeSpinLoop(
        format: AVAudioFormat,
        intense: Bool
    ) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = intense ? 0.96 : 1.12

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

        var seed: UInt64 = intense
            ? 0x98A7B6C5
            : 0x1234ABCD

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let loopPhase = t / duration

            let baseFrequency =
                intense ? 92.0 : 78.0

            let motorSweep =
                intense ? 21.0 : 13.0

            let motorFrequency =
                baseFrequency
                + motorSweep
                * sin(loopPhase * .pi * 2.0)

            let motor =
                sin(
                    2.0
                    * .pi
                    * motorFrequency
                    * t
                )
                * 0.17

            let harmonic =
                sin(
                    2.0
                    * .pi
                    * motorFrequency
                    * 2.02
                    * t
                )
                * 0.075

            let highMotor =
                sin(
                    2.0
                    * .pi
                    * motorFrequency
                    * 4.01
                    * t
                )
                * 0.027

            let reelRate =
                intense ? 18.0 : 14.0

            let reelPosition =
                loopPhase * reelRate

            let reelFraction =
                reelPosition
                - floor(reelPosition)

            let reelEnvelope =
                exp(-reelFraction * 52.0)

            let reelTick =
                sin(
                    2.0
                    * .pi
                    * 1_280.0
                    * t
                )
                * reelEnvelope
                * (intense ? 0.075 : 0.058)

            seed =
                seed
                &* 6_364_136_223_846_793_005
                &+ 1

            let randomValue =
                Double(
                    (seed >> 33) & 0xFFFF
                )
                / 65_535.0

            let mechanicalNoise =
                (randomValue * 2.0 - 1.0)
                * (intense ? 0.028 : 0.020)

            let wobble =
                0.88
                + 0.12
                * sin(
                    2.0
                    * .pi
                    * (intense ? 9.0 : 7.0)
                    * t
                )

            let fadeFrames = 420.0

            let startFade = min(
                1.0,
                Double(frame) / fadeFrames
            )

            let endFade = min(
                1.0,
                Double(
                    Int(frameCount) - frame
                ) / fadeFrames
            )

            let loopFade = min(
                startFade,
                endFade
            )

            let sample =
                (
                    motor
                    + harmonic
                    + highMotor
                    + reelTick
                    + mechanicalNoise
                )
                * wobble
                * loopFade

            channel[frame] = Float(
                max(
                    -0.55,
                    min(0.55, sample)
                )
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
            duration: 0.34
        ) { t in
            let knock =
                sin(
                    2.0
                    * .pi
                    * 112.0
                    * t
                )
                * exp(-t * 24.0)
                * 0.72

            let metal =
                sin(
                    2.0
                    * .pi
                    * 720.0
                    * t
                )
                * exp(-t * 34.0)
                * 0.20

            let click =
                sin(
                    2.0
                    * .pi
                    * 1_950.0
                    * t
                )
                * exp(-t * 58.0)
                * 0.14

            return knock + metal + click
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
