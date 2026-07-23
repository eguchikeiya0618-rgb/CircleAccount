import SwiftUI

struct RewardCardView: View {
    let isVisible: Bool
    let symbols: [String]
    let title: String
    let subtitle: String
    let isPremium: Bool

    @State private var cardScale: CGFloat = 0.72
    @State private var cardOpacity = 0.0
    @State private var glowPulse = false
    @State private var borderRotation = 0.0

    private var safeSymbols: [String] {
        [
            symbols.indices.contains(0) ? symbols[0] : "7",
            symbols.indices.contains(1) ? symbols[1] : "7",
            symbols.indices.contains(2) ? symbols[2] : "7"
        ]
    }

    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()

                rewardCard
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if isVisible {
                showCard()
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                showCard()
            } else {
                hideCard()
            }
        }
    }

    private var rewardCard: some View {
        VStack(spacing: 12) {
            badgeView

            ZStack {
                cardBackground
                cardBorder
                cardContent
            }
            .frame(width: 320, height: 290)
            .shadow(
                color: glowColor.opacity(glowPulse ? 0.85 : 0.40),
                radius: glowPulse ? 28 : 16
            )
        }
    }

    private var badgeView: some View {
        Text(isPremium ? "SSR PREMIUM" : "SR BONUS")
            .font(.caption.weight(.black))
            .tracking(1.4)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.82))
                    .overlay {
                        Capsule()
                            .stroke(glowColor.opacity(0.85), lineWidth: 1.5)
                    }
            )
            .shadow(color: glowColor.opacity(0.55), radius: 12)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(backgroundGradient)
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 260
                        )
                    )
            }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(
                borderGradient,
                lineWidth: 4
            )
            .rotationEffect(.degrees(borderRotation))
    }

    private var cardContent: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(
                    .system(
                        size: 34,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(1.1)
                .foregroundStyle(titleGradient)
                .shadow(color: glowColor, radius: 12)

            HStack(spacing: 10) {
                ForEach(Array(safeSymbols.enumerated()), id: \.offset) { item in
                    symbolCell(item.element)
                }
            }

            Text(subtitle)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 18)
        }
        .padding(.horizontal, 16)
    }

    private func symbolCell(_ symbol: String) -> some View {
        Text(symbol)
            .font(.system(size: symbol.count > 2 ? 31 : 42))
            .minimumScaleFactor(0.55)
            .lineLimit(1)
            .frame(width: 76, height: 76)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(glowColor.opacity(0.72), lineWidth: 2)
                    }
            )
            .shadow(color: glowColor.opacity(0.45), radius: 10)
    }

    private var glowColor: Color {
        isPremium ? .cyan : .yellow
    }

    private var backgroundGradient: LinearGradient {
        if isPremium {
            return LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.10, green: 0.02, blue: 0.18),
                    Color(red: 0.02, green: 0.08, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.01),
                Color(red: 0.42, green: 0.19, blue: 0.01),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: AngularGradient {
        if isPremium {
            return AngularGradient(
                colors: [
                    .red,
                    .orange,
                    .yellow,
                    .green,
                    .cyan,
                    .blue,
                    .purple,
                    .pink,
                    .red
                ],
                center: .center,
                angle: .degrees(borderRotation)
            )
        }

        return AngularGradient(
            colors: [
                .white,
                .yellow,
                .orange,
                .yellow,
                .white
            ],
            center: .center,
            angle: .degrees(borderRotation)
        )
    }

    private var titleGradient: LinearGradient {
        if isPremium {
            return LinearGradient(
                colors: [
                    .red,
                    .orange,
                    .yellow,
                    .green,
                    .cyan,
                    .blue,
                    .purple,
                    .pink
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [
                .white,
                .yellow,
                .orange
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func showCard() {
        cardScale = 0.72
        cardOpacity = 0
        glowPulse = false
        borderRotation = 0

        withAnimation(
            .spring(
                response: 0.45,
                dampingFraction: 0.62
            )
        ) {
            cardScale = 1
            cardOpacity = 1
        }

        withAnimation(
            .easeInOut(duration: 0.75)
                .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }

        withAnimation(
            .linear(duration: 5)
                .repeatForever(autoreverses: false)
        ) {
            borderRotation = 360
        }
    }

    private func hideCard() {
        withAnimation(.easeOut(duration: 0.18)) {
            cardOpacity = 0
            cardScale = 0.88
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        RewardCardView(
            isVisible: true,
            symbols: ["🌈7", "🌈7", "🌈7"],
            title: "JACKPOT",
            subtitle: "PREMIUM GET!",
            isPremium: true
        )
    }
}
