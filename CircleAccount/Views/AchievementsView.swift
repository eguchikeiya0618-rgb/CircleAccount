import SwiftUI

struct AchievementsView: View {

    let achievements: [Achievement]

    private var achievedCount: Int {
        achievements.filter { $0.isAchieved }.count
    }

    private var percent: Int {
        guard !achievements.isEmpty else { return 0 }
        return Int(Double(achievedCount) / Double(achievements.count) * 100)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black,
                         Color(red:0.03,green:0.05,blue:0.16),
                         Color(red:0.11,green:0.04,blue:0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing:20) {

                    VStack(spacing:12) {
                        Text("🏆")
                            .font(.system(size:64))

                        Text("ACHIEVEMENTS")
                            .font(.system(size:28,weight:.black,design:.rounded))
                            .foregroundStyle(.white)

                        ProgressView(value: Double(achievedCount),
                                     total: Double(max(achievements.count,1)))
                            .tint(.cyan)
                            .scaleEffect(y:1.8)

                        Text("\(achievedCount)/\(achievements.count)  (\(percent)%)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .frame(maxWidth:.infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius:28))

                    ForEach(achievements) { achievement in
                        HStack(spacing:16){

                            ZStack{
                                Circle()
                                    .fill(
                                        achievement.isAchieved
                                        ? Color.green.opacity(0.2)
                                        : Color.white.opacity(0.08)
                                    )
                                    .frame(width:64,height:64)

                                Text(achievement.isAchieved ? achievement.icon : "🔒")
                                    .font(.system(size:34))
                            }

                            VStack(alignment:.leading,spacing:6){
                                Text(achievement.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(achievement.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            Spacer()

                            Image(systemName:
                                    achievement.isAchieved
                                    ? "checkmark.seal.fill"
                                    : "lock.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    achievement.isAchieved
                                    ? .green
                                    : .gray
                                )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius:24))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("ACHIEVEMENTS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AchievementsView(achievements: [])
    }
}
