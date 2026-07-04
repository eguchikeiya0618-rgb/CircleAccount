import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserName") private var currentUserName = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    var email: String {
        Auth.auth().currentUser?.email ?? "未取得"
    }

    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentUserName.isEmpty ? "未設定" : currentUserName)
                            .font(.title2)
                            .bold()

                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(currentUserIsAdmin ? "管理者" : "メンバー")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(currentUserIsAdmin ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 8)
                }

                Section("サークル") {
                    HStack {
                        Text("サークル名")
                        Spacer()
                        Text("SiRiUS")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("設立")
                        Spacer()
                        Text("2023年7月")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("アプリ") {
                    HStack {
                        Text("アプリ名")
                        Spacer()
                        Text("SiRiUS")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("ポイント") {
                    NavigationLink {
                        PointCardView()
                    } label: {
                        Label("SiRiUS CARD", systemImage: "creditcard")
                    }
                }
                Section {
                    Button(role: .destructive) {
                        logout()
                    } label: {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("マイページ")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            currentUserId = ""
            currentUserName = ""
            currentUserIsAdmin = false
        } catch {
            print("ログアウト失敗: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
}
