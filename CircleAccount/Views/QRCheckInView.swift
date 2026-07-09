import SwiftUI
import FirebaseFirestore

struct QRCheckInView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var isShowingScanner = false
    @State private var message = "QRコードを読み取って受付できます"
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("SiRiUS")
                    .font(.system(size: 42, weight: .black, design: .serif))

                Text("QR受付")
                    .font(.title2)
                    .bold()

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSuccess ? .green : .secondary)

                Button {
                    isShowingScanner = true
                } label: {
                    Label("QRコードを読み取る", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentUserId.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("QR受付")
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView(
                    onCodeScanned: { code in
                        isShowingScanner = false
                        handleQRCode(code)
                    },
                    onCancel: {
                        isShowingScanner = false
                    }
                )
            }
        }
    }

    func handleQRCode(_ code: String) {
        let prefix = "SIRIUS_ACTIVITY:"

        guard code.hasPrefix(prefix) else {
            message = "SiRiUSの活動QRではありません"
            isSuccess = false
            return
        }

        let activityId = code.replacingOccurrences(of: prefix, with: "")
        joinActivity(activityId: activityId)
    }

    func joinActivity(activityId: String) {
        guard !currentUserId.isEmpty else {
            message = "ログイン情報がありません"
            isSuccess = false
            return
        }

        let ref = db.collection("activities").document(activityId)

        ref.getDocument { snapshot, error in
            if let error = error {
                message = "活動取得失敗: \(error.localizedDescription)"
                isSuccess = false
                return
            }

            guard let data = snapshot?.data() else {
                message = "活動が見つかりません"
                isSuccess = false
                return
            }

            let now = Date()

            var participants = data["participants"] as? [String] ?? []
            var waitingList = data["waitingList"] as? [String] ?? []
            var checkedInMembers = data["checkedInMembers"] as? [String] ?? []
            var attendanceArray = data["attendance"] as? [[String: Any]] ?? []

            let capacity = data["capacity"] as? Int ?? 0
            let activityDate = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let fee = data["fee"] as? Int ?? 0
            let usedTickets = data["usedTickets"] as? [[String: Any]] ?? []

            let discount = discountAmount(fee: fee, usedTickets: usedTickets)
            let payment = max(fee - discount, 0)

            if checkedInMembers.contains(currentUserId) {
                message = "この活動はすでに受付済みです"
                isSuccess = true
                return
            }

            let previousAttendance = attendanceArray.first {
                ($0["memberId"] as? String) == currentUserId
            }

            let previousAnsweredAt = (previousAttendance?["answeredAt"] as? Timestamp)?.dateValue()
            let previousStatus = previousAttendance?["status"] as? String

            let isEarlyAnswer =
                previousStatus == AttendanceStatus.attending.rawValue &&
                (previousAnsweredAt.map { $0 <= earlyAnswerDeadline(for: activityDate) } ?? false)

            let isEarlyArrival = now <= earlyArrivalDeadline(for: activityDate)

            participants.removeAll { $0 == currentUserId }
            waitingList.removeAll { $0 == currentUserId }
            attendanceArray.removeAll {
                ($0["memberId"] as? String) == currentUserId
            }

            attendanceArray.append([
                "memberId": currentUserId,
                "status": AttendanceStatus.attending.rawValue,
                "answeredAt": Timestamp(date: previousAnsweredAt ?? now),
                "checkedInAt": Timestamp(date: now),
                "earlyAnswerPointGranted": isEarlyAnswer
            ])

            checkedInMembers.append(currentUserId)

            let isParticipant: Bool

            if participants.count < capacity {
                participants.append(currentUserId)
                isParticipant = true
            } else {
                waitingList.append(currentUserId)
                isParticipant = false
            }

            ref.updateData([
                "participants": participants,
                "waitingList": waitingList,
                "attendance": attendanceArray,
                "checkedInMembers": checkedInMembers
            ]) { error in
                if let error = error {
                    message = "受付失敗: \(error.localizedDescription)"
                    isSuccess = false
                    return
                }

                var totalPoint = 0
                var pointMessages: [String] = []

                PointService.shared.addPoint(
                    memberId: currentUserId,
                    point: 5,
                    title: "練習参加",
                    icon: "🏸",
                    addAttendanceCount: true
                )
                totalPoint += 5
                pointMessages.append("🏸 練習参加 +5pt")

                if isEarlyAnswer {
                    PointService.shared.addPoint(
                        memberId: currentUserId,
                        point: 2,
                        title: "前日18時まで参加回答",
                        icon: "⏰"
                    )
                    totalPoint += 2
                    pointMessages.append("⏰ 早期回答 +2pt")
                }

                if isEarlyArrival {
                    PointService.shared.addPoint(
                        memberId: currentUserId,
                        point: 5,
                        title: "設営参加（18:30まで受付）",
                        icon: "🛠"
                    )
                    totalPoint += 5
                    pointMessages.append("🛠 設営参加 +5pt")
                }

                markTicketUsagesChecked(activityId: activityId)

                let paymentMessage = """
                
                💰本日のお支払い
                通常参加費 \(fee)円
                チケット割引 -\(discount)円
                👉 お支払い金額 \(payment)円
                
                PayPayまたは現金でお支払いください
                """

                if isParticipant {
                    message = "受付完了！\n\n" +
                        paymentMessage +
                        "\n\n" +
                        pointMessages.joined(separator: "\n") +
                        "\n\n合計 +\(totalPoint)pt"
                } else {
                    message = "キャンセル待ち登録完了！\n\n" +
                        paymentMessage +
                        "\n\n" +
                        pointMessages.joined(separator: "\n") +
                        "\n\n合計 +\(totalPoint)pt"
                }

                isSuccess = true
            }
        }
    }

    func discountAmount(fee: Int, usedTickets: [[String: Any]]) -> Int {
        let myTickets = usedTickets.filter {
            ($0["memberId"] as? String) == currentUserId
        }

        if myTickets.contains(where: { ($0["ticketType"] as? String) == "参加費無料券" }) {
            return fee
        }

        if myTickets.contains(where: { ($0["ticketType"] as? String) == "参加費半額券" }) {
            return fee / 2
        }

        if myTickets.contains(where: { ($0["ticketType"] as? String) == "参加費500円券" }) {
            return max(fee - 500, 0)
        }

        return 0
    }

    func markTicketUsagesChecked(activityId: String) {
        db.collection("ticketUsages")
            .whereField("activityId", isEqualTo: activityId)
            .whereField("memberId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "未確認")
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach { document in
                    document.reference.updateData([
                        "status": "確認済み"
                    ])
                }
            }
    }

    func earlyAnswerDeadline(for activityDate: Date) -> Date {
        let calendar = Calendar.current
        let activityDay = calendar.startOfDay(for: activityDate)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: activityDay) ?? activityDay

        return calendar.date(
            bySettingHour: 18,
            minute: 0,
            second: 0,
            of: previousDay
        ) ?? previousDay
    }

    func earlyArrivalDeadline(for activityDate: Date) -> Date {
        let calendar = Calendar.current
        let activityDay = calendar.startOfDay(for: activityDate)

        return calendar.date(
            bySettingHour: 18,
            minute: 30,
            second: 0,
            of: activityDay
        ) ?? activityDay
    }
}

#Preview {
    QRCheckInView()
}
