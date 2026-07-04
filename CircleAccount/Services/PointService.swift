import Foundation
import FirebaseFirestore

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
            
            let oldTotal = snapshot.data()?["totalPoint"] as? Int ?? 0
            let newTotal = oldTotal + point
            
            var updateData: [String: Any] = [
                "totalPoint": FieldValue.increment(Int64(point)),
                "availablePoint": FieldValue.increment(Int64(point))
            ]
            
            if addAttendanceCount {
                updateData["attendanceCount"] = FieldValue.increment(Int64(1))
            }
            
            if addSetupCount {
                updateData["setupCount"] = FieldValue.increment(Int64(1))
            }
            
            let reward = self.rankUpReward(oldTotal: oldTotal, newTotal: newTotal)
            
            if reward.challengeTickets > 0 {
                updateData["challengeTickets"] = FieldValue.increment(Int64(reward.challengeTickets))
            }
            
            if reward.priorityTickets > 0 {
                updateData["priorityTickets"] = FieldValue.increment(Int64(reward.priorityTickets))
            }
            
            transaction.updateData(updateData, forDocument: memberRef)
            
            return reward
        }) { rewardAny, error in
            if let error = error {
                print("ポイント付与失敗: \(error.localizedDescription)")
                return
            }

            memberRef.collection("pointHistories").addDocument(data: [
                "title": title,
                "point": point,
                "icon": icon,
                "date": Timestamp()
            ])

            if let reward = rewardAny as? (title: String, icon: String, challengeTickets: Int, priorityTickets: Int),
               reward.challengeTickets > 0 || reward.priorityTickets > 0 {

                memberRef.collection("pointHistories").addDocument(data: [
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
}
