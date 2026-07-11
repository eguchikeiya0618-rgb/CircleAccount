import SwiftUI
import FirebaseFirestore

struct HallOfFameView: View {
    private let db = Firestore.firestore()

    @State private var records: [HallOfFameRecord] = []
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if records.isEmpty {
                    Text("まだ歴代チャンピオンはありません")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 14) {
                            Text("🏆 \(record.month)")
                                .font(.title3)
                                .bold()

                            awardRow(icon: "🥇", name: record.championName, point: record.championPoint)
                            awardRow(icon: "🥈", name: record.secondName, point: record.secondPoint)
                            awardRow(icon: "🥉", name: record.thirdName, point: record.thirdPoint)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("歴代チャンピオン")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadRecords()
        }
    }

    func awardRow(icon: String, name: String, point: Int) -> some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(name)
                .font(.headline)

            Spacer()

            Text("\(point)pt")
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }

    func loadRecords() {
        db.collection("hallOfFame")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌", error.localizedDescription)
                    return
                }

                print("件数:", snapshot?.documents.count ?? 0)

                records = snapshot?.documents.map { document in
                    let data = document.data()

                    return HallOfFameRecord(
                        id: document.documentID,
                        month: data["month"] as? String ?? "",
                        championName: data["championName"] as? String ?? "",
                        championPoint: data["championPoint"] as? Int ?? 0,
                        secondName: data["secondName"] as? String ?? "",
                        secondPoint: data["secondPoint"] as? Int ?? 0,
                        thirdName: data["thirdName"] as? String ?? "",
                        thirdPoint: data["thirdPoint"] as? Int ?? 0
                    )
                } ?? []
            }
    }
}

struct HallOfFameRecord: Identifiable {
    let id: String
    let month: String

    let championName: String
    let championPoint: Int

    let secondName: String
    let secondPoint: Int

    let thirdName: String
    let thirdPoint: Int
}
