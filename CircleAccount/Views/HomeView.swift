import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var todayActivity: Activity?
    @State private var nextActivity: Activity?

    @State private var totalMembers = 0
    @State private var totalCollected = 0
    @State private var totalUncollected = 0
    @State private var thisMonthActivities = 0

    @State private var totalPoint = 0
    @State private var availablePoint = 0

    let mainColor = Color(red: 0.05, green: 0.11, blue: 0.26)
    let accentColor = Color(red: 0.15, green: 0.39, blue: 0.92)

    var nextReward: (title: String, point: Int, icon: String) {
        if availablePoint < 100 { return ("片付け免除", 100, "🧹") }
        if availablePoint < 180 { return ("100円引き", 180, "💴") }
        if availablePoint < 260 { return ("参加費無料", 260, "🎁") }
        return ("特典交換できます", max(availablePoint, 260), "🎉")
    }

    var remainingPoint: Int {
        max(nextReward.point - availablePoint, 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerView

                    if let todayActivity {
                        todayCard(todayActivity)
                    }

                    if let nextActivity {
                        nextActivityCard(nextActivity)
                    }

                    pointCardLink
                    rankingCardLink
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        SummaryCard(title: "メンバー", value: "\(totalMembers)人", icon: "person.3.fill", color: accentColor)
                        SummaryCard(title: "今月活動", value: "\(thisMonthActivities)回", icon: "calendar.badge.clock", color: accentColor)
                        SummaryCard(title: "回収済み", value: "\(totalCollected)円", icon: "checkmark.circle.fill", color: .green)
                        SummaryCard(title: "未回収", value: "\(totalUncollected)円", icon: "exclamationmark.circle.fill", color: .orange)
                    }

                    sloganView
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .onAppear {
                loadDashboard()
                loadPoint()
            }
        }
    }

    func todayCard(_ activity: Activity) -> some View {
        brandedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("TODAY", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Spacer()

                    Text("今日の活動")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                Text(activity.title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(mainColor)

                Label("\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))", systemImage: "clock")
                Label(activity.place, systemImage: "mappin.and.ellipse")

                Divider()

                HStack {
                    statusMini(title: "参加", value: "\(activity.attendingCount)人", color: accentColor)
                    Spacer()
                    statusMini(title: "未払い", value: "\(max(activity.attendingCount - activity.paidMembers.count, 0))人", color: .red)
                    Spacer()
                    statusMini(title: "待ち", value: "\(activity.waitingList.count)人", color: .orange)
                }
            }
        }
    }

    var pointCardLink: some View {
        NavigationLink {
            PointCardView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("SiRiUS CARD", systemImage: "creditcard.fill")
                        .font(.headline)
                        .foregroundStyle(accentColor)

                    Spacer()

                    Text("\(availablePoint)pt")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(accentColor)
                }

                ProgressView(value: Double(availablePoint), total: Double(nextReward.point))

                Text("あと\(remainingPoint)ptで \(nextReward.icon)\(nextReward.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    var rankingCardLink: some View {
        NavigationLink {
            RankingView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label("月間ランキング", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Text("今月の順位をチェック")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    var headerView: some View {
        VStack(spacing: 8) {
            Text("SiRiUS")
                .font(.system(size: 44, weight: .black, design: .serif))
                .foregroundStyle(mainColor)

            Text("Badminton Circle")
                .font(.subheadline)
                .foregroundStyle(accentColor)

            Text("EST. 2023.07")
                .font(.caption)
                .bold()
                .foregroundStyle(mainColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    func nextActivityCard(_ activity: Activity) -> some View {
        brandedCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("次回活動", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(accentColor)

                    Spacer()

                    Text(daysUntilText(activity.date))
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.12))
                        .foregroundStyle(accentColor)
                        .clipShape(Capsule())
                }

                Text(activity.title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(mainColor)

                Label(formatDate(activity.date), systemImage: "calendar")
                Label("\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))", systemImage: "clock")
                Label(activity.place, systemImage: "mappin.and.ellipse")

                Divider()

                HStack {
                    statusMini(title: "参加", value: "\(activity.attendingCount)人", color: accentColor)
                    Spacer()
                    statusMini(title: "未定", value: "\(activity.undecidedCount)人", color: .orange)
                    Spacer()
                    statusMini(title: "不参加", value: "\(activity.absentCount)人", color: .gray)
                }
            }
        }
    }

    func brandedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    func statusMini(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(color)
        }
    }

    var sloganView: some View {
        VStack(spacing: 6) {
            Text("つながる・集う・楽しむ")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("One team, One SiRiUS.")
                .font(.caption)
                .italic()
                .foregroundStyle(accentColor)
        }
        .padding(.top, 6)
    }

    func loadPoint() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members").document(currentUserId).getDocument { snapshot, _ in
            let data = snapshot?.data()
            totalPoint = data?["totalPoint"] as? Int ?? 0
            availablePoint = data?["availablePoint"] as? Int ?? 0
        }
    }

    func loadDashboard() {
        db.collection("members").getDocuments { snapshot, _ in
            totalMembers = snapshot?.documents.count ?? 0
        }

        db.collection("activities")
            .order(by: "date")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                var activities: [Activity] = []
                var collected = 0
                var uncollected = 0
                var monthCount = 0

                for document in documents {
                    let data = document.data()

                    let attendanceArray = data["attendance"] as? [[String: String]] ?? []
                    let attendance = attendanceArray.compactMap { item -> Attendance? in
                        guard
                            let memberId = item["memberId"],
                            let statusRawValue = item["status"],
                            let status = AttendanceStatus(rawValue: statusRawValue)
                        else { return nil }

                        return Attendance(memberId: memberId, status: status)
                    }

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
                        attendance: attendance,
                        paidMembers: data["paidMembers"] as? [String] ?? [],
                        pointGranted: data["pointGranted"] as? Bool ?? false,
                        pointGrantedAt: (data["pointGrantedAt"] as? Timestamp)?.dateValue()
                    )

                    activities.append(activity)

                    collected += activity.fee * activity.paidMembers.count
                    uncollected += activity.fee * max(activity.attendingCount - activity.paidMembers.count, 0)

                    if Calendar.current.isDate(activity.date, equalTo: Date(), toGranularity: .month) {
                        monthCount += 1
                    }
                }

                totalCollected = collected
                totalUncollected = uncollected
                thisMonthActivities = monthCount

                todayActivity = activities
                    .filter { Calendar.current.isDateInToday($0.date) }
                    .sorted { $0.startTime < $1.startTime }
                    .first

                nextActivity = activities
                    .filter { $0.date >= Date() && !Calendar.current.isDateInToday($0.date) }
                    .sorted { $0.date < $1.date }
                    .first
            }
    }

    func daysUntilText(_ date: Date) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: date)
        let days = Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0

        if days == 0 { return "今日" }
        if days == 1 { return "明日" }
        return "あと\(days)日"
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    HomeView()
}
