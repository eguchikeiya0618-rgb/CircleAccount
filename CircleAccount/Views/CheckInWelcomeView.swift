import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox
import Combine

struct CheckInWelcomeView: View {
    let memberName: String
    let totalPoint: Int
    let pointMessages: [String]
    let onClose: () -> Void

    @StateObject private var soundPlayer =
        CheckInSoundPlayer()

    @State private var sequenceStarted = false

    @State private var blackoutOpacity = 1.0
    @State private var flashOpacity = 0.0

    @State private var backgroundGlow = false
    @State private var ringRotation = 0.0
    @State private var ringScale: CGFloat = 0.25

    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 0.40

    @State private var shuttleOpacity = 0.0
    @State private var shuttleScale: CGFloat = 0.15
    @State private var shuttleRotation = -45.0

    @State private var welcomeOpacity = 0.0
    @State private var welcomeScale: CGFloat = 0.20

    @State private var memberOpacity = 0.0
    @State private var memberOffset: CGFloat = 25

    @State private var displayedPoint = 0
    @State private var pointOpacity = 0.0
    @State private var pointScale: CGFloat = 0.25
    @State private var pointPulse = false

    @State private var visibleMessageCount = 0

    @State private var missionBannerVisible = false
    @State private var missionBannerOffset: CGFloat = 130

    @State private var completionVisible = false
    @State private var completionScale: CGFloat = 0.25

    @State private var buttonVisible = false
    @State private var buttonOffset: CGFloat = 45

    @State private var screenShake: CGFloat = 0
    @State private var confettiActive = false
    
    @State private var achievementVisible = false
    @State private var achievementScale: CGFloat = 0.20

    private var displayName: String {
        memberName.isEmpty
            ? "メンバー"
            : memberName
    }

    private var isRainbowMode: Bool {
        totalPoint >= 7
    }

    var body: some View {
        ZStack {
            backgroundLayer

            animatedLightLayer

            if confettiActive {
                CheckInConfettiLayer()
                    .transition(.opacity)
            }

            rotatingRingLayer

            mainContent
                .offset(x: screenShake)

            if missionBannerVisible {
                missionBanner
            }

            if completionVisible {
                completionOverlay
            }
            if achievementVisible {
                AchievementUnlockOverlay(
                    icon: "⏰",
                    title: "早期回答デビュー",
                    description: "前日18時までの参加回答を達成しました！",
                    rewardPoint: 0
                )
                .scaleEffect(achievementScale)
                .transition(.scale.combined(with: .opacity))
                .zIndex(20)
            }
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)

            Color.black
                .ignoresSafeArea()
                .opacity(blackoutOpacity)
                .allowsHitTesting(false)
        }
        .interactiveDismissDisabled()
        .onAppear {
            startAnimationSequence()
        }
        .onDisappear {
            soundPlayer.stop()
        }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: isRainbowMode
                    ? [
                        Color(red: 0.08, green: 0.02, blue: 0.22),
                        Color.pink,
                        Color.purple,
                        Color.blue,
                        Color.cyan,
                        Color.green,
                        Color.yellow,
                        Color.orange
                    ]
                    : [
                        Color(
                            red: 0.01,
                            green: 0.04,
                            blue: 0.16
                        ),
                        Color(
                            red: 0.02,
                            green: 0.18,
                            blue: 0.46
                        ),
                        Color(
                            red: 0.15,
                            green: 0.04,
                            blue: 0.40
                        )
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    isRainbowMode
                        ? Color.white.opacity(
                            backgroundGlow ? 0.48 : 0.20
                        )
                        : Color.cyan.opacity(
                            backgroundGlow ? 0.42 : 0.15
                        ),
                    isRainbowMode
                        ? Color.yellow.opacity(0.18)
                        : Color.blue.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: 330
            )
            .scaleEffect(
                backgroundGlow ? 1.22 : 0.88
            )
        }
        .ignoresSafeArea()
    }

    private var animatedLightLayer: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 260, height: 260)
                    .blur(radius: 30)
                    .offset(
                        x: CGFloat(sin(time * 0.45)) * 120,
                        y: -260
                    )

                Circle()
                    .fill(Color.purple.opacity(0.20))
                    .frame(width: 300, height: 300)
                    .blur(radius: 38)
                    .offset(
                        x: CGFloat(cos(time * 0.34)) * 130,
                        y: 290
                    )

                ForEach(0..<14, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? Color.white.opacity(0.55)
                                : Color.cyan.opacity(0.65)
                        )
                        .frame(
                            width: CGFloat(3 + index % 4),
                            height: CGFloat(3 + index % 4)
                        )
                        .offset(
                            x:
                                CGFloat(
                                    (index * 53) % 340
                                ) - 170
                                + CGFloat(
                                    sin(
                                        time
                                        * (0.35
                                            + Double(index) * 0.025)
                                    )
                                ) * 12,
                            y:
                                CGFloat(
                                    (index * 89) % 690
                                ) - 345
                                + CGFloat(
                                    cos(
                                        time
                                        * (0.30
                                            + Double(index) * 0.02)
                                    )
                                ) * 10
                        )
                        .shadow(
                            color: .cyan,
                            radius: 5
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - 回転リング

    private var rotatingRingLayer: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .cyan,
                            .blue,
                            .purple,
                            .pink,
                            .white,
                            .cyan
                        ],
                        center: .center
                    ),
                    lineWidth: 8
                )
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(ringRotation))
                .scaleEffect(ringScale)
                .opacity(welcomeOpacity)
                .shadow(
                    color: Color.cyan.opacity(0.80),
                    radius: 20
                )

            Circle()
                .stroke(
                    Color.white.opacity(0.24),
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [8, 12]
                    )
                )
                .frame(width: 340, height: 340)
                .rotationEffect(
                    .degrees(-ringRotation * 0.65)
                )
                .scaleEffect(ringScale)
                .opacity(welcomeOpacity)
        }
    }

    // MARK: - メイン表示

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 35)

            VStack(spacing: 8) {
                Text("SiRiUS")
                    .font(
                        .system(
                            size: 45,
                            weight: .black,
                            design: .serif
                        )
                    )
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .shadow(
                        color: Color.cyan,
                        radius: 15
                    )
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Text("BADMINTON CIRCLE")
                    .font(.caption)
                    .fontWeight(.black)
                    .tracking(3)
                    .foregroundStyle(
                        Color.cyan.opacity(0.90)
                    )
                    .opacity(logoOpacity)
            }

            Spacer()
                .frame(height: 30)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.11))
                    .frame(width: 165, height: 165)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white,
                                .cyan,
                                .purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 165, height: 165)
                    .shadow(
                        color: Color.cyan.opacity(0.70),
                        radius: 22
                    )

                Text("🏸")
                    .font(.system(size: 86))
                    .opacity(shuttleOpacity)
                    .scaleEffect(shuttleScale)
                    .rotationEffect(
                        .degrees(shuttleRotation)
                    )
            }

            Spacer()
                .frame(height: 24)

            Text("WELCOME")
                .font(
                    .system(
                        size: 50,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            .cyan,
                            .blue,
                            .purple,
                            .white
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(
                    color: Color.cyan,
                    radius: 20
                )
                .shadow(
                    color: Color.white.opacity(0.70),
                    radius: 6
                )
                .opacity(welcomeOpacity)
                .scaleEffect(welcomeScale)

            Text("\(displayName)さん")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .padding(.top, 9)
                .opacity(memberOpacity)
                .offset(y: memberOffset)

            Spacer()
                .frame(height: 26)

            pointDisplay

            Spacer()
                .frame(height: 22)

            pointMessageList

            Spacer()

            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 25)
    }

    // MARK: - ポイント表示

    private var pointDisplay: some View {
        VStack(spacing: 6) {
            Text("POINT GET")
                .font(.caption)
                .fontWeight(.black)
                .tracking(2.4)
                .foregroundStyle(.white.opacity(0.70))

            HStack(
                alignment: .firstTextBaseline,
                spacing: 6
            ) {
                Text("+\(displayedPoint)")
                    .font(
                        .system(
                            size: 66,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .yellow,
                                .orange,
                                .white,
                                .yellow
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color.orange,
                        radius: 18
                    )

                Text("pt")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
            }

            Text(
                isRainbowMode
                    ? "🌈 EARLY ANSWER BONUS"
                    : "CHECK-IN POINT"
            )
            .font(.caption2)
            .fontWeight(.black)
            .tracking(1.4)
            .foregroundStyle(
                isRainbowMode
                    ? Color.yellow
                    : Color.cyan
            )
        }
        .opacity(pointOpacity)
        .scaleEffect(
            pointScale
                * (pointPulse ? 1.06 : 1)
        )
    }

    // MARK: - 獲得内容

    private var pointMessageList: some View {
        VStack(spacing: 10) {
            ForEach(
                Array(pointMessages.enumerated()),
                id: \.offset
            ) { index, message in
                if index < visibleMessageCount {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    Color.green.opacity(0.18)
                                )
                                .frame(width: 36, height: 36)

                            Image(
                                systemName:
                                    "checkmark"
                            )
                            .font(
                                .system(
                                    size: 14,
                                    weight: .black
                                )
                            )
                            .foregroundStyle(.green)
                        }

                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        Color.white.opacity(0.10)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                        .stroke(
                            Color.white.opacity(0.14),
                            lineWidth: 1
                        )
                    }
                    .transition(
                        .move(edge: .trailing)
                            .combined(with: .opacity)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - ミッションバナー

    private var missionBanner: some View {
        VStack {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 42, height: 42)

                    Image(
                        systemName:
                            "flag.checkered"
                    )
                    .foregroundStyle(.green)
                }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("MISSION UPDATE")
                        .font(.caption2)
                        .fontWeight(.black)
                        .tracking(1.3)
                        .foregroundStyle(
                            Color.green
                        )

                    Text("QR受付ミッション達成")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("+5pt")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.yellow)
            }
            .padding(14)
            .background(
                Color.black.opacity(0.60)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 19)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 19
                )
                .stroke(
                    Color.green.opacity(0.55),
                    lineWidth: 1.5
                )
            }
            .shadow(
                color: Color.green.opacity(0.35),
                radius: 15
            )
            .padding(.horizontal, 20)
            .offset(x: missionBannerOffset)

            Spacer()
        }
        .padding(.top, 58)
        .allowsHitTesting(false)
    }

    // MARK: - 完了表示

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()

            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 110, height: 110)
                        .shadow(
                            color: Color.green,
                            radius: 30
                        )

                    Image(
                        systemName:
                            "checkmark"
                    )
                    .font(
                        .system(
                            size: 56,
                            weight: .black
                        )
                    )
                    .foregroundStyle(.white)
                }

                Text("CHECK-IN COMPLETE")
                    .font(
                        .system(
                            size: 27,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(.white)

                Text("受付が完了しました")
                    .font(.headline)
                    .foregroundStyle(
                        .white.opacity(0.78)
                    )
            }
            .scaleEffect(completionScale)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 閉じるボタン

    private var closeButton: some View {
        Button {
            soundPlayer.play(
                fileName: "checkin_close",
                fallbackSoundID: 1104
            )

            let feedback =
                UIImpactFeedbackGenerator(
                    style: .medium
                )

            feedback.prepare()
            feedback.impactOccurred()

            onClose()
        } label: {
            HStack(spacing: 10) {
                Image(
                    systemName:
                        "house.fill"
                )

                Text("ホームへ戻る")
                    .bold()
            }
            .font(.headline)
            .foregroundStyle(
                Color(
                    red: 0.03,
                    green: 0.16,
                    blue: 0.40
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
            .shadow(
                color: Color.cyan.opacity(0.35),
                radius: 15,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .opacity(buttonVisible ? 1 : 0)
        .offset(y: buttonOffset)
        .disabled(!buttonVisible)
    }

    // MARK: - 演出開始

    private func startAnimationSequence() {
        guard !sequenceStarted else {
            return
        }

        sequenceStarted = true

        configureContinuousAnimations()

        Task { @MainActor in
            await runOpeningSequence()
            await runWelcomeSequence()
            await runPointSequence()
            await runMessageSequence()
            await runCompletionSequence()
        }
    }

    private func configureContinuousAnimations() {
        withAnimation(
            .easeInOut(duration: 0.75)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            backgroundGlow = true
        }

        withAnimation(
            .linear(duration: 3.2)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            ringRotation = 360
        }

        withAnimation(
            .easeInOut(duration: 0.50)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            pointPulse = true
        }
    }

    @MainActor
    private func runOpeningSequence() async {
        try? await Task.sleep(
            nanoseconds: 180_000_000
        )

        soundPlayer.play(
            fileName: "checkin_scan",
            fallbackSoundID: 1057
        )

        playImpact(
            style: .medium,
            intensity: 0.85
        )

        withAnimation(
            .easeOut(duration: 0.18)
        ) {
            blackoutOpacity = 0
            flashOpacity = 0.95
        }

        try? await Task.sleep(
            nanoseconds: 110_000_000
        )

        withAnimation(
            .easeOut(duration: 0.20)
        ) {
            flashOpacity = 0
        }

        withAnimation(
            .spring(
                response: 0.48,
                dampingFraction: 0.58
            )
        ) {
            logoOpacity = 1
            logoScale = 1
        }

        try? await Task.sleep(
            nanoseconds: 320_000_000
        )
    }

    @MainActor
    private func runWelcomeSequence() async {
        soundPlayer.play(
            fileName: "checkin_welcome",
            fallbackSoundID: 1025
        )

        runHeavyHapticBurst()
        runScreenShake()

        flashOpacity = 0.88

        withAnimation(
            .easeOut(duration: 0.16)
        ) {
            flashOpacity = 0
        }

        withAnimation(
            .spring(
                response: 0.52,
                dampingFraction: 0.46
            )
        ) {
            ringScale = 1
            shuttleOpacity = 1
            shuttleScale = 1
            shuttleRotation = 0

            welcomeOpacity = 1
            welcomeScale = 1
        }

        try? await Task.sleep(
            nanoseconds: 420_000_000
        )

        withAnimation(
            .spring(
                response: 0.44,
                dampingFraction: 0.72
            )
        ) {
            memberOpacity = 1
            memberOffset = 0
        }

        try? await Task.sleep(
            nanoseconds: 380_000_000
        )
    }

    @MainActor
    private func runPointSequence() async {
        soundPlayer.play(
            fileName: "point_get",
            fallbackSoundID: 1016
        )

        playImpact(
            style: .heavy,
            intensity: 1
        )

        displayedPoint = 0

        withAnimation(
            .spring(
                response: 0.42,
                dampingFraction: 0.43
            )
        ) {
            pointOpacity = 1
            pointScale = 1
        }

        try? await Task.sleep(
            nanoseconds: 300_000_000
        )

        guard totalPoint > 0 else {
            return
        }

        for point in 1...totalPoint {
            try? await Task.sleep(
                nanoseconds: 130_000_000
            )

            withAnimation(
                .spring(
                    response: 0.16,
                    dampingFraction: 0.52
                )
            ) {
                displayedPoint = point
                pointScale = 1.10
            }

            let feedback =
                UISelectionFeedbackGenerator()

            feedback.prepare()
            feedback.selectionChanged()

            AudioServicesPlaySystemSound(1104)

            try? await Task.sleep(
                nanoseconds: 55_000_000
            )

            withAnimation(
                .easeOut(duration: 0.08)
            ) {
                pointScale = 1.0
            }
        }

        playImpact(
            style: .heavy,
            intensity: 1
        )

        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.40
            )
        ) {
            pointScale = 1.22
        }

        try? await Task.sleep(
            nanoseconds: 170_000_000
        )

        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.65
            )
        ) {
            pointScale = 1.0
        }

        try? await Task.sleep(
            nanoseconds: 260_000_000
        )
    }
    @MainActor
    private func runMessageSequence() async {
        for index in pointMessages.indices {
            withAnimation(
                .spring(
                    response: 0.42,
                    dampingFraction: 0.72
                )
            ) {
                visibleMessageCount =
                    index + 1
            }

            soundPlayer.play(
                fileName: "mission_update",
                fallbackSoundID: 1104
            )

            playImpact(
                style: .light,
                intensity: 0.75
            )

            try? await Task.sleep(
                nanoseconds: 350_000_000
            )
        }

        missionBannerVisible = true

        withAnimation(
            .spring(
                response: 0.52,
                dampingFraction: 0.68
            )
        ) {
            missionBannerOffset = 0
        }

        try? await Task.sleep(
            nanoseconds: 720_000_000
        )

        withAnimation(
            .easeInOut(duration: 0.28)
        ) {
            missionBannerOffset = 130
        }

        try? await Task.sleep(
            nanoseconds: 280_000_000
        )

        missionBannerVisible = false
    }

    @MainActor
    private func runCompletionSequence() async {
        soundPlayer.play(
            fileName: "checkin_complete",
            fallbackSoundID: 1025
        )

        let notification =
            UINotificationFeedbackGenerator()

        notification.prepare()
        notification.notificationOccurred(
            .success
        )

        confettiActive = true


        completionVisible = true
        completionScale = 0.25
        flashOpacity = 0.82

        withAnimation(
            .easeOut(duration: 0.15)
        ) {
            flashOpacity = 0
        }

        withAnimation(
            .spring(
                response: 0.48,
                dampingFraction: 0.48
            )
        ) {
            completionScale = 1
        }

        try? await Task.sleep(
            nanoseconds: 950_000_000
        )

        withAnimation(
            .easeOut(duration: 0.28)
        ) {
            completionScale = 1.18
            completionVisible = false
        }

        try? await Task.sleep(
            nanoseconds: 260_000_000
        )

        // 前日18時までに回答していた場合だけ実績演出
        if isRainbowMode {
            soundPlayer.play(
                fileName: "achievement_unlock",
                fallbackSoundID: 1025
            )

            let achievementFeedback =
                UINotificationFeedbackGenerator()

            achievementFeedback.prepare()
            achievementFeedback.notificationOccurred(.success)

            achievementScale = 0.20

            withAnimation(
                .spring(
                    response: 0.52,
                    dampingFraction: 0.43
                )
            ) {
                achievementVisible = true
                achievementScale = 1
            }

            try? await Task.sleep(
                nanoseconds: 2_000_000_000
            )

            withAnimation(
                .easeOut(duration: 0.30)
            ) {
                achievementScale = 1.18
                achievementVisible = false
            }

            try? await Task.sleep(
                nanoseconds: 320_000_000
            )
        }

        withAnimation(
            .spring(
                response: 0.50,
                dampingFraction: 0.76
            )
        ) {
            buttonVisible = true
            buttonOffset = 0
        }
    }

    // MARK: - 振動

    private func playImpact(
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator =
            UIImpactFeedbackGenerator(
                style: style
            )

        generator.prepare()
        generator.impactOccurred(
            intensity: intensity
        )
    }

    private func runHeavyHapticBurst() {
        let delays: [Double] = [
            0.00,
            0.12,
            0.25,
            0.42
        ]

        for delay in delays {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay
            ) {
                playImpact(
                    style: .heavy,
                    intensity: 1
                )
            }
        }
    }

    private func runScreenShake() {
        let offsets: [CGFloat] = [
            -13,
            13,
            -10,
            10,
            -7,
            7,
            -4,
            4,
            0
        ]

        for (index, offset) in
            offsets.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline:
                    .now()
                    + Double(index) * 0.065
            ) {
                withAnimation(
                    .linear(duration: 0.06)
                ) {
                    screenShake = offset
                }
            }
        }
    }
}

// MARK: - 紙吹雪

private struct CheckInConfettiLayer: View {
    private let items = Array(0..<52)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            GeometryReader { geometry in
                ZStack {
                    ForEach(items, id: \.self) { index in
                        Text(confettiIcon(index))
                            .font(
                                .system(
                                    size:
                                        CGFloat(
                                            12 + index % 12
                                        )
                                )
                            )
                            .rotationEffect(
                                .degrees(
                                    time
                                    * Double(
                                        70 + index % 90
                                    )
                                )
                            )
                            .position(
                                x:
                                    CGFloat(
                                        (index * 71)
                                        % max(
                                            Int(
                                                geometry
                                                    .size
                                                    .width
                                            ),
                                            1
                                        )
                                    ),
                                y:
                                    fallingY(
                                        index: index,
                                        time: time,
                                        height:
                                            geometry
                                                .size
                                                .height
                                    )
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func fallingY(
        index: Int,
        time: TimeInterval,
        height: CGFloat
    ) -> CGFloat {
        let speed =
            125.0 + Double(index % 7) * 22

        let delay =
            Double(index % 13) * 0.11

        let distance =
            (time + delay) * speed

        return CGFloat(
            distance.truncatingRemainder(
                dividingBy:
                    Double(height + 180)
            )
        ) - 90
    }

    private func confettiIcon(
        _ index: Int
    ) -> String {
        let icons = [
            "✨",
            "⭐️",
            "🎉",
            "🏸",
            "🎊",
            "💫"
        ]

        return icons[index % icons.count]
    }
}

// MARK: - サウンド管理

@MainActor
private final class CheckInSoundPlayer:
    NSObject,
    ObservableObject,
    AVAudioPlayerDelegate {

    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        configureAudioSession()
    }

    func play(
        fileName: String,
        fallbackSoundID: SystemSoundID
    ) {
        let supportedExtensions = [
            "mp3",
            "wav",
            "m4a",
            "caf"
        ]

        for fileExtension in supportedExtensions {
            if let url =
                Bundle.main.url(
                    forResource: fileName,
                    withExtension: fileExtension
                ) {
                do {
                    audioPlayer =
                        try AVAudioPlayer(
                            contentsOf: url
                        )

                    audioPlayer?.delegate = self
                    audioPlayer?.volume = 1.0
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    return
                } catch {
                    print(
                        "❌ 音声再生失敗: \(error.localizedDescription)"
                    )
                }
            }
        }

        AudioServicesPlaySystemSound(
            fallbackSoundID
        )
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func configureAudioSession() {
        do {
            let session =
                AVAudioSession.sharedInstance()

            try session.setCategory(
                .playback,
                mode: .default,
                options: [
                    .duckOthers
                ]
            )

            try session.setActive(true)
        } catch {
            print(
                "❌ AudioSession設定失敗: \(error.localizedDescription)"
            )
        }
    }
}

#Preview {
    CheckInWelcomeView(
        memberName: "けーや",
        totalPoint: 7,
        pointMessages: [
            "🏸 練習参加 +5pt",
            "⏰ 早期回答 +2pt"
        ],
        onClose: {}
    )
}
