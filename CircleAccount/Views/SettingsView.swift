import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserName") private var currentUserName = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var logoutErrorMessage = ""

    private var email: String {
        Auth.auth().currentUser?.email ?? "未取得"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileCard
                        circleCard
                        appCard
                        pointCard
                        logoutCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.03, green: 0.06, blue: 0.16),
                Color(red: 0.09, green: 0.03, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.cyan.opacity(0.14))
                .frame(width: 250, height: 250)
                .blur(radius: 78)
                .offset(x: 100, y: -90)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 290, height: 290)
                .blur(radius: 88)
                .offset(x: -115, y: 120)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.30),
                                Color.blue.opacity(0.25),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)
                    .blur(radius: 9)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .purple, .cyan],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 86, height: 86)

                Image(systemName: currentUserIsAdmin ? "person.crop.circle.badge.checkmark" : "person.crop.circle.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 7) {
                Text(currentUserName.isEmpty ? "未設定" : currentUserName)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))

                Text(currentUserIsAdmin ? "ADMINISTRATOR" : "MEMBER")
                    .font(.caption2.weight(.black))
                    .tracking(1.3)
                    .foregroundStyle(currentUserIsAdmin ? .cyan : .white.opacity(0.72))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(currentUserIsAdmin ? Color.cyan.opacity(0.14) : Color.white.opacity(0.08))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        currentUserIsAdmin ? Color.cyan.opacity(0.34) : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.20),
                                    Color.cyan.opacity(0.26),
                                    Color.purple.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        )
        .shadow(color: Color.cyan.opacity(0.12), radius: 24, x: 0, y: 12)
    }

    private var circleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "CIRCLE",
                subtitle: "サークル情報",
                systemImage: "person.3.fill"
            )

            settingsRow(
                title: "サークル名",
                value: "SiRiUS",
                systemImage: "sparkles"
            )

            premiumDivider

            settingsRow(
                title: "設立",
                value: "2023年7月",
                systemImage: "calendar"
            )
        }
        .premiumSettingsCard()
    }

    private var appCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "APPLICATION",
                subtitle: "アプリ情報",
                systemImage: "iphone"
            )

            settingsRow(
                title: "アプリ名",
                value: "SiRiUS",
                systemImage: "app.fill"
            )

            premiumDivider

            settingsRow(
                title: "バージョン",
                value: "1.0.0",
                systemImage: "number.circle.fill"
            )
        }
        .premiumSettingsCard()
    }

    private var pointCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "POINT",
                subtitle: "ポイント・カード",
                systemImage: "creditcard.fill"
            )

            NavigationLink {
                PointCardView()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.22),
                                        Color.blue.opacity(0.20),
                                        Color.purple.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)

                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.cyan)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("SiRiUS CARD")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        Text("ポイントカードを確認")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.52))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.36))
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        }
                )
            }
            .buttonStyle(.plain)
        }
        .premiumSettingsCard()
    }

    private var logoutCard: some View {
        VStack(spacing: 14) {
            if !logoutErrorMessage.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(logoutErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.86))

                    Spacer()
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.red.opacity(0.26), lineWidth: 1)
                        }
                )
            }

            Button(role: .destructive) {
                logout()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 17, weight: .bold))

                    Text("ログアウト")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.82),
                            Color.pink.opacity(0.72)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: Color.red.opacity(0.20), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var premiumDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 46)
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.24),
                                Color.blue.opacity(0.20),
                                Color.purple.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(.cyan)

                Text(subtitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }

    private func settingsRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.11))
                    .frame(width: 34, height: 34)

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.cyan)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
    }

    private func logout() {
        logoutErrorMessage = ""

        do {
            try Auth.auth().signOut()
            currentUserId = ""
            currentUserName = ""
            currentUserIsAdmin = false
        } catch {
            logoutErrorMessage = "ログアウト失敗: \(error.localizedDescription)"
        }
    }
}

private extension View {
    func premiumSettingsCard() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
            )
            .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    SettingsView()
}
