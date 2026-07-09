import SwiftUI
import FirebaseFirestore

struct TicketUsage: Identifiable {
    let id: String
    let memberName: String
    let ticket: String
    let icon: String
    let usedAt: Date
    let status: String
}

struct TicketUsageHistoryView: View {
    private let db = Firestore.firestore()

    @State private var usages: [TicketUsage] = []

    var body: some View {
        List(usages) { usage in
            VStack(alignment: .leading, spacing: 6) {
                Text("\(usage.icon) \(usage.ticket)")
                    .font(.headline)

                Text("使用者：\(usage.memberName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formatDate(usage.usedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if usage.status == "未確認" {
                    Button("✅ 確認済みにする") {
                        markAsChecked(id: usage.id)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("✅ 確認済み")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("チケット使用履歴")
        .onAppear {
            loadUsages()
        }
    }

    func loadUsages() {
        db.collection("ticketUsages")
            .order(by: "usedAt", descending: true)
            .getDocuments { snapshot, _ in
                usages = snapshot?.documents.map { document in
                    let data = document.data()

                    return TicketUsage(
                        id: document.documentID,
                        memberName: data["memberName"] as? String ?? "不明",
                        ticket: data["ticket"] as? String ?? "",
                        icon: data["icon"] as? String ?? "",
                        usedAt: (data["usedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "未確認"
                    )
                } ?? []
            }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    func markAsChecked(id: String) {
        db.collection("ticketUsages")
            .document(id)
            .updateData([
                "status": "確認済み"
            ]) { error in
                if error == nil {
                    loadUsages()
                }
            }
    }
    }
