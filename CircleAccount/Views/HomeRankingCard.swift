import SwiftUI

// MARK: - ホームランキング表示用データ

struct HomeRankingEntry: Identifiable, Equatable {
    let id: String
    let name: String

    // 今月獲得ポイント
    let monthlyPoint: Int

    // 累計ポイント
    let totalPoint: Int

    let imageBase64: String
}

// MARK: - ホーム用「自分の順位」カード

struct HomeRankingCard: View {
    let entries: [HomeRankingEntry]
    let currentUserId: String
    let currentUserRank: Int
    let pointToNextRank: Int

    @State private var glowAnimation = false
    @State private var shimmerOffset: CGFloat = -1.4

    private var sortedEntries: [HomeRankingEntry] {
        entries.sorted {
            if $0.monthlyPoint == $1.monthlyPoint {
                return $0.name.localizedStandardCompare(
                    $1.name
                ) == .orderedAscending
            }

            return $0.monthlyPoint > $1.monthlyPoint
        }
    }

    private var currentUserEntry: HomeRankingEntry? {
        sortedEntries.first {
            $0.id == currentUserId
        }
    }

    private var currentMonthlyPoint: Int {
        currentUserEntry?.monthlyPoint ?? 0
    }

    private var currentTotalPoint: Int {
        currentUserEntry?.totalPoint ?? 0
    }

    private var currentName: String {
        currentUserEntry?.name ?? "あなた"
    }

    private var rankingMessage: String {
        guard currentUserRank > 0 else {
            return "ランキング集計中です"
        }

        if currentUserRank == 1 {
            return "現在トップです！このまま1位を守ろう"
        }

        if pointToNextRank > 0 {
            return "あと\(pointToNextRank)ptで\(currentUserRank - 1)位"
        }

        return "次の順位を目指してポイントを集めよう"
    }

    private var rankAccentColor: Color {
        switch currentUserRank {
        case 1:
            return .yellow

        case 2:
            return Color(
                red: 0.80,
                green: 0.87,
                blue: 0.96
            )

        case 3:
            return .orange

        default:
            return .cyan
        }
    }

    private var rankIcon: String {
        switch currentUserRank {
        case 1:
            return "👑"

        case 2:
            return "🥈"

        case 3:
            return "🥉"

        default:
            return "🏆"
        }
    }

    var body: some View {
        NavigationLink {
            RankingView()
        } label: {
            VStack(spacing: 0) {
                headerSection

                Divider()
                    .overlay(
                        Color.white.opacity(0.14)
                    )
                    .padding(.horizontal, 20)

                rankingInformationSection

                Divider()
                    .overlay(
                        Color.white.opacity(0.14)
                    )
                    .padding(.horizontal, 20)

                rankingLinkSection
            }
            .background {
                cardBackground
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 28)
            )
            .overlay {
                cardBorder
            }
            .overlay {
                shimmerLayer
                    .clipShape(
                        RoundedRectangle(cornerRadius: 28)
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: rankAccentColor.opacity(
                    glowAnimation ? 0.28 : 0.12
                ),
                radius: glowAnimation ? 22 : 13,
                x: 0,
                y: 9
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        rankAccentColor.opacity(0.16)
                    )
                    .frame(
                        width: 52,
                        height: 52
                    )

                Text(rankIcon)
                    .font(.system(size: 29))
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text("MY RANKING")
                    .font(
                        .system(
                            size: 14,
                            weight: .black
                        )
                    )
                    .tracking(1.7)
                    .foregroundStyle(.white)

                Text("今月のあなたの順位")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .white.opacity(0.62)
                    )
            }

            Spacer()

            Text("LIVE")
                .font(
                    .system(
                        size: 9,
                        weight: .black
                    )
                )
                .tracking(1)
                .foregroundStyle(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Color.cyan.opacity(0.13)
                )
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            Color.cyan.opacity(0.28),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - 順位情報

    private var rankingInformationSection: some View {
        VStack(spacing: 18) {
            HStack(
                alignment: .center,
                spacing: 16
            ) {
                rankCircle

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Text(currentName)
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(rankingMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            currentUserRank == 1
                                ? Color.yellow
                                : Color.cyan
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 8)

                monthlyPointSection
            }

            if currentUserRank > 1,
               pointToNextRank > 0 {
                nextRankProgressSection
            } else if currentUserRank == 1 {
                firstPlaceMessage
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: - 今月・累計ポイント

    private var monthlyPointSection: some View {
        VStack(
            alignment: .trailing,
            spacing: 4
        ) {
            Text("\(currentMonthlyPoint)")
                .font(
                    .system(
                        size: 35,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    rankAccentColor
                )
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Text("POINT")
                .font(
                    .system(
                        size: 9,
                        weight: .black
                    )
                )
                .tracking(1.3)
                .foregroundStyle(
                    .white.opacity(0.47)
                )

            Text("THIS MONTH")
                .font(
                    .system(
                        size: 8,
                        weight: .black
                    )
                )
                .tracking(1.1)
                .foregroundStyle(
                    rankAccentColor.opacity(0.86)
                )

            Text("TOTAL \(currentTotalPoint)pt")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(
                    .white.opacity(0.58)
                )
                .padding(.top, 3)
        }
    }

    // MARK: - 順位サークル

    private var rankCircle: some View {
        ZStack {
            Circle()
                .fill(
                    rankAccentColor.opacity(0.13)
                )
                .frame(
                    width: 82,
                    height: 82
                )

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            rankAccentColor,
                            Color.white.opacity(0.80),
                            rankAccentColor.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(
                    width: 76,
                    height: 76
                )

            VStack(spacing: 0) {
                if currentUserRank > 0 {
                    Text("\(currentUserRank)")
                        .font(
                            .system(
                                size: 31,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)

                    Text("位")
                        .font(
                            .system(
                                size: 11,
                                weight: .black
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                } else {
                    Text("-")
                        .font(
                            .system(
                                size: 30,
                                weight: .black
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                }
            }
        }
        .shadow(
            color: rankAccentColor.opacity(0.35),
            radius: 10
        )
    }

    // MARK: - 次順位まで

    private var nextRankProgressSection: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 7) {
                    Image(
                        systemName:
                            "arrow.up.right.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.cyan)

                    Text("NEXT RANK")
                        .font(
                            .system(
                                size: 10,
                                weight: .black
                            )
                        )
                        .tracking(1.2)
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                }

                Spacer()

                Text(
                    "あと\(pointToNextRank)ptで\(currentUserRank - 1)位"
                )
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(.cyan)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            Color.white.opacity(0.11)
                        )

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue,
                                    Color.cyan,
                                    Color.white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width:
                                geometry.size.width
                                * progressValue
                        )
                        .shadow(
                            color:
                                Color.cyan.opacity(0.55),
                            radius: 6
                        )
                }
            }
            .frame(height: 10)

            HStack {
                Text("現在 \(currentUserRank)位")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        .white.opacity(0.54)
                    )

                Spacer()

                Text("目標 \(currentUserRank - 1)位")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(
            Color.white.opacity(0.065)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.cyan.opacity(0.12),
                    lineWidth: 1
                )
        }
    }

    private var progressValue: CGFloat {
        guard pointToNextRank > 0 else {
            return 1
        }

        let value =
            1.0
            - min(
                Double(pointToNextRank) / 50.0,
                1.0
            )

        return CGFloat(
            max(value, 0.08)
        )
    }

    // MARK: - 1位専用表示

    private var firstPlaceMessage: some View {
        HStack(spacing: 11) {
            Text("👑")
                .font(.system(size: 25))

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("KING STATUS")
                    .font(
                        .system(
                            size: 10,
                            weight: .black
                        )
                    )
                    .tracking(1.2)
                    .foregroundStyle(
                        .yellow.opacity(0.78)
                    )

                Text("現在ランキング1位")
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundStyle(.yellow)

                Text("ポイント王の座を守りましょう！")
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.62)
                    )
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.yellow)
        }
        .padding(14)
        .background(
            Color.yellow.opacity(0.09)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.yellow.opacity(0.18),
                    lineWidth: 1
                )
        }
    }

    // MARK: - ランキングへのリンク

    private var rankingLinkSection: some View {
        HStack(spacing: 10) {
            Image(
                systemName: "list.number"
            )
            .font(.subheadline)
            .foregroundStyle(.cyan)

            Text("ランキングを見る")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            Text("POINT・ATTENDANCE・SETUP")
                .font(
                    .system(
                        size: 8,
                        weight: .bold
                    )
                )
                .tracking(0.4)
                .foregroundStyle(
                    .white.opacity(0.48)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Image(
                systemName: "chevron.right"
            )
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.cyan)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.white.opacity(0.045)
        )
    }

    // MARK: - 背景

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 0.025,
                                green: 0.055,
                                blue: 0.15
                            ),
                            Color(
                                red: 0.04,
                                green: 0.16,
                                blue: 0.36
                            ),
                            Color(
                                red: 0.06,
                                green: 0.31,
                                blue: 0.53
                            ),
                            Color(
                                red: 0.09,
                                green: 0.08,
                                blue: 0.26
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    rankAccentColor.opacity(
                        glowAnimation ? 0.20 : 0.08
                    )
                )
                .frame(
                    width: 220,
                    height: 220
                )
                .blur(radius: 23)
                .offset(
                    x: 155,
                    y: -130
                )

            Circle()
                .fill(
                    Color.purple.opacity(0.12)
                )
                .frame(
                    width: 180,
                    height: 180
                )
                .blur(radius: 20)
                .offset(
                    x: -155,
                    y: 150
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 28)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.64),
                        rankAccentColor.opacity(0.55),
                        Color.cyan.opacity(0.34),
                        Color.white.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }

    private var shimmerLayer: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.03),
                rankAccentColor.opacity(0.14),
                Color.white.opacity(0.30),
                rankAccentColor.opacity(0.10),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 105)
        .rotationEffect(.degrees(-18))
        .offset(
            x: shimmerOffset * 350
        )
        .blendMode(.screen)
    }

    // MARK: - アニメーション

    private func startAnimations() {
        withAnimation(
            .easeInOut(duration: 1.4)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            glowAnimation = true
        }

        withAnimation(
            .linear(duration: 3.4)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            shimmerOffset = 1.4
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        ZStack {
            Color.black
                .ignoresSafeArea()

            HomeRankingCard(
                entries: [
                    HomeRankingEntry(
                        id: "member1",
                        name: "けーや",
                        monthlyPoint: 85,
                        totalPoint: 687,
                        imageBase64: ""
                    ),
                    HomeRankingEntry(
                        id: "member2",
                        name: "こーちゃん",
                        monthlyPoint: 70,
                        totalPoint: 450,
                        imageBase64: ""
                    ),
                    HomeRankingEntry(
                        id: "member3",
                        name: "ぽよ",
                        monthlyPoint: 50,
                        totalPoint: 380,
                        imageBase64: ""
                    )
                ],
                currentUserId: "member1",
                currentUserRank: 1,
                pointToNextRank: 0
            )
            .padding()
        }
    }
}
