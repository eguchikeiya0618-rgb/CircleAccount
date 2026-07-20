import SwiftUI
import FirebaseFirestore

// MARK: - Hall of Fame画面

struct HallOfFameView: View {
    private let db = Firestore.firestore()

    @State private var records: [HallOfFameRecord] = []
    @State private var memberImages: [String: String] = [:]
    @State private var isLoading = true
    @State private var errorMessage = ""

    // MARK: - 集計結果

    private var validRecords: [HallOfFameRecord] {
        records.filter {
            !$0.pointKingName.isEmpty
            || !$0.championName.isEmpty
        }
    }

    private var latestRecord: HallOfFameRecord? {
        validRecords.first
    }

    private var mostPointWins: HallOfFameCountRecord {
        calculateMostWins {
            $0.displayPointKingName
        }
    }

    private var mostAttendanceWins: HallOfFameCountRecord {
        calculateMostWins {
            $0.attendanceKingName
        }
    }

    private var mostSetupWins: HallOfFameCountRecord {
        calculateMostWins {
            $0.setupKingName
        }
    }

    private var highestPointRecord: HallOfFameRecord? {
        validRecords.max {
            $0.displayPointKingPoint
                < $1.displayPointKingPoint
        }
    }

    private var currentPointKingStreak: HallOfFameStreakRecord {
        calculateCurrentPointKingStreak()
    }

    private var longestPointKingStreak: HallOfFameStreakRecord {
        calculateLongestPointKingStreak()
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            HallOfFameAmbientBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView {
                LazyVStack(spacing: 18) {
                    hallOfFameHeader

                    permanentRecordsSection

                    monthlyHistorySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("HALL OF FAME")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRecords()
        }
    }

    // MARK: - ローディング

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.orange)

                Text("殿堂記録を読み込み中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
        }
    }

    // MARK: - ヘッダー

    private var hallOfFameHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow,
                                Color.orange,
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)

                Circle()
                    .stroke(
                        Color.white.opacity(0.68),
                        lineWidth: 2
                    )
                    .frame(width: 92, height: 92)

                Text("👑")
                    .font(.system(size: 60))
            }
            .shadow(
                color: Color.orange.opacity(0.35),
                radius: 22,
                x: 0,
                y: 10
            )

            VStack(spacing: 5) {
                Text("SiRiUS HALL OF FAME")
                    .font(
                        .system(
                            size: 27,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.orange,
                                Color.purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("歴代チャンピオン・永久記録")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if let latestRecord {
                HStack(spacing: 9) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)

                    Text("最新王者")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))

                    Text(latestRecord.displayPointKingName)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)

                    Spacer()

                    if currentPointKingStreak.count >= 2 {
                        Text("\(currentPointKingStreak.count)連覇中")
                            .font(
                                .system(
                                    size: 9,
                                    weight: .black
                                )
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Color.yellow.opacity(0.18)
                            )
                            .foregroundStyle(.yellow)
                            .clipShape(Capsule())
                    }
                    
                    Text(
                        formattedMonth(latestRecord.month)
                    )
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 0.17,
                                green: 0.04,
                                blue: 0.30
                            ),
                            Color(
                                red: 0.45,
                                green: 0.10,
                                blue: 0.28
                            ),
                            Color.orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 17)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(
                            Color.yellow.opacity(0.45),
                            lineWidth: 1
                        )
                }
                .padding(.top, 7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
    }

    // MARK: - 永久記録

    private var permanentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle(
                icon: "infinity",
                title: "永久記録",
                subtitle: "ALL-TIME RECORDS",
                color: .orange
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                permanentRecordCard(
                    icon: "👑",
                    title: "最多ポイント王",
                    name: mostPointWins.name,
                    value:
                        mostPointWins.count > 0
                            ? "\(mostPointWins.count)回"
                            : "記録なし",
                    color: .orange
                )

                permanentRecordCard(
                    icon: "⚡️",
                    title: "歴代最高ポイント",
                    name:
                        highestPointRecord?
                            .displayPointKingName
                        ?? "記録なし",
                    value:
                        highestPointRecord == nil
                            ? "記録なし"
                            : "\(highestPointRecord?.displayPointKingPoint ?? 0)pt",
                    color: .purple
                )

                permanentRecordCard(
                    icon: "🏸",
                    title: "最多参加王",
                    name: mostAttendanceWins.name,
                    value:
                        mostAttendanceWins.count > 0
                            ? "\(mostAttendanceWins.count)回"
                            : "記録なし",
                    color: .blue
                )

                permanentRecordCard(
                    icon: "🔨",
                    title: "最多設営王",
                    name: mostSetupWins.name,
                    value:
                        mostSetupWins.count > 0
                            ? "\(mostSetupWins.count)回"
                            : "記録なし",
                    color: .green
                )
            }
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.18),
                                    Color.purple.opacity(0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Text("🔥")
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("歴代最長連覇")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(longestPointKingStreak.name)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)

                    if longestPointKingStreak.count >= 2 {
                        Text(
                            "\(longestPointKingStreak.count)か月連続ポイント王"
                        )
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.orange)
                    } else {
                        Text("連覇記録なし")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if longestPointKingStreak.count >= 2 {
                    Text("\(longestPointKingStreak.count)連覇")
                        .font(.headline)
                        .bold()
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
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
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(
                Color(.systemBackground)
                    .opacity(0.83)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 17)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(
                        Color.orange.opacity(0.14),
                        lineWidth: 1
                    )
            }
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("殿堂入り記録")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(validRecords.count)か月分")
                        .font(.headline)
                        .bold()
                }

                Spacer()

                Text("永久保存")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Color.orange.opacity(0.12)
                    )
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(
                Color(.systemBackground)
                    .opacity(0.80)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 17)
            )
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.11),
                    Color.purple.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 27)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 27)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.30),
                            Color.purple.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
    }

    private func permanentRecordCard(
        icon: String,
        title: String,
        name: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.system(size: 31))

                Spacer()

                Circle()
                    .fill(color.opacity(0.65))
                    .frame(width: 7, height: 7)
                    .shadow(
                        color: color,
                        radius: 5
                    )
            }

            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(name.isEmpty ? "記録なし" : name)
                .font(.headline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(color)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            Color(.systemBackground)
                .opacity(0.88)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    color.opacity(0.13),
                    lineWidth: 1
                )
        }
    }

    // MARK: - 月別記録一覧

    private var monthlyHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                icon: "trophy.fill",
                title: "歴代月間表彰",
                subtitle: "MONTHLY CHAMPIONS",
                color: .yellow
            )

            if !errorMessage.isEmpty {
                errorCard

            } else if validRecords.isEmpty {
                emptyHistoryCard

            } else {
                ForEach(
                    Array(validRecords.enumerated()),
                    id: \.element.id
                ) { index, record in
                    NavigationLink {
                        HallOfFameDetailView(
                            record: record,
                            memberImages: memberImages
                        )
                    } label: {
                        monthlyRecordCard(
                            record,
                            isLatest: index == 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var errorCard: some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .font(.system(size: 38))
            .foregroundStyle(.orange)

            Text("記録の読み込みに失敗しました")
                .font(.headline)

            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("再読み込み") {
                loadRecords()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 18)
        .background(Color(.systemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
    }

    private var emptyHistoryCard: some View {
        VStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 48))

            Text("まだ殿堂入り記録がありません")
                .font(.headline)

            Text(
                "管理者がランキング画面から\n今月の結果を保存すると表示されます"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .background(
            Color(.systemBackground)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
    }
    private func monthlyRecordCard(
        _ record: HallOfFameRecord,
        isLatest: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.30),
                                        Color.orange.opacity(0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Text(isLatest ? "👑" : "🏆")
                            .font(.system(size: 27))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            formattedMonth(record.month)
                        )
                        .font(.title3)
                        .bold()

                        Text("MONTHLY AWARDS")
                            .font(
                                .system(
                                    size: 8,
                                    weight: .black
                                )
                            )
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if isLatest {
                        Text("LATEST")
                            .font(
                                .system(
                                    size: 8,
                                    weight: .black
                                )
                            )
                            .tracking(0.8)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Color.orange.opacity(0.14)
                            )
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            monthlyAwardRow(
                icon: "👑",
                title: "ポイント王",
                subtitle: "POINT KING",
                name: record.displayPointKingName,
                value: "\(record.displayPointKingPoint)pt",
                color: .orange,
                memberId: record.displayPointKingId
            )
            

            monthlyAwardRow(
                icon: "🏸",
                title: "参加王",
                subtitle: "ATTENDANCE KING",
                name: record.attendanceKingName,
                value:
                    record.attendanceKingName.isEmpty
                        ? "記録なし"
                        : "\(record.attendanceKingCount)回",
                color: .blue,
                memberId: ""
            )

            monthlyAwardRow(
                icon: "🔨",
                title: "設営王",
                subtitle: "SETUP KING",
                name: record.setupKingName,
                value:
                    record.setupKingName.isEmpty
                        ? "記録なし"
                        : "\(record.setupKingCount)回",
                color: .green,
                memberId: ""
            )
            monthlyAwardRow(
                icon: "⭐️",
                title: "月間MVP",
                subtitle: "MONTHLY MVP",
                name: record.mvpName,
                value:
                    record.mvpName.isEmpty
                        ? "記録なし"
                        : "MVP",
                color: .yellow,
                memberId: record.mvpId
            )

            if !record.secondName.isEmpty
                || !record.thirdName.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 11) {
                    Text("ポイントランキング TOP 3")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    compactRankingRow(
                        icon: "🥇",
                        name: record.displayPointKingName,
                        point: record.displayPointKingPoint
                    )

                    if !record.secondName.isEmpty {
                        compactRankingRow(
                            icon: "🥈",
                            name: record.secondName,
                            point: record.secondPoint
                        )
                    }

                    if !record.thirdName.isEmpty {
                        compactRankingRow(
                            icon: "🥉",
                            name: record.thirdName,
                            point: record.thirdPoint
                        )
                    }
                }
            }
        }
        .padding(18)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(
                            isLatest ? 0.14 : 0.07
                        ),
                        Color.orange.opacity(
                            isLatest ? 0.07 : 0.03
                        ),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        Color.yellow.opacity(
                            isLatest ? 0.11 : 0.05
                        )
                    )
                    .frame(width: 135, height: 135)
                    .offset(x: 155, y: -55)
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(
                                isLatest ? 0.42 : 0.18
                            ),
                            Color.orange.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isLatest ? 1.4 : 1
                )
        }
        .shadow(
            color: Color.orange.opacity(
                isLatest ? 0.11 : 0.04
            ),
            radius: isLatest ? 13 : 7,
            x: 0,
            y: 6
        )
    }

    private func monthlyAwardRow(
        icon: String,
        title: String,
        subtitle: String,
        name: String,
        value: String,
        color: Color,
        memberId: String = ""
    ) -> some View {
        let imageBase64 = profileImage(
            memberId: memberId,
            memberName: name
        )

        return HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(color.opacity(0.13))
                    .frame(width: 50, height: 50)

                if !name.isEmpty && !imageBase64.isEmpty {
                    ProfileImageView(
                        imageBase64: imageBase64,
                        size: 42
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                color.opacity(0.75),
                                lineWidth: 1.5
                            )
                    }
                } else {
                    Text(icon)
                        .font(.system(size: 27))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(
                        .system(
                            size: 8,
                            weight: .black
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    name.isEmpty
                        ? "記録なし"
                        : name
                )
                .font(.headline)
                .bold()
                .lineLimit(1)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            Color(.systemBackground)
                .opacity(0.78)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 17)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(
                    color.opacity(0.11),
                    lineWidth: 1
                )
        }
    }

    private func compactRankingRow(
        icon: String,
        name: String,
        point: Int
    ) -> some View {
        HStack(spacing: 11) {
            Text(icon)
                .font(.title3)
                .frame(width: 31)

            Text(name)
                .font(.subheadline)
                .bold()
                .lineLimit(1)

            Spacer()

            Text("\(point)pt")
                .font(.subheadline)
                .bold()
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .opacity(0.72)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - 共通見出し

    private func sectionTitle(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.13))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .bold()

                Text(subtitle)
                    .font(
                        .system(
                            size: 8,
                            weight: .black
                        )
                    )
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - 永久記録集計

    private func calculateMostWins(
        nameProvider: (HallOfFameRecord) -> String
    ) -> HallOfFameCountRecord {
        var counts: [String: Int] = [:]

        for record in validRecords {
            let name = nameProvider(record)
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !name.isEmpty else {
                continue
            }

            counts[name, default: 0] += 1
        }

        guard let winner = counts.max(
            by: { first, second in
                if first.value == second.value {
                    return first.key
                        .localizedStandardCompare(
                            second.key
                        ) == .orderedDescending
                }

                return first.value < second.value
            }
        ) else {
            return HallOfFameCountRecord(
                name: "記録なし",
                count: 0
            )
        }

        return HallOfFameCountRecord(
            name: winner.key,
            count: winner.value
        )
    }
    // MARK: - 連覇記録集計

    private func calculateCurrentPointKingStreak()
        -> HallOfFameStreakRecord {

        guard
            let firstRecord = validRecords.first
        else {
            return HallOfFameStreakRecord(
                name: "記録なし",
                count: 0
            )
        }

        let championName =
            firstRecord.displayPointKingName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !championName.isEmpty else {
            return HallOfFameStreakRecord(
                name: "記録なし",
                count: 0
            )
        }

        var streakCount = 0

        for record in validRecords {
            let recordName =
                record.displayPointKingName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            if recordName == championName {
                streakCount += 1
            } else {
                break
            }
        }

        return HallOfFameStreakRecord(
            name: championName,
            count: streakCount
        )
    }

    private func calculateLongestPointKingStreak()
        -> HallOfFameStreakRecord {

        guard !validRecords.isEmpty else {
            return HallOfFameStreakRecord(
                name: "記録なし",
                count: 0
            )
        }

        var longestName = ""
        var longestCount = 0

        var currentName = ""
        var currentCount = 0

        // 古い月から新しい月の順に確認
        for record in validRecords.reversed() {
            let name =
                record.displayPointKingName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard !name.isEmpty else {
                currentName = ""
                currentCount = 0
                continue
            }

            if name == currentName {
                currentCount += 1
            } else {
                currentName = name
                currentCount = 1
            }

            if currentCount > longestCount {
                longestName = currentName
                longestCount = currentCount
            }
        }

        return HallOfFameStreakRecord(
            name:
                longestName.isEmpty
                    ? "記録なし"
                    : longestName,
            count: longestCount
        )
    }
    // MARK: - Firebase

    private func loadRecords() {
        isLoading = true
        errorMessage = ""

        db.collection("hallOfFame")
            .order(
                by: "createdAt",
                descending: true
            )
            .getDocuments { snapshot, error in
                if let error {
                    DispatchQueue.main.async {
                        records = []
                        isLoading = false
                        errorMessage =
                            "殿堂記録の取得に失敗しました\n"
                            + error.localizedDescription
                    }
                    return
                }

                var loadedRecords: [HallOfFameRecord] = []

                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()

                        let record = HallOfFameRecord(
                            id: document.documentID,

                            month:
                                data["month"] as? String
                                ?? "",

                            championName:
                                data["championName"] as? String
                                ?? "",

                            championPoint:
                                data["championPoint"] as? Int
                                ?? 0,

                            secondName:
                                data["secondName"] as? String
                                ?? "",

                            secondPoint:
                                data["secondPoint"] as? Int
                                ?? 0,

                            thirdName:
                                data["thirdName"] as? String
                                ?? "",

                            thirdPoint:
                                data["thirdPoint"] as? Int
                                ?? 0,

                            pointKingName:
                                data["pointKingName"] as? String
                                ?? "",

                            pointKingPoint:
                                data["pointKingPoint"] as? Int
                                ?? 0,
                            pointKingId:
                                data["pointKingId"] as? String
                                ?? data["championId"] as? String
                                ?? "",
                            attendanceKingName:
                                data["attendanceKingName"] as? String
                                ?? "",

                            attendanceKingCount:
                                data["attendanceKingCount"] as? Int
                                ?? 0,

                            setupKingName:
                                data["setupKingName"] as? String
                                ?? "",

                            setupKingCount:
                                data["setupKingCount"] as? Int
                                ?? 0,

                            mvpId:
                                data["mvpId"] as? String
                                ?? "",

                            mvpName:
                                data["mvpName"] as? String
                                ?? "",

                            mvpPoint:
                                data["mvpPoint"] as? Int
                                ?? 0
                        )
                        loadedRecords.append(record)
                    }
                }

                DispatchQueue.main.async {
                    records = loadedRecords.sorted {
                        first,
                        second in

                        first.month > second.month
                    }
                    loadMemberImages()
                    isLoading = false
                }
            }
    }

   
    private func loadMemberImages() {
        db.collection("members")
            .getDocuments { snapshot, error in
                if let error {
                    print(
                        "プロフィール画像取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                var loadedImages: [String: String] = [:]

                snapshot?.documents.forEach { document in
                    let data = document.data()

                    let imageBase64 =
                        data["profileImageBase64"] as? String
                        ?? ""

                    loadedImages[document.documentID] =
                        imageBase64
                    let memberName = data["name"] as? String ?? ""

                    if !memberName.isEmpty {
                        loadedImages[memberName] = imageBase64
                    }
                }

                DispatchQueue.main.async {
                    memberImages = loadedImages

                    print(
                        "プロフィール画像取得件数: \(loadedImages.count)"
                    )
                }
            }
    }
    private func profileImage(
        memberId: String,
        memberName: String
    ) -> String {
        if !memberId.isEmpty,
           let image = memberImages[memberId],
           !image.isEmpty {
            return image
        }

        return memberImages[memberName] ?? ""
    }
    
    // MARK: - 日付表示

    private func formattedMonth(
        _ month: String
    ) -> String {
        guard !month.isEmpty else {
            return "対象月不明"
        }

        let inputFormatter = DateFormatter()
        inputFormatter.locale =
            Locale(identifier: "ja_JP")
        inputFormatter.dateFormat = "yyyy-MM"

        let outputFormatter = DateFormatter()
        outputFormatter.locale =
            Locale(identifier: "ja_JP")
        outputFormatter.dateFormat = "yyyy年M月"

        guard
            let date =
                inputFormatter.date(
                    from: month
                )
        else {
            return month
        }

        return outputFormatter.string(
            from: date
        )
    }
}

// MARK: - Hall of Fame記録モデル

struct HallOfFameRecord: Identifiable {
    let id: String
    let month: String

    // 以前から保存している互換用データ
    let championName: String
    let championPoint: Int
    

    let secondName: String
    let secondPoint: Int

    let thirdName: String
    let thirdPoint: Int

    // 新しい月間表彰データ
    let pointKingName: String
    let pointKingPoint: Int
    let pointKingId: String

    let attendanceKingName: String
    let attendanceKingCount: Int

    let setupKingName: String
    let setupKingCount: Int
    
    let mvpId: String
    let mvpName: String
    let mvpPoint: Int

    var displayPointKingName: String {
        if !pointKingName.isEmpty {
            return pointKingName
        }

        return championName
    }

    var displayPointKingPoint: Int {
        if pointKingPoint > 0 {
            return pointKingPoint
        }

        return championPoint
    }
    var displayPointKingId: String {
        if !pointKingId.isEmpty {
            return pointKingId
        }

        return ""
    }
}
// MARK: - 最多受賞記録

struct HallOfFameCountRecord {
    let name: String
    let count: Int
}
// MARK: - 連覇記録

struct HallOfFameStreakRecord {
    let name: String
    let count: Int
}
// MARK: - 背景演出

private struct HallOfFameAmbientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(
                        Color.orange.opacity(0.06)
                    )
                    .frame(
                        width: 280,
                        height: 280
                    )
                    .blur(radius: 24)
                    .offset(
                        x:
                            CGFloat(
                                sin(time * 0.20)
                            ) * 95,
                        y: -280
                    )

                Circle()
                    .fill(
                        Color.purple.opacity(0.055)
                    )
                    .frame(
                        width: 260,
                        height: 260
                    )
                    .blur(radius: 26)
                    .offset(
                        x:
                            CGFloat(
                                cos(time * 0.17)
                            ) * 115,
                        y: 180
                    )

                Circle()
                    .fill(
                        Color.yellow.opacity(0.045)
                    )
                    .frame(
                        width: 220,
                        height: 220
                    )
                    .blur(radius: 25)
                    .offset(
                        x:
                            CGFloat(
                                sin(time * 0.14)
                            ) * 125,
                        y: 620
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        HallOfFameView()
    }
}
