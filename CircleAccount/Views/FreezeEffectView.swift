import SwiftUI

struct FreezeEffectView: View {
    let isVisible: Bool

    @State private var blueFlashOpacity = 0.0
    @State private var darknessOpacity = 0.0
    @State private var crackProgress: CGFloat = 0
    @State private var crackGlowOpacity = 0.0
    @State private var freezeTextOpacity = 0.0
    @State private var freezeTextScale: CGFloat = 0.72
    @State private var whiteoutOpacity = 0.0
    @State private var shardProgress: CGFloat = 0
    @State private var shardOpacity = 0.0
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(darknessOpacity)
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.cyan.opacity(0.60),
                        Color.blue.opacity(0.34),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )
                .opacity(blueFlashOpacity)
                .blendMode(.screen)
                .ignoresSafeArea()

                freezeMist
                    .opacity(darknessOpacity)
                    .blendMode(.screen)

                glassCracks(in: proxy.size)
                    .opacity(crackGlowOpacity)

                freezeTitle
                    .opacity(freezeTextOpacity)
                    .scaleEffect(freezeTextScale)

                glassShards(in: proxy.size)
                    .opacity(shardOpacity)

                Rectangle()
                    .fill(Color.white)
                    .opacity(whiteoutOpacity)
                    .blendMode(.screen)
                    .ignoresSafeArea()
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                play()
            } else {
                reset()
            }
        }
        .onAppear {
            if isVisible {
                play()
            }
        }
    }

    private var freezeMist: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.cyan.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: CGFloat(150 + index * 23),
                        height: CGFloat(45 + index * 8)
                    )
                    .blur(radius: CGFloat(14 + index))
                    .rotationEffect(.degrees(Double(index * 21)))
                    .offset(
                        x: CGFloat((index % 3) * 72 - 72),
                        y: CGFloat((index / 3) * 95 - 95)
                    )
            }
        }
    }

    private var freezeTitle: some View {
        VStack(spacing: 8) {
            Text("……")
                .font(
                    .system(
                        size: 22,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(7)
                .foregroundStyle(Color.white.opacity(0.86))

            Text("FREEZE")
                .font(
                    .system(
                        size: 48,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.cyan,
                            Color.blue,
                            Color.white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.78), radius: 3, y: 3)
                .shadow(
                    color: Color.cyan.opacity(pulse ? 0.98 : 0.48),
                    radius: pulse ? 30 : 15
                )

            Text("PREMIUM MODE")
                .font(
                    .system(
                        size: 13,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(3)
                .foregroundStyle(Color.white.opacity(0.88))
        }
    }

    private func glassCracks(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(
                x: canvasSize.width * 0.52,
                y: canvasSize.height * 0.43
            )

            let branches: [[CGPoint]] = [
                [
                    center,
                    CGPoint(x: size.width * 0.35, y: size.height * 0.28),
                    CGPoint(x: size.width * 0.16, y: size.height * 0.18),
                    CGPoint(x: size.width * 0.03, y: size.height * 0.08)
                ],
                [
                    center,
                    CGPoint(x: size.width * 0.69, y: size.height * 0.25),
                    CGPoint(x: size.width * 0.86, y: size.height * 0.13),
                    CGPoint(x: size.width * 0.98, y: size.height * 0.04)
                ],
                [
                    center,
                    CGPoint(x: size.width * 0.73, y: size.height * 0.48),
                    CGPoint(x: size.width * 0.91, y: size.height * 0.54)
                ],
                [
                    center,
                    CGPoint(x: size.width * 0.62, y: size.height * 0.69),
                    CGPoint(x: size.width * 0.72, y: size.height * 0.91)
                ],
                [
                    center,
                    CGPoint(x: size.width * 0.40, y: size.height * 0.67),
                    CGPoint(x: size.width * 0.31, y: size.height * 0.88)
                ],
                [
                    center,
                    CGPoint(x: size.width * 0.23, y: size.height * 0.54),
                    CGPoint(x: size.width * 0.04, y: size.height * 0.61)
                ]
            ]

            for (branchIndex, points) in branches.enumerated() {
                guard points.count >= 2 else { continue }

                var path = Path()
                path.move(to: points[0])

                let visibleSegments = max(
                    1,
                    Int(
                        CGFloat(points.count - 1)
                            * max(0.01, crackProgress)
                    )
                )

                for index in 1...min(visibleSegments, points.count - 1) {
                    path.addLine(to: points[index])
                }

                context.stroke(
                    path,
                    with: .color(
                        branchIndex.isMultiple(of: 2)
                            ? Color.white.opacity(0.96)
                            : Color.cyan.opacity(0.94)
                    ),
                    style: StrokeStyle(
                        lineWidth: branchIndex.isMultiple(of: 3) ? 3.0 : 1.8,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .shadow(color: Color.cyan.opacity(0.95), radius: 8)
        .shadow(color: Color.white.opacity(0.72), radius: 3)
    }

    private func glassShards(in size: CGSize) -> some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<26, id: \.self) { index in
                    let angle = Double(index) * (360.0 / 26.0)
                    let radians = angle * .pi / 180
                    let distance =
                        CGFloat(42 + (index % 8) * 25)
                        * shardProgress

                    shardShape(index: index)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    Color.cyan.opacity(0.56),
                                    Color.blue.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: CGFloat(8 + index % 4 * 4),
                            height: CGFloat(18 + index % 5 * 5)
                        )
                        .rotationEffect(
                            .degrees(
                                angle
                                    + Double(index * 17)
                                    * Double(shardProgress)
                            )
                        )
                        .position(
                            x: proxy.size.width * 0.52
                                + cos(radians) * distance,
                            y: proxy.size.height * 0.43
                                + sin(radians) * distance
                                + CGFloat(index % 4) * 12
                                    * shardProgress
                        )
                        .shadow(
                            color: Color.cyan.opacity(0.82),
                            radius: 5
                        )
                }
            }
        }
    }

    private func shardShape(index: Int) -> Path {
        var path = Path()

        if index.isMultiple(of: 2) {
            path.move(to: CGPoint(x: 0.5, y: 0))
            path.addLine(to: CGPoint(x: 1, y: 0.84))
            path.addLine(to: CGPoint(x: 0, y: 1))
        } else {
            path.move(to: CGPoint(x: 0, y: 0.22))
            path.addLine(to: CGPoint(x: 0.86, y: 0))
            path.addLine(to: CGPoint(x: 1, y: 1))
            path.addLine(to: CGPoint(x: 0.24, y: 0.78))
        }

        path.closeSubpath()
        return path
    }

    private func play() {
        reset()

        withAnimation(.easeOut(duration: 0.12)) {
            darknessOpacity = 0.86
            blueFlashOpacity = 0.92
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 0.30)) {
                blueFlashOpacity = 0.28
                freezeTextOpacity = 1
                freezeTextScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            crackGlowOpacity = 1

            withAnimation(.easeOut(duration: 0.72)) {
                crackProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            withAnimation(.easeOut(duration: 0.08)) {
                whiteoutOpacity = 1
                freezeTextOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.34) {
            shardOpacity = 1

            withAnimation(.easeOut(duration: 0.62)) {
                whiteoutOpacity = 0
                shardProgress = 1
                crackGlowOpacity = 0
                darknessOpacity = 0
                blueFlashOpacity = 0
            }
        }

        withAnimation(
            .easeInOut(duration: 0.34)
                .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }

    private func reset() {
        blueFlashOpacity = 0
        darknessOpacity = 0
        crackProgress = 0
        crackGlowOpacity = 0
        freezeTextOpacity = 0
        freezeTextScale = 0.72
        whiteoutOpacity = 0
        shardProgress = 0
        shardOpacity = 0
        pulse = false
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black,
                Color.blue.opacity(0.45),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        FreezeEffectView(isVisible: true)
    }
}
