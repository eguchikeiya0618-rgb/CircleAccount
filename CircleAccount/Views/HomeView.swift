import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false
    
    @AppStorage("testMVPName")
    private var testMVPName = ""

    @AppStorage("testMVPId")
    private var testMVPId = ""

    @State private var testMVPPoint = 0
    @State private var testMVPImageBase64 = ""

    @State private var todayActivity: Activity?
    @State private var nextActivity: Activity?

    @State private var totalMembers = 0
    @State private var totalCollected = 0
    @State private var totalUncollected = 0
    @State private var thisMonthActivities = 0

    @State private var totalPoint = 0
    @State private var memberName = ""

    @State private var latestChampionName = ""
    @State private var latestChampionPoint = 0
    @State private var latestChampionMonth = ""
    
    
    // 最新の月間MVP
    @State private var latestMVPName = ""
    @State private var latestMVPPoint = 0
    @State private var latestMVPImageBase64 = ""

    // 自分の今月ランキング
    @State private var myMonthlyRank = 0
    @State private var myMonthlyRankingPoint = 0
    @State private var activeMemberCount = 0

    @State private var latestNotice = ""
    @State private var latestNoticeDate = ""

    @State private var monthlyAttendanceCount = 0
    @State private var monthlySetupCount = 0
    @State private var monthlyEarlyAnswerCount = 0
    @State private var currentAttendanceStreak = 0
    
    @State private var rankingEntries: [HomeRankingEntry] = []

    @State private var currentUserRank = 0

    @State private var pointToNextRank = 0
    
    @State private var screenAppeared = false
    @State private var heroGlow = false
    @State private var shimmerOffset: CGFloat = -1.3
    @State private var heroShimmerOffset: CGFloat = -1.4
    @State private var logoScale: CGFloat = 0.88
    @State private var logoOpacity = 0.0
    @State private var welcomeOpacity = 0.0
    @State private var welcomeOffset: CGFloat = 12
    @State private var heroGlassSweepOffset: CGFloat = -1.6
    @State private var gachaGlow = false
    @State private var gachaSweepOffset: CGFloat = -1.4
    @State private var displayedPoint = 0

    private let mainColor = Color(
        red: 0.05,
        green: 0.11,
        blue: 0.26
    )

    private let accentColor = Color(
        red: 0.15,
        green: 0.39,
        blue: 0.92
    )

    private var memberLevel: Int {
        max(1, totalPoint / 50 + 1)
    }

    private var levelProgress: Double {
        Double(totalPoint % 50) / 50.0
    }

    private var pointToNextLevel: Int {
        let remainder = totalPoint % 50
        return remainder == 0 ? 50 : 50 - remainder
    }

    private var rankAccentColor: Color {
        if totalPoint >= 700 {
            return .cyan
        }

        if totalPoint >= 400 {
            return Color(
                red: 0.37,
                green: 0.88,
                blue: 1.0
            )
        }

        if totalPoint >= 200 {
            return .yellow
        }

        if totalPoint >= 100 {
            return .white
        }

        return .orange
    }

    private var greetingText: String {
        let hour = Calendar.current.component(
            .hour,
            from: Date()
        )

        if hour < 5 {
            return "夜更かし中ですね"
        }

        if hour < 11 {
            return "おはようございます"
        }

        if hour < 17 {
            return "こんにちは"
        }

        return "おかえりなさい"
    }

    private var displayName: String {
        memberName.isEmpty
            ? "メンバー"
            : memberName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(
                            red: 0.018,
                            green: 0.045,
                            blue: 0.12
                        ),
                        Color(
                            red: 0.035,
                            green: 0.10,
                            blue: 0.24
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                HomeAmbientBackground(
                    accentColor: rankAccentColor
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                HomeStarfieldOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView {
                    LazyVStack(spacing: 28) {
                        luxuryHeader

                        if !latestNotice.isEmpty {
                            noticeCard.homeCardEntrance()
                        }

                        activitySection.homeCardEntrance()

                        homeDashboardHero.homeCardEntrance()

                        HomeRankingCard(
                            entries: rankingEntries,
                            currentUserId: currentUserId,
                            currentUserRank: currentUserRank,
                            pointToNextRank: pointToNextRank
                        )
                        .homeCardEntrance()

                        LatestMVPHeroCard(
                            mvpName:
                                latestMVPName.isEmpty
                                    ? testMVPName
                                    : latestMVPName,
                            mvpPoint:
                                latestMVPName.isEmpty
                                    ? testMVPPoint
                                    : latestMVPPoint,
                            imageBase64:
                                latestMVPName.isEmpty
                                    ? testMVPImageBase64
                                    : latestMVPImageBase64
                        )
                        .homeCardEntrance()

                        featuredGachaCard.homeCardEntrance()

                        quickMenuSection.homeCardEntrance()

                        latestChampionCard.homeCardEntrance()

                        if currentUserIsAdmin {
                            administratorDashboard.homeCardEntrance()
                        } else {
                            memberSummaryGrid.homeCardEntrance()
                        }

                        sloganView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("HOME")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadDashboard()
                loadPoint()
                loadLatestChampion()
                loadLatestMVP()
                loadTestMVP()
                loadLatestNotice()
                loadRanking()
                startHomeAnimations()
            }
        }
    }

    @ViewBuilder
    private var activitySection: some View {
        if let todayActivity {
            todayCard(todayActivity)

            if let nextActivity {
                nextActivityCard(nextActivity)
            }
        } else if let nextActivity {
            nextActivityCard(nextActivity)
        }
    }
    // MARK: - ホーム演出

    private func startHomeAnimations() {
        guard !screenAppeared else {
            return
        }

        screenAppeared = true

        withAnimation(
            .spring(
                response: 0.65,
                dampingFraction: 0.72
            )
        ) {
            logoScale = 1
            logoOpacity = 1
        }

        withAnimation(
            .easeInOut(duration: 1.35)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            heroGlow = true
        }

        withAnimation(
            .linear(duration: 2.2)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            shimmerOffset = 1.4
        }
        withAnimation(
            .linear(duration: 3.0)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            heroShimmerOffset = 1.4
        }

        withAnimation(
            .easeOut(duration: 0.55)
                .delay(0.20)
        ) {
            welcomeOpacity = 1
            welcomeOffset = 0
        }

        withAnimation(
            .linear(duration: 3.6)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            heroGlassSweepOffset = 1.6
        }

        withAnimation(
            .easeInOut(duration: 1.15)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            gachaGlow = true
        }

        withAnimation(
            .linear(duration: 2.6)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            gachaSweepOffset = 1.5
        }

        animatePointCounter()
    }

    private func animatePointCounter() {
        displayedPoint = 0

        let target = max(totalPoint, 0)
        guard target > 0 else {
            displayedPoint = 0
            return
        }

        let steps = min(target, 36)
        let interval = 0.72 / Double(max(steps, 1))

        for step in 1...steps {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + interval * Double(step)
            ) {
                displayedPoint =
                    Int(
                        (Double(target) / Double(steps))
                        * Double(step)
                    )
            }
        }
    }

    // MARK: - ヘッダー

    private var luxuryHeader: some View {
        VStack(spacing: 4) {
            Text("SiRiUS")
                .font(
                    .system(
                        size: 45,
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundStyle(.white)
                .shadow(color: Color.cyan.opacity(0.28), radius: 14)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.90),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(-18))
                    .offset(
                        x: shimmerOffset * 180
                    )
                    .mask {
                        Text("SiRiUS")
                            .font(
                                .system(
                                    size: 45,
                                    weight: .black,
                                    design: .serif
                                )
                            )
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            Text("WELCOME BACK")
                .font(
                    .system(
                        size: 10,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(2.4)
                .foregroundStyle(accentColor.opacity(0.88))
                .opacity(welcomeOpacity)
                .offset(y: welcomeOffset)

            Text("BADMINTON CIRCLE")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(3.2)
                .foregroundStyle(accentColor)

            Text("EST. 2023.07")
                .font(.caption2)
                .bold()
                .foregroundStyle(
                    .white.opacity(0.46)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - プレイヤーダッシュボード

    private var homeDashboardHero: some View {
        VStack(spacing: 0) {
            playerGreetingSection

            Divider()
                .overlay(
                    Color.white.opacity(0.20)
                )
                .padding(.horizontal, 21)

            playerGrowthSection
        }
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 0.018,
                                    green: 0.055,
                                    blue: 0.16
                                ),
                                Color(
                                    red: 0.035,
                                    green: 0.20,
                                    blue: 0.47
                                ),
                                Color(
                                    red: 0.04,
                                    green: 0.47,
                                    blue: 0.72
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(
                        Color.cyan.opacity(
                            heroGlow ? 0.24 : 0.10
                        )
                    )
                    .frame(
                        width: 290,
                        height: 290
                    )
                    .blur(radius: 18)
                    .offset(
                        x: 165,
                        y: -145
                    )
                    .scaleEffect(
                        heroGlow ? 1.18 : 0.88
                    )

                Circle()
                    .fill(
                        Color.blue.opacity(
                            heroGlow ? 0.20 : 0.09
                        )
                    )
                    .frame(
                        width: 230,
                        height: 230
                    )
                    .blur(radius: 16)
                    .offset(
                        x: -155,
                        y: 155
                    )
                    .scaleEffect(
                        heroGlow ? 1.08 : 0.92
                    )

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.04),
                        Color.cyan.opacity(0.24),
                        Color.white.opacity(0.42),
                        Color.cyan.opacity(0.18),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 135)
                .rotationEffect(.degrees(-20))
                .offset(
                    x: heroShimmerOffset * 340
                )
                .blendMode(.screen)

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.34),
                        Color.cyan.opacity(0.18),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 120)
                .rotationEffect(.degrees(-18))
                .offset(x: heroGlassSweepOffset * 330)
                .blendMode(.screen)

                if pointToNextLevel <= 10 {
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(
                                heroGlow ? 0.28 : 0.10
                            ),
                            Color.orange.opacity(0.08),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 10,
                        endRadius: 250
                    )
                }

                DashboardParticleLayer()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 30
                        )
                    )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 30
                )
            )
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 30)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    LinearGradient(
                        colors: pointToNextLevel <= 10
                            ? [
                                Color.yellow.opacity(0.95),
                                Color.white.opacity(0.75),
                                Color.orange.opacity(0.55),
                                Color.yellow.opacity(0.25)
                            ]
                            : [
                                Color.white.opacity(0.78),
                                Color.cyan.opacity(0.65),
                                Color.blue.opacity(0.35),
                                Color.white.opacity(0.12)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth:
                        pointToNextLevel <= 10
                            ? 2.2
                            : 1.5
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 27)
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
                .padding(4)
        }
        .shadow(
            color:
                pointToNextLevel <= 10
                    ? Color.yellow.opacity(
                        heroGlow ? 0.42 : 0.20
                    )
                    : Color.cyan.opacity(
                        heroGlow ? 0.32 : 0.14
                    ),
            radius:
                heroGlow ? 28 : 15,
            x: 0,
            y: 11
        )
        .scaleEffect(
            screenAppeared ? 1 : 0.95
        )
        .opacity(
            screenAppeared ? 1 : 0
        )
        .animation(
            .spring(
                response: 0.65,
                dampingFraction: 0.74
            ),
            value: screenAppeared
        )
    }

    private var playerGreetingSection: some View {
        HStack(
            alignment: .top,
            spacing: 16
        ) {
            VStack(
                alignment: .leading,
                spacing: 7
            ) {
                Text(greetingText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .white.opacity(0.70)
                    )

                Text("\(displayName)さん")
                    .font(
                        .system(
                            size: 31,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(playerDashboardMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        .white.opacity(0.75)
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 6)

            VStack(
                alignment: .trailing,
                spacing: 6
            ) {
                Text("PLAYER LEVEL")
                    .font(
                        .system(
                            size: 9,
                            weight: .black
                        )
                    )
                    .tracking(1.3)
                    .foregroundStyle(
                        .white.opacity(0.55)
                    )

                Text("Lv.\(memberLevel)")
                    .font(
                        .system(
                            size: 29,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .shadow(
                        color: Color.cyan.opacity(0.55),
                        radius: 10
                    )

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(displayedPoint)pt")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text("PREMIUM POINT")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.52))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 20)
    }
    private var playerGrowthSection: some View {
        VStack(spacing: 18) {
            // 次のレベル
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 7) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text("NEXT LEVEL")
                            .font(.caption)
                            .fontWeight(.black)
                            .tracking(1.2)
                            .foregroundStyle(
                                .white.opacity(0.72)
                            )
                    }

                    Spacer()

                    Text("あと\(pointToNextLevel)pt")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.yellow)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                Color.white.opacity(0.14)
                            )

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan,
                                        Color.blue,
                                        Color.purple,
                                        Color.white
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width:
                                    geometry.size.width
                                    * max(
                                        min(
                                            levelProgress,
                                            1
                                        ),
                                        0.03
                                    )
                            )
                            .shadow(
                                color:
                                    Color.cyan.opacity(0.65),
                                radius: 7
                            )
                            .animation(
                                .spring(
                                    response: 0.75,
                                    dampingFraction: 0.72
                                ),
                                value: levelProgress
                            )
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("Lv.\(memberLevel)")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )

                    Spacer()

                    Text("Lv.\(memberLevel + 1)")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.white)
                }
            }

            Divider()
                .overlay(
                    Color.white.opacity(0.15)
                )

            // 連続参加
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            Color.orange.opacity(0.20)
                        )
                        .frame(
                            width: 48,
                            height: 48
                        )

                    Text("🔥")
                        .font(.system(size: 25))
                        .scaleEffect(
                            heroGlow ? 1.10 : 0.95
                        )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("CURRENT STREAK")
                        .font(
                            .system(
                                size: 9,
                                weight: .black
                            )
                        )
                        .tracking(1.4)
                        .foregroundStyle(
                            .white.opacity(0.55)
                        )

                    if currentAttendanceStreak > 0 {
                        Text(
                            "\(currentAttendanceStreak)連続参加中"
                        )
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.orange)
                    } else {
                        Text(
                            "次の活動から連続参加スタート"
                        )
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                    }
                }

                Spacer()

                if currentAttendanceStreak > 0 {
                    Text("\(currentAttendanceStreak)")
                        .font(
                            .system(
                                size: 34,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)

                    Text("回")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                }
            }

            // 今月の記録
            HStack(spacing: 11) {
                playerStatusTile(
                    icon: "figure.badminton",
                    title: "今月参加",
                    value:
                        "\(monthlyAttendanceCount)回",
                    color: .cyan
                )

                playerStatusTile(
                    icon: "hammer.fill",
                    title: "今月設営",
                    value:
                        "\(monthlySetupCount)回",
                    color: .orange
                )

                playerStatusTile(
                    icon: "clock.badge.checkmark",
                    title: "早期回答",
                    value:
                        "\(monthlyEarlyAnswerCount)回",
                    color: .yellow
                )
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 22)
    }
    private func playerStatusTile(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            Text(title)
                .font(
                    .system(
                        size: 9,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.58)
                )
                .lineLimit(1)

            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            Color.white.opacity(0.09)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
        }
    }

    private var playerDashboardMessage: String {
        if pointToNextLevel <= 10 {
            return "レベルアップまであと少しです！"
        }

        if currentAttendanceStreak >= 10 {
            return "素晴らしい連続参加記録です！"
        }

        if currentAttendanceStreak > 0 {
            return "連続参加記録を伸ばしましょう！"
        }

        return "次の活動もSiRiUSを楽しみましょう！"
    }

    // MARK: - 注目ガチャ

    private var featuredGachaCard: some View {
        NavigationLink {
            GachaView()
        } label: {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color(
                                red: 0.19,
                                green: 0.03,
                                blue: 0.12
                            ),
                            Color(
                                red: 0.46,
                                green: 0.08,
                                blue: 0.18
                            ),
                            Color(
                                red: 0.11,
                                green: 0.03,
                                blue: 0.24
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Circle()
                    .fill(
                        Color.orange.opacity(
                            gachaGlow ? 0.30 : 0.12
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 22)
                    .offset(x: 155, y: -90)

                Circle()
                    .fill(
                        Color.purple.opacity(
                            gachaGlow ? 0.25 : 0.10
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 22)
                    .offset(x: -145, y: 125)

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.05),
                        Color.yellow.opacity(0.48),
                        Color.white.opacity(0.68),
                        Color.orange.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 110)
                .rotationEffect(.degrees(-16))
                .offset(x: gachaSweepOffset * 330)
                .blendMode(.screen)

                HStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 22,
                            style: .continuous
                        )
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.32), radius: 8, y: 5)

                        RoundedRectangle(
                            cornerRadius: 22,
                            style: .continuous
                        )
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.82),
                                    Color.orange.opacity(0.72),
                                    Color.purple.opacity(0.58)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 88, height: 88)

                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            .frame(width: 80, height: 80)

                        Text("🎰")
                            .font(.system(size: 52))
                            .scaleEffect(
                                gachaGlow ? 1.06 : 0.96
                            )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 7
                    ) {
                        Text("TODAY'S GACHA")
                            .font(
                                .system(
                                    size: 11,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .tracking(2.0)
                            .foregroundStyle(
                                .white.opacity(0.62)
                            )

                        Text("SiRiUS SLOT")
                            .font(
                                .system(
                                    size: 25,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)

                        HStack(spacing: 7) {
                            Text("SSR 0.5%")
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .black
                                    )
                                )
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    Color.red.opacity(0.88)
                                )
                                .foregroundStyle(.white)
                                .clipShape(Capsule())

                            Text("100 PT / PLAY")
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .foregroundStyle(
                                    .yellow.opacity(0.94)
                                )
                        }

                        Text("レバーを引いてプレミアムを狙え")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                .white.opacity(0.72)
                            )
                    }

                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .fill(
                                Color.white.opacity(0.12)
                            )
                            .frame(width: 42, height: 42)

                        Image(
                            systemName:
                                "chevron.right"
                        )
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                    }
                }
                .padding(20)
            }
            .frame(minHeight: 150)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.90),
                            Color.white.opacity(0.70),
                            Color.orange.opacity(0.52),
                            Color.purple.opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.7
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
                .padding(4)
            }
            .shadow(
                color: Color.orange.opacity(
                    gachaGlow ? 0.36 : 0.18
                ),
                radius: gachaGlow ? 25 : 15,
                x: 0,
                y: 10
            )
        }
        .buttonStyle(.plain)
        .opacity(screenAppeared ? 1 : 0)
        .offset(y: screenAppeared ? 0 : 20)
        .animation(
            .easeOut(duration: 0.60)
                .delay(0.10),
            value: screenAppeared
        )
    }

    // MARK: - クイックメニュー

    private var quickMenuSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                Text("QUICK ACCESS")
                    .font(.caption)
                    .fontWeight(.black)
                    .tracking(1.8)
                    .foregroundStyle(
                        .white.opacity(0.72)
                    )

                Spacer()

                Text("よく使う機能")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                quickMenuItem(
                    title: "ガチャ",
                    icon: "🎰",
                    color: .orange,
                    destination: AnyView(
                        GachaView()
                    )
                )

                quickMenuItem(
                    title: "ランキング",
                    icon: "🏆",
                    color: .yellow,
                    destination: AnyView(
                        RankingView()
                    )
                )

                quickMenuItem(
                    title: "ミッション",
                    icon: "🎯",
                    color: .blue,
                    destination: AnyView(
                        MonthlyMissionView(
                            attendanceCount:
                                monthlyAttendanceCount,
                            setupCount:
                                monthlySetupCount,
                            earlyAnswerCount:
                                monthlyEarlyAnswerCount
                        )
                    )
                )

                quickMenuItem(
                    title: "カード",
                    icon: "💳",
                    color: .purple,
                    destination: AnyView(
                        PointCardView()
                    )
                )
            }
        }
        .padding(.vertical, 4)
        .opacity(
            screenAppeared ? 1 : 0
        )
        .offset(
            y: screenAppeared ? 0 : 18
        )
        .animation(
            .easeOut(duration: 0.55)
                .delay(0.15),
            value: screenAppeared
        )
    }

    private func quickMenuItem(
        title: String,
        icon: String,
        color: Color,
        destination: AnyView
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 17
                    )
                    .fill(
                        color.opacity(0.13)
                    )
                    .frame(height: 52)

                    Text(icon)
                        .font(
                            .system(size: 27)
                        )
                }

                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(8)
            .background(
                .ultraThinMaterial
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 24
                )
                .stroke(
                    Color.white.opacity(0.12),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(0.10),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 今日の活動

    private func todayCard(
        _ activity: Activity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 17
        ) {
            HStack {
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .fill(
                                Color.orange.opacity(
                                    0.15
                                )
                            )
                            .frame(
                                width: 38,
                                height: 38
                            )

                        Image(
                            systemName: "flame.fill"
                        )
                        .foregroundStyle(.orange)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text("TODAY")
                            .font(.headline)
                            .fontWeight(.black)
                            .tracking(1)
                            .foregroundStyle(.orange)

                        Text("本日の活動")
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                Spacer()

                Text("開催日")
                    .font(.caption)
                    .bold()
                    .padding(
                        .horizontal,
                        12
                    )
                    .padding(
                        .vertical,
                        7
                    )
                    .background(
                        Color.orange.opacity(
                            0.13
                        )
                    )
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            Text(activity.title)
                .font(
                    .system(
                        size: 27,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)

            VStack(
                alignment: .leading,
                spacing: 11
            ) {
                activityInformationRow(
                    icon: "clock.fill",
                    text:
                        "\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))",
                    color: .blue
                )

                activityInformationRow(
                    icon:
                        "mappin.and.ellipse",
                    text: activity.place,
                    color: .red
                )
            }

            Divider()

            HStack {
                statusMini(
                    title: "参加",
                    value:
                        "\(activity.attendingCount)人",
                    color: accentColor
                )

                Spacer()

                statusMini(
                    title: "未払い",
                    value:
                        "\(max(activity.attendingCount - activity.paidMembers.count, 0))人",
                    color: .red
                )

                Spacer()

                statusMini(
                    title: "待ち",
                    value:
                        "\(activity.waitingList.count)人",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            .ultraThinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 27
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 27
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(
                            0.45
                        ),
                        Color.red.opacity(
                            0.10
                        ),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.3
            )
        }
        .shadow(
            color:
                Color.orange.opacity(
                    0.10
                ),
            radius: 15,
            x: 0,
            y: 8
        )
    }

    private func activityInformationRow(
        icon: String,
        text: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 10
                )
                .fill(
                    color.opacity(0.11)
                )
                .frame(
                    width: 38,
                    height: 38
                )

                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    // MARK: - 次回活動

    private func nextActivityCard(
        _ activity: Activity
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Text("🏸")
                        .font(.system(size: 25))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT EVENT")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.7)
                        .foregroundStyle(.white.opacity(0.65))

                    Text("次回活動")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(daysUntilText(activity.date))
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.cyan.opacity(0.18))
                    .foregroundStyle(.cyan)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.cyan.opacity(0.34),
                                lineWidth: 1
                            )
                    }
            }
            .padding(.horizontal, 21)
            .padding(.top, 20)

            Divider()
                .overlay(Color.white.opacity(0.15))
                .padding(.horizontal, 21)
                .padding(.vertical, 17)

            Text(activity.title)
                .font(
                    .system(
                        size: 31,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .padding(.horizontal, 21)

            VStack(spacing: 11) {
                nextEventInformationRow(
                    icon: "calendar",
                    title: "DATE",
                    value: formatDate(activity.date),
                    color: .cyan
                )

                nextEventInformationRow(
                    icon: "clock.fill",
                    title: "TIME",
                    value:
                        "\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))",
                    color: .orange
                )

                nextEventInformationRow(
                    icon: "mappin.and.ellipse",
                    title: "PLACE",
                    value: activity.place,
                    color: .pink
                )
            }
            .padding(.horizontal, 21)
            .padding(.top, 18)

            Divider()
                .overlay(Color.white.opacity(0.15))
                .padding(.horizontal, 21)
                .padding(.vertical, 17)

            HStack(spacing: 10) {
                nextEventStatusTile(
                    title: "参加",
                    value: "\(activity.attendingCount)人",
                    icon: "person.fill.checkmark",
                    color: .cyan
                )

                nextEventStatusTile(
                    title: "未定",
                    value: "\(activity.undecidedCount)人",
                    icon: "questionmark",
                    color: .orange
                )

                nextEventStatusTile(
                    title: "不参加",
                    value: "\(activity.absentCount)人",
                    icon: "person.fill.xmark",
                    color: .gray
                )
            }
            .padding(.horizontal, 21)
            .padding(.bottom, 21)
        }
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 0.025,
                                    green: 0.08,
                                    blue: 0.20
                                ),
                                Color(
                                    red: 0.05,
                                    green: 0.25,
                                    blue: 0.52
                                ),
                                Color(
                                    red: 0.08,
                                    green: 0.50,
                                    blue: 0.70
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 190, height: 190)
                    .blur(radius: 14)
                    .offset(x: 155, y: -115)
                    .scaleEffect(heroGlow ? 1.12 : 0.90)

                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 155, height: 155)
                    .blur(radius: 14)
                    .offset(x: -150, y: 150)

                DashboardParticleLayer()
                    .clipShape(
                        RoundedRectangle(cornerRadius: 28)
                    )
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.cyan.opacity(0.45),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        }
        .shadow(
            color: Color.cyan.opacity(
                heroGlow ? 0.24 : 0.12
            ),
            radius: heroGlow ? 22 : 13,
            x: 0,
            y: 9
        )
    }

    private func nextEventInformationRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.17))
                    .frame(width: 45, height: 45)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.52))

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.09))
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
        }
    }

    private func nextEventStatusTile(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.09))
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    color.opacity(0.18),
                    lineWidth: 1
                )
        }
    }
    // MARK: - 大型リンクカード

    private var rankingCardLink: some View {
        luxuryNavigationCard(
            icon: "🏆",
            title: "月間ランキング",
            subtitle:
                "今月の順位をチェック",
            color: .orange,
            destination: AnyView(
                RankingView()
            )
        )
    }

    private var awardCard: some View {
        luxuryNavigationCard(
            icon: "👑",
            title: "HALL OF FAME",
            subtitle:
                "歴代チャンピオン・永久記録",
            color: .purple,
            destination: AnyView(
                HallOfFameView()
            )
        )
    }

    private var monthlyMissionCard: some View {
        luxuryNavigationCard(
            icon: "🎯",
            title: "月間ミッション",
            subtitle:
                "参加・設営・QR受付に挑戦",
            color: .blue,
            destination: AnyView(
                MonthlyMissionView(
                    attendanceCount:
                        monthlyAttendanceCount,
                    setupCount:
                        monthlySetupCount,
                    earlyAnswerCount:
                        monthlyEarlyAnswerCount
                )
            )
        )
    }

    private var gachaCardLink: some View {
        NavigationLink {
            GachaView()
        } label: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.orange.opacity(
                            0.17
                        ),
                        Color.red.opacity(
                            0.09
                        ),
                        Color.purple.opacity(
                            0.08
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        Color.orange.opacity(
                            0.11
                        )
                    )
                    .frame(
                        width: 130,
                        height: 130
                    )
                    .offset(
                        x: 150,
                        y: -35
                    )

                HStack(spacing: 15) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                        .fill(
                            Color.white.opacity(
                                0.78
                            )
                        )
                        .frame(
                            width: 68,
                            height: 68
                        )

                        Text("🎰")
                            .font(
                                .system(size: 42)
                            )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        HStack(spacing: 6) {
                            Text("SiRiUS GACHA")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(
                                    .orange
                                )

                            Text("HOT")
                                .font(
                                    .system(
                                        size: 9,
                                        weight: .black
                                    )
                                )
                                .padding(
                                    .horizontal,
                                    7
                                )
                                .padding(
                                    .vertical,
                                    4
                                )
                                .background(
                                    Color.red
                                )
                                .foregroundStyle(
                                    .white
                                )
                                .clipShape(
                                    Capsule()
                                )
                        }

                        Text(
                            "100ptで豪華チケットを獲得"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            "レバーを引いて運試し！"
                        )
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(
                            .orange
                        )
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(.headline)
                    .foregroundStyle(.orange)
                }
                .padding(19)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 26
                )
                .stroke(
                    Color.orange.opacity(
                        0.24
                    ),
                    lineWidth: 1.2
                )
            }
            .shadow(
                color:
                    Color.orange.opacity(
                        0.10
                    ),
                radius: 13,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
    }

    private func luxuryNavigationCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        destination: AnyView
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 17
                    )
                    .fill(
                        color.opacity(0.13)
                    )
                    .frame(
                        width: 61,
                        height: 61
                    )

                    Text(icon)
                        .font(
                            .system(size: 35)
                        )
                }

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    Text(title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(color)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        color.opacity(0.09),
                        Color(
                            .systemBackground
                        )
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 24
                )
                .stroke(
                    color.opacity(0.15),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - チャンピオン

    private var latestChampionCard: some View {
        NavigationLink {
            HallOfFameView()
        } label: {
            VStack(spacing: 0) {
                // 上部ヘッダー
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.28),
                                        Color.orange.opacity(0.14)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: 55,
                                height: 55
                            )

                        Text("👑")
                            .font(.system(size: 31))
                            .shadow(
                                color: Color.yellow.opacity(0.55),
                                radius: 8
                            )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text("HALL OF FAME")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .black
                                )
                            )
                            .tracking(1.1)
                            .foregroundStyle(.white)

                        Text("2026 SEASON • 歴代チャンピオン・永久記録")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                .white.opacity(0.62)
                            )
                    }

                    Spacer()

                    Text("VIEW")
                        .font(
                            .system(
                                size: 9,
                                weight: .black
                            )
                        )
                        .tracking(1.1)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Color.yellow.opacity(0.13)
                        )
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(
                                    Color.yellow.opacity(0.28),
                                    lineWidth: 1
                                )
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 17)

                Divider()
                    .overlay(
                        Color.white.opacity(0.15)
                    )
                    .padding(.horizontal, 20)

                // 前回チャンピオン表示
                HStack(
                    alignment: .center,
                    spacing: 16
                ) {
                    ZStack {
                        Circle()
                            .fill(
                                Color.yellow.opacity(0.12)
                            )
                            .frame(
                                width: 76,
                                height: 76
                            )

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.yellow,
                                        Color.white.opacity(0.85),
                                        Color.orange.opacity(0.55)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                            .frame(
                                width: 70,
                                height: 70
                            )

                        Text("🏆")
                            .font(.system(size: 35))
                    }
                    .shadow(
                        color: Color.yellow.opacity(0.30),
                        radius: 10
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("前回の月間チャンピオン")
                            .font(
                                .system(
                                    size: 10,
                                    weight: .black
                                )
                            )
                            .tracking(1.1)
                            .foregroundStyle(
                                .yellow.opacity(0.82)
                            )

                        if latestChampionName.isEmpty {
                            Text("まだ記録がありません")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    .white.opacity(0.72)
                                )

                            Text("月間結果が保存されると表示されます")
                                .font(.caption2)
                                .foregroundStyle(
                                    .white.opacity(0.48)
                                )
                        } else {
                            Text(latestChampionName)
                                .font(
                                    .system(
                                        size: 27,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text(
                                "\(formatChampionMonth(latestChampionMonth))・\(latestChampionPoint)pt"
                            )
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .white.opacity(0.64)
                            )
                        }
                    }

                    Spacer(minLength: 5)

                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                Divider()
                    .overlay(
                        Color.white.opacity(0.15)
                    )
                    .padding(.horizontal, 20)

                // 下部リンク
                HStack(spacing: 11) {
                    hallOfFameFeature(
                        icon: "crown.fill",
                        title: "歴代王者",
                        color: .yellow
                    )

                    hallOfFameFeature(
                        icon: "star.fill",
                        title: "MVP",
                        color: .orange
                    )

                    hallOfFameFeature(
                        icon: "medal.fill",
                        title: "永久記録",
                        color: .purple
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 17)
                .background(
                    Color.white.opacity(0.045)
                )
            }
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(
                                        red: 0.055,
                                        green: 0.035,
                                        blue: 0.12
                                    ),
                                    Color(
                                        red: 0.18,
                                        green: 0.07,
                                        blue: 0.30
                                    ),
                                    Color(
                                        red: 0.36,
                                        green: 0.14,
                                        blue: 0.32
                                    ),
                                    Color(
                                        red: 0.22,
                                        green: 0.13,
                                        blue: 0.05
                                    )
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .fill(
                            Color.yellow.opacity(
                                heroGlow ? 0.19 : 0.08
                            )
                        )
                        .frame(
                            width: 205,
                            height: 205
                        )
                        .blur(radius: 20)
                        .offset(
                            x: 150,
                            y: -115
                        )
                        .scaleEffect(
                            heroGlow ? 1.12 : 0.92
                        )

                    Circle()
                        .fill(
                            Color.purple.opacity(0.15)
                        )
                        .frame(
                            width: 180,
                            height: 180
                        )
                        .blur(radius: 18)
                        .offset(
                            x: -145,
                            y: 135
                        )

                    DashboardParticleLayer()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 28)
                        )
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 28)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.80),
                                Color.white.opacity(0.52),
                                Color.purple.opacity(0.44),
                                Color.orange.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        Color.white.opacity(0.08),
                        lineWidth: 1
                    )
                    .padding(4)
            }
            .shadow(
                color: Color.purple.opacity(
                    heroGlow ? 0.25 : 0.12
                ),
                radius: heroGlow ? 22 : 13,
                x: 0,
                y: 9
            )
        }
        .buttonStyle(.plain)
    }
    private func hallOfFameFeature(
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            Text(title)
                .font(
                    .system(
                        size: 10,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.72)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
    // MARK: - お知らせ

    private var noticeCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                Color.red.opacity(
                                    0.13
                                )
                            )
                            .frame(
                                width: 39,
                                height: 39
                            )

                        Image(
                            systemName:
                                "megaphone.fill"
                        )
                        .foregroundStyle(.red)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 1
                    ) {
                        Text("お知らせ")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.red)

                        if !latestNotice.isEmpty {
                            Text(
                                "NEW INFORMATION"
                            )
                            .font(
                                .system(
                                    size: 9,
                                    weight: .bold
                                )
                            )
                            .tracking(1.1)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }
                }

                Spacer()

                HStack(spacing: 7) {
                    Text("NEW")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.78))
                        .clipShape(Capsule())

                    if !latestNoticeDate.isEmpty {
                        Text(latestNoticeDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if latestNotice.isEmpty {
                Text(
                    "現在お知らせはありません"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.55)
                )
            } else {
                Text(latestNotice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .white
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(19)
        .background(
            LinearGradient(
                colors: [
                    Color.red.opacity(0.10),
                    Color.pink.opacity(0.04),
                    Color.white.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24
            )
            .stroke(
                Color.red.opacity(0.16),
                lineWidth: 1
            )
        }
    }
    // MARK: - 管理者ダッシュボード

    private var administratorDashboard: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                        .fill(
                            Color.indigo.opacity(
                                0.13
                            )
                        )
                        .frame(
                            width: 42,
                            height: 42
                        )

                        Image(
                            systemName:
                                "chart.bar.xaxis"
                        )
                        .foregroundStyle(.indigo)
                        .shadow(color: .indigo.opacity(0.34), radius: 5)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text("ADMIN DASHBOARD")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(
                                .white
                            )

                        Text("サークル運営状況")
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                Spacer()

                Text("管理者")
                    .font(.caption2)
                    .bold()
                    .padding(
                        .horizontal,
                        9
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        Color.indigo.opacity(
                            0.12
                        )
                    )
                    .foregroundStyle(
                        .indigo
                    )
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                dashboardMiniCard(
                    title: "メンバー",
                    value: "\(totalMembers)人",
                    icon: "person.3.fill",
                    color: accentColor
                )

                dashboardMiniCard(
                    title: "今月活動",
                    value:
                        "\(thisMonthActivities)回",
                    icon:
                        "calendar.badge.clock",
                    color: .indigo
                )

                dashboardMiniCard(
                    title: "回収済み",
                    value:
                        "\(totalCollected)円",
                    icon:
                        "checkmark.circle.fill",
                    color: .green
                )

                dashboardMiniCard(
                    title: "未回収",
                    value:
                        "\(totalUncollected)円",
                    icon:
                        "exclamationmark.circle.fill",
                    color: .orange
                )
            }
        }
        .padding(19)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [
                    Color.indigo.opacity(
                        0.10
                    ),
                    Color.blue.opacity(
                        0.04
                    ),
                    Color.white.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 26
            )
            .stroke(
                Color.indigo.opacity(
                    0.15
                ),
                lineWidth: 1
            )
        }
        .shadow(color: .black.opacity(0.18), radius: 13, y: 7)
    }

    private func dashboardMiniCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 9
        ) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(
                    .white
                )
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            Color.white.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - 一般メンバー用情報

    private var memberSummaryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 13
        ) {
            SummaryCard(
                title: "メンバー",
                value: "\(totalMembers)人",
                icon: "person.3.fill",
                color: accentColor
            )

            SummaryCard(
                title: "今月活動",
                value:
                    "\(thisMonthActivities)回",
                icon:
                    "calendar.badge.clock",
                color: accentColor
            )
        }
    }

    // MARK: - 共通部品

    private func statusMini(
        title: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(color)
        }
    }

    private var sloganView: some View {
        VStack(spacing: 7) {
            Text("つながる・集う・楽しむ")
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Text("One team, One SiRiUS.")
                .font(.caption)
                .italic()
                .foregroundStyle(
                    accentColor
                )
        }
        .padding(.vertical, 12)
    }

    // MARK: - Firebase

    private func loadLatestChampion() {
        db.collection("hallOfFame")
            .order(
                by: "createdAt",
                descending: true
            )
            .limit(to: 1)
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "前回チャンピオン取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let document =
                        snapshot?
                            .documents
                            .first
                else {
                    DispatchQueue
                        .main
                        .async {
                            latestChampionName = ""
                            latestChampionPoint = 0
                            latestChampionMonth = ""
                        }

                    return
                }

                let data =
                    document.data()

                DispatchQueue
                    .main
                    .async {
                        latestChampionName =
                            data[
                                "championName"
                            ] as? String
                            ?? ""

                        latestChampionPoint =
                            data[
                                "championPoint"
                            ] as? Int
                            ?? 0

                        latestChampionMonth =
                            data[
                                "month"
                            ] as? String
                            ?? ""
                    }
            }
    }
    private func loadLatestMVP() {
        db.collection("hallOfFame")
            .order(
                by: "createdAt",
                descending: true
            )
            .limit(to: 1)
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "最新MVP取得失敗: \(error.localizedDescription)"
                    )

                    DispatchQueue.main.async {
                        latestMVPName = ""
                        latestMVPPoint = 0
                        latestMVPImageBase64 = ""
                    }

                    return
                }

                guard
                    let document =
                        snapshot?
                            .documents
                            .first
                else {
                    DispatchQueue.main.async {
                        latestMVPName = ""
                        latestMVPPoint = 0
                        latestMVPImageBase64 = ""
                    }

                    return
                }

                let data = document.data()

                print(data)
                
                let loadedMVPName =
                    data["mvpName"] as? String
                    ?? ""

                let loadedMVPPoint =
                    data["mvpPoint"] as? Int
                    ?? 0

                let savedMVPImage =
                    data["mvpImageBase64"] as? String
                    ?? ""

                DispatchQueue.main.async {
                    latestMVPName =
                        loadedMVPName

                    latestMVPPoint =
                        loadedMVPPoint

                    if !savedMVPImage.isEmpty {
                        latestMVPImageBase64 =
                            savedMVPImage
                    } else {
                        loadLatestMVPProfileImage(
                            mvpName: loadedMVPName
                        )
                    }
                }
            }
    }
    private func loadLatestMVPProfileImage(
        mvpName: String
    ) {
        guard !mvpName.isEmpty else {
            latestMVPImageBase64 = ""
            return
        }

        db.collection("members")
            .whereField(
                "name",
                isEqualTo: mvpName
            )
            .limit(to: 1)
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "MVPプロフィール画像取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let data =
                        snapshot?
                            .documents
                            .first?
                            .data()
                else {
                    return
                }

                let imageBase64 =
                    data["profileImageBase64"] as? String
                    ?? data["imageBase64"] as? String
                    ?? data["profileImage"] as? String
                    ?? ""

                DispatchQueue.main.async {
                    latestMVPImageBase64 =
                        imageBase64
                }
            }
    }
    private func loadTestMVP() {
        guard !testMVPId.isEmpty else {
            DispatchQueue.main.async {
                testMVPPoint = 0
                testMVPImageBase64 = ""
            }

            return
        }

        db.collection("members")
            .document(testMVPId)
            .getDocument {
                snapshot,
                error in

                if let error {
                    print(
                        "テストMVP取得失敗: \(error.localizedDescription)"
                    )

                    DispatchQueue.main.async {
                        testMVPPoint = 0
                        testMVPImageBase64 = ""
                    }

                    return
                }

                guard
                    let data = snapshot?.data()
                else {
                    DispatchQueue.main.async {
                        testMVPPoint = 0
                        testMVPImageBase64 = ""
                    }

                    return
                }

                let loadedPoint =
                    data["totalPoint"] as? Int
                    ?? 0

                let loadedImageBase64 =
                    data["profileImageBase64"] as? String
                    ?? data["imageBase64"] as? String
                    ?? data["profileImage"] as? String
                    ?? ""

                DispatchQueue.main.async {
                    testMVPPoint = loadedPoint
                    testMVPImageBase64 =
                        loadedImageBase64
                }
            }
    }
    private func loadRanking() {
        db.collection("members")
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "ホームランキング取得失敗: \(error.localizedDescription)"
                    )

                    DispatchQueue.main.async {
                        rankingEntries = []
                        currentUserRank = 0
                        pointToNextRank = 0
                    }

                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        rankingEntries = []
                        currentUserRank = 0
                        pointToNextRank = 0
                    }

                    return
                }

                var loadedEntries: [HomeRankingEntry] = []

                for document in documents {
                    let data = document.data()

                    let isActive =
                        data["isActive"] as? Bool
                        ?? true

                    guard isActive else {
                        continue
                    }

                    let name =
                        data["name"] as? String
                        ?? ""

                    guard !name.isEmpty else {
                        continue
                    }

                    let monthlyPoint =
                        data["monthlyPoint"] as? Int
                        ?? 0

                    let totalPoint =
                        data["totalPoint"] as? Int
                        ?? 0

                    let imageBase64 =
                        data["profileImageBase64"] as? String
                        ?? data["imageBase64"] as? String
                        ?? data["profileImage"] as? String
                        ?? ""

                    loadedEntries.append(
                        HomeRankingEntry(
                            id: document.documentID,
                            name: name,
                            monthlyPoint: monthlyPoint,
                            totalPoint: totalPoint,
                            imageBase64: imageBase64
                        )
                    )
                }

                let sortedEntries =
                    loadedEntries.sorted {
                        if $0.monthlyPoint
                            == $1.monthlyPoint {
                            return $0.name
                                .localizedStandardCompare(
                                    $1.name
                                ) == .orderedAscending
                        }

                        return $0.monthlyPoint
                            > $1.monthlyPoint
                    }

                let myIndex =
                    sortedEntries.firstIndex {
                        $0.id == currentUserId
                    }

                let calculatedRank: Int

                if let myIndex {
                    calculatedRank = myIndex + 1
                } else {
                    calculatedRank = 0
                }

                var calculatedPointToNextRank = 0

                if let myIndex,
                   myIndex > 0 {
                    let myMonthlyPoint =
                        sortedEntries[myIndex]
                            .monthlyPoint

                    let upperMonthlyPoint =
                        sortedEntries[myIndex - 1]
                            .monthlyPoint

                    calculatedPointToNextRank =
                        max(
                            upperMonthlyPoint
                            - myMonthlyPoint
                            + 1,
                            0
                        )
                }

                DispatchQueue.main.async {
                    rankingEntries =
                        sortedEntries

                    currentUserRank =
                        calculatedRank

                    pointToNextRank =
                        calculatedPointToNextRank
                }
            }
    }
    private func loadLatestNotice() {
        db.collection("notices")
            .order(
                by: "createdAt",
                descending: true
            )
            .limit(to: 1)
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "お知らせ取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let document =
                        snapshot?
                            .documents
                            .first
                else {
                    DispatchQueue
                        .main
                        .async {
                            latestNotice = ""
                            latestNoticeDate = ""
                        }

                    return
                }

                let data =
                    document.data()

                DispatchQueue
                    .main
                    .async {
                        latestNotice =
                            data[
                                "text"
                            ] as? String
                            ?? ""

                        if let timestamp =
                            data[
                                "createdAt"
                            ] as? Timestamp {
                            let formatter =
                                DateFormatter()

                            formatter.locale =
                                Locale(
                                    identifier:
                                        "ja_JP"
                                )

                            formatter.dateFormat =
                                "M/d"

                            latestNoticeDate =
                                formatter.string(
                                    from:
                                        timestamp
                                            .dateValue()
                                )
                        }
                    }
            }
    }

    private func loadPoint() {
        guard
            !currentUserId.isEmpty
        else {
            return
        }

        db.collection("members")
            .document(currentUserId)
            .getDocument {
                snapshot,
                error in

                if let error {
                    print(
                        "ポイント取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                let data =
                    snapshot?.data()

                DispatchQueue
                    .main
                    .async {
                        memberName =
                            data?[
                                "name"
                            ] as? String
                            ?? ""

                        totalPoint =
                            data?[
                                "totalPoint"
                            ] as? Int
                            ?? 0

                        animatePointCounter()
                    }
            }
    }

    private func loadDashboard() {
        db.collection("members")
            .getDocuments {
                snapshot,
                _ in

                DispatchQueue
                    .main
                    .async {
                        totalMembers =
                            snapshot?
                                .documents
                                .count
                            ?? 0
                    }
            }

        db.collection("activities")
            .order(by: "date")
            .getDocuments {
                snapshot,
                error in

                if let error {
                    print(
                        "活動情報取得失敗: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let documents =
                        snapshot?
                            .documents
                else {
                    return
                }

                var activities: [Activity] = []

                var collected = 0
                var uncollected = 0
                var monthCount = 0

                var myMonthlyAttendanceCount = 0
                var myMonthlySetupCount = 0
                var myMonthlyEarlyAnswerCount = 0

                for document in documents {
                    let data =
                        document.data()

                    let attendanceArray =
                        data[
                            "attendance"
                        ] as? [[String: Any]]
                        ?? []

                    let attendance =
                        attendanceArray
                            .compactMap {
                                item
                                    -> Attendance? in

                                guard
                                    let memberId =
                                        item[
                                            "memberId"
                                        ] as? String,
                                    let statusRawValue =
                                        item[
                                            "status"
                                        ] as? String,
                                    let status =
                                        AttendanceStatus(
                                            rawValue:
                                                statusRawValue
                                        )
                                else {
                                    return nil
                                }

                                let answeredAt =
                                    (
                                        item[
                                            "answeredAt"
                                        ] as? Timestamp
                                    )?
                                    .dateValue()
                                    ?? Date()

                                let earlyAnswerPointGranted =
                                    item[
                                        "earlyAnswerPointGranted"
                                    ] as? Bool
                                    ?? false

                                return Attendance(
                                    memberId:
                                        memberId,
                                    status:
                                        status,
                                    answeredAt:
                                        answeredAt,
                                    earlyAnswerPointGranted:
                                        earlyAnswerPointGranted
                                )
                            }

                    let activity =
                        Activity(
                            id:
                                document
                                    .documentID,
                            title:
                                data[
                                    "title"
                                ] as? String
                                ?? "",
                            date:
                                (
                                    data[
                                        "date"
                                    ] as? Timestamp
                                )?
                                .dateValue()
                                ?? Date(),
                            startTime:
                                (
                                    data[
                                        "startTime"
                                    ] as? Timestamp
                                )?
                                .dateValue()
                                ?? Date(),
                            endTime:
                                (
                                    data[
                                        "endTime"
                                    ] as? Timestamp
                                )?
                                .dateValue()
                                ?? Date(),
                            place:
                                data[
                                    "place"
                                ] as? String
                                ?? "",
                            fee:
                                data[
                                    "fee"
                                ] as? Int
                                ?? 0,
                            capacity:
                                data[
                                    "capacity"
                                ] as? Int
                                ?? 0,
                            memo:
                                data[
                                    "memo"
                                ] as? String
                                ?? "",
                            createdBy:
                                data[
                                    "createdBy"
                                ] as? String
                                ?? "",
                            participants:
                                data[
                                    "participants"
                                ] as? [String]
                                ?? [],
                            waitingList:
                                data[
                                    "waitingList"
                                ] as? [String]
                                ?? [],
                            attendance:
                                attendance,
                            paidMembers:
                                data[
                                    "paidMembers"
                                ] as? [String]
                                ?? [],
                            pointGranted:
                                data[
                                    "pointGranted"
                                ] as? Bool
                                ?? false,
                            pointGrantedAt:
                                (
                                    data[
                                        "pointGrantedAt"
                                    ] as? Timestamp
                                )?
                                .dateValue()
                        )

                    activities.append(
                        activity
                    )

                    collected +=
                        activity.fee
                        * activity
                            .paidMembers
                            .count

                    uncollected +=
                        activity.fee
                        * max(
                            activity
                                .attendingCount
                            - activity
                                .paidMembers
                                .count,
                            0
                        )

                    if Calendar
                        .current
                        .isDate(
                            activity.date,
                            equalTo: Date(),
                            toGranularity:
                                .month
                        ) {
                        monthCount += 1

                        if activity
                            .participants
                            .contains(
                                currentUserId
                            ) {
                            myMonthlyAttendanceCount += 1
                        }

                        if activity
                            .setupPointGrantedMembers
                            .contains(
                                currentUserId
                            ) {
                            myMonthlySetupCount += 1
                        }

                        if let myAttendance =
                            activity
                                .attendance
                                .first(
                                    where: {
                                        $0.memberId
                                        == currentUserId
                                    }
                                ),
                           myAttendance.status
                            == .attending,
                           myAttendance
                            .earlyAnswerPointGranted {
                            myMonthlyEarlyAnswerCount += 1
                        }
                    }
                }

                let today =
                    activities
                        .filter {
                            Calendar
                                .current
                                .isDateInToday(
                                    $0.date
                                )
                        }
                        .sorted {
                            $0.startTime
                            < $1.startTime
                        }
                        .first

                let next =
                    activities
                        .filter {
                            $0.date >= Date()
                            && !Calendar
                                .current
                                .isDateInToday(
                                    $0.date
                                )
                        }
                        .sorted {
                            $0.date
                            < $1.date
                        }
                        .first

                let pastActivities =
                    activities
                        .filter {
                            $0.date <= Date()
                        }
                        .sorted {
                            $0.date
                            > $1.date
                        }

                var calculatedStreak = 0

                for activity in pastActivities {
                    if activity
                        .participants
                        .contains(
                            currentUserId
                        ) {
                        calculatedStreak += 1
                    } else {
                        break
                    }
                }

                DispatchQueue
                    .main
                    .async {
                        totalCollected =
                            collected

                        totalUncollected =
                            uncollected

                        thisMonthActivities =
                            monthCount

                        monthlyAttendanceCount =
                            myMonthlyAttendanceCount

                        monthlySetupCount =
                            myMonthlySetupCount

                        monthlyEarlyAnswerCount =
                            myMonthlyEarlyAnswerCount

                        currentAttendanceStreak =
                            calculatedStreak

                        todayActivity =
                            today

                        nextActivity =
                            next
                    }
            }
    }

    // MARK: - 日付

    private func formatChampionMonth(
        _ month: String
    ) -> String {
        let inputFormatter =
            DateFormatter()

        inputFormatter.dateFormat =
            "yyyy-MM"

        let outputFormatter =
            DateFormatter()

        outputFormatter.locale =
            Locale(
                identifier: "ja_JP"
            )

        outputFormatter.dateFormat =
            "yyyy年M月"

        guard
            let date =
                inputFormatter.date(
                    from: month
                )
        else {
            return month
        }

        return outputFormatter
            .string(from: date)
    }

    private func daysUntilText(
        _ date: Date
    ) -> String {
        let today =
            Calendar
                .current
                .startOfDay(
                    for: Date()
                )

        let target =
            Calendar
                .current
                .startOfDay(
                    for: date
                )

        let days =
            Calendar
                .current
                .dateComponents(
                    [.day],
                    from: today,
                    to: target
                )
                .day
            ?? 0

        if days == 0 {
            return "今日"
        }

        if days == 1 {
            return "明日"
        }

        return "あと\(days)日"
    }

    private func formatDate(
        _ date: Date
    ) -> String {
        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier: "ja_JP"
            )

        formatter.dateFormat =
            "M月d日(E)"

        return formatter
            .string(from: date)
    }

    private func formatTime(
        _ date: Date
    ) -> String {
        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "HH:mm"

        return formatter
            .string(from: date)
    }
}
// MARK: - サマリーカード

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 11
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 12
                )
                .fill(
                    color.opacity(0.12)
                )
                .frame(
                    width: 42,
                    height: 42
                )

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(.title2)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(17)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 21,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 21,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.11),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.16),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - ホーム背景

private struct HomeAmbientBackground: View {
    let accentColor: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) {
            timeline in

            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(
                        accentColor.opacity(
                            0.07
                        )
                    )
                    .frame(
                        width: 280,
                        height: 280
                    )
                    .blur(radius: 20)
                    .offset(
                        x:
                            CGFloat(
                                sin(
                                    time * 0.22
                                )
                            ) * 90,
                        y: -270
                    )

                Circle()
                    .fill(
                        Color.purple.opacity(
                            0.045
                        )
                    )
                    .frame(
                        width: 250,
                        height: 250
                    )
                    .blur(radius: 25)
                    .offset(
                        x:
                            CGFloat(
                                cos(
                                    time * 0.18
                                )
                            ) * 110,
                        y: 240
                    )

                Circle()
                    .fill(
                        Color.cyan.opacity(
                            0.04
                        )
                    )
                    .frame(
                        width: 220,
                        height: 220
                    )
                    .blur(radius: 25)
                    .offset(
                        x:
                            CGFloat(
                                sin(
                                    time * 0.15
                                )
                    ) * 130,
                        y: 650
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.045), .cyan.opacity(0.035), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 230, height: 12)
                    .blur(radius: 6)
                    .rotationEffect(.degrees(-18))
                    .offset(
                        x: CGFloat(sin(time * 0.10)) * 45,
                        y: -95
                    )
            }
        }
    }
}

// MARK: - ホームダッシュボード粒子

private struct DashboardParticleLayer: View {
    private let particles: [
        (
            x: CGFloat,
            y: CGFloat,
            size: CGFloat,
            speed: Double
        )
    ] = [
        (
            -145,
            -135,
            4,
            0.42
        ),
        (
            -95,
            -80,
            6,
            0.50
        ),
        (
            -30,
            -145,
            3,
            0.58
        ),
        (
            45,
            -115,
            5,
            0.46
        ),
        (
            125,
            -85,
            4,
            0.53
        ),
        (
            150,
            -5,
            6,
            0.44
        ),
        (
            120,
            85,
            3,
            0.56
        ),
        (
            55,
            145,
            5,
            0.49
        ),
        (
            -35,
            135,
            4,
            0.54
        ),
        (
            -120,
            95,
            6,
            0.47
        ),
        (
            -155,
            10,
            3,
            0.60
        )
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) {
            timeline in

            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                ForEach(
                    particles.indices,
                    id: \.self
                ) { index in
                    let particle =
                        particles[index]

                    Circle()
                        .fill(
                            index
                                .isMultiple(
                                    of: 2
                                )
                                ? Color.white
                                    .opacity(
                                        0.52
                                    )
                                : Color.cyan
                                    .opacity(
                                        0.60
                                    )
                        )
                        .frame(
                            width:
                                particle
                                    .size,
                            height:
                                particle
                                    .size
                        )
                        .offset(
                            x:
                                particle.x
                                + CGFloat(
                                    sin(
                                        time
                                        * particle.speed
                                        + Double(
                                            index
                                        )
                                    )
                                ) * 8,
                            y:
                                particle.y
                                + CGFloat(
                                    cos(
                                        time
                                        * particle.speed
                                        + Double(
                                            index
                                        )
                                    )
                                ) * 7
                        )
                        .shadow(
                            color:
                                Color.cyan
                                    .opacity(
                                        0.65
                                    ),
                            radius: 4
                        )
                }
            }
        }
    }
}


// MARK: - ホーム星空オーバーレイ

private struct HomeStarfieldOverlay: View {
    private let stars: [
        (
            x: CGFloat,
            y: CGFloat,
            size: CGFloat,
            speed: Double
        )
    ] = [
        (-145, -310, 2.4, 0.42),
        (-80, -220, 1.8, 0.50),
        (15, -275, 2.2, 0.47),
        (125, -180, 1.7, 0.55),
        (160, -45, 2.8, 0.44),
        (95, 125, 1.9, 0.51),
        (-35, 210, 2.5, 0.48),
        (-145, 340, 1.8, 0.56),
        (70, 470, 2.2, 0.46),
        (155, 610, 1.7, 0.53),
        (-75, 745, 2.6, 0.49)
        ,(-130, 865, 1.6, 0.43)
        ,(25, 925, 2.0, 0.40)
        ,(140, 1030, 1.5, 0.46)
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                ZStack {
                    ForEach(
                        stars.indices,
                        id: \.self
                    ) { index in
                        let star = stars[index]

                        Circle()
                            .fill(
                                index.isMultiple(of: 2)
                                    ? Color.white.opacity(0.44)
                                    : Color.cyan.opacity(0.42)
                            )
                            .frame(
                                width: star.size,
                                height: star.size
                            )
                            .position(
                                x:
                                    proxy.size.width / 2
                                    + star.x
                                    + CGFloat(
                                        sin(
                                            time * star.speed
                                            + Double(index)
                                        )
                                    ) * 8,
                                y:
                                    proxy.size.height / 2
                                    + star.y
                                    + CGFloat(
                                        cos(
                                            time * star.speed
                                            + Double(index)
                                        )
                                    ) * 10
                            )
                            .shadow(
                                color: Color.cyan.opacity(0.50),
                                radius: 4
                            )
                    }
                }
            }
        }
    }
}

private extension View {
    func homeCardEntrance() -> some View {
        scrollTransition(.animated(.easeOut(duration: 0.25)), axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.90)
                .scaleEffect(phase.isIdentity ? 1 : 0.98)
                .offset(y: phase.isIdentity ? 0 : 10)
        }
    }
}

#Preview {
    HomeView()
}
