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

            var participants = data["participants"] as? [String] ?? []
            var waitingList = data["waitingList"] as? [String] ?? []
            var attendanceArray = data["attendance"] as? [[String: String]] ?? []
            let capacity = data["capacity"] as? Int ?? 0
            let alreadyCheckedIn = attendanceArray.contains { item in
                item["memberId"] == currentUserId &&
                item["status"] == AttendanceStatus.attending.rawValue
            }

            if alreadyCheckedIn {
                message = "この活動はすでに受付済みです"
                isSuccess = true
                return
            }
            participants.removeAll { $0 == currentUserId }
            waitingList.removeAll { $0 == currentUserId }
            attendanceArray.removeAll { $0["memberId"] == currentUserId }

            attendanceArray.append([
                "memberId": currentUserId,
                "status": AttendanceStatus.attending.rawValue
            ])

            if participants.count < capacity {
                participants.append(currentUserId)
                message = "受付中..."
            } else {
                waitingList.append(currentUserId)
                message = "定員いっぱいのためキャンセル待ちに登録します"
            }

            ref.updateData([
                "participants": participants,
                "waitingList": waitingList,
                "attendance": attendanceArray
            ]) { error in
                if let error = error {
                    message = "受付失敗: \(error.localizedDescription)"
                    isSuccess = false
                } else {
                    PointService.shared.addPoint(
                        memberId: currentUserId,
                        point: 5,
                        title: "練習参加",
                        icon: "🏸",
                        addAttendanceCount: true
                    )

                    if participants.contains(currentUserId) {
                        message = "受付完了！🏸\n+5pt獲得しました！"
                    } else {
                        message = "キャンセル待ち登録完了！\n+5pt獲得しました！"
                    }

                    isSuccess = true
                }
            }
        }
    }
}

#Preview {
    QRCheckInView()
}
