import SwiftUI
import FirebaseFirestore

struct ActivityDetailView: View {
    @Binding var activity: Activity
    private let db = Firestore.firestore()

    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false
    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var memberNames: [String: String] = [:]
    @State private var memberGenders: [String: Gender] = [:]
    @State private var memberLevels: [String: MemberLevel] = [:]
    @State private var isShowingQRCode = false
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var showUseTicketAlert = false
    @State private var selectedTicketTitle = ""
    @State private var selectedTicketField = ""
    @State private var selectedTicketIcon = ""
    @State private var ticketToCancel: UsedTicket?

    var attendingIds: [String] {
        activity.attendance.filter { $0.status == .attending }.map { $0.memberId }
    }

    var undecidedIds: [String] {
        activity.attendance.filter { $0.status == .undecided }.map { $0.memberId }
    }

    var absentIds: [String] {
        activity.attendance.filter { $0.status == .absent }.map { $0.memberId }
    }

    var paidCount: Int { activity.paidMembers.count }
    var unpaidCount: Int { max(attendingIds.count - activity.paidMembers.count, 0) }
    var collectedAmount: Int { activity.fee * paidCount }
    var uncollectedAmount: Int { activity.fee * unpaidCount }

    func hasUsedTicket(_ ticketType: String) -> Bool {
        activity.usedTickets.contains {
            $0.memberId == currentUserId &&
            $0.ticketType == ticketType
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.title)
                    .font(.largeTitle)
                    .bold()

                Label(formatDate(activity.date), systemImage: "calendar")
                Label("\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))", systemImage: "clock")
                Label(activity.place, systemImage: "mappin.and.ellipse")
                Label("参加費 \(activity.fee)円", systemImage: "creditcard")
                Label("定員 \(activity.capacity)人", systemImage: "person.3")

                if challengeTickets > 0 && !hasUsedTicket("対戦指名券") {
                    Button("🏸 対戦指名券を使用") {
                        selectedTicketTitle = "対戦指名券"
                        selectedTicketField = "challengeTickets"
                        selectedTicketIcon = "🏸"
                        showUseTicketAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                } else if hasUsedTicket("対戦指名券") {
                    Button("✅ 対戦指名券 使用済み") { }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                }

                if priorityTickets > 0 && !hasUsedTicket("優先ゲーム券") {
                    Button("🚀 優先ゲーム券を使用") {
                        selectedTicketTitle = "優先ゲーム券"
                        selectedTicketField = "priorityTickets"
                        selectedTicketIcon = "🚀"
                        showUseTicketAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                } else if hasUsedTicket("優先ゲーム券") {
                    Button("✅ 優先ゲーム券 使用済み") { }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                }

                if currentUserIsAdmin {
                    Button {
                        isShowingQRCode = true
                    } label: {
                        Label("QRコードを表示", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if activity.pointGranted {
                        VStack(spacing: 6) {
                            Label("ポイント付与済み", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.headline)

                            if let date = activity.pointGrantedAt {
                                Text("付与日時 \(formatDateTime(date))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Button {
                            grantPoints()
                        } label: {
                            Label("参加者へポイント一括付与", systemImage: "star.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(attendingIds.isEmpty)
                    }

                    usedTicketSection()
                    Divider()
                }

                Divider()

                Text("出欠状況")
                    .font(.title2)
                    .bold()

                HStack {
                    Text("参加 \(attendingIds.count)人")
                    Spacer()
                    Text("未定 \(undecidedIds.count)人")
                    Spacer()
                    Text("不参加 \(absentIds.count)人")
                }
                .font(.headline)

                attendanceNameSection(title: "参加", memberIds: attendingIds)
                attendanceNameSection(title: "未定", memberIds: undecidedIds)
                attendanceNameSection(title: "不参加", memberIds: absentIds)

                Divider()

                Text("会計")
                    .font(.title2)
                    .bold()

                HStack {
                    Text("回収済み")
                    Spacer()
                    Text("\(collectedAmount)円").bold()
                }

                HStack {
                    Text("未回収")
                    Spacer()
                    Text("\(uncollectedAmount)円")
                        .foregroundStyle(.red)
                        .bold()
                }

                Text("支払済 \(paidCount)人 / 未払い \(unpaidCount)人")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Text("参加者・支払い状況")
                    .font(.title2)
                    .bold()

                if attendingIds.isEmpty {
                    Text("まだ参加者はいません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(attendingIds, id: \.self) { memberId in
                        HStack {
                            memberNameRow(memberId)

                            Spacer()

                            Text(activity.paidMembers.contains(memberId) ? "支払い済み" : "未払い")
                                .font(.caption)
                                .foregroundStyle(activity.paidMembers.contains(memberId) ? .green : .red)

                            if currentUserIsAdmin {
                                Button {
                                    togglePaid(memberId)
                                } label: {
                                    Image(systemName: activity.paidMembers.contains(memberId) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Divider()

                Text("キャンセル待ち")
                    .font(.title2)
                    .bold()

                if activity.waitingList.isEmpty {
                    Text("キャンセル待ちはいません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activity.waitingList, id: \.self) { memberId in
                        memberNameRow(memberId)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("活動詳細")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMemberNames()
            loadMyTickets()
        }
        .sheet(isPresented: $isShowingQRCode) {
            QRCodeView(activity: activity)
        }
        .alert("チケットを使用しますか？", isPresented: $showUseTicketAlert) {
            Button("キャンセル", role: .cancel) { }

            Button("使用する", role: .destructive) {
                useTicket()
            }
        } message: {
            Text("使用すると元には戻せません。")
        }
        .alert(item: $ticketToCancel) { ticket in
            Alert(
                title: Text("使用済みチケットを取り消しますか？"),
                message: Text("\(memberNames[ticket.memberId] ?? "メンバー") の「\(ticket.ticketType)」を取り消します。チケットも1枚戻します。"),
                primaryButton: .destructive(Text("取り消す")) {
                    cancelUsedTicket(ticket)
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
    }

    func attendanceNameSection(title: String, memberIds: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            if memberIds.isEmpty {
                Text("該当者なし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(memberIds, id: \.self) { memberId in
                    memberNameRow(memberId)
                        .font(.caption)
                }
            }
        }
    }

    func memberNameRow(_ memberId: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(memberGenders[memberId] == .female ? Color.pink : Color.blue)
                .frame(width: 10, height: 10)

            Text(memberNames[memberId] ?? "読み込み中...")
                .fontWeight(.medium)

            if currentUserIsAdmin {
                Text(memberLevels[memberId]?.rawValue ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    func useTicket() {
        let usedAt = Date()

        PointService.shared.useTicket(
            memberId: currentUserId,
            ticketField: selectedTicketField,
            title: selectedTicketTitle,
            icon: selectedTicketIcon
        )

        let newTicket = UsedTicket(
            memberId: currentUserId,
            ticketType: selectedTicketTitle,
            usedAt: usedAt
        )

        activity.usedTickets.append(newTicket)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loadMyTickets()
        }

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "usedTickets": FieldValue.arrayUnion([[
                    "memberId": currentUserId,
                    "ticketType": selectedTicketTitle,
                    "usedAt": Timestamp(date: usedAt)
                ]])
            ])
    }

    func loadMyTickets() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members").document(currentUserId).getDocument { snapshot, _ in
            let data = snapshot?.data()

            challengeTickets = data?["challengeTickets"] as? Int ?? 0
            priorityTickets = data?["priorityTickets"] as? Int ?? 0
        }
    }

    func fetchMemberNames() {
        memberNames = [:]
        memberGenders = [:]
        memberLevels = [:]

        let ids = Array(Set(attendingIds + undecidedIds + absentIds + activity.waitingList + activity.usedTickets.map { $0.memberId }))

        for memberId in ids {
            db.collection("members").document(memberId).getDocument { snapshot, error in
                if let error = error {
                    print("参加者取得エラー: \(error.localizedDescription)")
                    return
                }

                let data = snapshot?.data()
                let name = data?["name"] as? String ?? "ID不一致: \(memberId)"
                let gender = Gender(rawValue: data?["gender"] as? String ?? "男性") ?? .male
                let level = MemberLevel(rawValue: data?["level"] as? String ?? "初心者") ?? .beginner

                DispatchQueue.main.async {
                    memberNames[memberId] = name
                    memberGenders[memberId] = gender
                    memberLevels[memberId] = level
                }
            }
        }
    }

    func grantPoints() {
        guard !activity.pointGranted else { return }

        for memberId in attendingIds {
            PointService.shared.addPoint(
                memberId: memberId,
                point: 5,
                title: "練習参加",
                icon: "🏸",
                addAttendanceCount: true
            )
        }

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "pointGranted": true,
                "pointGrantedAt": Timestamp()
            ])

        activity.pointGranted = true
        activity.pointGrantedAt = Date()
    }

    func usedTicketSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🎟 使用済みチケット")
                .font(.title2)
                .bold()

            if activity.usedTickets.isEmpty {
                Text("まだ使用済みチケットはありません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activity.usedTickets) { ticket in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(ticket.ticketType)
                                .font(.headline)

                            Spacer()

                            Button("取消") {
                                ticketToCancel = ticket
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }

                        Text(memberNames[ticket.memberId] ?? "読み込み中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    func cancelUsedTicket(_ ticket: UsedTicket) {
        let ticketField = ticket.ticketType == "対戦指名券" ? "challengeTickets" : "priorityTickets"

        db.collection("activities").document(activity.id).getDocument { snapshot, error in
            if let error = error {
                print("使用済みチケット取得エラー: \(error.localizedDescription)")
                return
            }

            guard var data = snapshot?.data(),
                  var usedTicketsArray = data["usedTickets"] as? [[String: Any]] else {
                return
            }

            if let index = usedTicketsArray.firstIndex(where: { item in
                let memberId = item["memberId"] as? String
                let ticketType = item["ticketType"] as? String
                return memberId == ticket.memberId && ticketType == ticket.ticketType
            }) {
                usedTicketsArray.remove(at: index)
            }

            db.collection("activities").document(activity.id).updateData([
                "usedTickets": usedTicketsArray
            ])

            db.collection("members").document(ticket.memberId).updateData([
                ticketField: FieldValue.increment(Int64(1))
            ])

            if let localIndex = activity.usedTickets.firstIndex(where: {
                $0.memberId == ticket.memberId &&
                $0.ticketType == ticket.ticketType &&
                $0.usedAt == ticket.usedAt
            }) {
                activity.usedTickets.remove(at: localIndex)
            } else if let localIndex = activity.usedTickets.firstIndex(where: {
                $0.memberId == ticket.memberId &&
                $0.ticketType == ticket.ticketType
            }) {
                activity.usedTickets.remove(at: localIndex)
            }

            if ticket.memberId == currentUserId {
                loadMyTickets()
            }
        }
    }

    func togglePaid(_ memberId: String) {
        let activityId = activity.id

        if activity.paidMembers.contains(memberId) {
            activity.paidMembers.removeAll { $0 == memberId }

            db.collection("activities").document(activityId).updateData([
                "paidMembers": FieldValue.arrayRemove([memberId])
            ])
        } else {
            activity.paidMembers.append(memberId)

            db.collection("activities").document(activityId).updateData([
                "paidMembers": FieldValue.arrayUnion([memberId])
            ])
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

    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
