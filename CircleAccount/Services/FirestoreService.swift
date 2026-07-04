import Foundation
import FirebaseFirestore

class FirestoreService {

    private let db = Firestore.firestore()

    func addMember(name: String) {
        db.collection("members").addDocument(data: [
            "name": name,
            "createdAt": Timestamp()
        ]) { error in
            if let error = error {
                print("保存失敗: \(error)")
            } else {
                print("保存成功！")
            }
        }
    }
}
