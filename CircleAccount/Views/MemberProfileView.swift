import SwiftUI

struct MemberProfileView: View {
    let member: Member

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

    var body: some View {
        ZStack {
            premiumBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    profileHeader
                    pointSummaryCard
                    badmintonProfileCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                Color.black,
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
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 90, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -100, y: 110)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.85),
                                Color.blue.opacity(0.85),
                                Color.purple.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 12)
                    .opacity(0.55)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 142, height: 142)

                ProfileImageView(
                    imageBase64: member.profileImageBase64,
                    size: 130
                )
            }

            VStack(spacing: 8) {
                Text(member.name)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(member.memberRank.rawValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if currentUserIsAdmin {
                    Text(member.level.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.22))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.cyan.opacity(0.45), lineWidth: 1)
                                }
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.cyan.opacity(0.28),
                                    Color.purple.opacity(0.20)
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

    private var pointSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "POINT STATUS",
                subtitle: "ポイント・参加実績",
                systemImage: "sparkles"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                statCard(
                    title: "累計ポイント",
                    value: "\(member.totalPoint)pt",
                    systemImage: "crown.fill"
                )

                statCard(
                    title: "今月ポイント",
                    value: "\(member.monthlyPoint)pt",
                    systemImage: "calendar.badge.clock"
                )

                statCard(
                    title: "参加回数",
                    value: "\(member.attendanceCount)回",
                    systemImage: "figure.badminton"
                )

                statCard(
                    title: "設営回数",
                    value: "\(member.setupCount)回",
                    systemImage: "shippingbox.fill"
                )

                statCard(
                    title: "月間優勝",
                    value: "\(member.monthlyChampionCount)回",
                    systemImage: "trophy.fill"
                )

                statCard(
                    title: "MVP",
                    value: "\(member.mvpCount)回",
                    systemImage: "star.fill"
                )
            }
        }
        .premiumSectionCard()
    }

    private var badmintonProfileCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "BADMINTON PROFILE",
                subtitle: "競技プロフィール",
                systemImage: "figure.badminton"
            )

            if hasBadmintonProfile {
                VStack(spacing: 0) {
                    if member.badmintonStartAge > 0 {
                        premiumProfileRow(
                            title: "競技開始年齢",
                            value: "\(member.badmintonStartAge)歳",
                            systemImage: "calendar"
                        )
                    }

                    if member.badmintonYears > 0 {
                        premiumDivider
                        premiumProfileRow(
                            title: "競技歴",
                            value: "\(member.badmintonYears)年",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }

                    if !member.racket.isEmpty {
                        premiumDivider
                        premiumProfileRow(
                            title: "使用ラケット",
                            value: member.racket,
                            systemImage: "sportscourt.fill"
                        )
                    }

                    if !member.stringName.isEmpty {
                        premiumDivider
                        premiumProfileRow(
                            title: "ガット",
                            value: member.stringName,
                            systemImage: "circle.grid.cross"
                        )
                    }

                    if !member.tension.isEmpty {
                        premiumDivider
                        premiumProfileRow(
                            title: "テンション",
                            value: "\(member.tension)ポンド",
                            systemImage: "gauge.with.dots.needle.50percent"
                        )
                    }

                    if !member.playStyle.isEmpty {
                        premiumDivider
                        premiumProfileRow(
                            title: "プレースタイル",
                            value: member.playStyle,
                            systemImage: "bolt.fill"
                        )
                    }
                }

                if !member.comment.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("MESSAGE", systemImage: "quote.bubble.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)

                        Text(member.comment)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.88))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.cyan.opacity(0.20), lineWidth: 1)
                                    }
                            )
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "figure.badminton")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))

                    Text("バドミントンプロフィールは\nまだ登録されていません")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .premiumSectionCard()
    }

    private var premiumDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 46)
    }

    private var hasBadmintonProfile: Bool {
        member.badmintonStartAge > 0 ||
        member.badmintonYears > 0 ||
        !member.racket.isEmpty ||
        !member.stringName.isEmpty ||
        !member.tension.isEmpty ||
        !member.playStyle.isEmpty ||
        !member.comment.isEmpty
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
                                Color.cyan.opacity(0.25),
                                Color.blue.opacity(0.22),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
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

    private func statCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.cyan)

                Spacer()
            }

            Text(value)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        )
    }

    private func premiumProfileRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.cyan)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .padding(.top, 6)

            Spacer(minLength: 14)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .padding(.top, 6)
        }
        .padding(.vertical, 12)
    }
}

private extension View {
    func premiumSectionCard() -> some View {
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
    NavigationStack {
        MemberProfileView(
            member: Member(
                name: "けーや",
                role: .member,
                isAdmin: false,
                isActive: true,
                badmintonStartAge: 10,
                badmintonYears: 20,
                racket: "ASTROX 100ZZ",
                stringName: "EXBOLT 65",
                tension: "26",
                playStyle: "後衛・スマッシュ中心",
                comment: "ミックスと男子ダブルスに出たいです！"
            )
        )
    }
}
