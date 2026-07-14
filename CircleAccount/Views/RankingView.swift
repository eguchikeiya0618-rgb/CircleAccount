import SwiftUI
import FirebaseFirestore
import UIKit

// MARK: - ランキング種類

enum RankingType: String, CaseIterable, Identifiable {
    case point = "ポイント"
    case attendance = "参加回数"
    case setup = "設営回数"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .point:
            return "trophy.fill"

        case .attendance:
            return "figure.badminton"

        case .setup:
            return "hammer.fill"
        }
    }
}

// MARK: - ランキング用メンバー

struct RankingMember: Identifiable {
    let id: String
    let name: String

    let monthlyPoint: Int
    let totalPoint: Int

    // 累計記録
    let attendanceCount: Int
    let setupCount: Int

    // 今月の記録
    let monthlyAttendanceCount: Int
    let monthlySetupCount: Int

    let monthlyChampionCount: Int
    let mvpCount: Int

    let profileImageBase64: String

    let dominantHand: String
    let badmintonStartAge: Int
    let badmintonYears: Int
    let racket: String
    let stringName: String
    let tension: String
    let playStyle: String
    let favoriteShot: String
    let comment: String

    let role: MemberRole
    let isAdmin: Bool
    let isActive: Bool

    let gender: Gender
    let level: MemberLevel
}

// MARK: - ランキング画面

struct RankingView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @State private var members: [RankingMember] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    @State private var selectedRankingType: RankingType = .point

    private var sortedMembers: [RankingMember] {
        members.sorted { first, second in
            let firstValue = rankingValue(first)
            let secondValue = rankingValue(second)

            if firstValue == secondValue {
                return first.name.localizedStandardCompare(second.name)
                    == .orderedAscending
            }

            return firstValue > secondValue
        }
    }

    private var myRank: Int? {
        guard let index = sortedMembers.firstIndex(where: {
            $0.id == currentUserId
        }) else {
            return nil
        }

        return index + 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                rankingHeader

                rankingTypePicker

                if isLoading {
                    ProgressView("ランキングを集計中...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)

                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)

                } else if sortedMembers.isEmpty {
                    Text("ランキング対象のメンバーがいません")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)

                } else {
                    if let myRank {
                        myRankingCard(rank: myRank)
                    }

                    rankingList
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ランキング")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRanking()
        }
    }

    // MARK: - ヘッダー

    private var rankingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("月間ランキング")
                        .font(.system(size: 34, weight: .black))

                    Text(currentMonthText())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("🏆")
                    .font(.system(size: 46))
            }

            Text(rankingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rankingDescription: String {
        switch selectedRankingType {
        case .point:
            return "今月獲得したポイントのランキングです"

        case .attendance:
            return "今月QR受付を完了した参加回数のランキングです"

        case .setup:
            return "今月設営ポイントを獲得した回数のランキングです"
        }
    }

    // MARK: - 切り替えボタン

    private var rankingTypePicker: some View {
        Picker(
            "ランキング種類",
            selection: $selectedRankingType
        ) {
            ForEach(RankingType.allCases) { type in
                Text(type.rawValue)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 自分の順位

    private func myRankingCard(rank: Int) -> some View {
        let member = sortedMembers.first {
            $0.id == currentUserId
        }

        return HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("あなたの現在順位")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(rank)位")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.blue)
            }

            Spacer()

            if let member {
                Text(rankingValueText(member))
                    .font(.title3)
                    .bold()
            }
        }
        .padding()
        .background(Color.blue.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        }
    }

    // MARK: - ランキング一覧

    private var rankingList: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(sortedMembers.enumerated()),
                id: \.element.id
            ) { index, member in
                NavigationLink {
                    RankingMemberProfileView(member: member)
                } label: {
                    rankingRow(
                        rank: index + 1,
                        member: member
                    )
                }
                .buttonStyle(.plain)

                if index < sortedMembers.count - 1 {
                    Divider()
                        .padding(.leading, 84)
                }
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private func rankingRow(
        rank: Int,
        member: RankingMember
    ) -> some View {
        HStack(spacing: 14) {
            Text(rankIcon(rank))
                .font(.system(size: rank <= 3 ? 34 : 21))
                .bold()
                .frame(width: 46)

            ProfileImageView(
                imageBase64: member.profileImageBase64,
                size: 52
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.headline)
                        .bold()

                    if member.id == currentUserId {
                        Text("あなた")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Text(rankingSubText(member))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(rankingValueText(member))
                    .font(.title3)
                    .bold()
                    .foregroundStyle(rankColor(rank))

                Text("\(rank)位")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 17)
        .padding(.horizontal, 8)
        .background(rowBackground(rank: rank, member: member))
    }

    private func rankingValue(
        _ member: RankingMember
    ) -> Int {
        switch selectedRankingType {
        case .point:
            return member.monthlyPoint

        case .attendance:
            return member.monthlyAttendanceCount

        case .setup:
            return member.monthlySetupCount
        }
    }

    private func rankingValueText(
        _ member: RankingMember
    ) -> String {
        switch selectedRankingType {
        case .point:
            return "\(member.monthlyPoint)pt"

        case .attendance:
            return "\(member.monthlyAttendanceCount)回"

        case .setup:
            return "\(member.monthlySetupCount)回"
        }
    }

    private func rankingSubText(
        _ member: RankingMember
    ) -> String {
        switch selectedRankingType {
        case .point:
            return "累計 \(member.totalPoint)pt"

        case .attendance:
            return "累計参加 \(member.attendanceCount)回"

        case .setup:
            return "累計設営 \(member.setupCount)回"
        }
    }

    private func rankIcon(_ rank: Int) -> String {
        switch rank {
        case 1:
            return "🥇"

        case 2:
            return "🥈"

        case 3:
            return "🥉"

        default:
            return "\(rank)"
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return .orange

        case 2:
            return .gray

        case 3:
            return .brown

        default:
            return .primary
        }
    }

    private func rowBackground(
        rank: Int,
        member: RankingMember
    ) -> Color {
        if member.id == currentUserId {
            return Color.blue.opacity(0.08)
        }

        switch rank {
        case 1:
            return Color.yellow.opacity(0.11)

        case 2:
            return Color.gray.opacity(0.07)

        case 3:
            return Color.brown.opacity(0.07)

        default:
            return Color.clear
        }
    }

    // MARK: - データ取得

    private func loadRanking() {
        isLoading = true
        errorMessage = ""

        db.collection("members")
            .getDocuments { memberSnapshot, memberError in
                if let memberError {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage =
                            "メンバー情報の取得に失敗しました\n"
                            + memberError.localizedDescription
                    }
                    return
                }

                let memberDocuments =
                    memberSnapshot?.documents ?? []

                loadMonthlyActivityCounts(
                    memberDocuments: memberDocuments
                )
            }
    }

    private func loadMonthlyActivityCounts(
        memberDocuments: [QueryDocumentSnapshot]
    ) {
        let calendar = Calendar.current
        let now = Date()

        guard let monthInterval = calendar.dateInterval(
            of: .month,
            for: now
        ) else {
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = "今月の期間を取得できませんでした"
            }
            return
        }

        db.collection("activities")
            .whereField(
                "date",
                isGreaterThanOrEqualTo:
                    Timestamp(date: monthInterval.start)
            )
            .whereField(
                "date",
                isLessThan:
                    Timestamp(date: monthInterval.end)
            )
            .getDocuments { activitySnapshot, activityError in
                if let activityError {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage =
                            "活動情報の取得に失敗しました\n"
                            + activityError.localizedDescription
                    }
                    return
                }

                var monthlyAttendanceCounts: [String: Int] = [:]
                var monthlySetupCounts: [String: Int] = [:]

                activitySnapshot?.documents.forEach { document in
                    let data = document.data()

                    let participantIds =
                        data["participants"] as? [String] ?? []

                    for memberId in Set(participantIds) {
                        monthlyAttendanceCounts[memberId, default: 0] += 1
                    }

                    let setupMemberIds =
                        data["setupPointGrantedMembers"]
                        as? [String] ?? []

                    for memberId in Set(setupMemberIds) {
                        monthlySetupCounts[memberId, default: 0] += 1
                    }
                }

                let loadedMembers = memberDocuments.compactMap {
                    document -> RankingMember? in

                    let data = document.data()
                    let isActive =
                        data["isActive"] as? Bool ?? true

                    guard isActive else {
                        return nil
                    }

                    return RankingMember(
                        id: document.documentID,
                        name:
                            data["name"] as? String ?? "メンバー",

                        monthlyPoint:
                            data["monthlyPoint"] as? Int ?? 0,

                        totalPoint:
                            data["totalPoint"] as? Int ?? 0,

                        attendanceCount:
                            data["attendanceCount"] as? Int ?? 0,

                        setupCount:
                            data["setupCount"] as? Int ?? 0,

                        monthlyAttendanceCount:
                            monthlyAttendanceCounts[
                                document.documentID,
                                default: 0
                            ],

                        monthlySetupCount:
                            monthlySetupCounts[
                                document.documentID,
                                default: 0
                            ],

                        monthlyChampionCount:
                            data["monthlyChampionCount"] as? Int ?? 0,

                        mvpCount:
                            data["mvpCount"] as? Int ?? 0,

                        profileImageBase64:
                            data["profileImageBase64"] as? String ?? "",

                        dominantHand:
                            data["dominantHand"] as? String ?? "",

                        badmintonStartAge:
                            data["badmintonStartAge"] as? Int ?? 0,

                        badmintonYears:
                            data["badmintonYears"] as? Int ?? 0,

                        racket:
                            data["racket"] as? String ?? "",

                        stringName:
                            data["stringName"] as? String ?? "",

                        tension:
                            data["tension"] as? String ?? "",

                        playStyle:
                            data["playStyle"] as? String ?? "",

                        favoriteShot:
                            data["favoriteShot"] as? String ?? "",

                        comment:
                            data["comment"] as? String ?? "",

                        role: MemberRole(
                            rawValue:
                                data["role"] as? String ?? ""
                        ) ?? .member,

                        isAdmin:
                            data["isAdmin"] as? Bool ?? false,

                        isActive: isActive,

                        gender: Gender(
                            rawValue:
                                data["gender"] as? String ?? ""
                        ) ?? .male,

                        level: MemberLevel(
                            rawValue:
                                data["level"] as? String ?? ""
                        ) ?? .beginner
                    )
                }

                DispatchQueue.main.async {
                    members = loadedMembers
                    isLoading = false
                }
            }
    }

    private func currentMonthText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
    }
}

// MARK: - ランキングメンバー詳細

struct RankingMemberProfileView: View {
    let member: RankingMember

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileImageView(
                    imageBase64: member.profileImageBase64,
                    size: 130
                )

                Text(member.name)
                    .font(.largeTitle)
                    .bold()

                if currentUserIsAdmin {
                    Text(member.level.rawValue)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                recordCard

                badmintonProfileCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recordCard: some View {
        VStack(spacing: 16) {
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
                title: "今月参加",
                value: "\(member.monthlyAttendanceCount)回"
            )

            Divider()

            profileRow(
                title: "今月設営",
                value: "\(member.monthlySetupCount)回"
            )

            Divider()

            profileRow(
                title: "累計参加",
                value: "\(member.attendanceCount)回"
            )

            Divider()

            profileRow(
                title: "累計設営",
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var badmintonProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "バドミントンプロフィール",
                systemImage: "figure.badminton"
            )
            .font(.title2)
            .bold()
            .foregroundStyle(.blue)

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

            if !member.favoriteShot.isEmpty {
                Divider()

                profileRow(
                    title: "得意ショット",
                    value: member.favoriteShot
                )
            }

            if !member.dominantHand.isEmpty {
                Divider()

                profileRow(
                    title: "利き手",
                    value: member.dominantHand
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
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func profileRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .bold()
        }
    }
}

#Preview {
    NavigationStack {
        RankingView()
    }
}
