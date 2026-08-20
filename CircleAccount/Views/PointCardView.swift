import SwiftUI
import FirebaseFirestore
import UIKit

struct PointCardView: View {
    @AppStorage("testMVPName")
    var testMVPName = ""
    
    @AppStorage("testMVPId")
    var testMVPId = ""
    
    @State private var testMVPPoint = 0
    @State private var testMVPImageBase64 = ""
    
    let db = Firestore.firestore()
    
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false
    
    @State private var memberNo = 1
    @State private var memberName = ""
    
    @State private var totalPoint = 0
    @State private var availablePoint = 0
    @State private var monthlyPoint = 0
    
    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var stringingFreeTickets = 0
    
    @State private var monthlyChampionCount = 0
    @State private var monthlySecondCount = 0
    @State private var monthlyThirdCount = 0
    @State private var mvpCount = 0
    
    @State private var myRank = 0
    @State private var myRankingPoint = 0
    @State private var pointToNextRank = 0
    @State private var targetRank = 0
    @State private var rankingMembers: [Member] = []
    
    @State private var isFlipped = false

    @State private var glowAnimation = false
    @State private var shimmerOffset: CGFloat = -1.3
    @State private var screenAppeared = false
    @State private var backgroundPulse = false
    @State private var displayedTotalPoint = 0
    @State private var titleShimmerOffset: CGFloat = -1.4
    @State private var hasStartedPresentationAnimations = false

    // プレミアムカード操作演出
    @State private var cardDragOffset: CGSize = .zero
    @State private var isCardPressed = false
    @State private var showCardTapFlash = false

    @State private var hasLoadedMember = false
    
    @State private var showRankUpAlert = false
    @State private var rankUpMessage = ""
    
    @State private var showUseTicketAlert = false
    @State private var selectedTicketTitle = ""
    @State private var selectedTicketField = ""
    @State private var selectedTicketIcon = ""
    
    @State private var showActivityTicketAlert = false
    @State private var showAlreadyAwardedAlert = false
    @State private var showMonthlyAwardAlert = false
    @State private var showMonthlyAwardDoneAlert = false
    @State private var showHallOfFameCelebration = false
    @State private var showMVPAnnouncement = false
    @State private var announcedMVPName = ""
    @State private var announcedMVPImageBase64 = ""
    
    @State private var celebrationMonthText = ""
    @State private var showHallOfFame = false
    
    @State private var awardTargetMonth = ""
    // MVP選択
    @State private var showMVPSelectionSheet = false
    @State private var selectedMVP: Member?
    @State private var mvpCandidates: [Member] = []
    @State private var showMVPRequiredAlert = false
    @State private var showAwardNotReadyAlert = false
    @State private var isMVPSelectionTestMode = false
    @State private var showMVPTestDoneAlert = false
    
    var rankBadge: String {
        if totalPoint >= 700 { return "LEGEND" }
        if totalPoint >= 400 { return "PLATINUM" }
        if totalPoint >= 200 { return "GOLD" }
        if totalPoint >= 100 { return "SILVER" }
        return "BRONZE"
    }
    
    var cardBackground: String {
        if totalPoint >= 700 { return "legend_card_bg" }
        if totalPoint >= 400 { return "platinum_card_bg" }
        if totalPoint >= 200 { return "gold_card_bg" }
        if totalPoint >= 100 { return "silver_card_bg" }
        return "bronze_card_bg"
    }
    
    var nextReward: (title: String, point: Int, icon: String) {
        if availablePoint < 100 {
            return ("片付けパス", 100, "🧹")
        } else if availablePoint < 200 {
            return ("参加費500円券", 200, "💰")
        } else if availablePoint < 400 {
            return ("参加費半額券", 400, "🏸")
        } else {
            return ("参加費無料券", 700, "🎁")
        }
    }
    
    var remainingPoint: Int {
        max(nextReward.point - availablePoint, 0)
    }
    
    var progressToNextRank: Double {
        guard pointToNextRank > 0 else { return 1.0 }
        let goal = myRankingPoint + pointToNextRank
        guard goal > 0 else { return 0.0 }
        return min(Double(myRankingPoint) / Double(goal), 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    premiumHeader

                    flippingCard
                        .opacity(screenAppeared ? 1 : 0)
                        .offset(y: screenAppeared ? 0 : 24)

                    premiumPointSummary
                    
                    Text("カードをタップするとランキングが見れます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ticketsSection
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content.opacity(phase.isIdentity ? 1.0 : 0.98)
                        }
                    exchangeSection
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content.opacity(phase.isIdentity ? 1.0 : 0.98)
                        }
                    
                    if currentUserIsAdmin {
                        monthlyAwardButton
                            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                                content.opacity(phase.isIdentity ? 1.0 : 0.98)
                            }
                        mvpSelectionTestButton
                            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                                content.opacity(phase.isIdentity ? 1.0 : 0.98)
                            }
                        celebrationTestButton
                            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                                content.opacity(phase.isIdentity ? 1.0 : 0.98)
                            }
                    }
                    
                    Button {
                        showHallOfFame = true
                    } label: {
                        HStack {
                            Label("歴代チャンピオンを見る", systemImage: "crown.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.046), radius: 6.9, y: 3)
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        PointHistoryView()
                    } label: {
                        HStack {
                            Label("ポイント履歴を見る", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.046), radius: 6.9, y: 3)
                    }
                    .buttonStyle(.plain)
                    
                    if currentUserIsAdmin {
                        NavigationLink {
                            TicketUsageHistoryView()
                        } label: {
                            HStack {
                                Label("🎫 チケット使用履歴", systemImage: "clock.badge.checkmark")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: .black.opacity(0.046), radius: 6.9, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    pointRuleSection
                    }
                    .padding()
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            .background {
                PremiumPointAmbientBackground(
                    rank: rankBadge,
                    pulse: backgroundPulse
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationTitle("ポイントカード")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {

                loadMember()
                loadRanking()

                restartPointCardShimmer()

                guard !hasStartedPresentationAnimations else { return }
                hasStartedPresentationAnimations = true

                withAnimation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
                ) {
                    glowAnimation = true
                }

                withAnimation(
                    .easeInOut(duration: 1.45)
                    .repeatForever(autoreverses: true)
                ) {
                    backgroundPulse = true
                }

                withAnimation(
                    .spring(response: 0.70, dampingFraction: 0.78)
                ) {
                    screenAppeared = true
                }

                animateDisplayedPoint(to: totalPoint)
            }
            .alert("🎉 RANK UP!", isPresented: $showRankUpAlert) {
                Button("OK") { }
            } message: {
                Text(rankUpMessage)
            }
            .alert("チケットを使用しますか？", isPresented: $showUseTicketAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("使用する", role: .destructive) {
                    useTicket()
                }
            } message: {
                Text("使用すると元に戻せません。")
            }
            .alert("活動詳細から使用してください", isPresented: $showActivityTicketAlert) {
                Button("OK") { }
            } message: {
                Text("このチケットは活動に紐づけて使用するため、近日の活動詳細画面から使用してください。")
            }
            .alert("🏆 月間表彰", isPresented: $showMonthlyAwardAlert) {
                Button("キャンセル", role: .cancel) { }
                
                Button("確定する") {
                    grantMonthlyAwards()
                }
            } message: {
                Text(
                    "\(formattedAwardMonth(awardTargetMonth))の結果を確定しますか？\n\n"
                    + "🥇1位\n"
                    + "🎾 ガット張り工賃無料券 ×1\n\n"
                    + "🥈2位\n"
                    + "⭐ 対戦指名券 ×1\n\n"
                    + "🥉3位\n"
                    + "🚀 優先ゲーム券 ×1\n\n"
                    + "確定後、その月のポイントはリセットされます。"
                )
            }
            .alert(
                "まだ月間表彰を確定できません",
                isPresented: $showAwardNotReadyAlert
            ) {
                Button("OK") { }
            } message: {
                Text(
                    "現在進行中の月は殿堂入りできません。\n"
                    + "翌月になってから前月分を確定してください。"
                )
            }
            .alert("🎉 月間表彰完了", isPresented: $showMonthlyAwardDoneAlert) {
                Button("OK") { }
            } message: {
                Text("受賞回数と特典チケットを反映しました。")
            }
            .alert("今月は表彰済みです", isPresented: $showAlreadyAwardedAlert) {
                Button("OK") { }
            } message: {
                Text("月間表彰は月に1回だけ実行できます。")
            }
            .sheet(isPresented: $showHallOfFame) {
                NavigationStack {
                    HallOfFameView()
                }
            }
            
            .sheet(isPresented: $showMVPSelectionSheet) {
                NavigationStack {
                    MVPSelectionView(
                        candidates: mvpCandidates,
                        selectedMVP: $selectedMVP
                    ) {
                        showMVPSelectionSheet = false
                        
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 0.25
                        ) {
                            if isMVPSelectionTestMode {
                                if let selectedMVP {
                                    testMVPName = selectedMVP.name
                                    testMVPId = selectedMVP.id
                                }

                                showMVPTestDoneAlert = true
                                isMVPSelectionTestMode = false
                            } else {
                                showMonthlyAwardAlert = true
                            }
                        }
                    }
                }
            }
            .alert(
                "MVP選択テスト完了",
                isPresented: $showMVPTestDoneAlert
            ) {
                Button("OK") { }
            } message: {
                if let selectedMVP {
                    Text("月間MVPとして「\(selectedMVP.name)」を選択しました。\n本番データの保存やポイントリセットは行っていません。")
                } else {
                    Text("本番データは変更されていません。")
                }
            }
            .alert(
                "MVPを選択してください",
                isPresented: $showMVPRequiredAlert
            ) {
                Button("OK") { }
            } message: {
                Text("月間表彰を確定する前に、MVPを1人選択してください。")
            }
            .overlay {
                ZStack {
                    if showHallOfFameCelebration {
                        HallOfFameCelebrationOverlay(
                            monthText: celebrationMonthText
                        ) {
                            withAnimation(
                                .easeOut(duration: 0.25)
                            ) {
                                showHallOfFameCelebration = false
                            }

                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.30
                            ) {
                                withAnimation(
                                    .spring(
                                        response: 0.60,
                                        dampingFraction: 0.78
                                    )
                                ) {
                                    showMVPAnnouncement = true
                                }
                            }
                        }
                        .zIndex(100)
                    }

                    if showMVPAnnouncement {
                        MVPAnnouncementOverlay(
                            memberName: announcedMVPName,
                            imageBase64: announcedMVPImageBase64
                        ) {
                            withAnimation(
                                .easeOut(duration: 0.25)
                            ) {
                                showMVPAnnouncement = false
                            }

                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.30
                            ) {
                                showHallOfFame = true
                            }
                        }
                        .zIndex(101)
                    }
                }
            }
        }

    private var premiumHeader: some View {
        VStack(spacing: 6) {
            Text("SiRiUS")
                .font(
                    .system(
                        size: 40,
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.56, blue: 1.0),
                            Color(red: 0.54, green: 0.28, blue: 0.96),
                            Color(red: 0.12, green: 0.88, blue: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    ZStack {
                        Color.clear

                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.20),
                                Color.cyan.opacity(0.62),
                                Color.white.opacity(0.98),
                                Color.purple.opacity(0.52),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 28)
                        .rotationEffect(.degrees(-20))
                        .offset(x: titleShimmerOffset * 85)
                        .blendMode(.screen)
                    }
                    .mask {
                        Text("SiRiUS")
                            .font(
                                .system(
                                    size: 40,
                                    weight: .black,
                                    design: .serif
                                )
                            )
                    }
                }
                .task {
                    await runTitleShimmerLoop()
                }

            Text("PREMIUM MEMBER WALLET")
                .font(
                    .system(
                        size: 10,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(2.5)
                .foregroundStyle(.secondary)

            Text(rankBadge)
                .font(
                    .system(
                        size: 11,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(1.5)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(
                    premiumRankPrimaryColor.opacity(0.13)
                )
                .foregroundStyle(premiumRankPrimaryColor)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            premiumRankPrimaryColor.opacity(0.24),
                            lineWidth: 1
                        )
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .opacity(screenAppeared ? 1 : 0)
        .offset(y: screenAppeared ? 0 : -14)
        .animation(
            .easeOut(duration: 0.55),
            value: screenAppeared
        )
    }

    private var premiumPointSummary: some View {
        HStack(spacing: 12) {
            premiumSummaryTile(
                title: "TOTAL",
                value: "\(displayedTotalPoint)pt",
                icon: "sparkles",
                color: premiumRankPrimaryColor
            )

            premiumSummaryTile(
                title: "AVAILABLE",
                value: "\(availablePoint)pt",
                icon: "wallet.pass.fill",
                color: .cyan
            )

            premiumSummaryTile(
                title: "MONTHLY",
                value: "\(monthlyPoint)pt",
                icon: "calendar.badge.clock",
                color: .orange
            )
        }
        .opacity(screenAppeared ? 1 : 0)
        .offset(y: screenAppeared ? 0 : 18)
        .animation(
            .easeOut(duration: 0.55).delay(0.12),
            value: screenAppeared
        )
    }

    private func premiumSummaryTile(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            Text(title)
                .font(
                    .system(
                        size: 9,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(0.8)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .system(
                        size: 14,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            Color(.systemBackground).opacity(0.88)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    color.opacity(0.17),
                    lineWidth: 1
                )
        }
        .shadow(
            color: color.opacity(0.09),
            radius: 10,
            x: 0,
            y: 5
        )
    }

    private var premiumRankPrimaryColor: Color {
        switch rankBadge {
        case "LEGEND": return .yellow
        case "PLATINUM": return .cyan
        case "GOLD": return .orange
        case "SILVER":
            return Color(
                red: 0.72,
                green: 0.83,
                blue: 1.0
            )
        default:
            return Color(
                red: 0.84,
                green: 0.39,
                blue: 0.16
            )
        }
    }

    private var premiumRankSecondaryColor: Color {
        switch rankBadge {
        case "LEGEND": return .pink
        case "PLATINUM": return .purple
        case "GOLD": return .yellow
        case "SILVER": return .white
        default: return .orange
        }
    }

    private func animateDisplayedPoint(to target: Int) {
        displayedTotalPoint = 0

        let safeTarget = max(target, 0)
        guard safeTarget > 0 else {
            displayedTotalPoint = 0
            return
        }

        let steps = min(safeTarget, 36)
        let interval = 0.72 / Double(max(steps, 1))

        for step in 1...steps {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + interval * Double(step)
            ) {
                displayedTotalPoint =
                    Int(
                        Double(safeTarget)
                        * Double(step)
                        / Double(steps)
                    )
            }
        }
    }

    private func restartPointCardShimmer() {
        shimmerOffset = -1.3

        DispatchQueue.main.async {
            withAnimation(
                .linear(duration: 5.2)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.5
            }
        }
    }

    @MainActor
    private func runTitleShimmerLoop() async {
        while !Task.isCancelled {
            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                titleShimmerOffset = -1.4
            }

            await Task.yield()
            guard !Task.isCancelled else { return }

            withAnimation(.linear(duration: 0.8)) {
                titleShimmerOffset = 1.4
            }

            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            try? await Task.sleep(for: .seconds(3.2))
        }
    }

}
import SwiftUI

private struct PremiumOwnedTicketArtworkView: View, Equatable {
    let ticketField: String
    let iconGlowActive: Bool

    @Environment(\.premiumTicketIsPressed) private var isPressed

    static let artworkWidth: CGFloat = 128
    static let artworkHeight: CGFloat = 76

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.ticketField == rhs.ticketField
        && lhs.iconGlowActive == rhs.iconGlowActive
    }

    private var theme: PremiumOwnedTicketTheme {
        PremiumOwnedTicketTheme(ticketField: ticketField)
    }

    var body: some View {
        let width = Self.artworkWidth
        let height = Self.artworkHeight

        return ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: theme.plateColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.hologramColor.opacity(0.42),
                        Color.white.opacity(0.20),
                        Color.clear
                    ],
                    startPoint: UnitPoint(x: 0.05, y: 0.95),
                    endPoint: UnitPoint(x: 0.90, y: 0.05)
                )
                .blendMode(.screen)
                .clipped()

                LinearGradient(
                    colors: theme.reflectionColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width * 0.30, height: height * 1.55)
                .rotationEffect(.degrees(18))
                .offset(x: width * 0.22)
                .blur(radius: 1.1)
                .blendMode(.screen)
                .clipped()

                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: theme.frameColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
                    .padding(2)

                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.clear,
                                theme.accentColor.opacity(0.28)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.7
                    )
                    .padding(4)

                HStack(spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SIRIUS")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(Color.white)

                        Text("PREMIUM")
                            .font(.system(size: 5.5, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(theme.accentColor)

                        Text("TICKET")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(Color.white.opacity(0.92))
                    }

                    Spacer(minLength: 2)

                    VStack(spacing: 3) {
                        Image(systemName: theme.symbolName)
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(theme.accentColor)
                            .shadow(
                                color: theme.accentColor.opacity(iconGlowActive ? 0.52 : 0.16),
                                radius: iconGlowActive ? 4.5 : 1.5
                            )

                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.purple.opacity(0.90))
                                    .frame(width: 2.6, height: 2.6)
                                    .shadow(color: Color.purple.opacity(0.85), radius: 2)
                            }
                        }
                    }
                    .offset(x: -6)
                }
                .padding(.horizontal, 12)

                VStack {
                    HStack {
                        Text(theme.serialNumber)
                            .font(.system(size: 6.8, weight: .bold, design: .monospaced))
                            .tracking(0.35)
                            .foregroundStyle(Color.white.opacity(0.45))

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(theme.rarityText)
                                .font(.system(size: 6.5, weight: .black, design: .rounded))
                                .tracking(0.7)
                                .foregroundStyle(theme.rarityColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: theme.rarityBadgeColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.88),
                                                    theme.rarityColor.opacity(0.78),
                                                    Color.black.opacity(0.72)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 0.8
                                        )
                                }
                                .shadow(color: theme.rarityColor.opacity(0.28), radius: 2)

                        }
                    }

                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)

                HStack {
                    ticketNotch
                        .offset(x: -5.5)

                    Spacer()

                    ticketNotch
                        .offset(x: 5.5)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: width * 0.52, height: 0.7)
                    .rotationEffect(.degrees(-18))
                    .offset(x: width * 0.08, y: -height * 0.18)
                    .blur(radius: 0.25)
                    .blendMode(.screen)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.clear,
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .clipped()
        .frame(width: width, height: height)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(
            isPressed
                ? .easeOut(duration: 0.15)
                : .spring(response: 0.28, dampingFraction: 0.72),
            value: isPressed
        )
        .accessibilityHidden(true)
    }

    private var ticketNotch: some View {
        Circle()
            .fill(Color.black)
            .frame(width: 11, height: 11)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                theme.accentColor.opacity(0.82),
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.72), radius: 1.5)
    }
}

private struct PremiumOwnedTicketTheme {
    let plateColors: [Color]
    let frameColors: [Color]
    let accentColor: Color
    let hologramColor: Color
    let symbolName: String
    let rarityText: String
    let rarityColor: Color
    let glowOpacity: Double
    let glowRadius: CGFloat
    let serialNumber: String

    var reflectionColors: [Color] {
        switch rarityText {
        case "SSR":
            return [
                Color.clear,
                Color.cyan.opacity(0.12),
                Color.white.opacity(0.72),
                Color.pink.opacity(0.18),
                Color.clear
            ]
        case "SR":
            return [
                Color.clear,
                Color.purple.opacity(0.06),
                Color.white.opacity(0.34),
                Color.purple.opacity(0.10),
                Color.clear
            ]
        default:
            return Array(repeating: Color.clear, count: 5)
        }
    }

    var rarityBadgeColors: [Color] {
        switch rarityText {
        case "SSR":
            return [
                Color.red.opacity(0.72),
                Color.yellow.opacity(0.72),
                Color.cyan.opacity(0.72),
                Color.purple.opacity(0.72)
            ]
        case "SR":
            return [
                Color.white.opacity(0.34),
                Color.purple.opacity(0.78),
                Color.black.opacity(0.72)
            ]
        default:
            return [
                Color.white.opacity(0.58),
                Color.gray.opacity(0.72),
                Color.black.opacity(0.76)
            ]
        }
    }

    init(ticketField: String) {
        switch ticketField {
        case "stringingFreeTickets":
            plateColors = [.black, Color(red: 0.22, green: 0.16, blue: 0.03), .black]
            frameColors = [.white, .yellow, .orange]
            accentColor = .yellow
            hologramColor = .yellow
            symbolName = "crown.fill"
            rarityText = "R"
            rarityColor = .white
            glowOpacity = 0.075
            glowRadius = 3
            serialNumber = "No.001"

        case "challengeTickets":
            plateColors = [Color(red: 0.16, green: 0.01, blue: 0.02), Color(red: 0.48, green: 0.03, blue: 0.06), .black]
            frameColors = [.white, .yellow, .red]
            accentColor = .yellow
            hologramColor = .red
            symbolName = "star.fill"
            rarityText = "R"
            rarityColor = .white
            glowOpacity = 0.075
            glowRadius = 3
            serialNumber = "No.002"

        case "priorityTickets":
            plateColors = [Color(red: 0.01, green: 0.07, blue: 0.18), Color(red: 0.03, green: 0.28, blue: 0.54), .black]
            frameColors = [.white, .cyan, Color.white.opacity(0.65)]
            accentColor = .cyan
            hologramColor = .blue
            symbolName = "bolt.fill"
            rarityText = "R"
            rarityColor = .white
            glowOpacity = 0.075
            glowRadius = 3
            serialNumber = "No.003"

        case "cleanupTickets":
            plateColors = [Color(red: 0.01, green: 0.12, blue: 0.07), Color(red: 0.02, green: 0.34, blue: 0.17), .black]
            frameColors = [.white, .green, Color.yellow.opacity(0.65)]
            accentColor = .green
            hologramColor = .green
            symbolName = "leaf.fill"
            rarityText = "R"
            rarityColor = .white
            glowOpacity = 0.06
            glowRadius = 2.25
            serialNumber = "No.004"

        case "discountTickets":
            plateColors = [Color(red: 0.20, green: 0.10, blue: 0.01), Color(red: 0.62, green: 0.36, blue: 0.03), .black]
            frameColors = [.white, .yellow, .orange]
            accentColor = .yellow
            hologramColor = .orange
            symbolName = "yensign.circle.fill"
            rarityText = "R"
            rarityColor = .white
            glowOpacity = 0.075
            glowRadius = 3
            serialNumber = "No.005"

        case "halfPriceTickets":
            plateColors = [Color(red: 0.10, green: 0.02, blue: 0.17), Color(red: 0.42, green: 0.08, blue: 0.62), .black]
            frameColors = [.white, .purple, .yellow]
            accentColor = Color(red: 0.84, green: 0.56, blue: 1.0)
            hologramColor = .purple
            symbolName = "percent"
            rarityText = "SR"
            rarityColor = Color(red: 0.88, green: 0.66, blue: 1.0)
            glowOpacity = 0.15
            glowRadius = 5.25
            serialNumber = "No.006"

        default:
            plateColors = [
                Color(red: 0.28, green: 0.02, blue: 0.12),
                Color(red: 0.05, green: 0.24, blue: 0.42),
                Color(red: 0.27, green: 0.04, blue: 0.46),
                .black
            ]
            frameColors = [.white, .yellow, .pink, .cyan, .yellow]
            accentColor = .yellow
            hologramColor = .pink
            symbolName = "gift.fill"
            rarityText = "SSR"
            rarityColor = .yellow
            glowOpacity = 0.255
            glowRadius = 7.5
            serialNumber = "No.007"
        }
    }
}

private struct PremiumTicketPressedKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var premiumTicketIsPressed: Bool {
        get { self[PremiumTicketPressedKey.self] }
        set { self[PremiumTicketPressedKey.self] = newValue }
    }
}

private struct PremiumTicketTapStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(
                \.premiumTicketIsPressed,
                configuration.isPressed && isEnabled
            )
    }
}

private struct PremiumTicketArtworkGlow: ViewModifier {
    let ticketField: String
    let isEnabled: Bool

    @State private var glowPulse = false
    @State private var shimmerMoves = false

    private var isSSR: Bool { ticketField == "freeTickets" }
    private var isSR: Bool { ticketField == "halfPriceTickets" }

    private var glowColor: Color {
        if isSSR { return Color(red: 0.68, green: 0.46, blue: 1.0) }
        if isSR { return Color.purple }
        return Color(red: 0.96, green: 0.72, blue: 0.22)
    }

    private var borderColors: [Color] {
        if isSSR {
            return [.red, .yellow, .green, .cyan, .blue, .purple, .red]
        }
        if isSR {
            return [
                Color.white.opacity(0.70),
                Color.purple,
                Color(red: 0.78, green: 0.48, blue: 1.0)
            ]
        }
        return [
            Color.white.opacity(0.54),
            Color(red: 0.96, green: 0.72, blue: 0.22),
            Color(red: 0.56, green: 0.34, blue: 0.08)
        ]
    }

    private var minimumGlowOpacity: Double {
        if isSSR { return 0.18 }
        if isSR { return 0.13 }
        return 0.08
    }

    private var maximumGlowOpacity: Double {
        if isSSR { return 0.38 }
        if isSR { return 0.29 }
        return 0.19
    }

    private var minimumGlowRadius: CGFloat {
        if isSSR { return 5 }
        if isSR { return 4 }
        return 3
    }

    private var maximumGlowRadius: CGFloat {
        if isSSR { return 11 }
        if isSR { return 8 }
        return 6
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                    .opacity(
                        isEnabled
                            ? (glowPulse ? 0.76 : 0.34)
                            : 0
                    )
            }
            .overlay {
                ZStack {
                    Color.clear

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.62),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 16)
                        .rotationEffect(.degrees(12))
                        .offset(x: shimmerMoves ? 100 : -100)
                        .opacity(isEnabled && isSSR ? 0.58 : 0)
                        .animation(
                            .linear(duration: 0.55)
                                .delay(4.1)
                                .repeatForever(autoreverses: false),
                            value: shimmerMoves
                        )
                }
                .clipped()
            }
            .shadow(
                color: glowColor.opacity(
                    isEnabled
                        ? (glowPulse ? maximumGlowOpacity : minimumGlowOpacity)
                        : 0
                ),
                radius: glowPulse ? maximumGlowRadius : minimumGlowRadius
            )
            .animation(
                .easeInOut(duration: 1.3)
                    .repeatForever(autoreverses: true),
                value: glowPulse
            )
            .onAppear {
                glowPulse = true
                shimmerMoves = true
            }
    }
}

extension PointCardView {
    var flippingCard: some View {
        ZStack {
            memberCard
                .opacity(isFlipped ? 0 : 1)

            rankingCard
                .opacity(isFlipped ? 1 : 0)
        }
        .overlay {
            cardAuroraLayer
        }
        .overlay {
            PremiumPointCardTapFlash(isVisible: showCardTapFlash)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 28)
        )
        // 表面・ランキング面の反転
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.72
        )
        // 指の位置に合わせた立体的な傾き
        .rotation3DEffect(
            .degrees(Double(-cardDragOffset.height / 17)),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.62
        )
        .rotation3DEffect(
            .degrees(Double(cardDragOffset.width / 17)),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.62
        )
        .scaleEffect(isCardPressed ? 0.975 : 1.0)
        .offset(
            x: cardDragOffset.width * 0.035,
            y: cardDragOffset.height * 0.035
        )
        .shadow(
            color: .black.opacity(isCardPressed ? 0.20 : 0.30),
            radius: isCardPressed ? 11 : 20,
            x: -cardDragOffset.width * 0.07,
            y: 11 - cardDragOffset.height * 0.05
        )
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .gesture(cardInteractionGesture)
        .animation(
            .spring(response: 0.38, dampingFraction: 0.76),
            value: cardDragOffset
        )
        .animation(
            .spring(response: 0.26, dampingFraction: 0.72),
            value: isCardPressed
        )
    }

    private var cardInteractionGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isCardPressed = true

                cardDragOffset = CGSize(
                    width: max(-72, min(72, value.translation.width)),
                    height: max(-48, min(48, value.translation.height))
                )
            }
            .onEnded { value in
                let travel = hypot(
                    value.translation.width,
                    value.translation.height
                )

                if travel < 12 {
                    triggerCardTapFeedback()

                    withAnimation(
                        .spring(response: 0.56, dampingFraction: 0.80)
                    ) {
                        isFlipped.toggle()
                    }
                }

                withAnimation(
                    .spring(response: 0.42, dampingFraction: 0.72)
                ) {
                    cardDragOffset = .zero
                    isCardPressed = false
                }
            }
    }

    private func triggerCardTapFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.78)

        showCardTapFlash = false

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.10)) {
                showCardTapFlash = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeOut(duration: 0.34)) {
                showCardTapFlash = false
            }
        }
    }
    
    var memberCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    
                    Text("SiRiUS MEMBER CARD")
                        .offset(x: 0, y: 35)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .opacity(0.7)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(memberName.isEmpty ? "MEMBER" : memberName)
                        .offset(x: -12, y: 5)
                        .font(.system(size: 17, weight: .black))
                        .lineLimit(1)
                    
                    Text("No. \(String(format: "%06d", memberNo))")
                        .offset(x: -3, y: 5)
                        .font(.system(size: 9, weight: .bold))
                        .opacity(0.7)
                    
                    Text(rankBadge)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.1)
                        .padding(.horizontal, 8)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                        .offset(x: 0, y: 3)
                }
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                Text("TOTAL POINT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .opacity(0.7)
                
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(totalPoint)")
                        .font(.system(size: 52, weight: .black))
                    
                    Text("pt")
                        .font(.system(size: 18, weight: .black))
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            HStack(spacing: 7) {
                walletBox(title: "今月", value: "\(monthlyPoint)pt")
                walletBox(title: "利用可能", value: "\(availablePoint)pt")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                        .opacity(0.7)
                    
                    Text("\(nextReward.icon) \(nextReward.title)")
                        .font(.system(size: 10, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    Text("あと\(remainingPoint)pt")
                        .font(.system(size: 9, weight: .medium))
                        .opacity(0.7)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer(minLength: 6)
            
            HStack {
                Text("OFFICIAL MEMBER")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .opacity(0.6)
                
                Spacer()
                
                Image(systemName: "qrcode")
                    .font(.system(size: 18))
                    .opacity(0.2)
            }
        }
        .padding(14)
        .cardStyle(imageName: cardBackground, rank: rankBadge)
    }
    func walletBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .opacity(0.7)
            
            Text(value)
                .font(.system(size: 13, weight: .black))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 72, alignment: .leading)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    var rankingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("今月ランキング")
                    .font(.system(size: 18, weight: .black))
                
                Spacer()
                
                
            }
            
            Spacer(minLength: 8)
            
            if rankingMembers.isEmpty {
                Spacer()
                Text("ランキングを読み込み中...")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(rankingMembers.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: 7) {
                            Text(rankIcon(index))
                                .frame(width: 22)
                            
                            Text("\(index + 1)位")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 30, alignment: .leading)
                            
                            Text(member.name)
                                .font(.system(size: 14, weight: .black))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(member.monthlyPoint)pt")
                                .offset(x: -90)
                                .font(.system(size: 14, weight: .black))
                        }
                    }
                }
                
                Spacer(minLength: 8)
                
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 1)
                
                Spacer(minLength: 8)
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("あなた")
                            .font(.system(size: 10, weight: .bold))
                            .opacity(0.7)
                        
                        Text(myRank == 0 ? "-位" : "\(myRank)位")
                            .font(.system(size: 34, weight: .black))
                        
                        Text("現在の順位")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.65)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(myRankingPoint)pt")
                            .font(.system(size: 30, weight: .black))
                        
                        Text("今月ポイント")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.65)
                        
                        if myRank == 1 {
                            Text("👑 現在トップ！")
                                .font(.system(size: 11, weight: .black))
                        } else if pointToNextRank > 0 {
                            Text("あと\(pointToNextRank)pt")
                                .font(.system(size: 10, weight: .black))
                        }
                    }
                }
            }
        }
        .padding(14)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .cardStyle(imageName: cardBackground, rank: rankBadge)
    }
    var cardAuroraLayer: some View {
        PremiumPointCardEffects(
            rank: rankBadge,
            shimmerOffset: shimmerOffset,
            glowAnimation: glowAnimation
        )
    }
}
import SwiftUI

extension PointCardView {
    var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MY TICKETS")
                        .font(
                            .system(
                                size: 11,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(1.8)
                        .foregroundStyle(.secondary)

                    Text("保有チケット")
                        .font(.title2)
                        .bold()
                }

                Spacer()

                Text("\(totalTicketCount.formatted(.number.grouping(.automatic)))枚")
                    .font(.caption)
                    .fontWeight(.black)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Color.purple.opacity(0.12)
                    )
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
            
            LazyVStack(spacing: 12) {
                ticketRow(icon: "🎾", title: "ガット張り工賃無料券", count: stringingFreeTickets, ticketField: "stringingFreeTickets")
                ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets, ticketField: "challengeTickets")
                ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets, ticketField: "priorityTickets")
                ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets, ticketField: "cleanupTickets")
                ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets, ticketField: "discountTickets")
                ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets, ticketField: "halfPriceTickets")
                ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets, ticketField: "freeTickets")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.055, blue: 0.13),
                    Color(red: 0.025, green: 0.02, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.34),
                            Color.yellow.opacity(0.50),
                            Color.purple.opacity(0.40)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.purple.opacity(0.184), radius: 18.4, x: 0, y: 8)
    }
    
    var exchangeSection: some View {
        NavigationLink {
            TicketShopView()
        } label: {
            HStack(spacing: 14) {
                Text("🛒")
                    .font(.system(size: 41))
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.16),
                                Color.yellow.opacity(0.055)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.yellow.opacity(0.12), radius: 3, y: 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("チケットショップ")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("ポイントでチケットを交換")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.secondary)
                    .shadow(color: Color.yellow.opacity(0.22), radius: 2)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.yellow.opacity(0.035),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(
                color: .black.opacity(0.069),
                radius: 9.2,
                x: 0,
                y: 4.6
            )
        }
        .buttonStyle(.plain)
    }
    var monthlyAwardButton: some View {
        Button {
            checkMonthlyAward()
        } label: {
            HStack {
                Text("🏆")
                    .font(.system(size: 25))
                
                VStack(alignment: .leading) {
                    Text("前月の表彰を確定する")
                        .font(.headline)
                    
                    Text("終了した月の結果を殿堂入りしてポイントをリセット")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.17),
                        Color.yellow.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.055), radius: 6.9, y: 4)
        }
        .buttonStyle(.plain)
    }
    // MARK: - 殿堂入り演出テストボタン
    
    var celebrationTestButton: some View {
        Button {
            celebrationMonthText = testCelebrationMonthText()
            
            withAnimation(
                .spring(
                    response: 0.45,
                    dampingFraction: 0.82
                )
            ) {
                showHallOfFameCelebration = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.18),
                                    Color.pink.opacity(0.15),
                                    Color.purple.opacity(0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                    
                    Text("🎉")
                        .font(.system(size: 29))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("殿堂入り演出をテスト")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("保存やポイントリセットは行いません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.10),
                        Color.pink.opacity(0.08),
                        Color.purple.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.30),
                                Color.pink.opacity(0.22),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.6)
                    .padding(1)
            }
            .shadow(color: .black.opacity(0.055), radius: 6.9, y: 4)
        }
        .buttonStyle(.plain)
    }
    // MARK: - MVP選択テストボタン
    
    var mvpSelectionTestButton: some View {
        Button {
            prepareMVPSelectionTest()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.20),
                                    Color.orange.opacity(0.16),
                                    Color.purple.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                    
                    Text("⭐")
                        .font(.system(size: 29))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("月間MVP選択をテスト")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("保存やポイントリセットは行いません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.08),
                        Color.orange.opacity(0.07),
                        Color.purple.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.32),
                                Color.orange.opacity(0.24),
                                Color.purple.opacity(0.18)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.6)
                    .padding(1)
            }
            .shadow(color: .black.opacity(0.055), radius: 6.9, y: 4)
        }
        .buttonStyle(.plain)
    }
    var totalTicketCount: Int {
        cleanupTickets
        + discountTickets
        + halfPriceTickets
        + freeTickets
        + challengeTickets
        + priorityTickets
        + stringingFreeTickets
    }

    func ticketRow(icon: String, title: String, count: Int, ticketField: String) -> AnyView {
        AnyView(Button {
            guard count > 0 else { return }

            if ticketField == "priorityTickets" || ticketField == "challengeTickets" {
                showActivityTicketAlert = true
                return
            }
            
            selectedTicketTitle = title
            selectedTicketField = ticketField
            selectedTicketIcon = icon
            showUseTicketAlert = true
        } label: {
            HStack(spacing: 10) {
                PremiumOwnedTicketArtworkView(
                    ticketField: ticketField,
                    iconGlowActive: glowAnimation && count > 0
                )
                    .equatable()
                    .frame(
                        width: PremiumOwnedTicketArtworkView.artworkWidth,
                        height: PremiumOwnedTicketArtworkView.artworkHeight,
                        alignment: .center
                    )
                    .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                        .shadow(color: Color.black.opacity(0.72), radius: 2, y: 1)

                    Text("残り \(count)枚")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(minWidth: 82, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)

                Text("×\(count)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: 52, alignment: .trailing)
                    .foregroundStyle(
                        count > 0 ? Color.white : Color.white.opacity(0.38)
                    )
                    .shadow(
                        color: count > 0
                            ? Color.purple.opacity(0.55)
                            : Color.clear,
                        radius: 8
                    )

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .frame(width: 10, alignment: .trailing)
                    .foregroundStyle(
                        count > 0
                            ? Color.yellow.opacity(0.86)
                            : Color.white.opacity(0.24)
                    )
            }
            .padding(.leading, 9)
            .padding(.trailing, 12)
            .frame(height: 137)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(count > 0 ? 0.065 : 0.035))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        count > 0
                            ? Color.yellow.opacity(0.22)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(PremiumTicketTapStyle(isEnabled: count > 0))
        .disabled(count <= 0))
    }

    
    func exchangeButton(title: String, point: Int, icon: String, ticketField: String) -> some View {
        Button {
            PointService.shared.exchangeTicket(
                memberId: currentUserId,
                requiredPoint: point,
                ticketField: ticketField,
                title: title,
                icon: icon
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                loadMember()
                loadRanking()
            }
        } label: {
            HStack {
                Text(icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    
                    Text("\(point)ptで交換")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                availablePoint >= point
                ? Color.blue.opacity(0.12)
                : Color.gray.opacity(0.12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(availablePoint < point)
    }
    
    var pointRuleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ポイントルール")
                .font(.headline)
            
            ruleRow("🏸 練習参加", "+5pt")
            ruleRow("⏰ 前日の18:00までに参加回答", "+2pt")
            ruleRow("🔧 設営参加", "+5pt")
            ruleRow("👥 Bクラス入賞者レベル以上の方を新規で連れてくる", "+20pt")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.046), radius: 6.9)
    }
    
    func ruleRow(_ title: String, _ point: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .lineSpacing(2)
            
            Spacer()
            
            Text(point)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.blue)
        }
    }
    
    func rankIcon(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "🏸"
        }
    }
}
import SwiftUI
import FirebaseFirestore

extension PointCardView {
    func loadMember() {
        guard !currentUserId.isEmpty else { return }
        
        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                
                let oldPoint = totalPoint
                let newPoint = data["totalPoint"] as? Int ?? 0
                
                totalPoint = newPoint
                animateDisplayedPoint(to: newPoint)
                availablePoint = data["availablePoint"] as? Int ?? 0
                monthlyPoint = data["monthlyPoint"] as? Int ?? 0
                
                cleanupTickets = data["cleanupTickets"] as? Int ?? 0
                discountTickets = data["discountTickets"] as? Int ?? 0
                halfPriceTickets = data["halfPriceTickets"] as? Int ?? 0
                freeTickets = data["freeTickets"] as? Int ?? 0
                stringingFreeTickets = data["stringingFreeTickets"] as? Int ?? 0
                challengeTickets = data["challengeTickets"] as? Int ?? 0
                priorityTickets = data["priorityTickets"] as? Int ?? 0
                
                memberNo = data["memberNo"] as? Int ?? 999999
                memberName = data["name"] as? String ?? "MEMBER"
                
                monthlyChampionCount = data["monthlyChampionCount"] as? Int ?? 0
                monthlySecondCount = data["monthlySecondCount"] as? Int ?? 0
                monthlyThirdCount = data["monthlyThirdCount"] as? Int ?? 0
                mvpCount = data["mvpCount"] as? Int ?? 0
                
                if hasLoadedMember {
                    checkRankUp(oldPoint: oldPoint, newPoint: newPoint)
                } else {
                    hasLoadedMember = true
                }
            }
    }
    
    func useTicket() {
        PointService.shared.useTicket(
            memberId: currentUserId,
            ticketField: selectedTicketField,
            title: selectedTicketTitle,
            icon: selectedTicketIcon
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loadMember()
        }
    }
    
    func checkRankUp(oldPoint: Int, newPoint: Int) {
        if oldPoint < 700 && newPoint >= 700 {
            rankUpMessage = "👑 Legend Player\n\n⭐ 対戦指名券 ×2\n🚀 優先ゲーム券 ×2 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 400 && newPoint >= 400 {
            rankUpMessage = "💎 Platinum Player\n\n⭐ 対戦指名券 ×1\n🚀 優先ゲーム券 ×1 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 200 && newPoint >= 200 {
            rankUpMessage = "🥇 Gold Player\n\n⭐ 対戦指名券 ×2 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 100 && newPoint >= 100 {
            rankUpMessage = "🥈 Silver Player\n\n⭐ 対戦指名券 ×1 を獲得しました！"
            showRankUpAlert = true
        }
    }
    
    func loadRanking() {
        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
            .getDocuments { snapshot, _ in
                let members = snapshot?.documents.compactMap { document -> Member? in
                    let data = document.data()
                    
                    return Member(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        role: MemberRole(rawValue: data["role"] as? String ?? "メンバー") ?? .member,
                        isAdmin: data["isAdmin"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,
                        gender: Gender(rawValue: data["gender"] as? String ?? "男性") ?? .male,
                        level: MemberLevel(rawValue: data["level"] as? String ?? "初心者") ?? .beginner,
                        totalPoint: data["totalPoint"] as? Int ?? 0,
                        availablePoint: data["availablePoint"] as? Int ?? 0,
                        cleanupTickets: data["cleanupTickets"] as? Int ?? 0,
                        discountTickets: data["discountTickets"] as? Int ?? 0,
                        halfPriceTickets: data["halfPriceTickets"] as? Int ?? 0,
                        freeTickets: data["freeTickets"] as? Int ?? 0,
                        challengeTickets: data["challengeTickets"] as? Int ?? 0,
                        priorityTickets: data["priorityTickets"] as? Int ?? 0,
                        attendanceCount: data["attendanceCount"] as? Int ?? 0,
                        setupCount: data["setupCount"] as? Int ?? 0,
                        monthlyChampionCount: data["monthlyChampionCount"] as? Int ?? 0,
                        monthlySecondCount: data["monthlySecondCount"] as? Int ?? 0,
                        monthlyThirdCount: data["monthlyThirdCount"] as? Int ?? 0,
                        mvpCount: data["mvpCount"] as? Int ?? 0,
                        monthlyPoint: data["monthlyPoint"] as? Int ?? 0,
                        legendCount: data["legendCount"] as? Int ?? 0,
                        isLegend: data["isLegend"] as? Bool ?? false,
                        profileImageBase64: data["profileImageBase64"] as? String ?? ""
                    )
                } ?? []
                
                rankingMembers = Array(members.prefix(10))
                
                if let index = members.firstIndex(where: { $0.id == currentUserId }) {
                    myRank = index + 1
                    myRankingPoint = members[index].monthlyPoint
                    
                    if index == 0 {
                        pointToNextRank = 0
                        targetRank = 0
                    } else if index >= 5, members.count >= 5 {
                        let targetPoint = members[4].monthlyPoint
                        pointToNextRank = max(targetPoint - myRankingPoint + 1, 0)
                        targetRank = 5
                    } else {
                        let targetPoint = members[index - 1].monthlyPoint
                        pointToNextRank = max(targetPoint - myRankingPoint + 1, 0)
                        targetRank = index
                    }
                } else {
                    myRank = 0
                    myRankingPoint = 0
                    pointToNextRank = 0
                    targetRank = 0
                }
            }
    }
}
import SwiftUI
import FirebaseFirestore

extension PointCardView {
    func grantMonthlyAwards() {
        guard rankingMembers.count >= 3 else {
            return
        }
        
        guard !awardTargetMonth.isEmpty else {
            return
        }
        
        guard let selectedMVP else {
            showMVPRequiredAlert = true
            return
        }
        
        let targetMonth = awardTargetMonth
        let newActiveMonth = monthKey(from: Date())
        
        let firstMember = rankingMembers[0]
        let secondMember = rankingMembers[1]
        let thirdMember = rankingMembers[2]
        
        // 現在保持しているランキングの上位10人
        let topTenMembers = Array(
            rankingMembers.prefix(10)
        )
        
        // 参加王
        let attendanceKing =
        topTenMembers.max {
            first,
            second in
            
            if first.attendanceCount
                == second.attendanceCount {
                return first.monthlyPoint
                < second.monthlyPoint
            }
            
            return first.attendanceCount
            < second.attendanceCount
        }
        
        // 設営王
        let setupKing =
        topTenMembers.max {
            first,
            second in
            
            if first.setupCount
                == second.setupCount {
                return first.monthlyPoint
                < second.monthlyPoint
            }
            
            return first.setupCount
            < second.setupCount
        }
        
        // Firestoreへ保存するTOP10データ
        let topTenData: [[String: Any]] =
        topTenMembers.enumerated().map {
            index,
            member in
            
            [
                "rank": index + 1,
                "memberId": member.id,
                "name": member.name,
                "point": member.monthlyPoint,
                "profileImageBase64":
                    member.profileImageBase64
            ]
        }
        
        var hallOfFameData: [String: Any] = [
            "month": targetMonth,
            
            // ポイント王
            "championId": firstMember.id,
            "championName": firstMember.name,
            "championPoint":
                firstMember.monthlyPoint,
            
            "pointKingId": firstMember.id,
            "pointKingName": firstMember.name,
            "pointKingPoint":
                firstMember.monthlyPoint,
            
            // ポイント2位
            "secondId": secondMember.id,
            "secondName": secondMember.name,
            "secondPoint":
                secondMember.monthlyPoint,
            
            // ポイント3位
            "thirdId": thirdMember.id,
            "thirdName": thirdMember.name,
            "thirdPoint":
                thirdMember.monthlyPoint,
            
            // 月間MVP
            "mvpId": selectedMVP.id,
            "mvpName": selectedMVP.name,
            "mvpPoint":
                selectedMVP.monthlyPoint,
            
            // TOP10
            "pointRankingTop10": topTenData,
            
            "createdAt": Timestamp()
        ]
        
        if let attendanceKing {
            hallOfFameData[
                "attendanceKingId"
            ] = attendanceKing.id
            
            hallOfFameData[
                "attendanceKingName"
            ] = attendanceKing.name
            
            hallOfFameData[
                "attendanceKingCount"
            ] = attendanceKing.attendanceCount
        } else {
            hallOfFameData[
                "attendanceKingId"
            ] = ""
            
            hallOfFameData[
                "attendanceKingName"
            ] = ""
            
            hallOfFameData[
                "attendanceKingCount"
            ] = 0
        }
        
        if let setupKing {
            hallOfFameData[
                "setupKingId"
            ] = setupKing.id
            
            hallOfFameData[
                "setupKingName"
            ] = setupKing.name
            
            hallOfFameData[
                "setupKingCount"
            ] = setupKing.setupCount
        } else {
            hallOfFameData[
                "setupKingId"
            ] = ""
            
            hallOfFameData[
                "setupKingName"
            ] = ""
            
            hallOfFameData[
                "setupKingCount"
            ] = 0
        }
        
        db.collection("hallOfFame")
            .document(targetMonth)
            .setData(
                hallOfFameData
            ) { error in
                if let error {
                    print(
                        "hallOfFame保存失敗: "
                        + error.localizedDescription
                    )
                    return
                }
                
                print(
                    "hallOfFame保存成功: "
                    + targetMonth
                )
                
                // 1位
                PointService.shared.addMonthlyAward(
                    memberId: firstMember.id,
                    field: "monthlyChampionCount"
                )
                
                db.collection("members")
                    .document(firstMember.id)
                    .updateData([
                        "earnedBadges":
                            FieldValue.arrayUnion([
                                "monthlyChampion"
                            ])
                    ])
                
                // 2位
                PointService.shared.addMonthlyAward(
                    memberId: secondMember.id,
                    field: "monthlySecondCount"
                )
                
                // 3位
                PointService.shared.addMonthlyAward(
                    memberId: thirdMember.id,
                    field: "monthlyThirdCount"
                )
                
                // MVP受賞回数
                PointService.shared.addMonthlyAward(
                    memberId: selectedMVP.id,
                    field: "mvpCount"
                )
                
                // MVPバッジ
                db.collection("members")
                    .document(selectedMVP.id)
                    .updateData([
                        "earnedBadges":
                            FieldValue.arrayUnion([
                                "monthlyMVP"
                            ])
                    ]) { mvpError in
                        if let mvpError {
                            print(
                                "MVPバッジ付与失敗: "
                                + mvpError
                                    .localizedDescription
                            )
                        }
                    }
                
                // 今月ポイントをリセット
                PointService.shared
                    .resetAllMonthlyPoints()
                
                // 月間設定更新
                db.collection("settings")
                    .document("monthlyAward")
                    .setData(
                        [
                            "lastAwardMonth":
                                targetMonth,
                            "activeMonth":
                                newActiveMonth,
                            "awardedAt":
                                Timestamp()
                        ],
                        merge: true
                    ) { settingsError in
                        if let settingsError {
                            print(
                                "月間設定更新失敗: "
                                + settingsError
                                    .localizedDescription
                            )
                        }
                    }
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.8
                ) {
                    loadMember()
                    loadRanking()
                    
                    awardTargetMonth = ""
                    celebrationMonthText =
                    formattedAwardMonth(
                        targetMonth
                    )
                    announcedMVPName = selectedMVP.name
                    announcedMVPImageBase64 =
                        selectedMVP.profileImageBase64
                    self.selectedMVP = nil
                    mvpCandidates = []
                    
                    withAnimation(.spring()) {
                        showHallOfFameCelebration =
                        true
                    }
                }
            }
    }
    func checkMonthlyAward() {
        let currentMonth = monthKey(from: Date())
        
        db.collection("settings")
            .document("monthlyAward")
            .getDocument { snapshot, error in
                if let error {
                    print(
                        "月間表彰設定の取得失敗: \(error.localizedDescription)"
                    )
                    return
                }
                
                let data = snapshot?.data()
                let activeMonth =
                data?["activeMonth"] as? String ?? ""
                
                let lastAwardMonth =
                data?["lastAwardMonth"] as? String ?? ""
                
                // 初回設定
                // 現在のmonthlyPointは今月分として登録する
                if activeMonth.isEmpty {
                    db.collection("settings")
                        .document("monthlyAward")
                        .setData(
                            [
                                "activeMonth": currentMonth
                            ],
                            merge: true
                        )
                    
                    DispatchQueue.main.async {
                        showAwardNotReadyAlert = true
                    }
                    
                    return
                }
                
                // activeMonthと現在月が同じなら、
                // まだその月は終了していない
                if activeMonth == currentMonth {
                    DispatchQueue.main.async {
                        showAwardNotReadyAlert = true
                    }
                    
                    return
                }
                
                // すでに確定済み
                if lastAwardMonth == activeMonth {
                    DispatchQueue.main.async {
                        showAlreadyAwardedAlert = true
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    prepareMVPSelection(
                        targetMonth: activeMonth
                    )
                }
            }
    }
}
import SwiftUI
import FirebaseFirestore

extension PointCardView {
    // MARK: - MVP選択準備
    
    func prepareMVPSelection(
        targetMonth: String
    ) {
        awardTargetMonth = targetMonth
        selectedMVP = nil
        mvpCandidates = []
        
        db.collection("members")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error {
                    print(
                        "MVP候補取得失敗: \(error.localizedDescription)"
                    )
                    
                    DispatchQueue.main.async {
                        showMVPRequiredAlert = true
                    }
                    return
                }
                
                let members =
                snapshot?.documents.compactMap {
                    document -> Member? in
                    
                    let data = document.data()
                    
                    let name =
                    data["name"] as? String
                    ?? ""
                    
                    guard !name.isEmpty else {
                        return nil
                    }
                    
                    return Member(
                        id: document.documentID,
                        name: name,
                        role:
                            MemberRole(
                                rawValue:
                                    data["role"] as? String
                                ?? ""
                            )
                        ?? .member,
                        isAdmin:
                            data["isAdmin"] as? Bool
                        ?? false,
                        isActive:
                            data["isActive"] as? Bool
                        ?? true,
                        totalPoint:
                            data["totalPoint"] as? Int
                        ?? 0,
                        availablePoint:
                            data["availablePoint"] as? Int
                        ?? 0,
                        attendanceCount:
                            data["attendanceCount"] as? Int
                        ?? 0,
                        setupCount:
                            data["setupCount"] as? Int
                        ?? 0,
                        monthlyPoint:
                            data["monthlyPoint"] as? Int
                        ?? 0,
                        profileImageBase64:
                            data["profileImageBase64"]
                        as? String
                        ?? ""
                    )
                }
                ?? []
                
                DispatchQueue.main.async {
                    mvpCandidates = members.sorted {
                        $0.name.localizedStandardCompare(
                            $1.name
                        ) == .orderedAscending
                    }
                    
                    showMVPSelectionSheet = true
                }
            }
    }
    // MARK: - MVP選択テスト準備

    func prepareMVPSelectionTest() {
        isMVPSelectionTestMode = true
        selectedMVP = nil

        // すでにランキングで取得済みのメンバーを即座に利用
        let cachedMembers = rankingMembers
            .filter { member in
                member.isActive && !member.name.isEmpty
            }
            .sorted {
                $0.name.localizedStandardCompare(
                    $1.name
                ) == .orderedAscending
            }

        if !cachedMembers.isEmpty {
            mvpCandidates = cachedMembers
            showMVPSelectionSheet = true
            return
        }

        // キャッシュが空の場合のみFirestoreから取得
        mvpCandidates = []

        db.collection("members")
            .getDocuments { snapshot, error in
                if let error {
                    print(
                        "MVPテスト候補取得失敗: "
                        + error.localizedDescription
                    )

                    DispatchQueue.main.async {
                        isMVPSelectionTestMode = false
                        showMVPRequiredAlert = true
                    }
                    return
                }

                let members =
                    snapshot?.documents.compactMap {
                        document -> Member? in

                        let data = document.data()

                        let name =
                            data["name"] as? String
                            ?? ""

                        let isActive =
                            data["isActive"] as? Bool
                            ?? true

                        guard
                            !name.isEmpty,
                            isActive
                        else {
                            return nil
                        }

                        return Member(
                            id: document.documentID,
                            name: name,
                            role:
                                MemberRole(
                                    rawValue:
                                        data["role"] as? String
                                        ?? ""
                                )
                                ?? .member,
                            isAdmin:
                                data["isAdmin"] as? Bool
                                ?? false,
                            isActive: isActive,
                            totalPoint:
                                data["totalPoint"] as? Int
                                ?? 0,
                            availablePoint:
                                data["availablePoint"] as? Int
                                ?? 0,
                            attendanceCount:
                                data["attendanceCount"] as? Int
                                ?? 0,
                            setupCount:
                                data["setupCount"] as? Int
                                ?? 0,
                            monthlyPoint:
                                data["monthlyPoint"] as? Int
                                ?? 0,
                            profileImageBase64:
                                data["profileImageBase64"] as? String
                                ?? ""
                        )
                    }
                    ?? []

                DispatchQueue.main.async {
                    mvpCandidates = members.sorted {
                        $0.name.localizedStandardCompare(
                            $1.name
                        ) == .orderedAscending
                    }

                    showMVPSelectionSheet = true
                }
            }
    }
    // MARK: - 演出テスト用月表示
    
    func testCelebrationMonthText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        
        return formatter.string(from: Date())
    }
    func monthKey(
        from date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale =
        Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM"
        
        return formatter.string(from: date)
    }
    
    func formattedAwardMonth(
        _ month: String
    ) -> String {
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
                inputFormatter.date(from: month)
        else {
            return month
        }
        
        return outputFormatter.string(from: date)
    }
}
import SwiftUI

// MARK: - MVP選択画面

struct MVPSelectionView: View {
    let candidates: [Member]
    
    @Binding var selectedMVP: Member?
    
    let onConfirm: () -> Void
    
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        List {
            Section {
                if candidates.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        
                        Text("メンバーを読み込み中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 120
                    )
                    
                } else {
                    ForEach(candidates) { member in
                        Button {
                            selectedMVP = member
                        } label: {
                            HStack(spacing: 14) {
                                ProfileImageView(
                                    imageBase64:
                                        member.profileImageBase64,
                                    size: 50
                                )
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selectedMVP?.id
                                            == member.id
                                            ? Color.orange
                                            : Color.gray
                                                .opacity(0.25),
                                            lineWidth:
                                                selectedMVP?.id
                                            == member.id
                                            ? 3
                                            : 1
                                        )
                                }
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    Text(member.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 10) {
                                        Text(
                                            "今月 \(member.monthlyPoint)pt"
                                        )
                                        
                                        Text(
                                            "参加 \(member.attendanceCount)回"
                                        )
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedMVP?.id
                                    == member.id {
                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                } else {
                                    Image(
                                        systemName: "circle"
                                    )
                                    .font(.title2)
                                    .foregroundStyle(
                                        .gray.opacity(0.35)
                                    )
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("今月もっとも活躍したメンバーを選択")
            } footer: {
                Text(
                    "MVPは管理者の判断で1人選択します。"
                )
            }
        }
        .navigationTitle("月間MVPを選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .cancellationAction
            ) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("決定") {
                    onConfirm()
                }
                .fontWeight(.bold)
                .disabled(selectedMVP == nil)
            }
        }
    }
}
import SwiftUI


// MARK: - Premium Point Background

private struct PremiumPointAmbientBackground: View {
    let rank: String
    let pulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(primaryColor.opacity(pulse ? 0.11 : 0.05))
                .frame(width: 310, height: 310)
                .blur(radius: 28)
                .offset(x: 145, y: -330)
                .scaleEffect(pulse ? 1.10 : 0.92)

            Circle()
                .fill(secondaryColor.opacity(pulse ? 0.08 : 0.035))
                .frame(width: 285, height: 285)
                .blur(radius: 30)
                .offset(x: -155, y: 80)
                .scaleEffect(pulse ? 1.06 : 0.94)

            Circle()
                .fill(Color.cyan.opacity(0.045))
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: 135, y: 560)

            PremiumPointBackgroundParticles(
                primaryColor: primaryColor
            )
        }
    }

    private var primaryColor: Color {
        switch rank {
        case "LEGEND": return .yellow
        case "PLATINUM": return .cyan
        case "GOLD": return .orange
        case "SILVER": return .blue
        default: return .orange
        }
    }

    private var secondaryColor: Color {
        switch rank {
        case "LEGEND": return .pink
        case "PLATINUM": return .purple
        case "GOLD": return .yellow
        case "SILVER": return .white
        default: return .red
        }
    }
}

private struct PremiumPointBackgroundParticles: View {
    let primaryColor: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 16.0)) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                ZStack {
                    ForEach(0..<12, id: \.self) { index in
                        let seed = Double(index + 1)
                        let xBase =
                            CGFloat(
                                sin(seed * 13.7)
                            ) * proxy.size.width * 0.43
                        let yBase =
                            CGFloat(index) * 105 - 80

                        Circle()
                            .fill(
                                index.isMultiple(of: 2)
                                ? Color.white.opacity(0.24)
                                : primaryColor.opacity(0.24)
                            )
                            .frame(
                                width:
                                    index.isMultiple(of: 3)
                                    ? 3.2
                                    : 2.0,
                                height:
                                    index.isMultiple(of: 3)
                                    ? 3.2
                                    : 2.0
                            )
                            .position(
                                x:
                                    proxy.size.width / 2
                                    + xBase
                                    + CGFloat(
                                        sin(
                                            time * 0.35
                                            + seed
                                        )
                                    ) * 11,
                                y:
                                    yBase
                                    + CGFloat(
                                        cos(
                                            time * 0.30
                                            + seed
                                        )
                                    ) * 12
                            )
                            .shadow(
                                color:
                                    primaryColor.opacity(0.42),
                                radius: 4
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Premium Point Card Effects

private struct PremiumPointCardTapFlash: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.08),
                    .white.opacity(0.92),
                    .white.opacity(0.18),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 82, height: 520)
            .rotationEffect(.degrees(-24))
            .scaleEffect(isVisible ? 1.15 : 0.75)
            .offset(x: isVisible ? 250 : -250)
            .blur(radius: 2.6)

            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isVisible ? 0.95 : 0),
                            .cyan.opacity(isVisible ? 0.55 : 0),
                            .purple.opacity(isVisible ? 0.48 : 0),
                            .white.opacity(isVisible ? 0.76 : 0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isVisible ? 2.0 : 0.8
                )
                .blur(radius: isVisible ? 0.8 : 2.5)
        }
        .opacity(isVisible ? 1 : 0)
        .blendMode(.screen)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.32), value: isVisible)
    }
}

private struct PremiumPointCardEffects: View {
    let rank: String
    let shimmerOffset: CGFloat
    let glowAnimation: Bool

    var body: some View {
        ZStack {
            RadialGradient(
                colors: auraColors,
                center: glowAnimation ? .topTrailing : .bottomLeading,
                startRadius: 10,
                endRadius: 330
            )
            .scaleEffect(glowAnimation ? 1.08 : 0.94)
            .opacity(glowAnimation ? 0.62 : 0.34)
            .blur(radius: 13)

            LinearGradient(
                colors: hologramColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 68, height: 520)
            .rotationEffect(.degrees(-23))
            .offset(x: shimmerOffset * 360)
            .blur(radius: 6)

            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.04),
                    .white.opacity(0.32),
                    .white.opacity(0.68),
                    .white.opacity(0.20),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 26, height: 500)
            .rotationEffect(.degrees(-23))
            .offset(x: shimmerOffset * 405)
            .blur(radius: 2.2)

            PremiumPointCardParticles(rank: rank)
        }
        .compositingGroup()
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private var auraColors: [Color] {
        switch rank {
        case "LEGEND":
            return [.yellow.opacity(0.25), .pink.opacity(0.15), .cyan.opacity(0.13), .clear]
        case "PLATINUM":
            return [.cyan.opacity(0.20), .purple.opacity(0.14), .pink.opacity(0.10), .clear]
        case "GOLD":
            return [.yellow.opacity(0.27), .orange.opacity(0.15), .clear]
        case "SILVER":
            return [.white.opacity(0.29), .blue.opacity(0.13), .clear]
        default:
            return [.orange.opacity(0.18), .red.opacity(0.09), .clear]
        }
    }

    private var hologramColors: [Color] {
        switch rank {
        case "LEGEND", "PLATINUM":
            return [.clear, .cyan.opacity(0.37), .purple.opacity(0.35), .pink.opacity(0.34), .yellow.opacity(0.35), .clear]
        case "GOLD":
            return [.clear, .yellow.opacity(0.38), .white.opacity(0.48), .orange.opacity(0.32), .clear]
        case "SILVER":
            return [.clear, .blue.opacity(0.23), .white.opacity(0.53), .cyan.opacity(0.21), .clear]
        default:
            return [.clear, .orange.opacity(0.30), .white.opacity(0.39), .red.opacity(0.21), .clear]
        }
    }
}

private struct PremiumPointCardParticles: View {
    let rank: String

    private var count: Int {
        switch rank {
        case "LEGEND": return 14
        case "PLATINUM": return 10
        case "GOLD": return 8
        case "SILVER": return 6
        default: return 4
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for index in 0..<count {
                    let seed = Double(index + 1)
                    let x = random(seed * 17.13) * size.width
                    let y = random(seed * 31.71) * size.height
                    let pulse = (sin(time * (1.4 + random(seed * 9.07)) + seed) + 1) * 0.5
                    let radius = 1.2 + random(seed * 4.11) * 2.2
                    let center = CGPoint(x: x, y: y)

                    context.opacity = 0.10 + pulse * 0.55
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(particleColor(index))
                    )

                    if index.isMultiple(of: 3) {
                        let beam = radius * 2.7
                        var path = Path()
                        path.move(to: CGPoint(x: center.x - beam, y: center.y))
                        path.addLine(to: CGPoint(x: center.x + beam, y: center.y))
                        path.move(to: CGPoint(x: center.x, y: center.y - beam))
                        path.addLine(to: CGPoint(x: center.x, y: center.y + beam))
                        context.stroke(path, with: .color(.white.opacity(0.72)), lineWidth: 0.5)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func particleColor(_ index: Int) -> Color {
        switch rank {
        case "LEGEND", "GOLD": return index.isMultiple(of: 2) ? .yellow : .white
        case "PLATINUM": return index.isMultiple(of: 2) ? .cyan : .white
        case "SILVER": return index.isMultiple(of: 2) ? .blue.opacity(0.55) : .white
        default: return index.isMultiple(of: 2) ? .orange : .white
        }
    }

    private func random(_ value: Double) -> Double {
        let raw = sin(value * 12.9898) * 43758.5453
        return raw - floor(raw)
    }
}

extension View {
    func cardStyle(imageName: String, rank: String) -> some View {
        self
            .foregroundStyle(.white)
            .frame(width: 340, height: 214)
            .background {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 340, height: 214)
                        .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear, .black.opacity(0.27)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    LinearGradient(
                        colors: [.white.opacity(0.12), .clear, .white.opacity(0.025)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.screen)

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.065)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.78),
                                premiumRankColor(rank).opacity(0.50),
                                .white.opacity(0.10),
                                .white.opacity(0.40)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.15
                    )
            }
            .shadow(color: premiumRankColor(rank).opacity(0.16), radius: 18)
            .shadow(color: .black.opacity(0.27), radius: 14, x: 0, y: 9)
    }

    func cardStyle(imageName: String) -> some View {
        cardStyle(imageName: imageName, rank: "BRONZE")
    }

    private func premiumRankColor(_ rank: String) -> Color {
        switch rank {
        case "LEGEND": return .yellow
        case "PLATINUM": return .cyan
        case "GOLD": return .orange
        case "SILVER": return Color(red: 0.78, green: 0.86, blue: 0.98)
        default: return Color(red: 0.76, green: 0.35, blue: 0.14)
        }
    }
}
