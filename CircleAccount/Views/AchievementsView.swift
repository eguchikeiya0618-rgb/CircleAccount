import SwiftUI

struct AchievementsView: View {

    let achievements: [Achievement]

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🏅 実績達成率")
                            .font(.headline)
                            .bold()

                        Spacer()

                        Text("\(achievements.filter { $0.isAchieved }.count)/\(achievements.count)")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.blue)
                    }

                    ProgressView(
                        value: Double(achievements.filter { $0.isAchieved }.count),
                        total: Double(max(achievements.count, 1))
                    )
                    .tint(.blue)
                    .scaleEffect(y: 1.4)

                    let percentage = achievements.isEmpty
                        ? 0
                        : Int(
                            Double(achievements.filter { $0.isAchieved }.count)
                            / Double(achievements.count)
                            * 100
                        )

                    Text("\(percentage)%達成")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                ForEach(achievements) { achievement in

                    HStack(spacing: 16) {

                        Text(achievement.isAchieved ? achievement.icon : "🔒")
                            .font(.system(size: 38))

                        VStack(alignment: .leading, spacing: 6) {

                            Text(achievement.title)
                                .font(.headline)

                            Text(achievement.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }

                        Spacer()

                        if achievement.isAchieved {

                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.title2)

                        } else {

                            Image(systemName: "lock.fill")
                                .foregroundStyle(.gray)

                        }

                    }
                    .padding()

                    .background(Color(.systemBackground))

                    .clipShape(RoundedRectangle(cornerRadius: 20))

                }

            }
            .padding()

        }

        .background(Color(.systemGroupedBackground))

        .navigationTitle("実績一覧")

    }

}

#Preview {

    NavigationStack {

        AchievementsView(achievements: [])

    }

}
