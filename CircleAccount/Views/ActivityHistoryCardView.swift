import SwiftUI

struct ActivityHistoryCardView: View {
    let recentActivities: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近の活動履歴")
                .font(.title2)
                .bold()

            if recentActivities.isEmpty {
                Text("まだ活動履歴はありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .padding(.top, 2)

                        Text(activity)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if index < recentActivities.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

#Preview {
    ActivityHistoryCardView(
        recentActivities: [
            "7/10 シリウス練習・三苫小学校 ✅ 参加",
            "7/5 シリウス練習・体育館 ✅ 参加"
        ]
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
