import SwiftUI
import UIKit

// MARK: - 月間MVP特別発表演出

struct MVPAnnouncementOverlay: View {
    let memberName: String
    let imageBase64: String
    let onClose: () -> Void

    // 表示段階
    @State private var showIntroText = false
    @State private var showCountdownGlow = false
    @State private var revealMVP = false
    @State private var showDetails = false
    @State private var showButton = false
    @State private var showConfetti = false

    // MVP画像
    @State private var profileScale: CGFloat = 0.12
    @State private var profileRotation: Double = -28
    @State private var profileOpacity = 0.0

    // 王冠
    @State private var crownOffsetY: CGFloat = -240
    @State private var crownRotation: Double = -24
    @State private var crownScale: CGFloat = 0.45
    @State private var crownOpacity = 0.0

    // 光
    @State private var flashOpacity = 0.0
    @State private var pulseGlow = false
    @State private var starRotation: Double = 0
    @State private var lightBeamRotation: Double = 0
    @State private var titleShimmerOffset: CGFloat = -250
    @State private var ringScale: CGFloat = 0.55
    @State private var ringOpacity = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.94)
                .ignoresSafeArea()

            MVPAnnouncementBackground(
                isAnimating: pulseGlow
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if revealMVP {
                rotatingLightBeams
                    .transition(.opacity)
            }

            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }

            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                Spacer()

                if showIntroText && !revealMVP {
                    introSection
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.90)
                            )
                        )
                }

                if revealMVP {
                    mvpRevealSection
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.70)
                            )
                        )
                }

                if showButton {
                    resultButton
                        .transition(
                            .move(edge: .bottom)
                                .combined(with: .opacity)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 30)
        }
        .onAppear {
            startAnnouncement()
        }
        .onDisappear {
            SoundManager.shared.stopAllSounds()
        }
        .transition(
            .opacity.combined(
                with: .scale(scale: 0.96)
            )
        )
    }

    // MARK: - 導入演出

    private var introSection: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(
                                    showCountdownGlow ? 0.50 : 0.12
                                ),
                                Color.orange.opacity(0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 75
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(
                        showCountdownGlow ? 1.18 : 0.82
                    )

                Text("⭐️")
                    .font(.system(size: 61))
                    .scaleEffect(
                        showCountdownGlow ? 1.08 : 0.92
                    )
            }

            Text("管理者が選ぶ")
                .font(
                    .system(
                        size: 18,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .tracking(1.5)
                .foregroundStyle(
                    .white.opacity(0.72)
                )

            Text("今月のMVPは…")
                .font(
                    .system(
                        size: 37,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .shadow(
                    color: Color.yellow.opacity(0.25),
                    radius: 12
                )

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 7, height: 7)
                        .opacity(
                            showCountdownGlow
                                ? 1.0
                                : 0.25
                        )
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever(
                                    autoreverses: true
                                )
                                .delay(Double(index) * 0.16),
                            value: showCountdownGlow
                        )
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - MVP発表本体

    private var mvpRevealSection: some View {
        VStack(spacing: 16) {
            ZStack {
                sparkleRing

                expandingRings

                profileGlow

                ProfileImageView(
                    imageBase64: imageBase64,
                    size: 166
                )
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.yellow,
                                    Color.orange,
                                    Color.pink
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                }
                .shadow(
                    color: Color.yellow.opacity(0.75),
                    radius: 28
                )
                .scaleEffect(profileScale)
                .rotationEffect(
                    .degrees(profileRotation)
                )
                .opacity(profileOpacity)

                Text("👑")
                    .font(.system(size: 66))
                    .offset(y: crownOffsetY)
                    .rotationEffect(
                        .degrees(crownRotation)
                    )
                    .scaleEffect(crownScale)
                    .opacity(crownOpacity)
                    .shadow(
                        color: Color.yellow.opacity(0.90),
                        radius: 20
                    )
            }
            .frame(height: 310)

            if showDetails {
                detailsSection
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                    )
            }
        }
    }

    // MARK: - プロフィール背景光

    private var profileGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        Color.yellow.opacity(0.78),
                        Color.orange.opacity(0.35),
                        Color.pink.opacity(0.16),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 150
                )
            )
            .frame(width: 310, height: 310)
            .scaleEffect(
                pulseGlow ? 1.13 : 0.90
            )
            .opacity(
                pulseGlow ? 0.95 : 0.62
            )
    }

    // MARK: - 回転する星

    private var sparkleRing: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                Image(
                    systemName:
                        index.isMultiple(of: 4)
                            ? "star.fill"
                            : "sparkle"
                )
                .font(
                    .system(
                        size:
                            index.isMultiple(of: 2)
                                ? 21
                                : 12,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    index.isMultiple(of: 3)
                        ? Color.yellow
                        : Color.orange
                )
                .offset(
                    x:
                        cos(
                            Double(index)
                                * .pi
                                / 8
                        )
                        * 132,
                    y:
                        sin(
                            Double(index)
                                * .pi
                                / 8
                        )
                        * 132
                )
                .rotationEffect(
                    .degrees(starRotation)
                )
                .shadow(
                    color: Color.yellow.opacity(0.55),
                    radius: 7
                )
            }
        }
    }

    // MARK: - 拡大するリング

    private var expandingRings: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.yellow.opacity(0.55),
                    lineWidth: 2
                )
                .frame(width: 210, height: 210)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(
                    Color.orange.opacity(0.34),
                    lineWidth: 1.5
                )
                .frame(width: 255, height: 255)
                .scaleEffect(ringScale * 1.08)
                .opacity(ringOpacity * 0.75)
        }
    }

    // MARK: - 名前・タイトル

    private var detailsSection: some View {
        VStack(spacing: 9) {
            shimmerTitle

            Text(
                memberName.isEmpty
                    ? "MVP"
                    : memberName
            )
            .font(
                .system(
                    size: 45,
                    weight: .black,
                    design: .rounded
                )
            )
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .shadow(
                color: Color.orange.opacity(0.40),
                radius: 12
            )

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)

                Text("今月もっとも輝いたメンバー")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .white.opacity(0.78)
                    )

                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var shimmerTitle: some View {
        Text("MONTHLY MVP")
            .font(
                .system(
                    size: 18,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(3.5)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.orange,
                        Color.yellow,
                        Color.white,
                        Color.yellow,
                        Color.orange
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.95),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 65)
                .offset(x: titleShimmerOffset)
                .mask {
                    Text("MONTHLY MVP")
                        .font(
                            .system(
                                size: 18,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(3.5)
                }
            }
    }

    // MARK: - 回転ライト

    private var rotatingLightBeams: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.yellow.opacity(0.14),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 55, height: 520)
                .rotationEffect(
                    .degrees(
                        Double(index) * 45
                        + lightBeamRotation
                    ),
                    anchor: .bottom
                )
                .offset(y: -250)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 結果ボタン

    private var resultButton: some View {
        Button {
            closeOverlay()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "crown.fill")

                Text("表彰結果を見る")
                    .font(.headline)
                    .bold()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .bold()
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 285)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange,
                        Color.pink,
                        Color.purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        Color.white.opacity(0.65),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: Color.pink.opacity(0.50),
                radius: 20,
                x: 0,
                y: 9
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 演出開始

    private func startAnnouncement() {
        
        let introFeedback =
            UIImpactFeedbackGenerator(style: .medium)

        introFeedback.prepare()
        introFeedback.impactOccurred()

        withAnimation(
            .easeOut(duration: 0.42)
        ) {
            showIntroText = true
        }

        withAnimation(
            .easeInOut(duration: 0.55)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            showCountdownGlow = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.65
        ) {
            revealWinner()
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.55
        ) {
            withAnimation(
                .spring(
                    response: 0.60,
                    dampingFraction: 0.75
                )
            ) {
                showDetails = true
            }

            withAnimation(
                .linear(duration: 1.25)
            ) {
                titleShimmerOffset = 250
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3.20
        ) {
            withAnimation(
                .spring(
                    response: 0.55,
                    dampingFraction: 0.82
                )
            ) {
                showButton = true
            }
        }
    }

    // MARK: - MVP登場

    private func revealWinner() {
        SoundManager.shared.playMVPBGM()
       
        let successFeedback =
            UINotificationFeedbackGenerator()

        successFeedback.prepare()
        successFeedback.notificationOccurred(.success)

        withAnimation(
            .easeOut(duration: 0.08)
        ) {
            flashOpacity = 1.0
        }

        withAnimation(
            .easeOut(duration: 0.32)
                .delay(0.08)
        ) {
            flashOpacity = 0
        }

        withAnimation(
            .easeOut(duration: 0.20)
        ) {
            showIntroText = false
        }

        withAnimation(
            .spring(
                response: 0.78,
                dampingFraction: 0.56
            )
        ) {
            revealMVP = true
            profileScale = 1
            profileRotation = 0
            profileOpacity = 1
            ringScale = 1.45
            ringOpacity = 0.85
        }

        withAnimation(
            .spring(
                response: 0.78,
                dampingFraction: 0.60
            )
            .delay(0.16)
        ) {
            crownOffsetY = -92
            crownRotation = 0
            crownScale = 1
            crownOpacity = 1
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.38
        ) {
           
            let crownFeedback =
                UIImpactFeedbackGenerator(style: .heavy)

            crownFeedback.prepare()
            crownFeedback.impactOccurred()
        }

        withAnimation(
            .easeInOut(duration: 0.85)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            pulseGlow = true
        }

        withAnimation(
            .linear(duration: 10)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            starRotation = 360
        }

        withAnimation(
            .linear(duration: 16)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            lightBeamRotation = 360
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.18
        ) {
            withAnimation(
                .easeIn(duration: 0.35)
            ) {
                showConfetti = true
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.75
        ) {
            withAnimation(
                .easeOut(duration: 0.55)
            ) {
                ringOpacity = 0
            }
        }
    }

    // MARK: - 閉じる

    private func closeOverlay() {
        SoundManager.shared.playResultButtonSound()
        SoundManager.shared.stopMVPBGM(
            fadeDuration: 0.55
        )

        let feedback =
            UIImpactFeedbackGenerator(style: .light)

        feedback.prepare()
        feedback.impactOccurred()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.18
        ) {
            onClose()
        }
    }
}

// MARK: - MVP背景演出

private struct MVPAnnouncementBackground: View {
    let isAnimating: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(
                            red: 0.12,
                            green: 0.03,
                            blue: 0.18
                        ),
                        Color(
                            red: 0.30,
                            green: 0.06,
                            blue: 0.18
                        ),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        Color.orange.opacity(0.18)
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 60)
                    .offset(
                        x:
                            CGFloat(
                                sin(time * 0.35)
                            ) * 110,
                        y: -210
                    )

                Circle()
                    .fill(
                        Color.purple.opacity(0.20)
                    )
                    .frame(width: 420, height: 420)
                    .blur(radius: 70)
                    .offset(
                        x:
                            CGFloat(
                                cos(time * 0.27)
                            ) * 125,
                        y: 260
                    )

                Circle()
                    .stroke(
                        Color.yellow.opacity(0.19),
                        lineWidth: 2
                    )
                    .frame(width: 390, height: 390)
                    .scaleEffect(
                        isAnimating ? 1.11 : 0.90
                    )

                Circle()
                    .stroke(
                        Color.orange.opacity(0.15),
                        lineWidth: 2
                    )
                    .frame(width: 530, height: 530)
                    .rotationEffect(
                        .degrees(time * 8)
                    )

                Circle()
                    .stroke(
                        Color.pink.opacity(0.12),
                        lineWidth: 1.5
                    )
                    .frame(width: 690, height: 690)
                    .rotationEffect(
                        .degrees(-time * 5)
                    )
            }
        }
    }
}

#Preview {
    MVPAnnouncementOverlay(
        memberName: "けーや",
        imageBase64: ""
    ) { }
}
