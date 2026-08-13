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

    @StateObject private var soundPlayer = CheckInSoundPlayer()

    @State private var didStart = false
    @State private var blackoutOpacity = 1.0
    @State private var flashOpacity = 0.0

    @State private var logoVisible = false
    @State private var heroVisible = false
    @State private var memberVisible = false
    @State private var pointVisible = false
    @State private var displayedPoint = 0
    @State private var visibleMessageCount = 0
    @State private var completionVisible = false
    @State private var achievementVisible = false
    @State private var closeButtonVisible = false
    @State private var confettiVisible = false

    @State private var glowPulse = false
    @State private var ringRotation = 0.0
    @State private var screenShake: CGFloat = 0

    private var displayName: String {
        let trimmed = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "メンバー" : trimmed
    }

    private var isPremiumBonus: Bool {
        totalPoint >= 7
    }

    var body: some View {
        ZStack {
            premiumBackground
            ambientLights

            if confettiVisible {
                CheckInConfettiLayer()
            }

            content
                .offset(x: screenShake)

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
            startSequence()
        }
        .onDisappear {
            soundPlayer.stop()
        }
    }

    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: isPremiumBonus
                    ? [
                        Color(red: 0.05, green: 0.01, blue: 0.13),
                        Color(red: 0.18, green: 0.03, blue: 0.30),
                        Color(red: 0.02, green: 0.14, blue: 0.32),
                        Color.black
                    ]
                    : [
                        Color.black,
                        Color(red: 0.02, green: 0.06, blue: 0.18),
                        Color(red: 0.08, green: 0.02, blue: 0.20)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    (isPremiumBonus ? Color.white : Color.cyan)
                        .opacity(glowPulse ? 0.34 : 0.12),
                    Color.blue.opacity(0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: 360
            )
            .scaleEffect(glowPulse ? 1.18 : 0.90)
        }
        .ignoresSafeArea()
    }

    private var ambientLights: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.16))
                    .frame(width: 250, height: 250)
                    .blur(radius: 36)
                    .offset(
                        x: CGFloat(sin(time * 0.40)) * 120,
                        y: -270
                    )

                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 290, height: 290)
                    .blur(radius: 42)
                    .offset(
                        x: CGFloat(cos(time * 0.34)) * 130,
                        y: 300
                    )

                ForEach(0..<16, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? Color.white : Color.cyan)
                        .frame(
                            width: CGFloat(2 + index % 4),
                            height: CGFloat(2 + index % 4)
                        )
                        .opacity(0.35 + Double(index % 4) * 0.10)
                        .offset(
                            x: CGFloat((index * 59) % 350) - 175,
                            y: CGFloat((index * 97) % 700) - 350
                                + CGFloat(sin(time * 0.45 + Double(index))) * 14
                        )
                        .shadow(color: .cyan, radius: 5)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                logoSection
                heroSection
                pointSection
                messageSection
                closeButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 34)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            .frame(minHeight: UIScreen.main.bounds.height)
        }
    }

    private var logoSection: some View {
        VStack(spacing: 6) {
            Text("SiRiUS")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .cyan, radius: 16)

            Text("BADMINTON CIRCLE")
                .font(.caption.weight(.black))
                .tracking(3)
                .foregroundStyle(.cyan)
        }
        .opacity(logoVisible ? 1 : 0)
        .scaleEffect(logoVisible ? 1 : 0.55)
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: isPremiumBonus
                                ? [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red]
                                : [.cyan, .blue, .purple, .white, .cyan],
                            center: .center
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(ringRotation))
                    .shadow(color: .cyan.opacity(0.75), radius: 22)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 164, height: 164)

                Text("🏸")
                    .font(.system(size: 84))
            }

            Text("WELCOME")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan, .blue, .purple, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .cyan, radius: 18)

            Text("\(displayName)さん")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .opacity(memberVisible ? 1 : 0)
                .offset(y: memberVisible ? 0 : 20)
        }
        .opacity(heroVisible ? 1 : 0)
        .scaleEffect(heroVisible ? 1 : 0.35)
    }

    private var pointSection: some View {
        VStack(spacing: 8) {
            Text("POINT GET")
                .font(.caption.weight(.black))
                .tracking(2.2)
                .foregroundStyle(.white.opacity(0.68))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("+\(displayedPoint)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .white, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .orange, radius: 18)

                Text("pt")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(isPremiumBonus ? "🌈 EARLY ANSWER BONUS" : "CHECK-IN POINT")
                .font(.caption2.weight(.black))
                .tracking(1.3)
                .foregroundStyle(isPremiumBonus ? .yellow : .cyan)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
        )
        .opacity(pointVisible ? 1 : 0)
        .scaleEffect(pointVisible ? 1 : 0.55)
    }

    private var messageSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(pointMessages.enumerated()), id: \.offset) { index, message in
                if index < visibleMessageCount {
                    messageRow(message)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func messageRow(_ message: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.green)
            }

            Text(message)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
        )
    }

    private var closeButton: some View {
        Button {
            soundPlayer.play(
                fileName: "checkin_close",
                fallbackSoundID: 1104
            )

            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()

            onClose()
        } label: {
            Label("ホームへ戻る", systemImage: "house.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(
                    Color(red: 0.03, green: 0.14, blue: 0.38)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .cyan.opacity(0.30), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .opacity(closeButtonVisible ? 1 : 0)
        .offset(y: closeButtonVisible ? 0 : 38)
        .disabled(!closeButtonVisible)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.54)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 112, height: 112)
                        .shadow(color: .green, radius: 30)

                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(.white)
                }

                Text("CHECK-IN COMPLETE")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)

                Text("受付が完了しました")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.76))
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.green.opacity(0.40), lineWidth: 1.5)
                    }
            )
        }
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }

    private func startSequence() {
        guard !didStart else { return }
        didStart = true

        startContinuousAnimations()

        Task { @MainActor in
            await openingStep()
            await welcomeStep()
            await pointStep()
            await messageStep()
            await completionStep()
        }
    }

    private func startContinuousAnimations() {
        withAnimation(
            .easeInOut(duration: 0.80)
                .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }

        withAnimation(
            .linear(duration: 3.1)
                .repeatForever(autoreverses: false)
        ) {
            ringRotation = 360
        }
    }

    @MainActor
    private func openingStep() async {
        try? await Task.sleep(nanoseconds: 180_000_000)

        soundPlayer.play(
            fileName: "checkin_scan",
            fallbackSoundID: 1057
        )

        flashOpacity = 0.95

        withAnimation(.easeOut(duration: 0.20)) {
            blackoutOpacity = 0
            flashOpacity = 0
        }

        withAnimation(
            .spring(response: 0.48, dampingFraction: 0.62)
        ) {
            logoVisible = true
        }

        try? await Task.sleep(nanoseconds: 340_000_000)
    }

    @MainActor
    private func welcomeStep() async {
        soundPlayer.play(
            fileName: "checkin_welcome",
            fallbackSoundID: 1025
        )

        runHeavyHapticBurst()
        runScreenShake()

        withAnimation(
            .spring(response: 0.52, dampingFraction: 0.50)
        ) {
            heroVisible = true
        }

        try? await Task.sleep(nanoseconds: 420_000_000)

        withAnimation(
            .spring(response: 0.44, dampingFraction: 0.74)
        ) {
            memberVisible = true
        }

        try? await Task.sleep(nanoseconds: 360_000_000)
    }

    @MainActor
    private func pointStep() async {
        soundPlayer.play(
            fileName: "point_get",
            fallbackSoundID: 1016
        )

        playImpact(style: .heavy, intensity: 1)

        withAnimation(
            .spring(response: 0.42, dampingFraction: 0.50)
        ) {
            pointVisible = true
        }

        try? await Task.sleep(nanoseconds: 260_000_000)

        if totalPoint > 0 {
            for point in 1...totalPoint {
                displayedPoint = point

                let feedback = UISelectionFeedbackGenerator()
                feedback.prepare()
                feedback.selectionChanged()

                AudioServicesPlaySystemSound(1104)

                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }

        playImpact(style: .heavy, intensity: 1)
        try? await Task.sleep(nanoseconds: 260_000_000)
    }

    @MainActor
    private func messageStep() async {
        for index in pointMessages.indices {
            withAnimation(
                .spring(response: 0.42, dampingFraction: 0.74)
            ) {
                visibleMessageCount = index + 1
            }

            soundPlayer.play(
                fileName: "mission_update",
                fallbackSoundID: 1104
            )

            playImpact(style: .light, intensity: 0.75)
            try? await Task.sleep(nanoseconds: 340_000_000)
        }
    }

    @MainActor
    private func completionStep() async {
        soundPlayer.play(
            fileName: "checkin_complete",
            fallbackSoundID: 1025
        )

        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        feedback.notificationOccurred(.success)

        confettiVisible = true

        withAnimation(
            .spring(response: 0.46, dampingFraction: 0.55)
        ) {
            completionVisible = true
        }

        try? await Task.sleep(nanoseconds: 1_150_000_000)

        withAnimation(.easeOut(duration: 0.28)) {
            completionVisible = false
        }

        try? await Task.sleep(nanoseconds: 260_000_000)

        if isPremiumBonus {
            soundPlayer.play(
                fileName: "achievement_unlock",
                fallbackSoundID: 1025
            )

            withAnimation(
                .spring(response: 0.52, dampingFraction: 0.48)
            ) {
                achievementVisible = true
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            withAnimation(.easeOut(duration: 0.30)) {
                achievementVisible = false
            }

            try? await Task.sleep(nanoseconds: 320_000_000)
        }

        withAnimation(
            .spring(response: 0.50, dampingFraction: 0.76)
        ) {
            closeButtonVisible = true
        }
    }

    private func playImpact(
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private func runHeavyHapticBurst() {
        let delays: [Double] = [0.00, 0.12, 0.25, 0.42]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playImpact(style: .heavy, intensity: 1)
            }
        }
    }

    private func runScreenShake() {
        let offsets: [CGFloat] = [-12, 12, -9, 9, -6, 6, -3, 3, 0]

        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.065
            ) {
                withAnimation(.linear(duration: 0.06)) {
                    screenShake = offset
                }
            }
        }
    }
}

private struct CheckInConfettiLayer: View {
    private let items = Array(0..<46)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geometry in
                ZStack {
                    ForEach(items, id: \.self) { index in
                        Text(icon(for: index))
                            .font(.system(size: CGFloat(12 + index % 10)))
                            .rotationEffect(
                                .degrees(time * Double(70 + index % 90))
                            )
                            .position(
                                x: CGFloat((index * 71) % max(Int(geometry.size.width), 1)),
                                y: fallingY(
                                    index: index,
                                    time: time,
                                    height: geometry.size.height
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
        let speed = 125.0 + Double(index % 7) * 22
        let delay = Double(index % 13) * 0.11
        let distance = (time + delay) * speed

        return CGFloat(
            distance.truncatingRemainder(
                dividingBy: Double(height + 180)
            )
        ) - 90
    }

    private func icon(for index: Int) -> String {
        let icons = ["✨", "⭐️", "🎉", "🏸", "🎊", "💫"]
        return icons[index % icons.count]
    }
}

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
        let supportedExtensions = ["mp3", "wav", "m4a", "caf"]

        for fileExtension in supportedExtensions {
            guard let url = Bundle.main.url(
                forResource: fileName,
                withExtension: fileExtension
            ) else {
                continue
            }

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.volume = 1
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                return
            } catch {
                print("❌ 音声再生失敗: \(error.localizedDescription)")
            }
        }

        AudioServicesPlaySystemSound(fallbackSoundID)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )

            try session.setActive(true)
        } catch {
            print("❌ AudioSession設定失敗: \(error.localizedDescription)")
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
