import SwiftUI

// MARK: - SlotEffectStage

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
//
// 旧「WARNING／激アツ／SUPER CHANCE／REVERSE／PUSH」全画面演出は廃止。
// 激アツは SlotLCDOverlayView の GekiAtsuLCDCutInView に一本化しています。
// このViewは既存コードとの互換性を保ちながら、JACKPOTとカード表示だけを担当します。

struct SlotEffectsView: View {
    let stage: SlotEffectStage
    let heatLevel: SlotHeatLevel
    let resultTitle: String
    let resultSubtitle: String
    var showsParticles = true

    @State private var flashOpacity: CGFloat = 0
    @State private var titleScale: CGFloat = 0.62
    @State private var titleOpacity: CGFloat = 0
    @State private var rayRotation: Double = 0

    @State private var cardOffset: CGFloat = 240
    @State private var cardRotation: Double = -18
    @State private var cardScale: CGFloat = 0.45
    @State private var cardOpacity: CGFloat = 0

    @State private var particlePhase: CGFloat = 0

    var body: some View {
        ZStack {
            jackpotLayer
            cardRevealLayer
            flashLayer
            particleLayer
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            resetForStage()
        }
        .onChange(of: stage) { _, _ in
            resetForStage()
        }
    }

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
                        .rotationEffect(
                            .degrees(
                                Double(index) * 360.0 / 14.0
                            )
                        )
                        .opacity(0.62)
                }
                .rotationEffect(.degrees(rayRotation))

                VStack(spacing: 0) {
                    Text("JACKPOT")
                        .font(
                            .system(
                                size: 56,
                                weight: .black,
                                design: .rounded
                            )
                        )
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
                        .shadow(
                            color: heatLevel.glowColor,
                            radius: 24
                        )

                    Text("PREMIUM WIN")
                        .font(
                            .system(
                                size: 18,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(5)
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var cardRevealLayer: some View {
        if stage == .cardReveal {
            ZStack {
                Color.black.opacity(0.58)

                VStack(spacing: 18) {
                    PremiumTicketArtworkView(
                        title: resultTitle,
                        subtitle: resultSubtitle
                    )
                    .frame(width: 270, height: 330)
                    .offset(y: cardOffset)
                    .rotation3DEffect(
                        .degrees(cardRotation),
                        axis: (x: 0.25, y: 1, z: 0)
                    )
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .shadow(
                        color: .yellow.opacity(0.55),
                        radius: 28
                    )

                    Text("GET!")
                        .font(
                            .system(
                                size: 36,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(4)
                        .foregroundStyle(Color.yellow)
                        .opacity(cardOpacity)
                }
            }
            .transition(.opacity)
        }
    }

    private var flashLayer: some View {
        Color.white
            .opacity(flashOpacity)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var particleLayer: some View {
        if showsParticles && (stage == .jackpot || stage == .cardReveal) {
            GeometryReader { proxy in
                ForEach(0..<44, id: \.self) { index in
                    let width = proxy.size.width
                    let height = proxy.size.height

                    let x =
                        CGFloat((index * 47) % 100)
                        / 100
                        * width

                    let baseY =
                        CGFloat((index * 31) % 100)
                        / 100
                        * height

                    let y =
                        (
                            baseY
                            + particlePhase
                            * CGFloat(40 + index % 30)
                        )
                        .truncatingRemainder(
                            dividingBy: height + 80
                        )
                        - 40

                    Group {
                        if index.isMultiple(of: 3) {
                            Image(systemName: "sparkles")
                                .font(
                                    .system(
                                        size: CGFloat(9 + index % 9)
                                    )
                                )
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
                    .rotationEffect(
                        .degrees(Double(index * 27))
                    )
                    .opacity(0.85)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func resetForStage() {
        flashOpacity = 0
        titleScale = 0.62
        titleOpacity = 0

        cardOffset = 240
        cardRotation = -18
        cardScale = 0.45
        cardOpacity = 0

        particlePhase = 0

        rayRotation = 0

        withAnimation(
            .linear(duration: 8.0)
                .repeatForever(autoreverses: false)
        ) {
            rayRotation = 360
        }

        switch stage {
        case .jackpot:
            withAnimation(
                .spring(
                    response: 0.52,
                    dampingFraction: 0.45
                )
            ) {
                titleScale = 1
                titleOpacity = 1
            }

            flash()

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.30
            ) {
                flash()
            }

            withAnimation(
                .linear(duration: 4.2)
                    .repeatForever(autoreverses: false)
            ) {
                particlePhase = 1
            }

        case .cardReveal:
            withAnimation(
                .spring(
                    response: 0.95,
                    dampingFraction: 0.62
                )
            ) {
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

        case .idle,
             .blackout,
             .warning,
             .chance,
             .superChance,
             .reverse,
             .push:
            break
        }
    }

    private func flash() {
        flashOpacity = 0.88

        withAnimation(.easeOut(duration: 0.24)) {
            flashOpacity = 0
        }
    }
}

// ガチャ結果と保有チケットで共有する唯一のチケット描画。
// ここを変更すると両画面へ同時に反映される。
struct PremiumTicketArtworkView: View {
    let title: String
    let subtitle: String

    var body: some View {
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
                        colors: [.white, .yellow, .orange, .white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )

            VStack(spacing: 10) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Color.yellow)

                Text(title)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.70))
            }
            .padding(24)
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        SlotEffectsView(
            stage: .jackpot,
            heatLevel: .premium,
            resultTitle: "参加費無料券",
            resultSubtitle: "次回の活動で使用できます"
        )
    }
}
