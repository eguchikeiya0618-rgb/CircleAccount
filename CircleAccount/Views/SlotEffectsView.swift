import SwiftUI

// MARK: - SlotEffectStage
// GachaView 側から stage を切り替えるだけで、
// 長い激アツ演出を表示できます。

enum SlotEffectStage: Equatable {
    case idle
    case blackout
    case warning
    case chance
    case superChance
    case reverse
    case push
    case jackpot
    case cardReveal
}

// MARK: - SlotEffectsView

struct SlotEffectsView: View {
    let stage: SlotEffectStage
    let heatLevel: SlotHeatLevel
    let resultTitle: String
    let resultSubtitle: String

    @State private var flashOpacity: CGFloat = 0
    @State private var warningScale: CGFloat = 0.65
    @State private var warningOpacity: CGFloat = 0
    @State private var ringScale: CGFloat = 0.25
    @State private var ringOpacity: CGFloat = 0
    @State private var rayRotation: Double = 0
    @State private var cardOffset: CGFloat = 240
    @State private var cardRotation: Double = -18
    @State private var cardScale: CGFloat = 0.45
    @State private var cardOpacity: CGFloat = 0
    @State private var shakeAmount: CGFloat = 0
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        ZStack {
            blackoutLayer
            rotatingRays
            warningLayer
            chanceLayer
            reverseLayer
            pushLayer
            jackpotLayer
            cardRevealLayer
            flashLayer
            particleLayer
        }
        .ignoresSafeArea()
        .allowsHitTesting(stage == .push)
        .onAppear {
            resetForStage()
        }
        .onChange(of: stage) { _, _ in
            resetForStage()
        }
    }

    // MARK: - Blackout

    @ViewBuilder
    private var blackoutLayer: some View {
        if stage == .blackout {
            Color.black
                .opacity(0.96)
                .transition(.opacity)

            VStack(spacing: 18) {
                Text("・・・・・・")
                    .font(.system(size: 42, weight: .black, design: .monospaced))
                    .tracking(8)
                    .foregroundStyle(Color.white.opacity(0.92))

                Text("何かが起きる")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Color.red.opacity(0.82))
            }
            .transition(.opacity.combined(with: .scale))
        }
    }

    // MARK: - WARNING

    @ViewBuilder
    private var warningLayer: some View {
        if stage == .warning {
            ZStack {
                Color.red.opacity(0.24)

                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 58, weight: .black))
                        .foregroundStyle(Color.yellow)
                        .shadow(color: .red, radius: 18)

                    Text("WARNING")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.yellow,
                                    Color.red
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red, radius: 16)

                    Text("激アツ演出 発生")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(warningScale)
                .opacity(warningOpacity)
                .offset(x: shakeAmount)
            }
            .transition(.opacity)
        }
    }

    // MARK: - CHANCE

    @ViewBuilder
    private var chanceLayer: some View {
        if stage == .chance || stage == .superChance {
            ZStack {
                Color.black.opacity(0.24)

                Circle()
                    .stroke(
                        heatLevel.glowColor.opacity(0.88),
                        lineWidth: 12
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .shadow(color: heatLevel.glowColor, radius: 28)

                VStack(spacing: 2) {
                    Text(stage == .superChance ? "SUPER" : "")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(Color.white)

                    Text("CHANCE")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: stage == .superChance
                                ? [Color.white, Color.yellow, Color.orange]
                                : [Color.white, Color.red, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: stage == .superChance ? .yellow : .red,
                            radius: 20
                        )
                }
                .scaleEffect(warningScale)
                .opacity(warningOpacity)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Reverse

    @ViewBuilder
    private var reverseLayer: some View {
        if stage == .reverse {
            ZStack {
                Color.purple.opacity(0.20)

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .trim(from: 0.12, to: 0.86)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.clear,
                                    Color.white,
                                    Color.purple,
                                    Color.blue,
                                    Color.clear
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(
                                lineWidth: CGFloat(8 + index * 3),
                                lineCap: .round
                            )
                        )
                        .frame(
                            width: CGFloat(190 + index * 60),
                            height: CGFloat(190 + index * 60)
                        )
                        .rotationEffect(.degrees(-rayRotation * Double(index + 1)))
                        .shadow(color: .purple, radius: 14)
                }

                VStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 58, weight: .black))
                    Text("REVERSE")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(Color.white)
                .shadow(color: .purple, radius: 18)
            }
            .transition(.opacity)
        }
    }

    // MARK: - PUSH

    @ViewBuilder
    private var pushLayer: some View {
        if stage == .push {
            ZStack {
                Color.black.opacity(0.62)

                VStack(spacing: 18) {
                    Text("運命を押せ")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(Color.white.opacity(0.86))

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white,
                                        heatLevel.lampColor,
                                        heatLevel.glowColor,
                                        Color.black
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 86
                                )
                            )
                            .frame(width: 170, height: 170)
                            .shadow(color: heatLevel.glowColor, radius: 35)

                        Circle()
                            .stroke(Color.white.opacity(0.65), lineWidth: 5)
                            .frame(width: 170, height: 170)

                        VStack(spacing: -4) {
                            Text("PUSH")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                            Text("BUTTON")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(3)
                        }
                        .foregroundStyle(Color.white)
                    }
                    .scaleEffect(warningScale)
                    .opacity(warningOpacity)

                    Text("タップで決着")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            .transition(.opacity)
        }
    }

    // MARK: - Jackpot

    @ViewBuilder
    private var jackpotLayer: some View {
        if stage == .jackpot {
            ZStack {
                Color.black.opacity(0.10)

                ForEach(0..<14, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    heatLevel.glowColor,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: 300)
                        .offset(y: -150)
                        .rotationEffect(.degrees(Double(index) * 360.0 / 14.0))
                        .opacity(0.62)
                }
                .rotationEffect(.degrees(rayRotation))

                VStack(spacing: 0) {
                    Text("JACKPOT")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.yellow,
                                    Color.orange,
                                    Color.pink,
                                    Color.purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white, radius: 12)
                        .shadow(color: heatLevel.glowColor, radius: 24)

                    Text("PREMIUM WIN")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(warningScale)
                .opacity(warningOpacity)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Card reveal

    @ViewBuilder
    private var cardRevealLayer: some View {
        if stage == .cardReveal {
            ZStack {
                Color.black.opacity(0.58)

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black,
                                        Color(red: 0.15, green: 0.12, blue: 0.03),
                                        Color.black
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.yellow,
                                        Color.orange,
                                        Color.white
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )

                        VStack(spacing: 10) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 44, weight: .black))
                                .foregroundStyle(Color.yellow)

                            Text(resultTitle)
                                .font(.system(size: 25, weight: .black, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.white)

                            Text(resultSubtitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.white.opacity(0.70))
                        }
                        .padding(24)
                    }
                    .frame(width: 270, height: 330)
                    .offset(y: cardOffset)
                    .rotation3DEffect(
                        .degrees(cardRotation),
                        axis: (x: 0.25, y: 1, z: 0)
                    )
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .shadow(color: .yellow.opacity(0.55), radius: 28)

                    Text("GET!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(Color.yellow)
                        .opacity(cardOpacity)
                }
            }
            .transition(.opacity)
        }
    }

    // MARK: - Rotating rays

    @ViewBuilder
    private var rotatingRays: some View {
        if stage == .warning
            || stage == .chance
            || stage == .superChance
            || stage == .jackpot {
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    heatLevel.glowColor.opacity(0.55),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 18, height: 360)
                        .offset(y: -180)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
            }
            .rotationEffect(.degrees(rayRotation))
            .opacity(0.35)
        }
    }

    // MARK: - Flash

    private var flashLayer: some View {
        Color.white
            .opacity(flashOpacity)
            .allowsHitTesting(false)
    }

    // MARK: - Particles

    @ViewBuilder
    private var particleLayer: some View {
        if stage == .jackpot || stage == .cardReveal {
            GeometryReader { proxy in
                ForEach(0..<44, id: \.self) { index in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let x = CGFloat((index * 47) % 100) / 100 * width
                    let baseY = CGFloat((index * 31) % 100) / 100 * height
                    let y = (baseY + particlePhase * CGFloat(40 + index % 30))
                        .truncatingRemainder(dividingBy: height + 80) - 40

                    Group {
                        if index.isMultiple(of: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: CGFloat(9 + index % 9)))
                        } else {
                            Circle()
                                .frame(
                                    width: CGFloat(5 + index % 7),
                                    height: CGFloat(5 + index % 7)
                                )
                        }
                    }
                    .foregroundStyle(
                        index.isMultiple(of: 2)
                        ? Color.yellow
                        : heatLevel.glowColor
                    )
                    .position(x: x, y: y)
                    .rotationEffect(.degrees(Double(index * 27)))
                    .opacity(0.85)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Stage animations

    private func resetForStage() {
        flashOpacity = 0
        warningScale = 0.65
        warningOpacity = 0
        ringScale = 0.25
        ringOpacity = 0
        cardOffset = 240
        cardRotation = -18
        cardScale = 0.45
        cardOpacity = 0
        shakeAmount = 0
        particlePhase = 0

        withAnimation(
            .linear(duration: 8.0)
            .repeatForever(autoreverses: false)
        ) {
            rayRotation = 360
        }

        switch stage {
        case .idle:
            break

        case .blackout:
            flash()

        case .warning:
            withAnimation(.spring(response: 0.42, dampingFraction: 0.46)) {
                warningScale = 1
                warningOpacity = 1
            }

            shake()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                flash()
            }

        case .chance, .superChance:
            withAnimation(.spring(response: 0.48, dampingFraction: 0.50)) {
                warningScale = 1
                warningOpacity = 1
                ringScale = 1
                ringOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                withAnimation(
                    .easeOut(duration: 0.85)
                    .repeatForever(autoreverses: false)
                ) {
                    ringScale = 1.55
                    ringOpacity = 0
                }
            }

        case .reverse:
            flash()

        case .push:
            withAnimation(
                .easeInOut(duration: 0.55)
                .repeatForever(autoreverses: true)
            ) {
                warningScale = 1.12
                warningOpacity = 1
            }

        case .jackpot:
            withAnimation(.spring(response: 0.52, dampingFraction: 0.45)) {
                warningScale = 1
                warningOpacity = 1
            }

            flash()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                flash()
            }

            withAnimation(
                .linear(duration: 4.2)
                .repeatForever(autoreverses: false)
            ) {
                particlePhase = 1
            }

        case .cardReveal:
            withAnimation(.spring(response: 0.95, dampingFraction: 0.62)) {
                cardOffset = 0
                cardRotation = 0
                cardScale = 1
                cardOpacity = 1
            }

            withAnimation(
                .linear(duration: 4.8)
                .repeatForever(autoreverses: false)
            ) {
                particlePhase = 1
            }
        }
    }

    private func flash() {
        flashOpacity = 0.88

        withAnimation(.easeOut(duration: 0.24)) {
            flashOpacity = 0
        }
    }

    private func shake() {
        let sequence: [CGFloat] = [-16, 14, -11, 9, -6, 4, 0]

        for (index, value) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.055
            ) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeAmount = value
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        SlotEffectsView(
            stage: .warning,
            heatLevel: .warning,
            resultTitle: "参加費無料券",
            resultSubtitle: "次回の活動で使用できます"
        )
    }
}
