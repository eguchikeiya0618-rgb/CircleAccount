//
//  VMovieOverlay.swift
//  CircleAccount
//
//  Bundle内の動画を全画面で再生するPremium演出用Overlay。
//

import SwiftUI
import AVKit

struct BundleMovieOverlay: View {
    let movieName: String
    var fileExtension = "mp4"
    var fadeDuration = 0.35
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
        ZStack {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .background(Color.black)
                    .allowsHitTesting(false)
            }
        }
        .opacity(overlayOpacity)
        .background(Color.black.ignoresSafeArea())
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

struct BonusMovieOverlay: View {
    let onFinished: () -> Void

    var body: some View {
        BundleMovieOverlay(
            movieName: "BonusMovie",
            onFinished: onFinished
        )
    }
}

#Preview {
    VMovieOverlay {
    }
}
