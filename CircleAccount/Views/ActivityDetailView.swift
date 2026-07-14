import SwiftUI
import FirebaseFirestore

struct ActivityDetailView: View {
    @Binding var activity: Activity
    private let db = Firestore.firestore()
    @AppStorage("currentUserId") private var currentUserId = ""


    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false
    

    @State private var memberNames: [String: String] = [:]
    @State private var memberGenders: [String: Gender] = [:]
    @State private var memberLevels: [String: MemberLevel] = [:]
    @State private var isShowingQRCode = false
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var showUseTicketAlert = false
    @State private var selectedTicketTitle = ""
    @State private var selectedTicketField = ""
    @State private var selectedTicketIcon = ""
    @State private var ticketToCancel: UsedTicket?
    @State private var selectedSetupMemberIds: Set<String> = []
    @State private var setupPointGrantedMemberIds: Set<String> = []
    @State private var showSetupPointDoneAlert = false

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
    func hasUsedPaymentTicket() -> Bool {
        let paymentTicketTypes = [
            "参加費無料券",
            "参加費500円券",
            "参加費半額券"
        ]

        return activity.usedTickets.contains {
            $0.memberId == currentUserId &&
            paymentTicketTypes.contains($0.ticketType)
        }
    }
    var body: some View {
        let discount = discountAmount()
        let payment = max(activity.fee - discount, 0)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.title)
                    .font(.largeTitle)
                    .bold()

                Label(formatDate(activity.date), systemImage: "calendar")
                Label("\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))", systemImage: "clock")
                Label(activity.place, systemImage: "mappin.and.ellipse")
                Label("参加費 \(activity.fee)円", systemImage: "creditcard")
              
                VStack(alignment: .leading, spacing: 6) {

                    Text("💰本日のお支払い")
                        .font(.headline)

                    if discount > 0 {
                        Text("通常参加費 \(activity.fee)円")
                            .foregroundStyle(.secondary)

                        Text("チケット割引 -\(discount)円")
                            .foregroundStyle(.green)
                    }

                    Text("👉 お支払い金額 \(payment)円")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 8)
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
                if freeTickets > 0 &&
                    !hasUsedPaymentTicket() {

                    Button("🎁 参加費無料券を使用") {
                        selectedTicketTitle = "参加費無料券"
                        selectedTicketField = "freeTickets"
                        selectedTicketIcon = "🎁"
                        showUseTicketAlert = true
                    }
                    .buttonStyle(.borderedProminent)

                } else if hasUsedTicket("参加費無料券") {

                    Button("✅ 参加費無料券 使用済み") { }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                }
                if discountTickets > 0 &&
                    !hasUsedPaymentTicket() {

                    Button("💰 参加費500円券を使用") {
                        selectedTicketTitle = "参加費500円券"
                        selectedTicketField = "discountTickets"
                        selectedTicketIcon = "💰"
                        showUseTicketAlert = true
                    }
                    .buttonStyle(.borderedProminent)

                } else if hasUsedTicket("参加費500円券") {

                    Button("✅ 参加費500円券 使用済み") { }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                }
                if halfPriceTickets > 0 &&
                    !hasUsedPaymentTicket() {

                    Button("🏸 参加費半額券を使用") {
                        selectedTicketTitle = "参加費半額券"
                        selectedTicketField = "halfPriceTickets"
                        selectedTicketIcon = "🏸"
                        showUseTicketAlert = true
                    }
                    .buttonStyle(.borderedProminent)

                } else if hasUsedTicket("参加費半額券") {

                    Button("✅ 参加費半額券 使用済み") { }
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
                            if currentUserIsAdmin {
                                Button {
                                    if selectedSetupMemberIds.contains(memberId) {
                                        selectedSetupMemberIds.remove(memberId)
                                    } else {
                                        selectedSetupMemberIds.insert(memberId)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(
                                            systemName:
                                                setupPointGrantedMemberIds.contains(memberId)
                                                ? "checkmark.circle.fill"
                                                : (
                                                    selectedSetupMemberIds.contains(memberId)
                                                    ? "checkmark.square.fill"
                                                    : "square"
                                                )
                                        )

                                        Text(
                                            setupPointGrantedMemberIds.contains(memberId)
                                            ? "給付済み"
                                            : "設営"
                                        )
                                            .font(.caption)
                                            .bold()
                                    }
                                    .foregroundStyle(
                                        setupPointGrantedMemberIds.contains(memberId)
                                            ? .green
                                            : .blue
                                    )
                                }
                                .disabled(setupPointGrantedMemberIds.contains(memberId))
                            }
                            Text(activity.paidMembers.contains(memberId) ? "支払い済み" : "未払い")
                                .font(.caption)
                                .foregroundStyle(activity.paidMembers.contains(memberId) ? .green : .red)

                            if currentUserIsAdmin {
                                Button {
                                    togglePaid(memberId)
                                } label: {
                                    Text(activity.paidMembers.contains(memberId) ? "支払い取消" : "支払い確認")
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            activity.paidMembers.contains(memberId)
                                            ? Color.orange
                                            : Color.green
                                        )
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                if currentUserIsAdmin {
                    Button {
                        grantSetupPoints()
                    } label: {
                        Label(
                            selectedSetupMemberIds.isEmpty
                                ? "設営した人を選択してください"
                                : "選択した\(selectedSetupMemberIds.count)人に設営ポイント付与",
                            systemImage: "hammer.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(selectedSetupMemberIds.isEmpty)
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
            setupPointGrantedMemberIds = Set(activity.setupPointGrantedMembers)
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
            icon: selectedTicketIcon,
            activityId: activity.id
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
                    "usedAt": Timestamp(date: usedAt),
                    "activityId": activity.id
                ]])
            ])
    }
    func discountAmount() -> Int {

        if hasUsedTicket("参加費無料券") {
            return activity.fee
        }

        if hasUsedTicket("参加費半額券") {
            return activity.fee / 2
        }

        if hasUsedTicket("参加費500円券") {
            return max(activity.fee - 500, 0)
        }

        return 0
    }
    func loadMyTickets() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members").document(currentUserId).getDocument { snapshot, _ in
            let data = snapshot?.data()

            challengeTickets = data?["challengeTickets"] as? Int ?? 0
            priorityTickets = data?["priorityTickets"] as? Int ?? 0
            discountTickets = data?["discountTickets"] as? Int ?? 0
            halfPriceTickets = data?["halfPriceTickets"] as? Int ?? 0
            freeTickets = data?["freeTickets"] as? Int ?? 0
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
        for memberId in absentIds {
            PointService.shared.resetAttendanceStreak(
                memberId: memberId
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
        let ticketField: String

        switch ticket.ticketType {
        case "対戦指名券":
            ticketField = "challengeTickets"

        case "優先ゲーム券":
            ticketField = "priorityTickets"

        case "参加費無料券":
            ticketField = "freeTickets"

        case "参加費500円券":
            ticketField = "discountTickets"

        case "参加費半額券":
            ticketField = "halfPriceTickets"

        default:
            return
        }

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
    func grantSetupPoints() {
        guard !selectedSetupMemberIds.isEmpty else { return }

        let memberIds = Array(selectedSetupMemberIds)

        for memberId in memberIds {
            PointService.shared.addPoint(
                memberId: memberId,
                point: 3,
                title: "設営参加",
                icon: "🛠"
            )
            db.collection("members")
                .document(memberId)
                .updateData([
                    "setupCount": FieldValue.increment(Int64(1))
                ])
        }

        setupPointGrantedMemberIds.formUnion(memberIds)
        activity.setupPointGrantedMembers = Array(setupPointGrantedMemberIds)

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "setupPointGrantedMembers": Array(setupPointGrantedMemberIds)
            ])

        selectedSetupMemberIds.removeAll()
        showSetupPointDoneAlert = true
    }
}
