import Foundation

struct Activity: Identifiable, Codable {
    var id: String = ""

    var title: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var place: String

    var fee: Int
    var capacity: Int
    var memo: String

    var createdBy: String

    // 参加者
    var participants: [String]

    // キャンセル待ち
    var waitingList: [String]

    // 出欠
    var attendance: [Attendance]

    // 支払い済み
    var paidMembers: [String] = []

    // ポイント一括付与済みか
    var pointGranted: Bool = false

    // ポイント付与日時
    var pointGrantedAt: Date? = nil
    var usedTickets: [UsedTicket] = []
    var createdAt = Date()

    var participantCount: Int {
        participants.count
    }

    var attendingCount: Int {
        attendance.filter { $0.status == .attending }.count
    }

    var undecidedCount: Int {
        attendance.filter { $0.status == .undecided }.count
    }

    var absentCount: Int {
        attendance.filter { $0.status == .absent }.count
    }

    var isFull: Bool {
        participantCount >= capacity
    }
}
struct UsedTicket: Codable, Identifiable {

    var id = UUID().uuidString

    var memberId: String
    var ticketType: String
    var usedAt: Date
}
