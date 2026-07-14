import SwiftUI
import FirebaseFirestore

struct SiriusAwardView: View {
    private let db = Firestore.firestore()

    @State private var pointKingName = ""
    @State private var pointKingPoint = 0
    
    @State private var setupKingName = ""
    @State private var setupKingCount = 0
    var body: some View {

        List {

            Section("👑 月間表彰") {

                awardRow(
                    icon: "👑",
                    title: "ポイント王",
                    subtitle: pointKingName.isEmpty
                        ? "集計中..."
                        : "\(pointKingName)・\(pointKingPoint)pt"
                )

                awardRow(
                    icon: "🧹",
                    title: "設営王",
                    subtitle: setupKingName.isEmpty
                        ? "集計中..."
                        : "\(setupKingName)・\(setupKingCount)回"
                )
                awardRow(
                    icon: "🔥",
                    title: "皆勤賞",
                    subtitle: "全活動参加"
                )

            }

        }
        .navigationTitle("SiRiUS AWARD")
        .onAppear {
            loadPointKing()
            loadSetupKing()
        }
    }

    func awardRow(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack {

            Text(icon)
                .font(.largeTitle)

            VStack(alignment: .leading) {

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

        }
        .padding(.vertical,6)

    }
    func loadPointKing() {

        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in

                guard let data = snapshot?.documents.first?.data() else {
                    return
                }

                pointKingName = data["name"] as? String ?? ""
                pointKingPoint = data["monthlyPoint"] as? Int ?? 0
            }
    }
    func loadSetupKing() {
        db.collection("members")
            .order(by: "setupCount", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    print("設営王取得失敗: \(error.localizedDescription)")
                    setupKingName = ""
                    setupKingCount = 0
                    return
                }

                guard let data = snapshot?.documents.first?.data() else {
                    setupKingName = ""
                    setupKingCount = 0
                    return
                }

                setupKingName = data["name"] as? String ?? ""
                setupKingCount = data["setupCount"] as? Int ?? 0
            }
    }
}

#Preview {
    NavigationStack {
        SiriusAwardView()
    }
}
