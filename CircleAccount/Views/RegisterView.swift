import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserName") private var currentUserName = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 18) {
            Text("新規登録")
                .font(.largeTitle)
                .bold()

            TextField("名前", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("メールアドレス", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("パスワード", text: $password)
                .textFieldStyle(.roundedBorder)

            TextField("招待コード", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            Button("登録する") {
                checkInviteCode()
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty || email.isEmpty || password.isEmpty || inviteCode.isEmpty)

            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(message.contains("完了") ? .green : .red)
            }
        }
        .padding()
        .navigationTitle("新規登録")
    }

    func checkInviteCode() {
        message = ""

        db.collection("circles")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    message = "招待コード確認失敗: \(error.localizedDescription)"
                    return
                }

                guard let circleDocument = snapshot?.documents.first else {
                    message = "招待コードが違います"
                    return
                }

                let circleData = circleDocument.data()
                let circleName = circleData["name"] as? String ?? "SIRIUS"

                register(circleId: circleDocument.documentID, circleName: circleName)
            }
    }

    func register(circleId: String, circleName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                message = "登録失敗: \(error.localizedDescription)"
                return
            }

            guard let uid = result?.user.uid else {
                message = "ユーザー情報が取得できません"
                return
            }

            let memberData: [String: Any] = [
                "name": name,
                "email": email,
                "authUid": uid,
                "circleId": circleId,
                "circleName": circleName,
                "role": MemberRole.member.rawValue,
                "isAdmin": false,
                "isActive": true,

                "gender": Gender.male.rawValue,
                "level": MemberLevel.beginner.rawValue,

                "totalPoint": 0,
                "availablePoint": 0,

                "cleanupTickets": 0,
                "discountTickets": 0,
                "halfPriceTickets": 0,
                "freeTickets": 0,

                "challengeTickets": 0,
                "priorityTickets": 0,

                "attendanceCount": 0,
                "setupCount": 0,

                "legendCount": 0,
                "isLegend": false,

                "memberNo": 999999,
                "profileImageBase64": "",

                "createdAt": Timestamp()
            ]

            var ref: DocumentReference? = nil

            ref = db.collection("members").addDocument(data: memberData) { error in
                if let error = error {
                    message = "メンバー登録失敗: \(error.localizedDescription)"
                    return
                }

                guard let memberId = ref?.documentID else {
                    message = "メンバーID取得失敗"
                    return
                }

                currentUserId = memberId
                currentUserName = name
                currentUserIsAdmin = false
                message = "登録完了"
            }
        }
    }
}

#Preview {
    RegisterView()
}
