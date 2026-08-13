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

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false
    
    @State private var members: [RankingMember] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    @State private var selectedRankingType: RankingType = .point
    @State private var isSavingHallOfFame = false
    @State private var hallOfFameMessage = ""
    @State private var showHallOfFameAlert = false

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
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.indigo.opacity(0.92),
                    Color.purple.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    rankingHeader
                    rankingTypePicker

                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.25)
                                .tint(.white)

                            Text("ランキングを集計中...")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 64)

                    } else if !errorMessage.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.yellow)

                            Text(errorMessage)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)

                    } else if sortedMembers.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.white.opacity(0.72))

                            Text("ランキング対象のメンバーがいません")
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)

                    } else {
                        if let myRank {
                            myRankingCard(rank: myRank)
                        }

                        rankingList

                        if currentUserIsAdmin {
                            hallOfFameSaveSection
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("ランキング")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadRanking()
        }
    }

    // MARK: - ヘッダー

    private var rankingHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("PREMIUM RANKING")
                        .font(.caption2)
                        .fontWeight(.black)
                        .tracking(2.2)
                        .foregroundStyle(.yellow)

                    Text("月間ランキング")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(currentMonthText())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: .yellow.opacity(0.5), radius: 18)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text(rankingDescription)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.76))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.45),
                                    .yellow.opacity(0.35),
                                    .purple.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.26), radius: 18, y: 10)
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
        HStack(spacing: 8) {
            ForEach(RankingType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedRankingType = type
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 17, weight: .bold))

                        Text(type.rawValue)
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(
                        selectedRankingType == type
                            ? Color.black
                            : Color.white.opacity(0.82)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if selectedRankingType == type {
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.white.opacity(0.10)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 自分の順位

    private func myRankingCard(rank: Int) -> some View {
        let member = sortedMembers.first {
            $0.id == currentUserId
        }

        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: .blue.opacity(0.5), radius: 14)

                Image(systemName: "person.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR POSITION")
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                    .foregroundStyle(.cyan)

                Text("現在 \(rank)位")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
            }

            Spacer()

            if let member {
                Text(rankingValueText(member))
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.8), .blue.opacity(0.55), .purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(color: .blue.opacity(0.22), radius: 16, y: 8)
    }

    // MARK: - ランキング一覧

    private var rankingList: some View {
        VStack(spacing: 12) {
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
            }
        }
    }

    private func rankingRow(
        rank: Int,
        member: RankingMember
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rankBadgeGradient(rank))
                    .frame(width: 48, height: 48)
                    .shadow(color: rankColor(rank).opacity(0.38), radius: 10)

                if rank <= 3 {
                    Text(rankIcon(rank))
                        .font(.system(size: 27))
                } else {
                    Text("\(rank)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
            }

            ProfileImageView(
                imageBase64: member.profileImageBase64,
                size: 54
            )
            .overlay {
                Circle()
                    .stroke(
                        member.id == currentUserId
                            ? Color.cyan
                            : Color.white.opacity(0.28),
                        lineWidth: 2
                    )
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(member.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    if member.id == currentUserId {
                        Text("YOU")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.cyan)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                }

                Text(rankingSubText(member))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(rankingValueText(member))
                    .font(.title3.weight(.black))
                    .foregroundStyle(rankColor(rank))

                Text("\(rank)位")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    member.id == currentUserId
                        ? Color.blue.opacity(0.24)
                        : Color.white.opacity(rank <= 3 ? 0.15 : 0.09)
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    member.id == currentUserId
                        ? Color.cyan.opacity(0.7)
                        : rankColor(rank).opacity(rank <= 3 ? 0.42 : 0.14),
                    lineWidth: member.id == currentUserId ? 1.4 : 1
                )
        }
        .shadow(
            color: rank <= 3
                ? rankColor(rank).opacity(0.16)
                : .black.opacity(0.12),
            radius: 12,
            y: 7
        )
    }

    private func rankBadgeGradient(_ rank: Int) -> LinearGradient {
        let colors: [Color]

        switch rank {
        case 1:
            colors = [.yellow, .orange]
        case 2:
            colors = [.white, .gray]
        case 3:
            colors = [.orange, .brown]
        default:
            colors = [.indigo, .purple]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            return Color.blue.opacity(0.18)
        }

        switch rank {
        case 1:
            return Color.orange.opacity(0.16)
        case 2:
            return Color.gray.opacity(0.10)
        case 3:
            return Color.brown.opacity(0.10)
        default:
            return Color.clear
        }
    }

    // MARK: - 月間表彰保存

    private var hallOfFameSaveSection: some View {
        VStack(spacing: 12) {
            Button {
                saveMonthlyHallOfFame()
            } label: {
                HStack(spacing: 10) {
                    if isSavingHallOfFame {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                    }

                    Text(
                        isSavingHallOfFame
                            ? "保存中..."
                            : "今月の結果を殿堂入り"
                    )
                    .font(.headline)
                    .bold()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange,
                            Color.purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
            }
            .buttonStyle(.plain)
            .disabled(
                isSavingHallOfFame
                || members.isEmpty
            )

            Text("同じ月は一度だけ保存できます")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.top, 4)
        .alert(
            "Hall of Fame",
            isPresented: $showHallOfFameAlert
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(hallOfFameMessage)
        }
    }

    private func saveMonthlyHallOfFame() {
        guard !members.isEmpty else {
            hallOfFameMessage =
                "保存できるランキングデータがありません"
            showHallOfFameAlert = true
            return
        }

        isSavingHallOfFame = true

        let monthKey = currentMonthKey()

        db.collection("hallOfFame")
            .whereField(
                "month",
                isEqualTo: monthKey
            )
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    DispatchQueue.main.async {
                        isSavingHallOfFame = false
                        hallOfFameMessage =
                            "保存確認に失敗しました\n"
                            + error.localizedDescription
                        showHallOfFameAlert = true
                    }
                    return
                }

                if let documents = snapshot?.documents,
                   !documents.isEmpty {
                    DispatchQueue.main.async {
                        isSavingHallOfFame = false
                        hallOfFameMessage =
                            "\(currentMonthText())はすでに殿堂入り済みです"
                        showHallOfFameAlert = true
                    }
                    return
                }

                guard
                    let pointKing =
                        members.max(
                            by: {
                                $0.monthlyPoint
                                < $1.monthlyPoint
                            }
                        ),
                    let attendanceKing =
                        members.max(
                            by: {
                                $0.monthlyAttendanceCount
                                < $1.monthlyAttendanceCount
                            }
                        ),
                    let setupKing =
                        members.max(
                            by: {
                                $0.monthlySetupCount
                                < $1.monthlySetupCount
                            }
                        )
                else {
                    DispatchQueue.main.async {
                        isSavingHallOfFame = false
                        hallOfFameMessage =
                            "月間王者を集計できませんでした"
                        showHallOfFameAlert = true
                    }
                    return
                }

                let pointRanking =
                    members.sorted {
                        if $0.monthlyPoint
                            == $1.monthlyPoint {
                            return
                                $0.name
                                .localizedStandardCompare(
                                    $1.name
                                )
                                == .orderedAscending
                        }

                        return
                            $0.monthlyPoint
                            > $1.monthlyPoint
                    }

                let second =
                    pointRanking.indices.contains(1)
                        ? pointRanking[1]
                        : nil

                let third =
                    pointRanking.indices.contains(2)
                        ? pointRanking[2]
                        : nil

                let data: [String: Any] = [
                    "month": monthKey,

                    "championName":
                        pointKing.name,
                    "championPoint":
                        pointKing.monthlyPoint,

                    "secondName":
                        second?.name
                        ?? "",
                    "secondPoint":
                        second?.monthlyPoint
                        ?? 0,

                    "thirdName":
                        third?.name
                        ?? "",
                    "thirdPoint":
                        third?.monthlyPoint
                        ?? 0,

                    "pointKingName":
                        pointKing.name,
                    "pointKingPoint":
                        pointKing.monthlyPoint,

                    "attendanceKingName":
                        attendanceKing.name,
                    "attendanceKingCount":
                        attendanceKing
                            .monthlyAttendanceCount,

                    "setupKingName":
                        setupKing.name,
                    "setupKingCount":
                        setupKing
                            .monthlySetupCount,

                    "createdAt":
                        FieldValue.serverTimestamp()
                ]

                db.collection("hallOfFame")
                    .addDocument(data: data) {
                        saveError in

                        DispatchQueue.main.async {
                            isSavingHallOfFame = false

                            if let saveError {
                                hallOfFameMessage =
                                    "殿堂入りの保存に失敗しました\n"
                                    + saveError
                                        .localizedDescription
                            } else {
                                hallOfFameMessage =
                                    "\(currentMonthText())の結果を殿堂入りしました！"
                            }

                            showHallOfFameAlert = true
                        }
                    }
            }
    }

    private func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.locale =
            Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM"

        return formatter.string(
            from: Date()
        )
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
                    .foregroundStyle(.white)

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
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.indigo.opacity(0.88),
                    Color.purple.opacity(0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
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
