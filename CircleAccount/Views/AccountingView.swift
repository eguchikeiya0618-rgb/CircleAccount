import SwiftUI
import FirebaseFirestore

struct AccountingView: View {

    private let db = Firestore.firestore()

    @State private var activities: [Activity] = []

    var totalSales: Int {
        activities.reduce(0) {
            $0 + ($1.fee * $1.paidMembers.count)
        }
    }

    var totalUnpaid: Int {
        activities.reduce(0) {
            $0 + ($1.fee * max($1.participantCount - $1.paidMembers.count, 0))
        }
    }

    var body: some View {
        NavigationStack {
            List {

                Section("会計サマリー") {

                    HStack {
                        Text("回収済み")
                        Spacer()
                        Text("\(totalSales)円")
                            .bold()
                    }

                    HStack {
                        Text("未回収")
                        Spacer()
                        Text("\(totalUnpaid)円")
                            .foregroundStyle(.red)
                            .bold()
                    }
                }

                Section("活動別") {

                    ForEach(activities) { activity in

                        VStack(alignment: .leading, spacing: 8) {

                            Text(activity.title)
                                .font(.headline)

                            Text("\(formatDate(activity.date)) \(formatTime(activity.startTime))〜\(formatTime(activity.endTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("参加 \(activity.participantCount)人")
                                Spacer()
                                Text("支払済 \(activity.paidMembers.count)人")
                            }

                            HStack {
                                Text("回収済 \(activity.fee * activity.paidMembers.count)円")
                                Spacer()
                                Text("未回収 \(activity.fee * max(activity.participantCount - activity.paidMembers.count, 0))円")
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("会計")
            .onAppear {
                loadActivities()
            }
        }
    }

    func loadActivities() {

        db.collection("activities")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("会計データ読み込み失敗: \(error)")
                    return
                }

                var loadedActivities: [Activity] = []

                snapshot?.documents.forEach { document in

                    let data = document.data()

                    let activity = Activity(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                        endTime: (data["endTime"] as? Timestamp)?.dateValue() ?? Date(),
                        place: data["place"] as? String ?? "",
                        fee: data["fee"] as? Int ?? 0,
                        capacity: data["capacity"] as? Int ?? 0,
                        memo: data["memo"] as? String ?? "",
                        createdBy: data["createdBy"] as? String ?? "",
                        participants: data["participants"] as? [String] ?? [],
                        waitingList: data["waitingList"] as? [String] ?? [],
                        attendance: [],
                        paidMembers: data["paidMembers"] as? [String] ?? []
                    )

                    loadedActivities.append(activity)
                }

                activities = loadedActivities
            }
    }

    func formatDate(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ja_JP")

        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return formatter.string(from: date)
    }
}

#Preview {
    AccountingView()
}
