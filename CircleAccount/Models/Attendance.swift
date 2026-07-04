import Foundation

struct Attendance: Identifiable, Codable {
    var id: String = UUID().uuidString
    var memberId: String
    var status: AttendanceStatus
}

enum AttendanceStatus: String, Codable, CaseIterable {
    case attending = "参加"
    case undecided = "未定"
    case absent = "不参加"
}
