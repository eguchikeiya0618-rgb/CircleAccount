import SwiftUI

struct PremiumBurstView: View {
    let trigger: Int
    let glowColor: Color

    @State private var progress: CGFloat = 0
    @State private var opacity = 0.0
    @State private var flashOpacity = 0.0
    @State private var ringScale: CGFloat = 0.55
    @State private var ringOpacity = 0.0
    @State private var rotation = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.96),
                                glowColor.opacity(0.72),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                        )
                    )
                    .opacity(flashOpacity)
                    .blendMode(.screen)

                ForEach(0..<42, id: \.self) { index in
                    let angle = Double(index) * (360.0 / 42.0)
                    let radians = angle * .pi / 180
                    let distance =
                        CGFloat(30 + (index % 9) * 10)
                        * progress

                    Circle()
                        .fill(
                            index.isMultiple(of: 3)
                                ? Color.white
                                : (
                                    index.isMultiple(of: 2)
                                        ? Color.yellow
                                        : Color.orange
                                )
                        )
                        .frame(
                            width: CGFloat(4 + index % 4 * 2),
                            height: CGFloat(4 + index % 4 * 2)
                        )
                        .position(
                            x: proxy.size.width / 2
                                + cos(radians) * distance,
                            y: proxy.size.height / 2
                                + sin(radians) * distance
                        )
                        .opacity(
                            opacity
                                * (1 - Double(progress) * 0.72)
                        )
                        .shadow(
                            color: index.isMultiple(of: 3)
                                ? Color.white.opacity(0.95)
                                : glowColor.opacity(0.95),
                            radius: 7
                        )
                }

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.white,
                                    Color.yellow,
                                    glowColor,
                                    Color.orange,
                                    Color.white
                                ],
                                center: .center,
                                angle: .degrees(rotation + Double(index) * 36)
                            ),
                            lineWidth: CGFloat(5 - index)
                        )
                        .frame(
                            width: CGFloat(120 + index * 42),
                            height: CGFloat(120 + index * 42)
                        )
                        .scaleEffect(
                            ringScale + CGFloat(index) * 0.08
                        )
                        .opacity(
                            ringOpacity
                                * (1 - Double(index) * 0.22)
                        )
                        .shadow(
                            color: glowColor.opacity(0.88),
                            radius: 16
                        )
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 78, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                glowColor,
                                Color.white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(0.72 + progress * 0.52)
                    .opacity(opacity * (1 - Double(progress) * 0.55))
                    .shadow(color: Color.white, radius: 12)
                    .shadow(color: glowColor, radius: 24)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            play()
        }
    }

    private func play() {
        progress = 0
        opacity = 1
        flashOpacity = 0.95
        ringScale = 0.55
        ringOpacity = 1
        rotation = -18

        withAnimation(.easeOut(duration: 0.18)) {
            flashOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.62)) {
            progress = 1
            ringScale = 1.55
            rotation = 84
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.20
        ) {
            withAnimation(.easeOut(duration: 0.38)) {
                opacity = 0
                ringOpacity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PremiumBurstView(
            trigger: 1,
            glowColor: .purple
        )
    }
}
