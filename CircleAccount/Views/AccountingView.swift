import SwiftUI
import FirebaseFirestore

struct AccountingView: View {

    private let db = Firestore.firestore()

    @State private var activities: [Activity] = []
    @State private var uncheckedTicketCount = 0

    private var totalSales: Int {
        activities.reduce(0) {
            $0 + ($1.fee * $1.paidMembers.count)
        }
    }

    private var totalUnpaid: Int {
        activities.reduce(0) {
            $0 + ($1.fee * max($1.participantCount - $1.paidMembers.count, 0))
        }
    }

    private var totalParticipants: Int {
        activities.reduce(0) { $0 + $1.participantCount }
    }

    private var collectionRate: Int {
        let total = totalSales + totalUnpaid
        guard total > 0 else { return 0 }
        return Int((Double(totalSales) / Double(total)) * 100)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.indigo.opacity(0.92),
                        Color.purple.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        summaryGrid
                        ticketAlertCard
                        activitySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Accounting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                loadActivities()
                loadUncheckedTicketCount()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CIRCLE ACCOUNT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(2.2)
                        .foregroundStyle(.white.opacity(0.62))

                    Text("会計ダッシュボード")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 27))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }

            Text("回収状況と活動別の収支をまとめて確認できます")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.top, 8)
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            summaryCard(
                title: "回収済み",
                value: "\(totalSales.formatted())円",
                icon: "checkmark.circle.fill",
                accent: .green
            )

            summaryCard(
                title: "未回収",
                value: "\(totalUnpaid.formatted())円",
                icon: "exclamationmark.circle.fill",
                accent: .red
            )

            summaryCard(
                title: "参加者",
                value: "\(totalParticipants)人",
                icon: "person.2.fill",
                accent: .cyan
            )

            summaryCard(
                title: "回収率",
                value: "\(collectionRate)%",
                icon: "chart.pie.fill",
                accent: .orange
            )
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        icon: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)

                Spacer()

                Circle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 9, height: 9)
            }

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.66))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var ticketAlertCard: some View {
        NavigationLink {
            TicketUsageHistoryView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            uncheckedTicketCount > 0
                            ? Color.red.opacity(0.22)
                            : Color.white.opacity(0.10)
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "ticket.fill")
                        .font(.title2)
                        .foregroundStyle(uncheckedTicketCount > 0 ? .red : .white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("未確認チケット使用")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(
                        uncheckedTicketCount > 0
                        ? "確認が必要な申請があります"
                        : "未確認の申請はありません"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                Text("\(uncheckedTicketCount)件")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(uncheckedTicketCount > 0 ? .red : .white.opacity(0.70))

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        uncheckedTicketCount > 0
                        ? Color.red.opacity(0.42)
                        : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("活動別会計")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(activities.count)件")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.58))
            }

            if activities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.45))

                    Text("会計データがありません")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("活動が登録されると、ここに収支が表示されます")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activities) { activity in
                        activityCard(activity)
                    }
                }
            }
        }
    }

    private func activityCard(_ activity: Activity) -> some View {
        let paidCount = activity.paidMembers.count
        let unpaidCount = max(activity.participantCount - paidCount, 0)
        let sales = activity.fee * paidCount
        let unpaid = activity.fee * unpaidCount
        let rate = activity.participantCount > 0
            ? Int((Double(paidCount) / Double(activity.participantCount)) * 100)
            : 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(activity.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(
                        "\(formatDate(activity.date))  \(formatTime(activity.startTime))〜\(formatTime(activity.endTime))"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Text("\(rate)%")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(rate == 100 ? .green : .orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.09))
                    .clipShape(Capsule())
            }

            ProgressView(value: Double(rate), total: 100)
                .tint(rate == 100 ? .green : .orange)

            HStack(spacing: 0) {
                accountingStat(
                    title: "参加",
                    value: "\(activity.participantCount)人",
                    icon: "person.2.fill"
                )

                Divider()
                    .overlay(.white.opacity(0.12))
                    .frame(height: 34)

                accountingStat(
                    title: "支払済",
                    value: "\(paidCount)人",
                    icon: "checkmark.seal.fill"
                )

                Divider()
                    .overlay(.white.opacity(0.12))
                    .frame(height: 34)

                accountingStat(
                    title: "未払い",
                    value: "\(unpaidCount)人",
                    icon: "clock.badge.exclamationmark"
                )
            }

            HStack {
                Label("\(sales.formatted())円", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Spacer()

                Label("\(unpaid.formatted())円", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(unpaid > 0 ? .red : .white.opacity(0.55))
            }
            .font(.subheadline)
            .fontWeight(.bold)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        }
    }

    private func accountingStat(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.60))

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
    }

    private func loadActivities() {
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

                DispatchQueue.main.async {
                    activities = loadedActivities
                }
            }
    }

    private func loadUncheckedTicketCount() {
        db.collection("ticketUsages")
            .whereField("status", isEqualTo: "未確認")
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    uncheckedTicketCount = snapshot?.documents.count ?? 0
                }
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    AccountingView()
}

