import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement

    @Environment(\.dismiss) private var dismiss
    @State private var isAnimated = false
    @State private var showConfetti = false
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    achievement.color.opacity(0.35),
                    Color(.systemBackground),
                    achievement.color.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .zIndex(10)
            }

            VStack(spacing: 26) {
                Spacer()

                Text("🎉 ACHIEVEMENT UNLOCKED!")
                    .font(.headline)
                    .bold()
                    .tracking(1.2)
                    .foregroundStyle(achievement.color)

                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.20))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isAnimated ? 1.15 : 0.75)
                        .opacity(isAnimated ? 0.35 : 0.85)

                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 140, height: 140)
                        .shadow(
                            color: achievement.color.opacity(0.35),
                            radius: 24
                        )

                    Text(achievement.icon)
                        .font(.system(size: 76))
                        .scaleEffect(isAnimated ? 1 : 0.4)
                }

                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.system(size: 38, weight: .black))
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    Text("獲得報酬")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    Text("🎁 \(achievement.reward)")
                        .font(.headline)
                        .bold()
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("受け取る")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(achievement.color)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(28)
        }
        .onAppear {
            showConfetti = true

            withAnimation(
                .spring(response: 0.65, dampingFraction: 0.58)
            ) {
                isAnimated = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showConfetti = false
            }
        }
    }
}

#Preview {
    AchievementUnlockView(
        achievement: Achievement(
            icon: "🥇",
            title: "GOLD",
            subtitle: "達成",
            description: "累計200ptを獲得する",
            reward: "⭐ 対戦指名券 ×2",
            isAchieved: true,
            color: .orange
        )
    )
}
