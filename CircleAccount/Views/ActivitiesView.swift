import SwiftUI
import FirebaseFirestore

struct ActivitiesView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false
    @FocusState private var isInputFocused: Bool

    @State private var activities: [Activity] = []

    @State private var title = ""
    @State private var date = Date()
    @State private var tempDate = Date()

    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(7200)

    @State private var place = ""
    @State private var fee = ""
    @State private var capacity = ""
    @State private var memo = ""

    @State private var isShowingDatePicker = false
    @State private var isShowingStartPicker = false
    @State private var isShowingEndPicker = false

    @State private var tempStartTime = Date()
    @State private var tempEndTime = Date()

    @State private var selectedActivity: Activity?
    @State private var activityToDelete: Activity?
    @State private var isShowingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if currentUserIsAdmin {
                        activityForm
                    }

                    activityList
                }
                .padding()
            }
            .navigationTitle("活動日")
            .onAppear {
                loadActivities()
            }
            .sheet(isPresented: $isShowingDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $isShowingStartPicker) {
                timePickerSheet(
                    title: "開始時間",
                    time: $tempStartTime,
                    onCancel: {
                        isShowingStartPicker = false
                    },
                    onDone: {
                        startTime = tempStartTime
                        isShowingStartPicker = false
                    }
                )
            }
            .sheet(isPresented: $isShowingEndPicker) {
                timePickerSheet(
                    title: "終了時間",
                    time: $tempEndTime,
                    onCancel: {
                        isShowingEndPicker = false
                    },
                    onDone: {
                        endTime = tempEndTime
                        isShowingEndPicker = false
                    }
                )
            }
            .sheet(item: $selectedActivity) { activity in
                EditActivityView(
                    activity: activity,
                    onSaved: {
                        selectedActivity = nil
                        loadActivities()
                    },
                    onCancel: {
                        selectedActivity = nil
                    }
                )
            }
            .alert("活動を削除しますか？", isPresented: $isShowingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}

                Button("削除", role: .destructive) {
                    if let activity = activityToDelete {
                        deleteActivity(activity)
                    }
                }
            } message: {
                if let activity = activityToDelete {
                    Text("「\(activity.title)」を削除します。この操作は元に戻せません。")
                }
            }
        }
    }

    var activityForm: some View {
        VStack(spacing: 14) {
            TextField("タイトル", text: $title)
                .textFieldStyle(.roundedBorder)

            Button {
                tempDate = date
                isShowingDatePicker = true
            } label: {
                HStack {
                    Text("日付")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(formatDateValue(date))
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.blue)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Text(formatJapaneseDate(date))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                tempStartTime = startTime
                isShowingStartPicker = true
            } label: {
                HStack {
                    Text("開始時間")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formatTime(startTime))
                        .font(.title3)
                        .bold()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                tempEndTime = endTime
                isShowingEndPicker = true
            } label: {
                HStack {
                    Text("終了時間")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formatTime(endTime))
                        .font(.title3)
                        .bold()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            TextField("場所", text: $place)
                .textFieldStyle(.roundedBorder)

            TextField("参加費", text: $fee)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)

            TextField("定員", text: $capacity)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)

            TextField("メモ", text: $memo)
                .textFieldStyle(.roundedBorder)

            Button("活動日を追加") {
                addActivity()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdd)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "活動日",
                    selection: $tempDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .padding()

                Spacer()
            }
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isShowingDatePicker = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        date = tempDate
                        isShowingDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    func timePickerSheet(
        title: String,
        time: Binding<Date>,
        onCancel: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        NavigationStack {
            VStack {
                DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("決定") {
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    var activityList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("活動一覧")
                .font(.title2)
                .bold()

            ForEach($activities) { $activity in
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink {
                        ActivityDetailView(activity: $activity)
                    } label: {
                        ActivityCard(activity: activity)
                    }
                    .buttonStyle(.plain)

                    HStack {
                        attendanceButton(activity: $activity, status: .attending)
                        attendanceButton(activity: $activity, status: .undecided)
                        attendanceButton(activity: $activity, status: .absent)
                    }

                    if currentUserIsAdmin {
                        HStack {
                            Button {
                                selectedActivity = activity
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }

                            Spacer()

                            Button(role: .destructive) {
                                activityToDelete = activity
                                isShowingDeleteAlert = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    func attendanceButton(activity: Binding<Activity>, status: AttendanceStatus) -> some View {
        Button {
            updateAttendance(activity: activity, status: status)
        } label: {
            Text(status.rawValue)
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(currentStatus(activity.wrappedValue) == status ? Color.blue.opacity(0.2) : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .disabled(currentUserId.isEmpty)
    }

    var canAdd: Bool {
        !title.isEmpty && !place.isEmpty && Int(fee) != nil && Int(capacity) != nil
    }

    func addActivity() {
        db.collection("activities").addDocument(data: [
            "title": title,
            "date": Timestamp(date: date),
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "place": place,
            "fee": Int(fee) ?? 0,
            "capacity": Int(capacity) ?? 0,
            "memo": memo,
            "createdBy": currentUserId,
            "participants": [],
            "waitingList": [],
            "attendance": [],
            "pointGrantedMembers": [],
            "paidMembers": [],
            "setupPointGrantedMembers": [],
            "pointGranted": false,
            "pointGrantedAt": NSNull(),
            "createdAt": Timestamp()
        ]) { error in
            if let error = error {
                print("保存失敗: \(error)")
                return
            }

            clearForm()
            loadActivities()
            isInputFocused = false
        }
    }

    func loadActivities() {
        db.collection("activities")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("読み込み失敗: \(error)")
                    return
                }

                activities = snapshot?.documents.compactMap { document in
                    let data = document.data()

                    let attendanceArray =
                        data["attendance"] as? [[String: Any]] ?? []
                    let attendance = attendanceArray.compactMap { item -> Attendance? in
                        guard
                            let memberId = item["memberId"] as? String,
                            let statusRawValue = item["status"] as? String,
                            let status = AttendanceStatus(rawValue: statusRawValue)
                        else {
                            return nil
                        }

                        let answeredAt =
                            (item["answeredAt"] as? Timestamp)?.dateValue() ?? Date()

                        let earlyAnswerPointGranted =
                            item["earlyAnswerPointGranted"] as? Bool ?? false

                        return Attendance(
                            memberId: memberId,
                            status: status,
                            answeredAt: answeredAt,
                            earlyAnswerPointGranted: earlyAnswerPointGranted
                        )
                    }
                    let usedTicketsArray = data["usedTickets"] as? [[String: Any]] ?? []

                    let usedTickets = usedTicketsArray.compactMap { item -> UsedTicket? in
                        guard
                            let memberId = item["memberId"] as? String,
                            let ticketType = item["ticketType"] as? String,
                            let usedAt = item["usedAt"] as? Timestamp
                        else {
                            return nil
                        }

                        return UsedTicket(
                            memberId: memberId,
                            ticketType: ticketType,
                            usedAt: usedAt.dateValue()
                        )
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
                        paidMembers: data["paidMembers"] as? [String] ?? [],
                        setupPointGrantedMembers:
                            data["setupPointGrantedMembers"] as? [String] ?? [],
                        pointGranted: data["pointGranted"] as? Bool ?? false,
                        pointGrantedAt: (data["pointGrantedAt"] as? Timestamp)?.dateValue(),usedTickets: usedTickets,
                    )
                } ?? []
            }
    }

    func updateAttendance(activity: Binding<Activity>, status: AttendanceStatus) {
        let activityId = activity.wrappedValue.id

        activity.wrappedValue.attendance.removeAll { $0.memberId == currentUserId }
        activity.wrappedValue.participants.removeAll { $0 == currentUserId }
        activity.wrappedValue.waitingList.removeAll { $0 == currentUserId }

        activity.wrappedValue.attendance.append(
            Attendance(
                memberId: currentUserId,
                status: status,
                answeredAt: Date()
            )
        )
        if status == .attending {
            if activity.wrappedValue.participants.count < activity.wrappedValue.capacity {
                activity.wrappedValue.participants.append(currentUserId)
            } else {
                activity.wrappedValue.waitingList.append(currentUserId)
            
                }
            }

        let attendanceData = activity.wrappedValue.attendance.map {
            [
                "memberId": $0.memberId,
                "status": $0.status.rawValue,
                "answeredAt": Timestamp(date: $0.answeredAt),
                "earlyAnswerPointGranted": $0.earlyAnswerPointGranted
            ]
        }

        db.collection("activities").document(activityId).updateData([
            "attendance": attendanceData,
            "participants": activity.wrappedValue.participants,
            "waitingList": activity.wrappedValue.waitingList
        ])
    }

    func currentStatus(_ activity: Activity) -> AttendanceStatus? {
        activity.attendance.first { $0.memberId == currentUserId }?.status
    }

    func deleteActivity(_ activity: Activity) {
        db.collection("activities").document(activity.id).delete { error in
            if let error = error {
                print("削除失敗: \(error)")
                return
            }

            activities.removeAll { $0.id == activity.id }
            activityToDelete = nil
        }
    }

    func clearForm() {
        title = ""
        place = ""
        fee = ""
        capacity = ""
        memo = ""
        isInputFocused = false
    }

    func formatDateValue(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    func formatJapaneseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            // タイトル
            HStack {
                Text(activity.title)
                    .font(.title3)
                    .bold()

                Spacer()

                statusBadge
            }

            Divider()

            // 日時
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)

                Text(formatDate(activity.date))
                    .fontWeight(.medium)
            }

            HStack(spacing: 14) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)

                Text("\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))")
                    .fontWeight(.medium)
            }

            HStack(spacing: 14) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)

                Text(activity.place)
            }

            Divider()

            HStack {

                statView(
                    icon: "person.fill.checkmark",
                    color: .green,
                    title: "参加",
                    value: "\(activity.attendingCount)"
                )

                Spacer()

                statView(
                    icon: "questionmark.circle.fill",
                    color: .orange,
                    title: "未定",
                    value: "\(activity.undecidedCount)"
                )

                Spacer()

                statView(
                    icon: "xmark.circle.fill",
                    color: .gray,
                    title: "欠席",
                    value: "\(activity.absentCount)"
                )

            }

            Divider()

            HStack {

                Label("\(activity.fee)円", systemImage: "yensign.circle.fill")
                    .foregroundStyle(.blue)

                Spacer()

                Label(
                    "\(activity.capacity - activity.participants.count)席",
                    systemImage: "chair.fill"
                )
                .foregroundStyle(activity.isFull ? .red : .green)
            }
            .font(.headline)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 10)
    }

    @ViewBuilder
    var statusBadge: some View {
        if activityEndDateTime < Date() {
            Text("終了")
                .font(.caption)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        } else if activity.isFull {
            Text("満員")
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red)
                .clipShape(Capsule())
        } else {
            Text("募集中")
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green)
                .clipShape(Capsule())
        }
    }

    var activityEndDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: activity.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: activity.endTime)

        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? activity.endTime
    }
    }

    func statView(
        icon: String,
        color: Color,
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 6) {

            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

        }

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

