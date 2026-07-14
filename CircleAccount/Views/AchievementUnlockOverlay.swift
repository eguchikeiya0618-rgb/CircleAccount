import SwiftUI

struct AchievementUnlockOverlay: View {
    let icon: String
    let title: String
    let description: String
    let rewardPoint: Int

    @State private var glowActive = false
    @State private var ringRotation = 0.0
    @State private var trophyScale: CGFloat = 0.20
    @State private var contentOpacity = 0.0
    @State private var titleOffset: CGFloat = 25

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.yellow.opacity(
                        glowActive ? 0.58 : 0.22
                    ),
                    Color.orange.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: 330
            )
            .ignoresSafeArea()
            .scaleEffect(glowActive ? 1.20 : 0.88)

            VStack(spacing: 22) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.caption)
                    .fontWeight(.black)
                    .tracking(2.4)
                    .foregroundStyle(.yellow)
                    .opacity(contentOpacity)
                    .offset(y: titleOffset)

                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .yellow,
                                    .orange,
                                    .white,
                                    .yellow
                                ],
                                center: .center
                            ),
                            lineWidth: 9
                        )
                        .frame(width: 210, height: 210)
                        .rotationEffect(
                            .degrees(ringRotation)
                        )
                        .shadow(
                            color: Color.yellow.opacity(0.85),
                            radius: 24
                        )

                    Circle()
                        .fill(Color.white.opacity(0.13))
                        .frame(width: 170, height: 170)

                    VStack(spacing: 5) {
                        Text("🏆")
                            .font(.system(size: 72))

                        Text(icon)
                            .font(.system(size: 35))
                    }
                }
                .scaleEffect(trophyScale)

                VStack(spacing: 10) {
                    Text("実績解除！")
                        .font(
                            .system(
                                size: 24,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.yellow)

                    Text(title)
                        .font(
                            .system(
                                size: 32,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                }
                .opacity(contentOpacity)

                if rewardPoint > 0 {
                    HStack(spacing: 7) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)

                        Text("+\(rewardPoint)pt")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.13))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.yellow.opacity(0.50),
                                lineWidth: 1.5
                            )
                    }
                    .opacity(contentOpacity)
                }
            }
            .padding(28)
        }
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 0.55)
                .repeatForever(autoreverses: true)
        ) {
            glowActive = true
        }

        withAnimation(
            .linear(duration: 2.4)
                .repeatForever(autoreverses: false)
        ) {
            ringRotation = 360
        }

        withAnimation(
            .spring(
                response: 0.52,
                dampingFraction: 0.45
            )
        ) {
            trophyScale = 1
            contentOpacity = 1
            titleOffset = 0
        }
    }
}

#Preview {
    AchievementUnlockOverlay(
        icon: "⏰",
        title: "早期回答デビュー",
        description: "前日18時までの参加回答を達成しました！",
        rewardPoint: 0
    )
}
