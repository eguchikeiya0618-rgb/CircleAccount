import Foundation
import FirebaseFirestore

struct PointHistory: Identifiable, Codable {
    var id: String = UUID().uuidString

    /// ポイント内容
    var title: String

    /// 加算・減算ポイント
    var point: Int

    /// 日付
    var date: Date

    /// アイコン
    var icon: String

    init(
        id: String = UUID().uuidString,
        title: String,
        point: Int,
        date: Date = Date(),
        icon: String
    ) {
        self.id = id
        self.title = title
        self.point = point
        self.date = date
        self.icon = icon
    }
}
