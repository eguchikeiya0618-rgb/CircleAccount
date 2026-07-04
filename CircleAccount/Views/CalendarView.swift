import SwiftUI
import FirebaseFirestore

struct CalendarView: View {
    private let db = Firestore.firestore()

    @State private var currentMonth = Date()
    @State private var activities: [Activity] = []
    @State private var selectedDate = Date()

    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var selectedActivities: [Binding<Activity>] {
        activities.indices.compactMap { index in
            if Calendar.current.isDate(activities[index].date, inSameDayAs: selectedDate) {
                return $activities[index]
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    weekHeader
                    calendarGrid
                    selectedActivityList
                }
                .padding()
            }
            .navigationTitle("カレンダー")
            .onAppear {
                selectedDate = Date()
                loadActivities()
            }
        }
    }

    var monthHeader: some View {
        HStack {
            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthTitle)
                .font(.title2)
                .bold()

            Spacer()

            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
    }

    var weekHeader: some View {
        HStack {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(calendarDays, id: \.self) { date in
                if let date = date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }

    func dayCell(_ date: Date) -> some View {
        let hasActivity = activities.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }

        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)

                if hasActivity {
                    Circle()
                        .fill(isSelected ? Color.white : Color.blue)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.blue :
                isToday ? Color.blue.opacity(0.12) :
                Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    var selectedActivityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatSelectedDate(selectedDate))
                .font(.headline)

            if selectedActivities.isEmpty {
                Text("活動予定はありません")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(selectedActivities) { $activity in
                    NavigationLink {
                        ActivityDetailView(activity: $activity)
                    } label: {
                        ActivityCard(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let emptyDays = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: emptyDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    func changeMonth(_ value: Int) {
        currentMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) ?? Date()
    }

    func loadActivities() {
        db.collection("activities")
            .order(by: "date")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("カレンダー読み込み失敗: \(error.localizedDescription)")
                    return
                }

                activities = snapshot?.documents.compactMap { document in
                    let data = document.data()

                    let attendanceArray = data["attendance"] as? [[String: String]] ?? []
                    let attendance = attendanceArray.compactMap { item -> Attendance? in
                        guard
                            let memberId = item["memberId"],
                            let statusRawValue = item["status"],
                            let status = AttendanceStatus(rawValue: statusRawValue)
                        else {
                            return nil
                        }

                        return Attendance(memberId: memberId, status: status)
                    }

                    return Activity(
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
                        paidMembers: data["paidMembers"] as? [String] ?? []
                    )
                } ?? []
            }
    }

    func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
}
