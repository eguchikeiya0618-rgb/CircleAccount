import SwiftUI

struct MemberProfileView: View {
    let member: Member

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                pointCard
                badmintonProfileCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    var profileHeader: some View {
        VStack(spacing: 14) {
            ProfileImageView(
                imageBase64: member.profileImageBase64,
                size: 130
            )

            Text(member.name)
                .font(.largeTitle)
                .bold()

            if currentUserIsAdmin {
                Text(member.level.rawValue)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(member.memberRank.rawValue)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    var pointCard: some View {
        VStack(spacing: 14) {
            profileRow(
                title: "累計ポイント",
                value: "\(member.totalPoint)pt"
            )

            Divider()

            profileRow(
                title: "今月ポイント",
                value: "\(member.monthlyPoint)pt"
            )

            Divider()

            profileRow(
                title: "参加回数",
                value: "\(member.attendanceCount)回"
            )

            Divider()

            profileRow(
                title: "設営回数",
                value: "\(member.setupCount)回"
            )

            Divider()

            profileRow(
                title: "月間優勝",
                value: "\(member.monthlyChampionCount)回"
            )

            Divider()

            profileRow(
                title: "MVP",
                value: "\(member.mvpCount)回"
            )
        }
        .profileSectionCard()
    }

    var badmintonProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "バドミントンプロフィール",
                systemImage: "figure.badminton"
            )
            .font(.title2)
            .bold()
            .foregroundStyle(.blue)

            if hasBadmintonProfile {
                if member.badmintonStartAge > 0 {
                    profileRow(
                        title: "競技開始年齢",
                        value: "\(member.badmintonStartAge)歳"
                    )
                }

                if member.badmintonYears > 0 {
                    Divider()

                    profileRow(
                        title: "競技歴",
                        value: "\(member.badmintonYears)年"
                    )
                }

                if !member.racket.isEmpty {
                    Divider()

                    profileRow(
                        title: "使用ラケット",
                        value: member.racket
                    )
                }

                if !member.stringName.isEmpty {
                    Divider()

                    profileRow(
                        title: "ガット",
                        value: member.stringName
                    )
                }

                if !member.tension.isEmpty {
                    Divider()

                    profileRow(
                        title: "テンション",
                        value: "\(member.tension)ポンド"
                    )
                }

                if !member.playStyle.isEmpty {
                    Divider()

                    profileRow(
                        title: "プレースタイル",
                        value: member.playStyle
                    )
                }

                if !member.comment.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ひとこと")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)

                        Text(member.comment)
                            .font(.body)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding()
                            .background(Color.blue.opacity(0.08))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                    }
                }
            } else {
                Text("バドミントンプロフィールはまだ登録されていません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.vertical, 10)
            }
        }
        .profileSectionCard()
    }

    var hasBadmintonProfile: Bool {
        member.badmintonStartAge > 0 ||
        member.badmintonYears > 0 ||
        !member.racket.isEmpty ||
        !member.stringName.isEmpty ||
        !member.tension.isEmpty ||
        !member.playStyle.isEmpty ||
        !member.comment.isEmpty
    }

    func profileRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .bold()
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
        }
    }
}

extension View {
    func profileSectionCard() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(
                color: .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
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
