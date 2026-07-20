import SwiftUI

struct ConfettiView: View {
    @State private var animate = false

    private let pieces = Array(0..<55)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces, id: \.self) { index in
                    ConfettiPiece(index: index)
                        .position(
                            x: confettiX(
                                index: index,
                                width: geometry.size.width
                            ),
                            y: animate
                                ? geometry.size.height + 100
                                : -100
                        )
                        .rotationEffect(
                            .degrees(
                                animate
                                ? Double(index * 65)
                                : 0
                            )
                        )
                        .animation(
                            .linear(
                                duration: confettiDuration(index: index)
                            )
                            .delay(confettiDelay(index: index)),
                            value: animate
                        )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animate = true
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    func confettiX(index: Int, width: CGFloat) -> CGFloat {
        let position = (index * 47 + 13) % 100
        return width * CGFloat(position) / 100
    }

    func confettiDuration(index: Int) -> Double {
        1.8 + Double(index % 8) * 0.18
    }

    func confettiDelay(index: Int) -> Double {
        Double(index % 15) * 0.06
    }
}

struct ConfettiPiece: View {
    let index: Int

    var body: some View {
        Group {
            if index % 3 == 0 {
                Circle()
                    .fill(confettiColor)
            } else if index % 3 == 1 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(confettiColor)
            } else {
                Capsule()
                    .fill(confettiColor)
            }
        }
        .frame(
            width: index % 2 == 0 ? 11 : 7,
            height: index % 2 == 0 ? 17 : 12
        )
    }

    var confettiColor: Color {
        switch index % 6 {
        case 0:
            return .yellow
        case 1:
            return .pink
        case 2:
            return .blue
        case 3:
            return .green
        case 4:
            return .orange
        default:
            return .purple
        }
    }
}

#Preview {
    ConfettiView()
        .background(Color.black)
}
// MARK: - 殿堂入り確定演出

struct HallOfFameCelebrationOverlay: View {
    let monthText: String
    let onClose: () -> Void

    // 背景
    @State private var backgroundOpacity = 0.0

    // 王冠
    @State private var crownScale: CGFloat = 0.15
    @State private var crownRotation = -18.0
    @State private var crownOffsetY: CGFloat = -90
    @State private var glowScale: CGFloat = 0.65
    @State private var glowOpacity = 0.0
    @State private var ringScale: CGFloat = 0.35
    @State private var ringOpacity = 0.0

    // 文字
    @State private var hallTitleOpacity = 0.0
    @State private var hallTitleOffsetY: CGFloat = 22

    @State private var mainTitleScale: CGFloat = 0.35
    @State private var mainTitleOpacity = 0.0

    @State private var detailOpacity = 0.0
    @State private var detailOffsetY: CGFloat = 18

    // ボタン
    @State private var buttonOpacity = 0.0
    @State private var buttonScale: CGFloat = 0.75

    // キラキラ
    @State private var sparkleAnimation = false

    // 二重終了防止
    @State private var didClose = false

    private let sparkles = Array(0..<18)

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity * 0.78)
                .ignoresSafeArea()

            celebrationBackground

            ConfettiView()
                .opacity(backgroundOpacity)

            sparkleLayer

            VStack(spacing: 16) {
                crownSection

                hallOfFameTitle

                mainCelebrationTitle

                detailSection

                resultButton
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .onAppear {
            startCelebration()
        }
        .transition(
            .opacity.combined(
                with: .scale(scale: 0.96)
            )
        )
    }

    // MARK: - 背景

    private var celebrationBackground: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.28),
                    Color.pink.opacity(0.14),
                    Color.purple.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 430
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()

            Circle()
                .fill(Color.yellow.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 28)
                .scaleEffect(
                    sparkleAnimation ? 1.12 : 0.86
                )
                .opacity(backgroundOpacity)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 34)
                .offset(x: -180, y: 270)
                .scaleEffect(
                    sparkleAnimation ? 0.90 : 1.12
                )
                .opacity(backgroundOpacity)

            Circle()
                .fill(Color.orange.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 32)
                .offset(x: 190, y: -310)
                .scaleEffect(
                    sparkleAnimation ? 1.08 : 0.88
                )
                .opacity(backgroundOpacity)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 王冠

    private var crownSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.88),
                            Color.orange.opacity(0.40),
                            Color.pink.opacity(0.16),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 122
                    )
                )
                .frame(width: 245, height: 245)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 3)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow,
                            Color.white,
                            Color.orange,
                            Color.pink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 186, height: 186)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(
                    Color.white.opacity(0.42),
                    lineWidth: 1.5
                )
                .frame(width: 210, height: 210)
                .scaleEffect(ringScale * 1.18)
                .opacity(ringOpacity * 0.65)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow,
                                Color.orange,
                                Color.pink,
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 136, height: 136)

                Circle()
                    .stroke(
                        Color.white.opacity(0.90),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)

                Text("👑")
                    .font(.system(size: 78))
            }
            .scaleEffect(crownScale)
            .rotationEffect(.degrees(crownRotation))
            .offset(y: crownOffsetY)
            .shadow(
                color: Color.yellow.opacity(0.78),
                radius: 30,
                x: 0,
                y: 10
            )
        }
        .frame(height: 235)
    }

    // MARK: - タイトル

    private var hallOfFameTitle: some View {
        Text("HALL OF FAME")
            .font(
                .system(
                    size: 34,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(0.5)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.yellow,
                        Color.orange,
                        Color.pink,
                        Color.purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: Color.orange.opacity(0.36),
                radius: 10,
                x: 0,
                y: 4
            )
            .opacity(hallTitleOpacity)
            .offset(y: hallTitleOffsetY)
    }

    private var mainCelebrationTitle: some View {
        Text("殿堂入り！")
            .font(
                .system(
                    size: 45,
                    weight: .black,
                    design: .rounded
                )
            )
            .foregroundStyle(.white)
            .shadow(
                color: Color.black.opacity(0.42),
                radius: 8,
                x: 0,
                y: 5
            )
            .scaleEffect(mainTitleScale)
            .opacity(mainTitleOpacity)
    }

    // MARK: - 詳細

    private var detailSection: some View {
        VStack(spacing: 8) {
            Text(monthText)
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(.yellow)

            Text("月間表彰の結果を永久保存しました")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(
                    .white.opacity(0.82)
                )
                .multilineTextAlignment(.center)
        }
        .opacity(detailOpacity)
        .offset(y: detailOffsetY)
    }

    // MARK: - ボタン

    private var resultButton: some View {
        Button {
            closeOverlay()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "crown.fill")
                    .font(.headline)

                Text("結果を見る")
                    .font(.headline)
                    .fontWeight(.black)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.black)
            }
            .foregroundStyle(.white)
            .frame(width: 230)
            .padding(.vertical, 15)
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
                        Color.white.opacity(0.48),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: Color.pink.opacity(0.40),
                radius: 16,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .opacity(buttonOpacity)
        .scaleEffect(buttonScale)
    }

    // MARK: - キラキラ

    private var sparkleLayer: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles, id: \.self) { index in
                    Image(
                        systemName:
                            index.isMultiple(of: 3)
                                ? "sparkles"
                                : "star.fill"
                    )
                    .font(
                        .system(
                            size:
                                index.isMultiple(of: 2)
                                    ? 15
                                    : 9
                        )
                    )
                    .foregroundStyle(
                        index.isMultiple(of: 2)
                            ? Color.yellow
                            : Color.white
                    )
                    .position(
                        x: sparkleX(
                            index: index,
                            width: geometry.size.width
                        ),
                        y: sparkleY(
                            index: index,
                            height: geometry.size.height
                        )
                    )
                    .scaleEffect(
                        sparkleAnimation
                            ? sparkleEndScale(index)
                            : sparkleStartScale(index)
                    )
                    .opacity(
                        sparkleAnimation
                            ? sparkleEndOpacity(index)
                            : 0.15
                    )
                    .rotationEffect(
                        .degrees(
                            sparkleAnimation
                                ? Double(index * 75)
                                : 0
                        )
                    )
                    .animation(
                        .easeInOut(
                            duration:
                                0.75
                                + Double(index % 5) * 0.16
                        )
                        .repeatForever(
                            autoreverses: true
                        )
                        .delay(
                            Double(index % 7) * 0.09
                        ),
                        value: sparkleAnimation
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(backgroundOpacity)
    }

    private func sparkleX(
        index: Int,
        width: CGFloat
    ) -> CGFloat {
        let value = (index * 47 + 11) % 100
        return width * CGFloat(value) / 100
    }

    private func sparkleY(
        index: Int,
        height: CGFloat
    ) -> CGFloat {
        let value = (index * 61 + 8) % 100
        return height * CGFloat(value) / 100
    }

    private func sparkleStartScale(
        _ index: Int
    ) -> CGFloat {
        index.isMultiple(of: 2) ? 0.35 : 0.55
    }

    private func sparkleEndScale(
        _ index: Int
    ) -> CGFloat {
        index.isMultiple(of: 3) ? 1.55 : 1.10
    }

    private func sparkleEndOpacity(
        _ index: Int
    ) -> Double {
        index.isMultiple(of: 4) ? 1.0 : 0.68
    }

    // MARK: - 演出開始

    private func startCelebration() {
        withAnimation(
            .easeOut(duration: 0.24)
        ) {
            backgroundOpacity = 1
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {
            withAnimation(
                .spring(
                    response: 0.58,
                    dampingFraction: 0.55
                )
            ) {
                crownScale = 1
                crownRotation = 0
                crownOffsetY = 0
            }

            withAnimation(
                .easeOut(duration: 0.48)
            ) {
                glowScale = 1
                glowOpacity = 1
                ringScale = 1
                ringOpacity = 0.92
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.42
        ) {
            sparkleAnimation = true

            withAnimation(
                .easeOut(duration: 0.42)
            ) {
                hallTitleOpacity = 1
                hallTitleOffsetY = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.70
        ) {
            withAnimation(
                .spring(
                    response: 0.44,
                    dampingFraction: 0.48
                )
            ) {
                mainTitleOpacity = 1
                mainTitleScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.98
        ) {
            withAnimation(
                .easeOut(duration: 0.36)
            ) {
                detailOpacity = 1
                detailOffsetY = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.22
        ) {
            withAnimation(
                .spring(
                    response: 0.42,
                    dampingFraction: 0.72
                )
            ) {
                buttonOpacity = 1
                buttonScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.35
        ) {
            withAnimation(
                .easeInOut(duration: 1.0)
                    .repeatForever(
                        autoreverses: true
                    )
            ) {
                glowScale = 1.13
                glowOpacity = 0.72
                ringScale = 1.20
                ringOpacity = 0.16
            }
        }

        // 操作しない場合は8秒後に自動終了
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 8.0
        ) {
            closeOverlay()
        }
    }

    // MARK: - 終了

    private func closeOverlay() {
        guard !didClose else {
            return
        }

        didClose = true

        withAnimation(
            .easeOut(duration: 0.28)
        ) {
            backgroundOpacity = 0
            hallTitleOpacity = 0
            mainTitleOpacity = 0
            detailOpacity = 0
            buttonOpacity = 0
            crownScale = 0.82
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.30
        ) {
            onClose()
        }
    }
}

