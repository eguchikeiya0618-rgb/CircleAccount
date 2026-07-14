import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

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

    @State private var latestNotice = ""
    @State private var latestNoticeDate = ""

    @State private var monthlyAttendanceCount = 0
    @State private var monthlySetupCount = 0
    @State private var monthlyEarlyAnswerCount = 0
    @State private var currentAttendanceStreak = 0

    @State private var screenAppeared = false
    @State private var heroGlow = false
    @State private var shimmerOffset: CGFloat = -1.3
    @State private var heroShimmerOffset: CGFloat = -1.4
    @State private var logoScale: CGFloat = 0.88
    @State private var logoOpacity = 0.0

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
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                HomeAmbientBackground(
                    accentColor: rankAccentColor
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                ScrollView {
                    LazyVStack(spacing: 18) {
                        luxuryHeader

                        noticeCard

                        homeDashboardHero

                        quickMenuSection

                        if let todayActivity {
                            todayCard(todayActivity)
                        } else if let nextActivity {
                            nextActivityCard(nextActivity)
                        }

                        if todayActivity != nil,
                           let nextActivity {
                            nextActivityCard(nextActivity)
                        }

                        rankingCardLink
                        latestChampionCard
                        awardCard
                        monthlyMissionCard
                        gachaCardLink

                        if currentUserIsAdmin {
                            administratorDashboard
                        } else {
                            memberSummaryGrid
                        }

                        sloganView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadDashboard()
                loadPoint()
                loadLatestChampion()
                loadLatestNotice()
                startHomeAnimations()
            }
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
                .foregroundStyle(mainColor)
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

            Text("BADMINTON CIRCLE")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(3.2)
                .foregroundStyle(accentColor)

            Text("EST. 2023.07")
                .font(.caption2)
                .bold()
                .foregroundStyle(
                    mainColor.opacity(0.60)
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
                spacing: 7
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
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 20)
    }

    private var playerGrowthSection: some View {
        VStack(spacing: 18) {
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
                    Text(
                        "\(currentAttendanceStreak)"
                    )
                    .font(
                        .system(
                            size: 36,
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

            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 7) {
                        Image(
                            systemName: "bolt.fill"
                        )
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

                    Text(
                        "あと\(pointToNextLevel)pt"
                    )
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
                                    Color.cyan.opacity(
                                        0.65
                                    ),
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

            HStack(spacing: 11) {
                playerStatusTile(
                    icon: "figure.badminton",
                    title: "今月参加",
                    value:
                        "\(monthlyAttendanceCount)回",
                    color: .cyan
                )

                playerStatusTile(
                    icon: "flame.fill",
                    title: "連続参加",
                    value:
                        "\(currentAttendanceStreak)回",
                    color: .orange
                )

                playerStatusTile(
                    icon:
                        "arrow.up.right.circle.fill",
                    title: "次のLv.",
                    value:
                        "あと\(pointToNextLevel)pt",
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
                        mainColor.opacity(0.72)
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
                    .foregroundStyle(mainColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(8)
            .background(
                Color(.systemBackground)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 20
                )
                .stroke(
                    color.opacity(0.13),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(0.045),
                radius: 8,
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
                .foregroundStyle(mainColor)

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
            Color(.systemBackground)
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
                .foregroundStyle(mainColor)
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
            icon: "🏆",
            title: "SiRiUS AWARD",
            subtitle:
                "ポイント王・設営王・皆勤賞",
            color: .orange,
            destination: AnyView(
                SiriusAwardView()
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
            SiriusAwardView()
        } label: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(
                            0.18
                        ),
                        Color.orange.opacity(
                            0.10
                        ),
                        Color(
                            .systemBackground
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        Color.yellow.opacity(
                            0.13
                        )
                    )
                    .frame(
                        width: 130,
                        height: 130
                    )
                    .offset(
                        x: -155,
                        y: 30
                    )

                HStack(spacing: 15) {
                    Text("👑")
                        .font(
                            .system(size: 46)
                        )
                        .shadow(
                            color:
                                Color.yellow.opacity(
                                    0.40
                                ),
                            radius: 10
                        )

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text(
                            "前回の月間チャンピオン"
                        )
                        .font(.caption)
                        .bold()
                        .foregroundStyle(
                            .orange
                        )

                        if latestChampionName
                            .isEmpty {
                            Text(
                                "まだ記録がありません"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                .secondary
                            )
                        } else {
                            Text(
                                latestChampionName
                            )
                            .font(.title2)
                            .bold()
                            .foregroundStyle(
                                mainColor
                            )

                            Text(
                                "\(formatChampionMonth(latestChampionMonth))・\(latestChampionPoint)pt"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(19)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 25
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 25
                )
                .stroke(
                    Color.orange.opacity(
                        0.17
                    ),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
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

                if !latestNoticeDate.isEmpty {
                    Text(latestNoticeDate)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }

            if latestNotice.isEmpty {
                Text(
                    "現在お知らせはありません"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
            } else {
                Text(latestNotice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        mainColor
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
                    Color(
                        .systemBackground
                    )
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
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text("ADMIN DASHBOARD")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(
                                mainColor
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
        .background(
            LinearGradient(
                colors: [
                    Color.indigo.opacity(
                        0.10
                    ),
                    Color.blue.opacity(
                        0.04
                    ),
                    Color(
                        .systemBackground
                    )
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
                    mainColor
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
            Color(
                .systemBackground
            )
            .opacity(0.83)
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
        .background(
            Color(.systemBackground)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 21
            )
        )
        .shadow(
            color:
                .black.opacity(0.045),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - ホーム背景

private struct HomeAmbientBackground: View {
    let accentColor: Color

    var body: some View {
        TimelineView(.animation) {
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
        TimelineView(.animation) {
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

#Preview {
    HomeView()
}
