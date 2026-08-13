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

    @State private var isLoading = false
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            premiumBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 18)

                    heroSection
                    registerCard

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.02, green: 0.05, blue: 0.15),
                Color(red: 0.09, green: 0.02, blue: 0.19)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 100, y: -90)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.purple.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: -120, y: 120)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.28),
                                Color.blue.opacity(0.24),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 94, height: 94)
                    .blur(radius: 9)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .purple, .cyan],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("JOIN SiRiUS")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("招待コードを使ってサークルに参加")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
    }

    private var registerCard: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("CREATE ACCOUNT")
                    .font(.caption.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(.cyan)

                Text("新規登録")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            premiumField(
                title: "名前",
                systemImage: "person.fill"
            ) {
                TextField("表示名", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .tint(.cyan)
            }

            premiumField(
                title: "メールアドレス",
                systemImage: "envelope.fill"
            ) {
                TextField("example@email.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .tint(.cyan)
            }

            premiumField(
                title: "パスワード",
                systemImage: "lock.fill"
            ) {
                HStack(spacing: 10) {
                    Group {
                        if isPasswordVisible {
                            TextField("パスワード", text: $password)
                        } else {
                            SecureField("パスワード", text: $password)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .tint(.cyan)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(
                            systemName: isPasswordVisible
                                ? "eye.slash.fill"
                                : "eye.fill"
                        )
                        .foregroundStyle(.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                }
            }

            premiumField(
                title: "招待コード",
                systemImage: "ticket.fill"
            ) {
                TextField("招待コードを入力", text: $inviteCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .tint(.cyan)
            }

            if !message.isEmpty {
                messageView
            }

            Button {
                checkInviteCode()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                    }

                    Text(isLoading ? "登録中..." : "登録する")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: canRegister && !isLoading
                            ? [.cyan, .blue, .purple]
                            : [Color.gray.opacity(0.45), Color.gray.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: canRegister && !isLoading
                        ? Color.cyan.opacity(0.28)
                        : .clear,
                    radius: 18,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)
            .disabled(!canRegister || isLoading)

            Text("登録すると、SiRiUSの活動・ポイント・ランキング機能を利用できます。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
        )
        .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: 12)
    }

    private var messageView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(
                systemName: message.contains("完了")
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .foregroundStyle(message.contains("完了") ? .green : .red)

            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.86))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    message.contains("完了")
                        ? Color.green.opacity(0.12)
                        : Color.red.opacity(0.12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            message.contains("完了")
                                ? Color.green.opacity(0.26)
                                : Color.red.opacity(0.26),
                            lineWidth: 1
                        )
                }
        )
    }

    private var canRegister: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func premiumField<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))

            content()
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        }
                )
        }
    }

    private func checkInviteCode() {
        message = ""
        isLoading = true

        let normalizedInviteCode = inviteCode
            .trimmingCharacters(in: .whitespacesAndNewlines)

        db.collection("circles")
            .whereField("inviteCode", isEqualTo: normalizedInviteCode)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        message = "招待コード確認失敗: \(error.localizedDescription)"
                    }
                    return
                }

                guard let circleDocument = snapshot?.documents.first else {
                    DispatchQueue.main.async {
                        isLoading = false
                        message = "招待コードが違います"
                    }
                    return
                }

                let circleData = circleDocument.data()
                let circleName = circleData["name"] as? String ?? "SIRIUS"

                register(
                    circleId: circleDocument.documentID,
                    circleName: circleName
                )
            }
    }

    private func register(
        circleId: String,
        circleName: String
    ) {
        Auth.auth().createUser(
            withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        ) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    message = "登録失敗: \(error.localizedDescription)"
                }
                return
            }

            guard let uid = result?.user.uid else {
                DispatchQueue.main.async {
                    isLoading = false
                    message = "ユーザー情報が取得できません"
                }
                return
            }

            let normalizedName = name
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let normalizedEmail = email
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let memberData: [String: Any] = [
                "name": normalizedName,
                "email": normalizedEmail,
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

            var ref: DocumentReference?

            ref = db.collection("members").addDocument(data: memberData) { error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error = error {
                        message = "メンバー登録失敗: \(error.localizedDescription)"
                        return
                    }

                    guard let memberId = ref?.documentID else {
                        message = "メンバーID取得失敗"
                        return
                    }

                    currentUserId = memberId
                    currentUserName = normalizedName
                    currentUserIsAdmin = false
                    message = "登録完了"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
