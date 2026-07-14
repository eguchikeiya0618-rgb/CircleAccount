import SwiftUI
import FirebaseFirestore

struct MonthlyMissionView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    let attendanceCount: Int
    let setupCount: Int
    let earlyAnswerCount: Int

    private let attendanceTarget = 5
    private let setupTarget = 3
    private let earlyAnswerTarget = 3

    private var isAllCompleted: Bool {
        attendanceCount >= attendanceTarget &&
        setupCount >= setupTarget &&
        earlyAnswerCount >= earlyAnswerTarget
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                missionHeader

                missionRow(
                    icon: "🏸",
                    title: "今月5回参加",
                    current: attendanceCount,
                    target: attendanceTarget
                )

                missionRow(
                    icon: "🧹",
                    title: "今月3回設営",
                    current: setupCount,
                    target: setupTarget
                )

                missionRow(
                    icon: "⏰",
                    title: "今月3回早期回答",
                    current: earlyAnswerCount,
                    target: earlyAnswerTarget
                )

                rewardCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("月間ミッション")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if isAllCompleted {
                grantMonthlyMissionBadge()
            }
        }
    }

    var missionHeader: some View {
        VStack(spacing: 10) {
            Text("🎯")
                .font(.system(size: 56))

            Text("今月のミッション")
                .font(.title2)
                .bold()

            Text("サークルへの参加と貢献で限定バッジを目指そう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    func missionRow(
        icon: String,
        title: String,
        current: Int,
        target: Int
    ) -> some View {
        let displayedCurrent = min(current, target)
        let isCompleted = current >= target

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text("\(displayedCurrent)/\(target)回")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title2)
                .foregroundStyle(
                    isCompleted
                        ? Color.green
                        : Color.secondary
                )
            }

            ProgressView(
                value: Double(displayedCurrent),
                total: Double(target)
            )
            .tint(
                isCompleted
                    ? Color.green
                    : Color.blue
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var rewardCard: some View {
        VStack(spacing: 10) {
            Text(
                isAllCompleted
                    ? "🎉 全ミッション達成！"
                    : "🏅 全ミッション達成報酬"
            )
            .font(.headline)
            .bold()

            Text("限定バッジ「今月の貢献者」")
                .font(.title3)
                .bold()

            Text(
                isAllCompleted
                    ? "プロフィールに残る限定バッジを獲得しました"
                    : "ポイントや無料券は付与されません"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            isAllCompleted
                ? Color.green.opacity(0.14)
                : Color.orange.opacity(0.12)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func grantMonthlyMissionBadge() {
        guard !currentUserId.isEmpty else {
            return
        }

        db.collection("members")
            .document(currentUserId)
            .updateData([
                "earnedBadges": FieldValue.arrayUnion([
                    "monthlyContributor"
                ])
            ]) { error in
                if let error {
                    print(
                        "❌ 月間ミッションバッジ付与失敗: "
                        + error.localizedDescription
                    )
                } else {
                    print("✅ 月間ミッションバッジ付与成功")
                }
            }
    }
}

#Preview {
    NavigationStack {
        MonthlyMissionView(
            attendanceCount: 1,
            setupCount: 1,
            earlyAnswerCount: 1
        )
    }
}
