import SwiftUI
import FirebaseFirestore

struct CalendarView: View {
    private let db = Firestore.firestore()

    @State private var currentMonth = Date()
    @State private var activities: [Activity] = []
    @State private var selectedDate = Date()
    @State private var isLoading = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    private var selectedActivities: [Binding<Activity>] {
        activities.indices.compactMap { index in
            if Calendar.current.isDate(
                activities[index].date,
                inSameDayAs: selectedDate
            ) {
                return $activities[index]
            }

            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground

                ScrollView {
                    VStack(spacing: 18) {
                        premiumHeader
                        calendarCard
                        selectedActivitySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("CALENDAR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                selectedDate = Date()
                currentMonth = Date()
                loadActivities()
            }
        }
    }

    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(
                        red: 0.025,
                        green: 0.055,
                        blue: 0.16
                    ),
                    Color(
                        red: 0.10,
                        green: 0.04,
                        blue: 0.22
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: 170, y: -300)

            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 250, height: 250)
                .blur(radius: 34)
                .offset(x: -170, y: 330)
        }
    }

    private var premiumHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.10))
                .frame(width: 58, height: 58)

                Image(systemName: "calendar")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("SiRiUS SCHEDULE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2.0)
                    .foregroundStyle(.white.opacity(0.52))

                Text("活動カレンダー")
                    .font(
                        .system(
                            size: 27,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)

                Text("活動日をタップして詳細を確認")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 18) {
            monthHeader
            weekHeader
            calendarGrid
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        Color.cyan.opacity(0.24),
                        Color.purple.opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
        .shadow(
            color: Color.cyan.opacity(0.10),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    private var monthHeader: some View {
        HStack {
            monthButton(systemName: "chevron.left") {
                changeMonth(-1)
            }

            Spacer()

            VStack(spacing: 3) {
                Text(monthTitle)
                    .font(
                        .system(
                            size: 24,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)

                Text("MONTHLY SCHEDULE")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.6)
                    .foregroundStyle(.cyan.opacity(0.72))
            }

            Spacer()

            monthButton(systemName: "chevron.right") {
                changeMonth(1)
            }
        }
    }

    private func monthButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.09))
                    .frame(width: 42, height: 42)

                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var weekHeader: some View {
        HStack(spacing: 8) {
            ForEach(
                Array(["日", "月", "火", "水", "木", "金", "土"].enumerated()),
                id: \.offset
            ) { index, day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(
                        index == 0
                            ? Color.red.opacity(0.92)
                            : index == 6
                                ? Color.cyan.opacity(0.92)
                                : Color.white.opacity(0.52)
                    )
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 52)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let hasActivity = activities.contains {
            Calendar.current.isDate(
                $0.date,
                inSameDayAs: date
            )
        }

        let isSelected = Calendar.current.isDate(
            date,
            inSameDayAs: selectedDate
        )

        let isToday = Calendar.current.isDateInToday(date)
        let weekday = Calendar.current.component(.weekday, from: date)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        isSelected
                            ? Color.black
                            : weekday == 1
                                ? Color.red.opacity(0.92)
                                : weekday == 7
                                    ? Color.cyan.opacity(0.92)
                                    : Color.white
                    )

                Circle()
                    .fill(
                        hasActivity
                            ? isSelected
                                ? Color.black
                                : Color.cyan
                            : Color.clear
                    )
                    .frame(width: 6, height: 6)
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? LinearGradient(
                            colors: [.white, .cyan.opacity(0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(isToday ? 0.14 : 0.055),
                                Color.white.opacity(0.025)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    isToday && !isSelected
                        ? Color.cyan.opacity(0.62)
                        : Color.white.opacity(isSelected ? 0.34 : 0.06),
                    lineWidth: isToday && !isSelected ? 1.4 : 1
                )
            }
            .shadow(
                color: isSelected
                    ? Color.cyan.opacity(0.36)
                    : Color.clear,
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SELECTED DATE")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.cyan.opacity(0.72))

                    Text(formatSelectedDate(selectedDate))
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(selectedActivities.count)件")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }

            if isLoading {
                loadingCard
            } else if selectedActivities.isEmpty {
                emptyActivityCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(selectedActivities) { $activity in
                        NavigationLink {
                            ActivityDetailView(activity: $activity)
                        } label: {
                            ActivityCard(activity: activity)
                                .padding(2)
                                .background(.ultraThinMaterial)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 22,
                                        style: .continuous
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 22,
                                        style: .continuous
                                    )
                                    .stroke(
                                        Color.white.opacity(0.10),
                                        lineWidth: 1
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var loadingCard: some View {
        SiriusLoadingStateView("活動を読み込み中")
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }

    private var emptyActivityCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 62, height: 62)

                Text("🏸")
                    .font(.system(size: 30))
            }

            Text("活動予定はありません")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("別の日付を選択してください")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.09), lineWidth: 1)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents(
                    [.year, .month],
                    from: currentMonth
                )
            ),
            let range = calendar.range(
                of: .day,
                in: .month,
                for: startOfMonth
            )
        else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: startOfMonth
        )

        let emptyDays = max(firstWeekday - 1, 0)
        var days: [Date?] = Array(repeating: nil, count: emptyDays)

        for day in range {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: startOfMonth
            ) {
                days.append(date)
            }
        }

        return days
    }

    private func changeMonth(_ value: Int) {
        guard
            let newMonth = Calendar.current.date(
                byAdding: .month,
                value: value,
                to: currentMonth
            )
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.24)) {
            currentMonth = newMonth
            selectedDate = newMonth
        }
    }

    private func loadActivities() {
        isLoading = true

        db.collection("activities")
            .order(by: "date")
            .getDocuments { snapshot, error in
                if let error {
                    print("カレンダー読み込み失敗: \(error.localizedDescription)")

                    DispatchQueue.main.async {
                        activities = []
                        isLoading = false
                    }
                    return
                }

                let loadedActivities: [Activity] =
                    snapshot?.documents.compactMap { document in
                        let data = document.data()

                        let attendanceArray =
                            data["attendance"] as? [[String: String]]
                            ?? []

                        let attendance =
                            attendanceArray.compactMap { item -> Attendance? in
                                guard
                                    let memberId = item["memberId"],
                                    let statusRawValue = item["status"],
                                    let status = AttendanceStatus(
                                        rawValue: statusRawValue
                                    )
                                else {
                                    return nil
                                }

                                return Attendance(
                                    memberId: memberId,
                                    status: status
                                )
                            }

                        return Activity(
                            id: document.documentID,
                            title: data["title"] as? String ?? "",
                            date:
                                (data["date"] as? Timestamp)?
                                .dateValue()
                                ?? Date(),
                            startTime:
                                (data["startTime"] as? Timestamp)?
                                .dateValue()
                                ?? Date(),
                            endTime:
                                (data["endTime"] as? Timestamp)?
                                .dateValue()
                                ?? Date(),
                            place: data["place"] as? String ?? "",
                            fee: data["fee"] as? Int ?? 0,
                            capacity: data["capacity"] as? Int ?? 0,
                            memo: data["memo"] as? String ?? "",
                            createdBy: data["createdBy"] as? String ?? "",
                            participants:
                                data["participants"] as? [String]
                                ?? [],
                            waitingList:
                                data["waitingList"] as? [String]
                                ?? [],
                            attendance: attendance,
                            paidMembers:
                                data["paidMembers"] as? [String]
                                ?? []
                        )
                    } ?? []

                DispatchQueue.main.async {
                    activities = loadedActivities
                    isLoading = false
                }
            }
    }

    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
}
