//
//  RetroImageTypewriterPreviewOverlay.swift
//  CircleAccount
//
//  全20文字・同一テンポ・文字飛び防止・終了通知同期版
//
//  「次 回 黄 金 の V 、 覚 醒 運 命 の 7 7 7 を 掴 み 取 れ」
//  を、最初から最後まで同じ中央大表示・同じ打鍵演出で再生します。
//  前の文字は残さず、1文字ずつ切り替わります。
//  最後に TypewriterFinalCard を全文表示します。
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

    @State private var sequenceToken = 0
    @State private var playbackTask: Task<Void, Never>?
    @State private var isVisible = false

    @State private var currentStep: TypewriterStep?
    @State private var currentImage: UIImage?

    @State private var glyphOpacity = 0.0
    @State private var glyphScale: CGFloat = 1.48
    @State private var glyphRotation: Double = 0
    @State private var glyphOffset = CGSize.zero

    @State private var inkBurstOpacity = 0.0
    @State private var inkBurstScale: CGFloat = 0.42

    @State private var finalCardOpacity = 0.0
    @State private var finalCardScale: CGFloat = 1.22
    @State private var finalCardBlur: CGFloat = 12

    @State private var whiteFlashOpacity = 0.0
    @State private var redFlashOpacity = 0.0

    @State private var screenOffset = CGSize.zero
    @State private var screenScale: CGFloat = 1
    @State private var screenOpacity = 1.0

    @State private var audioPlayer: AVAudioPlayer?

    private let steps: [TypewriterStep] = [
        // 全20文字をほぼ同一テンポで表示。
        // 「回」「、」「醒」「最後のれ」だけ、区切りとしてごく僅かに長くしています。
        .init(character: "次", candidates: ["Typewriter_次"], hold: 0.38, blank: 0.08),
        .init(character: "回", candidates: ["Typewriter_回"], hold: 0.38, blank: 0.08),

        .init(character: "黄", candidates: ["Typewriter_黄"], hold: 0.38, blank: 0.08),
        .init(character: "金", candidates: ["Typewriter_金"], hold: 0.38, blank: 0.08),
        .init(character: "の", candidates: ["Typewriter_の", "Typewriter_の_1"], hold: 0.38, blank: 0.08),
        .init(character: "V", candidates: ["Typewriter_V"], hold: 0.38, blank: 0.08),
        .init(character: "、", candidates: ["Typewriter_読点", "Typewriter_、"], hold: 0.38, blank: 0.08),
        .init(character: "覚", candidates: ["Typewriter_覚"], hold: 0.38, blank: 0.08),
        .init(character: "醒", candidates: ["Typewriter_醒"], hold: 0.38, blank: 0.08),

        .init(character: "運", candidates: ["Typewriter_運"], hold: 0.38, blank: 0.08),
        .init(character: "命", candidates: ["Typewriter_命"], hold: 0.38, blank: 0.08),
        .init(character: "の", candidates: ["Typewriter_の_2", "Typewriter_の"], hold: 0.38, blank: 0.08),

        // 777は間を空けず、三連打のリズムで表示。
        .init(character: "7", candidates: ["Typewriter_7_1"], hold: 0.38, blank: 0.08),
        .init(character: "7", candidates: ["Typewriter_7_2", "Typewriter_7_1"], hold: 0.38, blank: 0.08),
        .init(character: "7", candidates: ["Typewriter_7_3", "Typewriter_7_1"], hold: 0.38, blank: 0.08),

        .init(character: "を", candidates: ["Typewriter_を"], hold: 0.38, blank: 0.08),
        .init(character: "掴", candidates: ["Typewriter_掴"], hold: 0.38, blank: 0.08),
        .init(character: "み", candidates: ["Typewriter_み"], hold: 0.38, blank: 0.08),
        .init(character: "取", candidates: ["Typewriter_取"], hold: 0.38, blank: 0.08),
        .init(character: "れ", candidates: ["Typewriter_れ"], hold: 0.38, blank: 0.08)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    Color.black
                        .ignoresSafeArea()

                    subtleFilmLayer(size: proxy.size)
                    singleCharacterLayer(size: proxy.size)
                    finalCardLayer(size: proxy.size)

                    Color.red
                        .opacity(redFlashOpacity)
                        .ignoresSafeArea()
                        .blendMode(.plusLighter)

                    Color.white
                        .opacity(whiteFlashOpacity)
                        .ignoresSafeArea()
                        .blendMode(.plusLighter)
                }
            }
            .scaleEffect(screenScale)
            .offset(screenOffset)
            .opacity(screenOpacity)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, value in
            guard value > 0 else { return }
            play()
        }
        .onDisappear {
            playbackTask?.cancel()
            playbackTask = nil
        }
    }

    private func subtleFilmLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<26, id: \.self) { index in
                Circle()
                    .fill(
                        index.isMultiple(of: 5)
                        ? Color.red.opacity(0.08)
                        : Color.white.opacity(0.03)
                    )
                    .frame(
                        width: CGFloat(1 + index % 3),
                        height: CGFloat(1 + index % 3)
                    )
                    .position(
                        x: CGFloat((index * 83) % max(Int(size.width), 1)),
                        y: CGFloat((index * 131) % max(Int(size.height), 1))
                    )
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color.red.opacity(0.03),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func singleCharacterLayer(size: CGSize) -> some View {
        ZStack {
            if let step = currentStep {
                inkBurst
                    .opacity(inkBurstOpacity)
                    .scaleEffect(inkBurstScale)

                if let currentImage {
                    Image(uiImage: currentImage)
                        .resizable()
                        .scaledToFit()
                        // 全文字を同じ枠に入れて統一表示
                        .frame(
                            width: min(size.width * 0.78, 360),
                            height: min(size.height * 0.62, 430)
                        )
                        .scaleEffect(glyphScale)
                        .rotationEffect(.degrees(glyphRotation))
                        .offset(glyphOffset)
                        .opacity(glyphOpacity)
                        .shadow(color: .white.opacity(0.12), radius: 8)
                } else {
                    Text(step.character)
                        .font(
                            .system(
                                size: min(size.width * 0.53, 210),
                                weight: .black,
                                design: .serif
                            )
                        )
                        .foregroundStyle(
                            Color(red: 0.96, green: 0.94, blue: 0.89)
                        )
                        .frame(
                            width: min(size.width * 0.78, 360),
                            height: min(size.height * 0.62, 430)
                        )
                        .scaleEffect(glyphScale)
                        .rotationEffect(.degrees(glyphRotation))
                        .offset(glyphOffset)
                        .opacity(glyphOpacity)
                        .shadow(color: .white.opacity(0.12), radius: 8)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(finalCardOpacity > 0 ? 0 : 1)
    }

    private var inkBurst: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                Capsule()
                    .fill(
                        index.isMultiple(of: 4)
                        ? Color.red.opacity(0.48)
                        : Color.white.opacity(0.32)
                    )
                    .frame(
                        width: CGFloat(3 + index % 4),
                        height: CGFloat(16 + index % 5 * 5)
                    )
                    .offset(y: -88)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 3)
                .frame(width: 176, height: 176)
        }
    }

    private func finalCardLayer(size: CGSize) -> some View {
        Group {
            if let image = resolvedImage(candidates: ["TypewriterFinalCard"]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
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
        .frame(width: size.width * 0.96, height: size.height * 0.91)
        .scaleEffect(finalCardScale)
        .blur(radius: finalCardBlur)
        .opacity(finalCardOpacity)
        .shadow(color: .white.opacity(0.12), radius: 14)
    }

    private func play() {
        // 前回の予約・再生が残っていても、必ずここで停止します。
        playbackTask?.cancel()
        playbackTask = nil

        sequenceToken += 1
        let token = sequenceToken

        reset()
        isVisible = true

        // 文字を一括予約せず、1文字ずつ順番に処理します。
        // これにより後半の文字飛び・順番逆転・PUSHの割り込みを防ぎます。
        playbackTask = Task { @MainActor in
            await runSequence(token: token)
        }
    }

    @MainActor
    private func runSequence(token: Int) async {
        guard await waitForSequence(0.42, token: token) else { return }

        for step in steps {
            guard token == sequenceToken, !Task.isCancelled else { return }

            // 先に前の文字を完全に消してから、次の文字を表示します。
            currentStep = nil
            currentImage = nil
            glyphOpacity = 0
            glyphScale = 1.48
            glyphRotation = 0
            glyphOffset = .zero

            guard await waitForSequence(step.blank, token: token) else { return }

            show(step)

            // 全20文字を同じ表示時間に統一。
            // hideアニメーションを挟まないため、最後の7や「を」も短くなりません。
            guard await waitForSequence(step.hold, token: token) else { return }

            currentStep = nil
            currentImage = nil
            glyphOpacity = 0
        }

        currentStep = nil
        currentImage = nil
        playFinalImpact()

        guard await waitForSequence(0.22, token: token) else { return }

        showFinalCard()

        // 最終カードは表示開始から合計4.00秒維持します。
        guard await waitForSequence(3.70, token: token) else { return }

        redFlashOpacity = 0.34
        withAnimation(.easeOut(duration: 0.20)) {
            redFlashOpacity = 0
        }

        guard await waitForSequence(0.30, token: token) else { return }

        // 4秒表示した後に画面を閉じます。
        withAnimation(.easeIn(duration: 0.28)) {
            screenOpacity = 0
            screenScale = 1.02
        }

        guard await waitForSequence(0.30, token: token) else { return }
        guard token == sequenceToken, !Task.isCancelled else { return }

        isVisible = false
        playbackTask = nil

        // Controller側はこの通知を受け取ってからPUSHへ進みます。
        NotificationCenter.default.post(
            name: .retroTypewriterPreviewDidFinish,
            object: nil
        )

        onFinished?()
    }

    @MainActor
    private func waitForSequence(
        _ seconds: Double,
        token: Int
    ) async -> Bool {
        guard seconds > 0 else {
            return token == sequenceToken && !Task.isCancelled
        }

        do {
            try await Task.sleep(
                nanoseconds: UInt64(seconds * 1_000_000_000)
            )
        } catch {
            return false
        }

        return token == sequenceToken && !Task.isCancelled
    }

    private func show(_ step: TypewriterStep) {
        currentStep = step
        currentImage = resolvedImage(candidates: step.candidates)

        // 最初から最後まで同じ出現演出
        glyphOpacity = 0
        glyphScale = 1.48
        glyphRotation = Double.random(in: -1.6...1.6)
        glyphOffset = CGSize(
            width: CGFloat.random(in: -2.5...2.5),
            height: CGFloat.random(in: -2.5...2.5)
        )

        inkBurstOpacity = 0.72
        inkBurstScale = 0.42

        whiteFlashOpacity = 0.10

        withAnimation(.easeOut(duration: 0.07)) {
            whiteFlashOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.18)) {
            inkBurstOpacity = 0
            inkBurstScale = 1.12
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.62)) {
            glyphOpacity = 1
            glyphScale = 1
            glyphRotation = 0
            glyphOffset = .zero
        }

        playKeyImpact()
    }

    private func hideCharacter() {
        withAnimation(.easeOut(duration: 0.16)) {
            glyphOpacity = 0
            glyphScale = 0.96
        }
    }

    private func showFinalCard() {
        currentStep = nil
        currentImage = nil

        whiteFlashOpacity = 0.72

        withAnimation(.easeOut(duration: 0.10)) {
            whiteFlashOpacity = 0
        }

        finalCardOpacity = 1
        finalCardScale = 1.22
        finalCardBlur = 12

        withAnimation(.spring(response: 0.42, dampingFraction: 0.66)) {
            finalCardScale = 1
            finalCardBlur = 0
        }

        playLargeShake()
    }

    private func resolvedImage(candidates: [String]) -> UIImage? {
        for name in candidates {
            if let image = UIImage(named: name) {
                return image
            }
        }
        return nil
    }

    private func playKeyImpact() {
        playSound(named: "typewriter")

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.56)

        screenOffset = CGSize(
            width: CGFloat.random(in: -1.8...1.8),
            height: CGFloat.random(in: -1.2...1.2)
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            screenOffset = .zero
        }
    }

    private func playFinalImpact() {
        playSound(named: "previewImpact")

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        whiteFlashOpacity = 0.28
        screenScale = 1.045

        withAnimation(.easeOut(duration: 0.10)) {
            whiteFlashOpacity = 0
        }

        withAnimation(.spring(response: 0.30, dampingFraction: 0.54)) {
            screenScale = 1
        }
    }

    private func playLargeShake() {
        let values: [CGSize] = [
            .init(width: -11, height: 4),
            .init(width: 9, height: -3),
            .init(width: -7, height: 3),
            .init(width: 5, height: -2),
            .init(width: -3, height: 1),
            .init(width: 2, height: -1),
            .zero
        ]

        for (index, value) in values.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.04
            ) {
                screenOffset = value
            }
        }
    }

    private func playSound(named name: String) {
        let extensions = ["caf", "wav", "mp3", "m4a"]

        guard
            let url = extensions.compactMap({
                Bundle.main.url(
                    forResource: name,
                    withExtension: $0
                )
            }).first
        else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            // SEがなくても動作します。
        }
    }


    private func reset() {
        currentStep = nil
        currentImage = nil

        glyphOpacity = 0
        glyphScale = 1.48
        glyphRotation = 0
        glyphOffset = .zero

        inkBurstOpacity = 0
        inkBurstScale = 0.42

        finalCardOpacity = 0
        finalCardScale = 1.22
        finalCardBlur = 12

        whiteFlashOpacity = 0
        redFlashOpacity = 0

        screenOffset = .zero
        screenScale = 1
        screenOpacity = 1

        audioPlayer?.stop()
        audioPlayer = nil
    }
}

private struct TypewriterStep {
    let character: String
    let candidates: [String]
    let hold: Double
    let blank: Double
}

#Preview {
    RetroImageTypewriterPreviewOverlay(trigger: 1)
        .frame(width: 380, height: 560)
}



