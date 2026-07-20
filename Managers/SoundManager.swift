import Foundation
import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()

    private var bgmPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []

    private init() {
        configureAudioSession()
    }

    // MARK: - オーディオ設定

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )

            try session.setActive(true)
        } catch {
            print(
                "オーディオ設定失敗: "
                + error.localizedDescription
            )
        }
    }

    // MARK: - MVPファンファーレ

    func playMVPBGM() {
        playBGM(
            fileName: "ラッパのファンファーレ",
            fileExtension: "mp3",
            volume: 0.85,
            loop: false
        )
    }

    func stopMVPBGM(
        fadeDuration: TimeInterval = 0.45
    ) {
        fadeOutBGM(
            duration: fadeDuration
        )
    }

    // MARK: - MVP効果音

    func playMVPIntroSound() {
        playSystemSound(
            soundID: 1113
        )
    }

    func playMVPRevealSound() {
        playSystemSound(
            soundID: 1025
        )
    }

    func playCrownSound() {
        playSystemSound(
            soundID: 1057
        )
    }

    func playResultButtonSound() {
        playSystemSound(
            soundID: 1104
        )
    }

    // MARK: - BGM共通処理

    private func playBGM(
        fileName: String,
        fileExtension: String,
        volume: Float,
        loop: Bool
    ) {
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: fileExtension
            )
        else {
            print(
                "音声ファイルが見つかりません: "
                + fileName
                + "."
                + fileExtension
            )
            return
        }

        do {
            bgmPlayer?.stop()

            let player = try AVAudioPlayer(
                contentsOf: url
            )

            player.numberOfLoops = loop ? -1 : 0
            player.volume = volume
            player.prepareToPlay()
            player.play()

            bgmPlayer = player

            print(
                "MVPファンファーレ再生開始"
            )
        } catch {
            print(
                "音声再生失敗: "
                + error.localizedDescription
            )
        }
    }

    // MARK: - フェードアウト

    private func fadeOutBGM(
        duration: TimeInterval
    ) {
        guard let player = bgmPlayer else {
            return
        }

        let steps = 15
        let originalVolume = player.volume
        let interval =
            duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(
                deadline:
                    .now()
                    + interval * Double(step)
            ) {
                let progress =
                    Float(step)
                    / Float(steps)

                player.volume =
                    originalVolume
                    * (1 - progress)

                if step == steps {
                    player.stop()
                    player.currentTime = 0
                    self.bgmPlayer = nil
                }
            }
        }
    }

    // MARK: - システム効果音

    private func playSystemSound(
        soundID: SystemSoundID
    ) {
        AudioServicesPlaySystemSound(
            soundID
        )
    }

    // MARK: - 全停止

    func stopAllSounds() {
        bgmPlayer?.stop()
        bgmPlayer = nil

        effectPlayers.forEach {
            $0.stop()
        }

        effectPlayers.removeAll()
    }
}
