import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserName") private var currentUserName = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("🏸 SIRIUS")
                    .font(.largeTitle)
                    .bold()

                Text("Badminton Circle")
                    .foregroundStyle(.secondary)

                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("ログイン") {
                    login()
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)

                NavigationLink {
                    RegisterView()
                } label: {
                    Text("新規登録はこちら")
                }

                Button("パスワードを忘れた方") {
                    resetPassword()
                }
                .disabled(email.isEmpty)

                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(message.contains("送信") ? .green : .red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("ログイン")
        }
    }

    func login() {
        message = ""

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                message = "ログイン失敗: \(error.localizedDescription)"
                return
            }

            guard let uid = result?.user.uid else {
                message = "ユーザー情報が取得できません"
                return
            }

            loadMember(uid: uid)
        }
    }

    func resetPassword() {
        message = ""

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = "送信失敗: \(error.localizedDescription)"
            } else {
                message = "パスワード再設定メールを送信しました"
            }
        }
    }

    func loadMember(uid: String) {
        db.collection("members")
            .whereField("authUid", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    message = "メンバー取得失敗: \(error.localizedDescription)"
                    return
                }

                guard let document = snapshot?.documents.first else {
                    message = "このログインユーザーに紐づくメンバーが見つかりません"
                    return
                }

                let data = document.data()

                currentUserId = document.documentID
                currentUserName = data["name"] as? String ?? ""
                currentUserIsAdmin = data["isAdmin"] as? Bool ?? false
            }
    }
}

#Preview {
    LoginView()
}
