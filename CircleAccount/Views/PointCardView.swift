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
                VStack(spacing: 22) {
                    premiumHeader

                    flippingCard
                        .opacity(screenAppeared ? 1 : 0)
                        .offset(y: screenAppeared ? 0 : 24)

                    premiumPointSummary
                    
                    Text("カードをタップするとランキングが見れます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ticketsSection
                    exchangeSection
                    
                    if currentUserIsAdmin {
                        monthlyAwardButton
                        mvpSelectionTestButton
                        celebrationTestButton
                    }
                    
                    Button {
                        showHallOfFame = true
                    } label: {
                        Label("歴代チャンピオンを見る", systemImage: "crown.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        PointHistoryView()
                    } label: {
                        Label("ポイント履歴を見る", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    
                    if currentUserIsAdmin {
                        NavigationLink {
                            TicketUsageHistoryView()
                        } label: {
                            Label("🎫 チケット使用履歴", systemImage: "clock.badge.checkmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
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

                withAnimation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
                ) {
                    glowAnimation = true
                }

                withAnimation(
                    .linear(duration: 4.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 1.5
                }

                withAnimation(
                    .easeInOut(duration: 1.45)
                    .repeatForever(autoreverses: true)
                ) {
                    backgroundPulse = true
                }

                withAnimation(
                    .linear(duration: 2.8)
                    .repeatForever(autoreverses: false)
                ) {
                    titleShimmerOffset = 1.4
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
                            premiumRankPrimaryColor,
                            Color.white,
                            premiumRankSecondaryColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.95),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 70)
                    .rotationEffect(.degrees(-18))
                    .offset(x: titleShimmerOffset * 170)
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
}
import SwiftUI

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

                Text("\(totalTicketCount)枚")
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
            
            ticketRow(icon: "🎾", title: "ガット張り工賃無料券", count: stringingFreeTickets, ticketField: "stringingFreeTickets")
            Divider()
            ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets, ticketField: "challengeTickets")
            Divider()
            ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets, ticketField: "priorityTickets")
            Divider()
            ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets, ticketField: "cleanupTickets")
            Divider()
            ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets, ticketField: "discountTickets")
            Divider()
            ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets, ticketField: "halfPriceTickets")
            Divider()
            ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets, ticketField: "freeTickets")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    var exchangeSection: some View {
        NavigationLink {
            TicketShopView()
        } label: {
            HStack(spacing: 14) {
                Text("🛒")
                    .font(.system(size: 38))
                    .frame(width: 56, height: 56)
                    .background(Color.blue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
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
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(
                color: .black.opacity(0.06),
                radius: 8,
                x: 0,
                y: 4
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
                    .font(.title2)
                
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
            .background(Color.orange.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 18))
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

    func ticketRow(icon: String, title: String, count: Int, ticketField: String) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text("残り \(count)枚")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()

            Text("\(count)")
                .font(
                    .system(
                        size: 17,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    count > 0 ? Color.primary : Color.secondary
                )

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(
                    count > 0
                    ? Color.purple
                    : Color.secondary.opacity(0.45)
                )
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            guard count > 0 else { return }
            
            if ticketField == "priorityTickets" || ticketField == "challengeTickets" {
                showActivityTicketAlert = true
                return
            }
            
            selectedTicketTitle = title
            selectedTicketField = ticketField
            selectedTicketIcon = icon
            showUseTicketAlert = true
        }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("ポイントルール")
                .font(.headline)
            
            ruleRow("🏸 練習参加", "+5pt")
            ruleRow("⏰ 前日の18:00までに参加回答", "+2pt")
            ruleRow("🔧 設営参加", "+5pt")
            ruleRow("👥 Bクラス入賞者レベル以上の方を新規で連れてくる", "+20pt")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
    
    func ruleRow(_ title: String, _ point: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
            
            Spacer()
            
            Text(point)
                .font(.caption)
                .bold()
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
            .frame(width: 76, height: 520)
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
            .frame(width: 30, height: 500)
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
            return [.clear, .cyan.opacity(0.32), .purple.opacity(0.30), .pink.opacity(0.29), .yellow.opacity(0.30), .clear]
        case "GOLD":
            return [.clear, .yellow.opacity(0.33), .white.opacity(0.43), .orange.opacity(0.27), .clear]
        case "SILVER":
            return [.clear, .blue.opacity(0.18), .white.opacity(0.48), .cyan.opacity(0.16), .clear]
        default:
            return [.clear, .orange.opacity(0.25), .white.opacity(0.34), .red.opacity(0.16), .clear]
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
