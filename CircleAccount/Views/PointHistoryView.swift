import SwiftUI
import FirebaseFirestore

struct PointHistoryView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var histories: [PointHistory] = []

    var body: some View {
        List {
            if histories.isEmpty {
                Text("ポイント履歴はまだありません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(histories) { history in
                    HStack(spacing: 12) {
                        Text(history.icon)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(history.title)
                                .font(.headline)

                            Text(formatDate(history.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(history.point > 0 ? "+" : "")\(history.point)pt")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(history.point >= 0 ? .blue : .red)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("ポイント履歴")
        .onAppear {
            loadHistories()
        }
    }

    func loadHistories() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .document(currentUserId)
            .collection("pointHistories")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, _ in
                histories = snapshot?.documents.compactMap { document in
                    let data = document.data()

                    return PointHistory(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        point: data["point"] as? Int ?? 0,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        icon: data["icon"] as? String ?? "⭐"
                    )
                } ?? []
            }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PointHistoryView()
    }
}
