//
//  PremiumBonusVideoSequenceOverlay.swift
//  CircleAccount
//
//  PUSH後に VMovie.mp4 → BonusMovie.mp4 を連続再生する専用Overlay
//

import SwiftUI
import UIKit
import AVFoundation
import Combine

struct PremiumBonusVideoSequenceOverlay: View {
    let trigger: Int
    let vMovieName: String
    let bonusMovieName: String
    let onFinished: () -> Void

    @StateObject private var controller = PremiumBonusVideoSequenceController()

    var body: some View {
        ZStack {
            if controller.isVisible {
                Color.black

                if let player = controller.player {
                    PremiumPlayerLayerView(player: player)
                        .transition(.opacity)
                }

                if let errorMessage = controller.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.yellow)

                        Text("動画を読み込めません")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)

                        Text(errorMessage)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                    .padding(24)
                }
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
        )
        .background(Color.clear)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }

            controller.play(
                vMovieName: vMovieName,
                bonusMovieName: bonusMovieName,
                fileExtension: "mp4",
                onFinished: onFinished
            )
        }
        .onDisappear {
            controller.stop()
        }
    }
}

@MainActor
private final class PremiumBonusVideoSequenceController: ObservableObject {
    @Published private(set) var player: AVQueuePlayer?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isVisible = false

    private var endObserver: NSObjectProtocol?
    private var completion: (() -> Void)?

    func play(
        vMovieName: String,
        bonusMovieName: String,
        fileExtension: String,
        onFinished: @escaping () -> Void
    ) {
        stop()

        errorMessage = nil
        completion = onFinished
        isVisible = true

        guard let vURL = Bundle.main.url(
            forResource: vMovieName,
            withExtension: fileExtension
        ) else {
            errorMessage = "\(vMovieName).\(fileExtension) をTarget MembershipとCopy Bundle Resourcesへ追加してください。"
            return
        }

        guard let bonusURL = Bundle.main.url(
            forResource: bonusMovieName,
            withExtension: fileExtension
        ) else {
            errorMessage = "\(bonusMovieName).\(fileExtension) をTarget MembershipとCopy Bundle Resourcesへ追加してください。"
            return
        }

        let vItem = AVPlayerItem(url: vURL)
        let bonusItem = AVPlayerItem(url: bonusURL)
        let queuePlayer = AVQueuePlayer(items: [vItem, bonusItem])

        queuePlayer.actionAtItemEnd = .advance
        queuePlayer.isMuted = false
        queuePlayer.volume = 1.0

        player = queuePlayer

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: bonusItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let finished = self.completion
                self.stop()
                finished?()
            }
        }

        queuePlayer.play()
    }

    func stop() {
        player?.pause()
        player?.removeAllItems()
        player = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        completion = nil
        errorMessage = nil
        isVisible = false
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}

private struct PremiumPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PremiumPlayerUIView {
        let view = PremiumPlayerUIView()
        view.playerLayer.player = player
        return view
    }

    func updateUIView(
        _ uiView: PremiumPlayerUIView,
        context: Context
    ) {
        uiView.playerLayer.player = player
    }

    static func dismantleUIView(
        _ uiView: PremiumPlayerUIView,
        coordinator: Void
    ) {
        uiView.playerLayer.player = nil
    }
}

private final class PremiumPlayerUIView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let playerLayer = layer as? AVPlayerLayer else {
            fatalError("AVPlayerLayerの生成に失敗しました。")
        }

        return playerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
    }
}

