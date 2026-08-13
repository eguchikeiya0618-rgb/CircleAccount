//
//  VMovieOverlay.swift
//  CircleAccount
//
//  Bundle内の動画を全画面で再生するPremium演出用Overlay。
//

import SwiftUI
import AVKit
import UIKit


private final class BundleMoviePlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    func configure(
        player: AVPlayer,
        videoGravity: AVLayerVideoGravity
    ) {
        playerLayer.player = player
        playerLayer.videoGravity = videoGravity
        playerLayer.masksToBounds = true
        playerLayer.backgroundColor = UIColor.clear.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

private struct BundleMoviePlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> BundleMoviePlayerUIView {
        let view = BundleMoviePlayerUIView()
        view.backgroundColor = .clear
        view.configure(
            player: player,
            videoGravity: videoGravity
        )
        return view
    }

    func updateUIView(
        _ uiView: BundleMoviePlayerUIView,
        context: Context
    ) {
        uiView.configure(
            player: player,
            videoGravity: videoGravity
        )
    }
}

struct BundleMovieOverlay: View {
    let movieName: String
    var fileExtension = "mp4"
    var fadeDuration = 0.35
    var contentMode: ContentMode = .fit
    var isOpaquePresentation = false
    var endLeadTime: Double?
    var onApproachingEnd: (() -> Void)?
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var overlayOpacity = 0.0
    @State private var playbackToken = UUID()
    @State private var hasFinished = false
    @State private var hasNotifiedApproachingEnd = false
    @State private var endObserver: NSObjectProtocol?
    @State private var timeObserver: Any?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                if let player {
                    BundleMoviePlayerLayer(
                        player: player,
                        videoGravity: .resizeAspectFill
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .allowsHitTesting(false)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .opacity(isOpaquePresentation ? 1 : overlayOpacity)
        .background(Color.black)
        .onAppear {
            startPlayback()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private func startPlayback() {
        let token = UUID()
        playbackToken = token
        hasFinished = false
        hasNotifiedApproachingEnd = false
        overlayOpacity = 0

        guard let url = Bundle.main.url(
            forResource: movieName,
            withExtension: fileExtension
        ) else {
            finishPlayback(token: token)
            return
        }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)

        newPlayer.actionAtItemEnd = .pause
        newPlayer.isMuted = SlotSoundManager.shared
            .shouldMuteEmbeddedAudio(for: movieName)
        newPlayer.volume = newPlayer.isMuted ? 0 : 1
        player = newPlayer

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            Task { @MainActor in
                finishPlayback(token: token)
            }
        }

        if let endLeadTime,
           endLeadTime > 0,
           onApproachingEnd != nil {
            timeObserver = newPlayer.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
                queue: .main
            ) { currentTime in
                let duration = item.duration.seconds

                guard duration.isFinite,
                      duration > 0,
                      duration - currentTime.seconds <= endLeadTime else {
                    return
                }

                Task { @MainActor in
                    notifyApproachingEnd(token: token)
                }
            }
        }

        withAnimation(.easeIn(duration: fadeDuration)) {
            overlayOpacity = 1
        }

        newPlayer.play()
    }

    @MainActor
    private func finishPlayback(token: UUID) {
        guard token == playbackToken,
              !hasFinished else {
            return
        }

        hasFinished = true
        player?.pause()

        withAnimation(.easeOut(duration: fadeDuration)) {
            overlayOpacity = 0
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + fadeDuration
        ) {
            guard token == playbackToken else { return }

            stopPlayback()
            onFinished()
        }
    }

    @MainActor
    private func notifyApproachingEnd(token: UUID) {
        guard token == playbackToken,
              !hasFinished,
              !hasNotifiedApproachingEnd else {
            return
        }

        hasNotifiedApproachingEnd = true
        onApproachingEnd?()
    }

    @MainActor
    private func stopPlayback() {
        if let timeObserver,
           let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        player?.pause()
        player = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}

struct VMovieOverlay: View {
    let onFinished: () -> Void

    var body: some View {
        BundleMovieOverlay(
            movieName: "VMovie",
            onFinished: onFinished
        )
    }
}

#Preview {
    VMovieOverlay {
    }
}
