import Foundation

struct Member: Identifiable, Codable {
    var id: String = ""

    var name: String

    var role: MemberRole
    var isAdmin: Bool
    var isActive: Bool

    // 性別
    var gender: Gender = .male

    // レベル（運営のみ表示）
    var level: MemberLevel = .beginner

    // SiRiUS POINT
    var totalPoint: Int = 0
    var availablePoint: Int = 0

    // チケット
    var cleanupTickets: Int = 0
    var discountTickets: Int = 0
    var halfPriceTickets: Int = 0      // ←追加
    var freeTickets: Int = 0

    // ランクアップ報酬
    var challengeTickets: Int = 0      // ←追加
    var priorityTickets: Int = 0       // ←追加

    // 実績
    var attendanceCount: Int = 0
    var setupCount: Int = 0
    var streakCount: Int = 0
    
    
    // 月間実績
    var monthlyChampionCount: Int = 0      // 月間1位
    var monthlySecondCount: Int = 0        // 月間2位
    var monthlyThirdCount: Int = 0         // 月間3位
    var mvpCount: Int = 0                  // MVP

    // 今月ポイント
    var monthlyPoint: Int = 0
    
    // LEGEND
    var legendCount: Int = 0
    var isLegend: Bool = false

    // プロフィール画像
    var profileImageBase64: String = ""

    var createdAt = Date()

    var memberRank: MemberRank {
        if totalPoint >= 700 {
            return .legend
        } else if totalPoint >= 400 {
            return .platinum
        } else if totalPoint >= 200 {
            return .gold
        } else if totalPoint >= 100 {
            return .silver
        } else {
            return .bronze
        }
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case owner = "代表"
    case manager = "運営"
    case member = "メンバー"
    case guest = "ゲスト"
}

enum Gender: String, Codable, CaseIterable {
    case male = "男性"
    case female = "女性"
}

enum MemberLevel: String, Codable, CaseIterable {
    case beginner = "初心者"
    case c = "C"
    case b = "B"
    case a = "A"
}

enum MemberRank: String, Codable {
    case bronze = "🥉 Bronze"
    case silver = "🥈 Silver"
    case gold = "🥇 Gold"
    case platinum = "💎 Platinum"
    case legend = "👑 Legend"
}
