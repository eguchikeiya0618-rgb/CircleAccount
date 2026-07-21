import SwiftUI

struct PseudoRepeatOverlay: View {
    let isVisible: Bool
    let repeatCount: Int
    let reelPool: [String]
    let isPremium: Bool

    @State private var overlayOpacity = 0.0
    @State private var contentScale: CGFloat = 0.62
    @State private var flashOpacity = 0.0
    @State private var ringScale: CGFloat = 0.35
    @State private var ringOpacity = 0.0
    @State private var reelPhase = 0.0
    @State private var pulse = false

    private var safePool: [String] {
        reelPool.isEmpty ? ["7", "BAR", "⭐️", "🔔", "🍒"] : reelPool
    }

    var body: some View {
        Group {
            if isVisible {
                GeometryReader { proxy in
                    ZStack {
                        Color.black
                            .opacity(0.82 * overlayOpacity)
                            .ignoresSafeArea()

                        rotatingRings

                        VStack(spacing: 14) {
                            Text("REPLAY")
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .tracking(5)
                                .foregroundStyle(Color.white.opacity(0.82))

                            Text("もう一回転!!")
                                .font(
                                    .system(
                                        size: 39,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .minimumScaleFactor(0.65)
                                .lineLimit(1)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.yellow,
                                            Color.orange,
                                            Color.red,
                                            Color.white
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.black, radius: 3, y: 3)
                                .shadow(
                                    color: Color.red.opacity(0.98),
                                    radius: pulse ? 24 : 14
                                )
                                .shadow(
                                    color: Color.yellow.opacity(0.88),
                                    radius: pulse ? 38 : 24
                                )

                            pseudoReels

                            Text(isPremium ? "期待度 MAX" : "CHANCE")
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .tracking(2)
                                .foregroundStyle(
                                    isPremium
                                        ? Color.yellow
                                        : Color.orange
                                )
                                .shadow(color: Color.red, radius: 8)
                        }
                        .scaleEffect(contentScale)
                        .opacity(overlayOpacity)

                        Rectangle()
                            .fill(Color.white)
                            .opacity(flashOpacity)
                            .blendMode(.screen)
                            .ignoresSafeArea()
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                }
                .transition(.opacity)
                .onAppear {
                    play()
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                play()
            } else {
                reset()
            }
        }
    }

    private var rotatingRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.clear,
                                Color.red,
                                Color.orange,
                                Color.yellow,
                                Color.white,
                                Color.red,
                                Color.clear
                            ],
                            center: .center
                        ),
                        lineWidth: CGFloat(7 - index * 2)
                    )
                    .frame(
                        width: CGFloat(170 + index * 74),
                        height: CGFloat(170 + index * 74)
                    )
                    .scaleEffect(
                        ringScale + CGFloat(index) * 0.08
                    )
                    .opacity(
                        ringOpacity
                            * (1.0 - Double(index) * 0.18)
                    )
                    .rotationEffect(
                        .degrees(
                            reelPhase
                                * (index.isMultiple(of: 2) ? 1 : -1)
                        )
                    )
                    .shadow(
                        color: Color.red.opacity(0.92),
                        radius: 18
                    )
            }
        }
    }

    private var pseudoReels: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                    .fill(Color.black.opacity(0.72))

                    VStack(spacing: 5) {
                        Text(symbol(at: repeatCount + index + 2))
                        Text(symbol(at: repeatCount + index + 5))
                        Text(symbol(at: repeatCount + index + 8))
                    }
                    .font(.system(size: 25))
                    .offset(
                        y: CGFloat(
                            sin(
                                reelPhase * .pi / 180
                                    + Double(index)
                            )
                        ) * 16
                    )
                    .blur(radius: 1.8)
                }
                .frame(width: 74, height: 104)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.red,
                                Color.yellow
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                }
                .shadow(
                    color: Color.red.opacity(0.75),
                    radius: 12
                )
            }
        }
    }

    private func symbol(at index: Int) -> String {
        let count = safePool.count
        guard count > 0 else { return "7" }

        let normalized = ((index % count) + count) % count
        return safePool[normalized]
    }

    private func play() {
        reset()

        withAnimation(.easeOut(duration: 0.12)) {
            overlayOpacity = 1
            flashOpacity = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.46
                )
            ) {
                contentScale = 1
                ringScale = 1
                ringOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.16)) {
                flashOpacity = 0
            }
        }

        withAnimation(
            .linear(duration: 0.42)
                .repeatForever(autoreverses: false)
        ) {
            reelPhase = 360
        }

        withAnimation(
            .easeInOut(duration: 0.26)
                .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }

    private func reset() {
        overlayOpacity = 0
        contentScale = 0.62
        flashOpacity = 0
        ringScale = 0.35
        ringOpacity = 0
        reelPhase = 0
        pulse = false
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black,
                Color.red.opacity(0.30),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PseudoRepeatOverlay(
            isVisible: true,
            repeatCount: 1,
            reelPool: ["7", "BAR", "⭐️", "🔔", "🍒"],
            isPremium: true
        )
    }
}
