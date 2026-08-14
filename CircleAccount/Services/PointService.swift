import Foundation
import FirebaseFirestore

enum GachaTestConfiguration {
    // falseへ戻すだけで通常の1/1/3/18/39/38%抽選へ復帰する。
    static let usesSSRAndSRVerificationMode = true
}

struct GachaPrize {
    let icon: String
    let title: String
    let ticketField: String
    let rarity: Int
}
final class PointService {
    static let shared = PointService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func addPoint(
        memberId: String,
        point: Int,
        title: String,
        icon: String,
        addAttendanceCount: Bool = false,
        addSetupCount: Bool = false
    ) {
        let memberRef = db.collection("members").document(memberId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]

            let oldTotal = data["totalPoint"] as? Int ?? 0
            let newTotal = oldTotal + point

            var updatedData: [String: Any] = [
                "totalPoint": FieldValue.increment(Int64(point)),
                "availablePoint": FieldValue.increment(Int64(point)),
                "monthlyPoint": FieldValue.increment(Int64(point))
            ]

            if addAttendanceCount {
                updatedData["attendanceCount"] =
                    FieldValue.increment(Int64(1))

                updatedData["streakCount"] =
                    FieldValue.increment(Int64(1))
            }

            if addSetupCount {
                updatedData["setupCount"] =
                    FieldValue.increment(Int64(1))
            }

            let reward = self.rankUpReward(
                oldTotal: oldTotal,
                newTotal: newTotal
            )

            if reward.challengeTickets > 0 {
                updatedData["challengeTickets"] =
                    FieldValue.increment(
                        Int64(reward.challengeTickets)
                    )
            }

            if reward.priorityTickets > 0 {
                updatedData["priorityTickets"] =
                    FieldValue.increment(
                        Int64(reward.priorityTickets)
                    )
            }

            transaction.updateData(
                updatedData,
                forDocument: memberRef
            )

            return reward

        }) { rewardAny, error in
            if let error = error {
                print(
                    "ポイント付与失敗: \(error.localizedDescription)"
                )
                return
            }

            memberRef.collection("pointHistories")
                .addDocument(data: [
                    "title": title,
                    "point": point,
                    "icon": icon,
                    "date": Timestamp()
                ])

            if addAttendanceCount {
                self.checkAndGrantStreakBonus(
                    memberId: memberId
                )
            }

            if let reward = rewardAny as? (
                title: String,
                icon: String,
                challengeTickets: Int,
                priorityTickets: Int
            ),
            reward.challengeTickets > 0 ||
            reward.priorityTickets > 0 {

                memberRef.collection("pointHistories")
                    .addDocument(data: [
                        "title": reward.title,
                        "point": 0,
                        "icon": reward.icon,
                        "date": Timestamp()
                    ])
            }
        }
    }
    private func rankUpReward(
        oldTotal: Int,
        newTotal: Int
    ) -> (title: String, icon: String, challengeTickets: Int, priorityTickets: Int) {
        
        if oldTotal < 700 && newTotal >= 700 {
            return ("Legendランクアップ報酬：対戦指名券×2・優先ゲーム券×2", "👑", 2, 2)
        }
        
        if oldTotal < 400 && newTotal >= 400 {
            return ("Platinumランクアップ報酬：対戦指名券×1・優先ゲーム券×1", "💎", 1, 1)
        }
        
        if oldTotal < 200 && newTotal >= 200 {
            return ("Goldランクアップ報酬：対戦指名券×2", "🥇", 2, 0)
        }
        
        if oldTotal < 100 && newTotal >= 100 {
            return ("Silverランクアップ報酬：対戦指名券×1", "🥈", 1, 0)
        }
        
        return ("", "", 0, 0)
    }
    func checkAndGrantStreakBonus(memberId: String) {
        guard !memberId.isEmpty else { return }

        let memberRef = db.collection("members").document(memberId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let streakCount = snapshot.data()?["streakCount"] as? Int ?? 0
            let claimedBonuses =
                snapshot.data()?["claimedStreakBonuses"] as? [String] ?? []

            let bonusPoint: Int
            let bonusId: String

            switch streakCount {
            case 3:
                bonusPoint = 3
                bonusId = "streak3"

            case 5:
                bonusPoint = 5
                bonusId = "streak5"

            case 10:
                bonusPoint = 10
                bonusId = "streak10"

            default:
                return nil
            }

            guard !claimedBonuses.contains(bonusId) else {
                return nil
            }

            transaction.updateData([
                "totalPoint": FieldValue.increment(Int64(bonusPoint)),
                "availablePoint": FieldValue.increment(Int64(bonusPoint)),
                "monthlyPoint": FieldValue.increment(Int64(bonusPoint)),
                "claimedStreakBonuses": FieldValue.arrayUnion([bonusId])
            ], forDocument: memberRef)

            return [
                "streakCount": streakCount,
                "bonusPoint": bonusPoint
            ]
        }) { result, error in
            if let error {
                print("連続参加ボーナス付与失敗: \(error.localizedDescription)")
                return
            }

            guard
                let result = result as? [String: Int],
                let streakCount = result["streakCount"],
                let bonusPoint = result["bonusPoint"]
            else {
                return
            }

            memberRef.collection("pointHistories").addDocument(data: [
                "title": "🔥 \(streakCount)回連続参加ボーナス",
                "point": bonusPoint,
                "icon": "🔥",
                "date": Timestamp()
            ])
        }
    }
    func exchangeTicket(
        memberId: String,
        requiredPoint: Int,
        ticketField: String,
        title: String,
        icon: String
    ) {
        let memberRef = db.collection("members").document(memberId)
        
        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot
            
            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            let availablePoint = snapshot.data()?["availablePoint"] as? Int ?? 0
            
            if availablePoint < requiredPoint {
                errorPointer?.pointee = NSError(
                    domain: "PointService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "ポイントが不足しています"]
                )
                return nil
            }
            
            let updateData: [String: Any] = [
                "availablePoint": FieldValue.increment(Int64(-requiredPoint)),
                ticketField: FieldValue.increment(Int64(1))
            ]
            
            transaction.updateData(updateData, forDocument: memberRef)
            
            return nil
        }) { _, error in
            if let error = error {
                print("チケット交換失敗: \(error.localizedDescription)")
                return
            }
            
            memberRef.collection("pointHistories").addDocument(data: [
                "title": title,
                "point": -requiredPoint,
                "icon": icon,
                "date": Timestamp()
            ])
           
        }
    }
    func runGacha(
        memberId: String,
        completion: @escaping (Result<GachaPrize, Error>) -> Void
    ) {
        let cost = 100
        let memberRef = db.collection("members").document(memberId)

        let prize = GachaTestConfiguration.usesSSRAndSRVerificationMode
            ? drawSSRAndSRVerificationPrize()
            : drawGachaPrize()

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let availablePoint =
                snapshot.data()?["availablePoint"] as? Int ?? 0

            if availablePoint < cost {
                errorPointer?.pointee = NSError(
                    domain: "PointService",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "ガチャを回すには100pt必要です"
                    ]
                )
                return nil
            }

            transaction.updateData([
                "availablePoint": FieldValue.increment(Int64(-cost)),
                prize.ticketField: FieldValue.increment(Int64(1)),
                "gachaCount": FieldValue.increment(Int64(1))
            ], forDocument: memberRef)

            return nil
        }) { _, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            memberRef.collection("pointHistories")
                .addDocument(data: [
                    "title": "ガチャ：\(prize.title)を獲得",
                    "point": -cost,
                    "icon": prize.icon,
                    "date": Timestamp()
                ])

            self.db.collection("gachaHistories")
                .addDocument(data: [
                    "memberId": memberId,
                    "prizeTitle": prize.title,
                    "prizeIcon": prize.icon,
                    "ticketField": prize.ticketField,
                    "rarity": prize.rarity,
                    "cost": cost,
                    "createdAt": Timestamp()
                ])

            DispatchQueue.main.async {
                completion(.success(prize))
            }
        }
    }

    private func drawSSRAndSRVerificationPrize() -> GachaPrize {
        if Int.random(in: 0..<100) < 50 {
            // SSR枠内では777と🌈777を均等に確認できるようにする。
            if Bool.random() {
                return GachaPrize(
                    icon: "🎾",
                    title: "ガット張り工賃無料券",
                    ticketField: "stringingFreeTickets",
                    rarity: 5
                )
            }

            return GachaPrize(
                icon: "🎁",
                title: "参加費無料券",
                ticketField: "freeTickets",
                rarity: 5
            )
        }

        return GachaPrize(
            icon: "🏸",
            title: "参加費半額券",
            ticketField: "halfPriceTickets",
            rarity: 4
        )
    }

    private func drawGachaPrize() -> GachaPrize {
        let number = Int.random(in: 1...100)

        switch number {

        case 1:
            return GachaPrize(
                icon: "🎾",
                title: "ガット張り工賃無料券",
                ticketField: "stringingFreeTickets",
                rarity: 5
            )

        case 2:
            return GachaPrize(
                icon: "🎁",
                title: "参加費無料券",
                ticketField: "freeTickets",
                rarity: 5
            )

        case 3...5:
            return GachaPrize(
                icon: "🏸",
                title: "参加費半額券",
                ticketField: "halfPriceTickets",
                rarity: 4
            )

        case 6...23:
            return GachaPrize(
                icon: "💰",
                title: "参加費500円券",
                ticketField: "discountTickets",
                rarity: 3
            )

        case 24...62:
            return GachaPrize(
                icon: "🔔",
                title: "対戦指名券",
                ticketField: "challengeTickets",
                rarity: 3
            )

        default:
            return GachaPrize(
                icon: "🍇",
                title: "優先ゲーム券",
                ticketField: "priorityTickets",
                rarity: 3
            )
        }
    }
    func grantAchievementRewardOnce(
        memberId: String,
        achievementId: String,
        ticketField: String,
        ticketCount: Int = 1,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let memberRef = db.collection("members").document(memberId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let claimedRewards =
                snapshot.data()?["claimedAchievementRewards"] as? [String] ?? []

            // すでに受け取っている場合は何もしない
            if claimedRewards.contains(achievementId) {
                return false
            }

            transaction.updateData([
                ticketField: FieldValue.increment(Int64(ticketCount)),
                "claimedAchievementRewards": FieldValue.arrayUnion([
                    achievementId
                ])
            ], forDocument: memberRef)

            return true
        }) { result, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            let wasGranted = result as? Bool ?? false

            if wasGranted {
                memberRef.collection("pointHistories")
                    .addDocument(data: [
                        "title": "実績報酬を獲得",
                        "point": 0,
                        "icon": "🏆",
                        "achievementId": achievementId,
                        "date": Timestamp()
                    ])
            }

            DispatchQueue.main.async {
                completion(.success(wasGranted))
            }
        }
    }
    func useTicket(
        memberId: String,
        ticketField: String,
        title: String,
        icon: String,
        activityId: String? = nil
    ) {
        let memberRef = db.collection("members").document(memberId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let ticketCount = snapshot.data()?[ticketField] as? Int ?? 0
            let memberName = snapshot.data()?["name"] as? String ?? ""

            if ticketCount <= 0 {
                errorPointer?.pointee = NSError(
                    domain: "PointService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "チケットがありません"]
                )
                return nil
            }

            transaction.updateData([
                ticketField: FieldValue.increment(Int64(-1))
            ], forDocument: memberRef)

            return memberName
        }) { memberNameAny, error in
            if let error = error {
                print("チケット使用失敗: \(error.localizedDescription)")
                return
            }

            let memberName = memberNameAny as? String ?? ""

            memberRef.collection("pointHistories").addDocument(data: [
                "title": "\(title)を使用",
                "point": 0,
                "icon": icon,
                "date": Timestamp()
            ])

            self.db.collection("ticketUsages").addDocument(data: [
                "memberId": memberId,
                "memberName": memberName,
                "ticket": title,
                "icon": icon,
                "activityId": activityId ?? "",
                "usedAt": Timestamp(),
                "status": "未確認"
            ])
        }
    }
    func resetAttendanceStreak(memberId: String) {
        guard !memberId.isEmpty else { return }

        db.collection("members")
            .document(memberId)
            .updateData([
                "streakCount": 0
            ]) { error in
                if let error {
                    print("連続参加リセット失敗: \(error.localizedDescription)")
                }
            }
    }
    func addMonthlyAward(
        memberId: String,
        field: String
    ) {
        let ref = db.collection("members").document(memberId)
        
        var updates: [String: Any] = [
            field: FieldValue.increment(Int64(1))
        ]
        
        switch field {
        case "monthlyChampionCount":
            updates["stringingFreeTickets"] = FieldValue.increment(Int64(1))
            
        case "monthlySecondCount":
            updates["challengeTickets"] = FieldValue.increment(Int64(1))
            
        case "monthlyThirdCount":
            updates["priorityTickets"] = FieldValue.increment(Int64(1))
            
        default:
            break
        }
        
        ref.updateData(updates)
    }
    func resetAllMonthlyPoints() {
        Firestore.firestore().collection("members")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    document.reference.updateData([
                        "monthlyPoint": 0
                    ])
                }
            }
    }
}
