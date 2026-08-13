//
//  RetroNextEpisodePreviewOverlay.swift
//  CircleAccount
//
//  激アツ演出後の完全暗転から始まる、レトロ怪盗アニメ風の
//  本格タイプライター次回予告演出。
//  文字を一文字ずつ表示し、カーソル・打鍵振動・画面揺れ・赤フラッシュを再生します。
//
//  追加画像：不要
//  任意SE：typewriter.caf / typewriterReturn.caf / previewImpact.caf
//

import SwiftUI
import UIKit
import AVFoundation

struct RetroNextEpisodePreviewOverlay: View {
    let trigger: Int
    let isRainbowJackpot: Bool

    @State private var sequenceToken = 0
    @State private var isVisible = false

    @State private var blackOpacity = 0.0
    @State private var filmOpacity = 0.0
    @State private var whiteFlashOpacity = 0.0
    @State private var redFlashOpacity = 0.0

    @State private var borderOpacity = 0.0
    @State private var borderInset: CGFloat = 34
    @State private var borderPulse = false

    @State private var scanOffset: CGFloat = -1.2
    @State private var scratchOffset: CGFloat = -220

    @State private var nextText = ""
    @State private var titleText = ""
    @State private var subtitleText = ""
    @State private var finalText = ""

    @State private var nextOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var finalOpacity = 0.0

    @State private var nextScale: CGFloat = 1.42
    @State private var titleScale: CGFloat = 1.08
    @State private var finalScale: CGFloat = 1.65

    @State private var lineProgress: CGFloat = 0
    @State private var cursorVisible = false
    @State private var activeLine: TypewriterLine?

    @State private var shakeX: CGFloat = 0
    @State private var shakeY: CGFloat = 0
    @State private var microJitterX: CGFloat = 0
    @State private var microJitterY: CGFloat = 0

    @State private var audioPlayer: AVAudioPlayer?

    private let nextSource = "次回"
    private let titleSource = "黄金のV、覚醒"
    private let subtitleSource = "運命の777を掴み取れ"
    private let finalSource = "勝利を、掴め。"

    private enum TypewriterLine {
        case next
        case title
        case subtitle
        case final
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    Color.black
                        .opacity(blackOpacity)

                    retroBackground(size: proxy.size)
                    filmNoise(size: proxy.size)
                    content(size: proxy.size)

                    Color.red
                        .opacity(redFlashOpacity)
                        .blendMode(.plusLighter)

                    Color.white
                        .opacity(whiteFlashOpacity)
                        .blendMode(.plusLighter)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .offset(
                x: shakeX + microJitterX,
                y: shakeY + microJitterY
            )
            .clipped()
            .compositingGroup()
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            play()
        }
    }

    private func retroBackground(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.12, green: 0.003, blue: 0.008),
                    Color(red: 0.23, green: 0.006, blue: 0.008),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(filmOpacity)

            RadialGradient(
                colors: [
                    Color.red.opacity(borderPulse ? 0.22 : 0.10),
                    Color.clear,
                    Color.black.opacity(0.90)
                ],
                center: .center,
                startRadius: 15,
                endRadius: max(size.width, size.height) * 0.72
            )
            .opacity(filmOpacity)

            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.84),
                            Color(red: 0.80, green: 0.08, blue: 0.05),
                            Color(red: 0.96, green: 0.83, blue: 0.56),
                            Color.white.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.6
                )
                .padding(borderInset)
                .opacity(borderOpacity)
                .shadow(
                    color: Color.red.opacity(borderPulse ? 0.74 : 0.28),
                    radius: borderPulse ? 18 : 7
                )
        }
    }

    private func filmNoise(size: CGSize) -> some View {
        ZStack {
            VStack(spacing: 5) {
                ForEach(0..<82, id: \.self) { index in
                    Rectangle()
                        .fill(
                            index.isMultiple(of: 11)
                                ? Color.white.opacity(0.065)
                                : Color.white.opacity(0.021)
                        )
                        .frame(height: 1)
                }
            }
            .offset(y: scanOffset * size.height)
            .opacity(filmOpacity)
            .blendMode(.screen)

            ForEach(0..<9, id: \.self) { index in
                Rectangle()
                    .fill(
                        Color.white.opacity(
                            index.isMultiple(of: 2) ? 0.085 : 0.035
                        )
                    )
                    .frame(width: index.isMultiple(of: 3) ? 2 : 1)
                    .offset(
                        x: scratchOffset + CGFloat(index) * 68,
                        y: CGFloat((index % 4) * 55 - 84)
                    )
                    .rotationEffect(.degrees(Double(index - 4) * 1.4))
                    .opacity(filmOpacity)
            }

            ForEach(0..<42, id: \.self) { index in
                Circle()
                    .fill(
                        index.isMultiple(of: 4)
                            ? Color.red.opacity(0.13)
                            : Color.white.opacity(0.075)
                    )
                    .frame(
                        width: CGFloat(1 + index % 3),
                        height: CGFloat(1 + index % 3)
                    )
                    .position(
                        x: CGFloat((index * 71) % 350) + 10,
                        y: CGFloat((index * 131) % 510) + 10
                    )
                    .opacity(filmOpacity)
            }
        }
    }

    private func content(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer()

            typewriterRow(
                text: nextText,
                line: .next,
                font: .system(size: 52, weight: .black, design: .serif),
                color: .white,
                spacing: 11
            )
            .scaleEffect(nextScale)
            .opacity(nextOpacity)
            .shadow(color: .black, radius: 2, x: 2, y: 2)
            .shadow(color: .red.opacity(0.55), radius: 10)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.82),
                            Color(red: 0.94, green: 0.80, blue: 0.52),
                            Color.white.opacity(0.82),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width * 0.74 * lineProgress, height: 2)
                .padding(.top, 14)
                .padding(.bottom, 34)

            typewriterRow(
                text: titleText,
                line: .title,
                font: .system(size: 35, weight: .black, design: .serif),
                color: .red,
                spacing: 1.7
            )
            .scaleEffect(titleScale)
            .opacity(titleOpacity)
            .shadow(color: .black, radius: 2.6, x: 2, y: 2)
            .shadow(color: .red.opacity(0.68), radius: 11)
            .frame(maxWidth: size.width * 0.90)

            Spacer().frame(height: 28)

            typewriterRow(
                text: subtitleText,
                line: .subtitle,
                font: .system(size: 19, weight: .bold, design: .serif),
                color: .white,
                spacing: 1.7
            )
            .opacity(subtitleOpacity)
            .shadow(color: .black, radius: 2, x: 2, y: 2)
            .frame(maxWidth: size.width * 0.88)

            Spacer().frame(height: 38)

            typewriterRow(
                text: finalText,
                line: .final,
                font: .system(size: 30, weight: .black, design: .serif),
                color: isRainbowJackpot ? .yellow : .white,
                spacing: 2.2
            )
            .scaleEffect(finalScale)
            .opacity(finalOpacity)
            .shadow(color: .black, radius: 3, x: 3, y: 3)
            .shadow(color: .red, radius: 15)

            Spacer().frame(height: 58)
        }
        .padding(.horizontal, 26)
    }

    private func typewriterRow(
        text: String,
        line: TypewriterLine,
        font: Font,
        color: Color,
        spacing: CGFloat
    ) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(font)
                .tracking(spacing)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if activeLine == line && cursorVisible {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                Color.white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 9, height: cursorHeight(for: line))
                    .shadow(color: color, radius: 5)
            }
        }
    }

    private func cursorHeight(for line: TypewriterLine) -> CGFloat {
        switch line {
        case .next:
            return 46
        case .title:
            return 32
        case .subtitle:
            return 20
        case .final:
            return 29
        }
    }

    private func play() {
        sequenceToken += 1
        let token = sequenceToken

        reset()
        isVisible = true
        blackOpacity = 1

        // 既存の完全暗転から直接始める。
        schedule(after: 0.05, token: token) {
            filmOpacity = 1
            borderOpacity = 1
            borderInset = 34

            withAnimation(.spring(response: 0.32, dampingFraction: 0.66)) {
                borderInset = 18
            }

            withAnimation(
                .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
            ) {
                scanOffset = 1.2
            }

            withAnimation(
                .linear(duration: 1.7)
                    .repeatForever(autoreverses: false)
            ) {
                scratchOffset = 240
            }

            withAnimation(
                .easeInOut(duration: 0.44)
                    .repeatForever(autoreverses: true)
            ) {
                borderPulse = true
            }

            startMicroJitter(token: token)
        }

        // 「次回」を一文字ずつ。
        schedule(after: 0.22, token: token) {
            nextOpacity = 1
            nextScale = 1.42
            activeLine = .next
            startCursorBlink(token: token)

            withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) {
                nextScale = 1
            }

            type(
                nextSource,
                interval: 0.23,
                token: token
            ) { value in
                nextText = value
            }
        }

        // 下線。
        schedule(after: 0.92, token: token) {
            playSound(named: "typewriterReturn")
            impact(.rigid, intensity: 0.72)

            withAnimation(.easeOut(duration: 0.34)) {
                lineProgress = 1
            }
        }

        // タイトルを一文字ずつ。
        schedule(after: 1.22, token: token) {
            titleOpacity = 1
            titleScale = 1.08
            activeLine = .title

            withAnimation(.easeOut(duration: 0.20)) {
                titleScale = 1
            }

            type(
                titleSource,
                interval: 0.145,
                token: token
            ) { value in
                titleText = value
            }
        }

        // サブタイトル。
        schedule(after: 2.72, token: token) {
            playSound(named: "typewriterReturn")
            subtitleOpacity = 1
            activeLine = .subtitle

            type(
                subtitleSource,
                interval: 0.105,
                token: token
            ) { value in
                subtitleText = value
            }
        }

        // 決め台詞。
        schedule(after: 4.20, token: token) {
            playSound(named: "typewriterReturn")
            finalOpacity = 1
            finalScale = 1.65
            activeLine = .final

            type(
                finalSource,
                interval: 0.165,
                token: token
            ) { value in
                finalText = value
            }
        }

        // 最後の句点で強い赤フラッシュ。
        schedule(after: 5.48, token: token) {
            activeLine = nil
            cursorVisible = false

            playSound(named: "previewImpact")
            redFlashOpacity = 0.82
            whiteFlashOpacity = 0.34

            withAnimation(.easeOut(duration: 0.08)) {
                whiteFlashOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.16)) {
                redFlashOpacity = 0
            }

            withAnimation(
                .spring(response: 0.28, dampingFraction: 0.42)
            ) {
                finalScale = 1
            }

            notification(.success)
            playShake(intensity: 0.86)
        }

        // 余韻。
        schedule(after: 5.95, token: token) {
            withAnimation(.easeOut(duration: 0.36)) {
                nextOpacity = 0
                titleOpacity = 0
                subtitleOpacity = 0
                finalOpacity = 0
                filmOpacity = 0
                borderOpacity = 0
            }
        }

        schedule(after: 6.35, token: token) {
            blackOpacity = 0
            isVisible = false
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }

    private func type(
        _ source: String,
        interval: Double,
        token: Int,
        update: @escaping (String) -> Void
    ) {
        let characters = Array(source)

        for index in characters.indices {
            schedule(
                after: Double(index) * interval,
                token: token
            ) {
                let value = String(characters[0...index])
                update(value)
                typeKeyImpact(character: characters[index])
            }
        }
    }

    private func typeKeyImpact(character: Character) {
        playSound(named: "typewriter")

        let generator = UIImpactFeedbackGenerator(
            style: character == "、" || character == "。" ? .medium : .light
        )
        generator.prepare()
        generator.impactOccurred(
            intensity: character == "、" || character == "。" ? 0.62 : 0.32
        )

        let amount: CGFloat =
            character == "、" || character == "。" ? 2.8 : 1.5

        microJitterX = Bool.random() ? amount : -amount
        microJitterY = Bool.random() ? amount * 0.42 : -amount * 0.42

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            microJitterX = 0
            microJitterY = 0
        }
    }

    private func startCursorBlink(token: Int) {
        cursorVisible = true

        func blink() {
            guard token == sequenceToken, isVisible else { return }

            withAnimation(.easeInOut(duration: 0.06)) {
                cursorVisible.toggle()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                blink()
            }
        }

        blink()
    }

    private func startMicroJitter(token: Int) {
        func jitter() {
            guard token == sequenceToken, isVisible else { return }

            let x = CGFloat.random(in: -0.34...0.34)
            let y = CGFloat.random(in: -0.20...0.20)

            microJitterX = x
            microJitterY = y

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) {
                jitter()
            }
        }

        jitter()
    }

    private func playShake(intensity: CGFloat) {
        let sequence: [(CGFloat, CGFloat)] = [
            (-16, 5),
            (14, -5),
            (-11, 4),
            (9, -3),
            (-7, 2),
            (5, -2),
            (-3, 1),
            (0, 0)
        ]

        for (index, value) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.031
            ) {
                shakeX = value.0 * intensity
                shakeY = value.1 * intensity
            }
        }
    }

    private func playSound(named name: String) {
        let extensions = ["caf", "wav", "mp3", "m4a"]

        guard
            let url = extensions.compactMap({
                Bundle.main.url(forResource: name, withExtension: $0)
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
            // SEがなくても演出は継続する。
        }
    }

    private func schedule(
        after delay: Double,
        token: Int,
        action: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard token == sequenceToken else { return }
            action()
        }
    }

    private func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private func notification(
        _ type: UINotificationFeedbackGenerator.FeedbackType
    ) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private func reset() {
        blackOpacity = 0
        filmOpacity = 0
        whiteFlashOpacity = 0
        redFlashOpacity = 0

        borderOpacity = 0
        borderInset = 34
        borderPulse = false

        scanOffset = -1.2
        scratchOffset = -220

        nextText = ""
        titleText = ""
        subtitleText = ""
        finalText = ""

        nextOpacity = 0
        titleOpacity = 0
        subtitleOpacity = 0
        finalOpacity = 0

        nextScale = 1.42
        titleScale = 1.08
        finalScale = 1.65

        lineProgress = 0
        cursorVisible = false
        activeLine = nil

        shakeX = 0
        shakeY = 0
        microJitterX = 0
        microJitterY = 0

        audioPlayer?.stop()
        audioPlayer = nil
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        RetroNextEpisodePreviewOverlay(
            trigger: 1,
            isRainbowJackpot: true
        )
        .frame(width: 370, height: 520)
    }
}

