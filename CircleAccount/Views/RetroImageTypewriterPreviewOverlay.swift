//
//  RetroImageTypewriterPreviewOverlay.swift
//  CircleAccount
//
//  完全静止フレーム切替版
//
//  各文字のフェード・拡大縮小・揺れ・毎文字SEをすべて廃止。
//  1枚の画像を一定時間表示して次の画像へ直接切り替えるため、
//  フレーム落ちが起きても文字を読み飛ばしにくい構成です。
//

import SwiftUI
import UIKit
import AVFoundation

extension Notification.Name {
    static let retroTypewriterPreviewDidFinish =
        Notification.Name("RetroImageTypewriterPreviewDidFinish")
}

struct RetroImageTypewriterPreviewOverlay: View {

    let trigger: Int
    var onFinished: (() -> Void)? = nil

    @State private var isVisible = false
    @State private var currentFrame: TypewriterFrame?
    @State private var finalCardVisible = false
    @State private var finalImpactPlayer: AVAudioPlayer?
    @State private var playbackTask: Task<Void, Never>?

    private static let imageCache: [String: UIImage] = {
        let names = [
            "Typewriter_次",
            "Typewriter_回",
            "Typewriter_黄",
            "Typewriter_金",
            "Typewriter_の",
            "Typewriter_の_1",
            "Typewriter_の_2",
            "Typewriter_V",
            "Typewriter_読点",
            "Typewriter_、",
            "Typewriter_覚",
            "Typewriter_醒",
            "Typewriter_運",
            "Typewriter_命",
            "Typewriter_777",
            "Typewriter_を",
            "Typewriter_掴",
            "Typewriter_み",
            "Typewriter_取",
            "Typewriter_れ",
            "TypewriterFinalCard"
        ]

        var result: [String: UIImage] = [:]

        for name in names {
            if let image = UIImage(named: name) {
                result[name] = image.preparingForDisplay() ?? image
            }
        }

        return result
    }()

    private let frames: [TypewriterFrame] = [
        .init(text: "次", imageNames: ["Typewriter_次"], duration: 0.34),
        .init(text: "回", imageNames: ["Typewriter_回"], duration: 0.44),

        .init(text: "黄", imageNames: ["Typewriter_黄"], duration: 0.34),
        .init(text: "金", imageNames: ["Typewriter_金"], duration: 0.34),
        .init(text: "の", imageNames: ["Typewriter_の", "Typewriter_の_1"], duration: 0.34),
        .init(text: "V", imageNames: ["Typewriter_V"], duration: 0.48),

        .init(text: "、", imageNames: ["Typewriter_読点", "Typewriter_、"], duration: 0.34),

        .init(text: "覚", imageNames: ["Typewriter_覚"], duration: 0.38),
        .init(text: "醒", imageNames: ["Typewriter_醒"], duration: 0.58),

        .init(text: "運", imageNames: ["Typewriter_運"], duration: 0.38),
        .init(text: "命", imageNames: ["Typewriter_命"], duration: 0.38),
        .init(text: "の", imageNames: ["Typewriter_の_2", "Typewriter_の"], duration: 0.38),

        .init(text: "777", imageNames: ["Typewriter_777"], duration: 0.82),

        .init(text: "を", imageNames: ["Typewriter_を"], duration: 0.40),
        .init(text: "掴", imageNames: ["Typewriter_掴"], duration: 0.78),
        .init(text: "み", imageNames: ["Typewriter_み"], duration: 0.54),
        .init(text: "取", imageNames: ["Typewriter_取"], duration: 0.66),
        .init(text: "れ", imageNames: ["Typewriter_れ"], duration: 0.72)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    Color.black
                        .ignoresSafeArea()

                    if finalCardVisible {
                        finalCard(size: proxy.size)
                    } else if let currentFrame {
                        frameView(currentFrame, size: proxy.size)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, value in
            guard value > 0 else { return }
            startPlayback()
        }
        .onDisappear {
            playbackTask?.cancel()
            playbackTask = nil
        }
    }

    @ViewBuilder
    private func frameView(
        _ frame: TypewriterFrame,
        size: CGSize
    ) -> some View {
        if let image = resolvedImage(frame.imageNames) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(
                    width: frame.text == "777"
                        ? min(size.width * 0.94, 560)
                        : min(size.width * 0.80, 370),
                    height: frame.text == "777"
                        ? min(size.height * 0.50, 310)
                        : min(size.height * 0.64, 440)
                )
                .drawingGroup(opaque: false, colorMode: .nonLinear)
        } else {
            Text(frame.text)
                .font(
                    .system(
                        size: frame.text == "777"
                            ? min(size.width * 0.30, 126)
                            : min(size.width * 0.53, 210),
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    Color(red: 0.96, green: 0.94, blue: 0.89)
                )
        }
    }

    @ViewBuilder
    private func finalCard(size: CGSize) -> some View {
        if let image = Self.imageCache["TypewriterFinalCard"] {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(
                    width: size.width * 0.96,
                    height: size.height * 0.91
                )
                .drawingGroup(opaque: false, colorMode: .nonLinear)
        } else {
            VStack(spacing: 18) {
                Text("次回")
                Text("黄金のV、覚醒")
                Text("運命の777を掴み取れ")
            }
            .font(
                .system(
                    size: min(size.width * 0.095, 40),
                    weight: .black,
                    design: .serif
                )
            )
            .foregroundStyle(
                Color(red: 0.96, green: 0.94, blue: 0.89)
            )
        }
    }

    private func startPlayback() {
        playbackTask?.cancel()

        isVisible = true
        finalCardVisible = false
        currentFrame = nil
        prepareFinalImpactSound()

        playbackTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }

            for frame in frames {
                currentFrame = frame

                try? await Task.sleep(
                    for: .milliseconds(
                        Int(frame.duration * 1_000)
                    )
                )

                guard !Task.isCancelled else { return }
            }

            currentFrame = nil
            playFinalImpact()
            finalCardVisible = true

            try? await Task.sleep(for: .milliseconds(4_200))
            guard !Task.isCancelled else { return }

            isVisible = false
            finalCardVisible = false

            NotificationCenter.default.post(
                name: .retroTypewriterPreviewDidFinish,
                object: nil
            )

            onFinished?()
            playbackTask = nil
        }
    }

    private func resolvedImage(_ names: [String]) -> UIImage? {
        for name in names {
            if let image = Self.imageCache[name] {
                return image
            }
        }
        return nil
    }

    private func prepareFinalImpactSound() {
        guard finalImpactPlayer == nil else { return }

        let extensions = ["caf", "wav", "mp3", "m4a"]

        guard let url = extensions.compactMap({
            Bundle.main.url(
                forResource: "previewImpact",
                withExtension: $0
            )
        }).first else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1
            player.prepareToPlay()
            finalImpactPlayer = player
        } catch {
            finalImpactPlayer = nil
        }
    }

    private func playFinalImpact() {
        finalImpactPlayer?.currentTime = 0
        finalImpactPlayer?.play()

        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        feedback.notificationOccurred(.success)
    }
}

private struct TypewriterFrame {
    let text: String
    let imageNames: [String]
    let duration: Double
}

#Preview {
    RetroImageTypewriterPreviewOverlay(trigger: 1)
        .frame(width: 380, height: 560)
}

