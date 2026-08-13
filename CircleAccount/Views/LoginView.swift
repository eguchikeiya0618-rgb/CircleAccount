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
    @State private var isLoading = false
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        Spacer(minLength: 34)

                        heroSection
                        loginCard
                        footerText

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.02, green: 0.05, blue: 0.15),
                Color(red: 0.08, green: 0.02, blue: 0.18)
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.30),
                                Color.blue.opacity(0.24),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 108, height: 108)
                    .blur(radius: 10)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .purple, .cyan],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                Text("🏸")
                    .font(.system(size: 52))
            }

            Text("SiRiUS")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .cyan.opacity(0.45), radius: 18)

            Text("BADMINTON CIRCLE")
                .font(.caption.weight(.black))
                .tracking(3)
                .foregroundStyle(.cyan)

            Text("サークル活動を、もっと楽しく。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
    }

    private var loginCard: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("WELCOME BACK")
                    .font(.caption.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(.cyan)

                Text("ログイン")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                }
            }

            if !message.isEmpty {
                messageView
            }

            Button {
                login()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                    }

                    Text(isLoading ? "ログイン中..." : "ログイン")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: canLogin && !isLoading
                            ? [.cyan, .blue, .purple]
                            : [Color.gray.opacity(0.45), Color.gray.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: canLogin && !isLoading ? Color.cyan.opacity(0.28) : .clear,
                    radius: 18,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)
            .disabled(!canLogin || isLoading)

            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)

                Text("OR")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.40))

                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)
            }

            NavigationLink {
                RegisterView()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "person.badge.plus")
                    Text("新規登録はこちら")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.cyan)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cyan.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.cyan.opacity(0.28), lineWidth: 1)
                        }
                )
            }
            .buttonStyle(.plain)

            Button {
                resetPassword()
            } label: {
                Text("パスワードを忘れた方")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(email.isEmpty ? .white.opacity(0.25) : .white.opacity(0.65))
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty || isLoading)
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
                systemName: message.contains("送信")
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .foregroundStyle(message.contains("送信") ? .green : .red)

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
                    message.contains("送信")
                        ? Color.green.opacity(0.12)
                        : Color.red.opacity(0.12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            message.contains("送信")
                                ? Color.green.opacity(0.26)
                                : Color.red.opacity(0.26),
                            lineWidth: 1
                        )
                }
        )
    }

    private var footerText: some View {
        Text("© SiRiUS Badminton Circle")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.28))
    }

    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
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

    private func login() {
        message = ""
        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    message = "ログイン失敗: \(error.localizedDescription)"
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

            loadMember(uid: uid)
        }
    }

    private func resetPassword() {
        message = ""
        isLoading = true

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    message = "送信失敗: \(error.localizedDescription)"
                } else {
                    message = "パスワード再設定メールを送信しました"
                }
            }
        }
    }

    private func loadMember(uid: String) {
        db.collection("members")
            .whereField("authUid", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false

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
}

#Preview {
    LoginView()
}
