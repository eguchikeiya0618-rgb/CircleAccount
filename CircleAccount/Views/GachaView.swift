import SwiftUI
import FirebaseFirestore
import UIKit

struct GachaView: View {
    private let db = Firestore.firestore()
    @AppStorage("currentUserId")
    private var currentUserId = ""

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

    @AppStorage("gachaSoundEnabled")
    private var gachaSoundEnabled = true

    @StateObject private var animation = SlotAnimationController()

    @State private var result: GachaPrize?
    @State private var pendingPrize: GachaPrize?
    @State private var showResult = false

    @State private var availablePoint = 0
    @State private var isRequestingGacha = false

    @State private var errorMessage = ""
    @State private var showError = false

    private var canRunGacha: Bool {
        availablePoint >= 100
        && !isRequestingGacha
        && !animation.isSequenceRunning
    }

    private var reelSymbols: [String] {
        guard let prize = pendingPrize else {
            return ["BAR", "🔔", "🍇"]
        }

        switch prize.title {
        case "ガット張り工賃無料券":
            return ["7", "7", "7"]

        case "参加費無料券":
            return ["🌈7", "🌈7", "🌈7"]

        case "参加費半額券":
            return ["7", "7", "BAR"]

        case "参加費500円券":
            return ["BAR", "BAR", "BAR"]

        case "対戦指名券":
            return ["🔔", "🔔", "🔔"]

        case "優先ゲーム券":
            return ["🍇", "🍇", "🍇"]

        default:
            return ["BAR", "🔔", "🍇"]
        }
    }

    var body: some View {
        ZStack {
            casinoBackground

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 22) {
                        Spacer(minLength: 8)

                        PremiumSlotMachineView(
                            symbols: reelSymbols,
                            resultTitle: animation.resultTitle,
                            resultSubtitle: animation.resultSubtitle,
                            isSpinning: animation.isSpinning,
                            stoppedReelCount: animation.stoppedReelCount,
                            heatLevel: animation.heatLevel,
                            statusText: animation.statusText,
                            subStatusText: animation.subStatusText,
                            isPushVisible: animation.isPushVisible,
                            isPushEnabled: animation.isPushEnabled,
                            leverProgress: animation.leverProgress,
                            isFirstReelStopEnabled: animation.canStopFirstReel,
                            cinematicPhase: animation.cinematicPhase,
                            cinematicTrigger: animation.cinematicTrigger,
                            expectationLevel: animation.expectationLevel,
                            reelSlipTrigger: animation.reelSlipTrigger,
                            reelSlipIndex: animation.reelSlipIndex,
                            reelSlipIntensity: animation.reelSlipIntensity,
                            onFirstReelStop: {
                                animation.stopFirstReel()
                            },
                            onPush: {
                                animation.pressPush()
                            },
                            onPremiumSequenceFinished: {
                                animation.finishPremiumSequence()
                            },
                            onLeverChanged: { progress in
                                guard canRunGacha else { return }
                                animation.setLeverProgress(progress)
                            },
                            onLeverReleased: {
                                handleLeverRelease()
                            }
                        )
                        .id("slotMachine")

                        pointCard
                        prizeList
                        startButton(proxy: proxy)

                        Text("※ガチャ1回につき100ptを消費します")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.62))
                            .multilineTextAlignment(.center)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 14)
                }
                .scrollIndicators(.hidden)
            }

            SlotEffectsView(
                stage: animation.stage,
                heatLevel: animation.heatLevel,
                resultTitle: animation.resultTitle,
                resultSubtitle: animation.resultSubtitle
            )
        }
        .navigationTitle("ガチャ")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showResult) {
            if let result {
                UltimateGachaResultView(
                    prize: result,
                    showResult: $showResult
                )
            }
        }
        .alert(
            "ガチャを回せませんでした",
            isPresented: $showError
        ) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadPoint()
            animation.prepare(soundEnabled: gachaSoundEnabled)
        }
        .onChange(of: gachaSoundEnabled) { _, enabled in
            animation.prepare(soundEnabled: enabled)
        }
        .onChange(of: animation.shouldShowResult) { _, shouldShow in
            guard shouldShow, let pendingPrize else { return }

            result = pendingPrize
            showResult = true
        }
        .onChange(of: showResult) { _, isShowing in
            if !isShowing {
                loadPoint()
                pendingPrize = nil
                result = nil
                animation.reset()
            }
        }
        .onDisappear {
            animation.cancel()
        }
    }

    private var casinoBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.008, green: 0.010, blue: 0.018),
                    Color(red: 0.030, green: 0.020, blue: 0.055),
                    Color(red: 0.008, green: 0.010, blue: 0.018)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.055, green: 0.060, blue: 0.075)
                        .opacity(0.20),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 560
            )
        }
        .ignoresSafeArea()
    }

    private var soundToggle: some View {
        HStack {
            Label(
                gachaSoundEnabled ? "サウンド ON" : "サウンド OFF",
                systemImage: gachaSoundEnabled
                    ? "speaker.wave.2.fill"
                    : "speaker.slash.fill"
            )
            .font(.subheadline.bold())

            Spacer()

            Toggle("", isOn: $gachaSoundEnabled)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
    }

    private var pointCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        availablePoint >= 100
                            ? Color.green.opacity(0.18)
                            : Color.red.opacity(0.16)
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(
                        availablePoint >= 100 ? .green : .red
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("現在のポイント")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.65))

                Text("\(availablePoint)pt")
                    .font(.title2.bold())
                    .foregroundStyle(
                        availablePoint >= 100 ? .green : .red
                    )
            }

            Spacer()

            Text(
                availablePoint >= 100
                    ? "ガチャ可能"
                    : "あと\(max(100 - availablePoint, 0))pt"
            )
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                availablePoint >= 100
                    ? Color.green.opacity(0.16)
                    : Color.red.opacity(0.14)
            )
            .foregroundStyle(
                availablePoint >= 100 ? .green : .red
            )
            .clipShape(Capsule())
        }
        .padding()
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var prizeList: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("排出アイテム", systemImage: "gift.fill")
                    .font(.headline)

                Spacer()

                Label(
                    currentUserIsAdmin ? "管理者表示" : "排出率は非公開",
                    systemImage: currentUserIsAdmin
                        ? "eye.fill"
                        : "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.58))
            }

            Divider()
                .overlay(Color.white.opacity(0.14))

            prizeRow("🎾", "ガット張り工賃無料券", "SSR", "1%", .yellow)
            prizeRow("🎁", "参加費無料券", "SSR", "1%", .yellow)
            prizeRow("🏸", "参加費半額券", "SR", "3%", .purple)
            prizeRow("💰", "参加費500円券", "R", "18%", .orange)
            prizeRow("⭐", "対戦指名券", "R", "24%", .orange)
            prizeRow("🚀", "優先ゲーム券", "R", "23%", .orange)
            prizeRow("🧹", "片付けパス", "N", "30%", .gray)
        }
        .padding()
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(.white)
    }

    private func prizeRow(
        _ icon: String,
        _ title: String,
        _ rarity: String,
        _ rate: String,
        _ color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())

                Text(rarity)
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.18))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }

            Spacer()

            if currentUserIsAdmin {
                Text(rate)
                    .font(.headline.bold())
                    .foregroundStyle(color)
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private func startButton(proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.40)) {
                proxy.scrollTo("slotMachine", anchor: .top)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                requestGacha()
            }
        } label: {
            HStack(spacing: 12) {
                if isRequestingGacha {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                }

                VStack(spacing: 1) {
                    Text(
                        isRequestingGacha
                            ? "抽選データ取得中..."
                            : "レバーを引く"
                    )
                    .font(.headline.bold())

                    if !isRequestingGacha {
                        Text("100pt消費")
                            .font(.caption2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                canRunGacha
                    ? LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [.gray, .gray.opacity(0.72)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: canRunGacha
                    ? Color.orange.opacity(0.35)
                    : Color.clear,
                radius: 14,
                y: 7
            )
        }
        .buttonStyle(.plain)
        .disabled(!canRunGacha)
    }

    private func handleLeverRelease() {
        guard canRunGacha else {
            animation.returnLever()
            return
        }

        guard animation.leverProgress >= 0.98 else {
            animation.returnLever()
            return
        }

        requestGacha()
    }

    private func requestGacha() {
        guard !currentUserId.isEmpty else {
            animation.returnLever()
            showErrorMessage("ユーザー情報を確認できませんでした。")
            return
        }

        guard availablePoint >= 100 else {
            animation.returnLever()
            showErrorMessage("ガチャを回すには100pt必要です。")
            return
        }

        guard canRunGacha else { return }

        isRequestingGacha = true

        PointService.shared.runGacha(memberId: currentUserId) { gachaResult in
            DispatchQueue.main.async {
                isRequestingGacha = false

                switch gachaResult {
                case .success(let prize):
                    availablePoint = max(availablePoint - 100, 0)

                    // 先に回転を開始する。
                    // この時点では pendingPrize を更新しないため、
                    // 当たり絵柄が回転開始前に一瞬表示されることを防げる。
                    animation.start(
                        soundEnabled: gachaSoundEnabled,
                        resultTitle: prize.title,
                        resultSubtitle: resultSubtitle(for: prize),
                        route: animationRoute(for: prize)
                    )

                    // 回転状態が画面へ反映された次の更新で、
                    // 停止時に使用する本当の絵柄を渡す。
                    DispatchQueue.main.async {
                        pendingPrize = prize
                    }

                    heavyHaptic()

                case .failure(let error):
                    animation.returnLever()
                    showErrorMessage(error.localizedDescription)
                }
            }
        }
    }

    private func animationRoute(for prize: GachaPrize) -> SlotAnimationRoute {
        switch prize.rarity {
        case 5...:
            // SSRは完成版Premiumシーケンスを唯一のマスター経路とする。
            return .premium

        case 4:
            return Int.random(in: 0..<100) < 55
                ? .superChance
                : .chance

        case 3:
            return Int.random(in: 0..<100) < 42
                ? .chance
                : .normal

        default:
            return Int.random(in: 0..<100) < 12
                ? .chance
                : .normal
        }
    }
    private func resultSubtitle(for prize: GachaPrize) -> String {
        switch prize.rarity {
        case 5...:
            return "SSR PREMIUM TICKET"
        case 4:
            return "SUPER RARE TICKET"
        case 3:
            return "RARE TICKET"
        default:
            return "NORMAL TICKET"
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func heavyHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }

    private func loadPoint() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                guard error == nil, let data = snapshot?.data() else {
                    return
                }

                DispatchQueue.main.async {
                    availablePoint = data["availablePoint"] as? Int ?? 0
                }
            }
    }
}

// MARK: - Result screen

struct UltimateGachaResultView: View {
    let prize: GachaPrize
    @Binding var showResult: Bool

    @State private var contentVisible = false
    @State private var iconScale: CGFloat = 0.96
    @State private var ringRotation = 0.0
    @State private var glowScale: CGFloat = 0.78
    @State private var flashVisible = true
    @State private var ticketFloating = false
    @State private var ticketGlowPulse = false
    @State private var sparklePhase = false
    @State private var informationVisible = false

    private var rarityText: String {
        switch prize.rarity {
        case 5...: return "SSR"
        case 4: return "SR"
        case 3: return "R"
        default: return "N"
        }
    }

    private var rarityColor: Color {
        switch prize.rarity {
        case 5...: return Color(red: 0.64, green: 0.48, blue: 1.0)
        case 4: return .purple
        case 3: return .blue
        default: return .gray
        }
    }

    private var itemDescription: String {
        switch prize.ticketField {
        case "stringingFreeTickets":
            return "ガット張り工賃が無料になります"
        case "freeTickets":
            return "活動参加費が無料になります"
        case "halfPriceTickets":
            return "参加費が50%OFFになります"
        case "discountTickets":
            return "活動参加費が500円になります"
        case "challengeTickets":
            return "対戦相手を指名できます"
        case "priorityTickets":
            return "ゲームへ優先的に参加できます"
        case "cleanupTickets":
            return "活動後の片付けを免除できます"
        default:
            return "CircleAccountで使用できるプレミアムチケットです"
        }
    }

    private var rarityLabel: String {
        switch prize.rarity {
        case 5...: return "PREMIUM SSR TICKET"
        case 4: return "SUPER RARE TICKET"
        case 3: return "RARE TICKET"
        default: return "NORMAL TICKET"
        }
    }

    private var usageNote: String {
        switch prize.ticketField {
        case "halfPriceTickets":
            return "次回参加時に自動で使用されます"
        case "freeTickets", "discountTickets":
            return "次回参加時に利用できます"
        case "stringingFreeTickets":
            return "ガット張りの受付時に利用できます"
        case "challengeTickets", "priorityTickets":
            return "対象の活動で利用できます"
        case "cleanupTickets":
            return "次回の活動参加時に利用できます"
        default:
            return "保有チケット画面から確認できます"
        }
    }

    private var rarityLongName: String {
        switch prize.rarity {
        case 5...: return "SUPER SUPER RARE"
        case 4: return "SUPER RARE"
        case 3: return "RARE"
        default: return "NORMAL"
        }
    }

    private var premiumPrizeLabel: String {
        switch prize.rarity {
        case 5...: return "PREMIUM PRIZE"
        case 4: return "SUPER RARE"
        case 3: return "RARE REWARD"
        default: return "REWARD"
        }
    }

    private var premiumPrizeLabelStyle: AnyShapeStyle {
        switch prize.rarity {
        case 5...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.pink, .orange, .yellow, .cyan, .blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 4:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.purple.opacity(0.78), .purple, Color.pink.opacity(0.76)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 3:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.78), .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        default:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.92), Color.gray.opacity(0.78)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    private var isSSR: Bool {
        prize.rarity >= 5
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    rarityColor.opacity(0.62),
                    Color.black,
                    Color(red: 0.018, green: 0.020, blue: 0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isSSR {
                Rectangle()
                    .fill(
                        AngularGradient(
                            colors: [
                                .red, .orange, .yellow, .green,
                                .cyan, .blue, .purple, .pink, .red
                            ],
                            center: .center
                        )
                    )
                    .opacity(0.25)
                    .rotationEffect(.degrees(ringRotation))
                    .scaleEffect(1.8)
                    .blendMode(.screen)
                    .ignoresSafeArea()
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            rarityColor.opacity(0.58),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 240
                    )
                )
                .frame(width: 480, height: 480)
                .scaleEffect(glowScale)

            VStack(spacing: 22) {
                Spacer()

                Text(premiumPrizeLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(3.4)
                    .foregroundStyle(premiumPrizeLabelStyle)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
                    .shadow(
                        color: isSSR ? rarityColor.opacity(0.30) : Color.clear,
                        radius: isSSR ? 7 : 0
                    )

                Text(rarityText)
                    .font(.system(size: 70, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isSSR
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        .red, .orange, .yellow, .green,
                                        .cyan, .blue, .purple, .pink
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(rarityColor)
                    )
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 5)
                    .shadow(color: rarityColor, radius: 22)

                Text(rarityLongName)
                    .font(.system(size: 11, weight: .light, design: .rounded))
                    .tracking(2.8)
                    .foregroundStyle(Color.white.opacity(0.90))
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 3)

                ZStack {
                    PremiumOwnedTicketArtworkView(
                        ticketField: prize.ticketField,
                        iconGlowActive: true,
                        artworkSize: CGSize(
                            width: PremiumOwnedTicketArtworkView.artworkWidth * 1.34,
                            height: PremiumOwnedTicketArtworkView.artworkHeight * 1.16 * 0.73
                        ),
                        showsSerialNumber: false
                    )
                    .scaleEffect(iconScale, anchor: .center)
                    .frame(
                        width: PremiumOwnedTicketArtworkView.artworkWidth * 1.34,
                        height: PremiumOwnedTicketArtworkView.artworkHeight * 1.16 * 0.73
                    )
                    .shadow(
                        color: rarityColor.opacity(ticketGlowPulse ? 0.54 : 0.38),
                        radius: ticketGlowPulse ? 24 : 17,
                        y: 8
                    )

                    ticketSparkles
                }
                .offset(y: ticketFloating ? -31 : -28)

                VStack(spacing: 7) {
                    Text(prize.title)
                        .font(.system(size: 24, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(rarityLabel)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(rarityColor)

                    Text(itemDescription)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(usageNote)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.48))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("チケットを1枚獲得しました")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.54))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 15)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    rarityColor.opacity(0.30),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .padding(.horizontal, 24)
                .opacity(informationVisible ? 1 : 0)
                .offset(y: informationVisible ? -1 : 5)

                Spacer()

                Button {
                    showResult = false
                } label: {
                    Label("受け取る", systemImage: "gift.fill")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            isSSR
                                ? LinearGradient(
                                    colors: [
                                        .red, .orange, .yellow, .green,
                                        .cyan, .blue, .purple, .pink
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [
                                        rarityColor,
                                        rarityColor.opacity(0.68)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(GachaReceiveButtonStyle())
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .opacity(contentVisible ? 1 : 0)

            Color.white
                .ignoresSafeArea()
                .opacity(flashVisible ? 0.94 : 0)
                .allowsHitTesting(false)
        }
        .interactiveDismissDisabled()
        .onAppear {
            playRarityHaptic()

            withAnimation(.easeOut(duration: 0.16)) {
                contentVisible = true
            }

            withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                iconScale = 1.02
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    iconScale = 1.0
                    informationVisible = true
                }
            }

            withAnimation(
                .linear(duration: isSSR ? 2.8 : 5.5)
                .repeatForever(autoreverses: false)
            ) {
                ringRotation = 360
            }

            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                glowScale = 1.0
                ticketGlowPulse = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(
                    .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    ticketFloating = true
                }

                sparklePhase = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                flashVisible = false
            }
        }
    }

    private var ticketSparkles: some View {
        ZStack {
            sparkle(index: 0, x: -100, y: -48)
            sparkle(index: 1, x: 102, y: -31)
            sparkle(index: 2, x: 94, y: 47)
            sparkle(index: 3, x: -92, y: 50)
            sparkle(index: 4, x: 24, y: -66)
        }
        .allowsHitTesting(false)
    }

    private func sparkle(index: Int, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: index == 1 ? "sparkle" : "sparkles")
            .font(.system(size: index == 1 ? 10 : 13, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.86))
            .shadow(color: rarityColor.opacity(0.58), radius: 4)
            .offset(
                x: x,
                y: y + (sparklePhase ? -7 : 3)
            )
            .opacity(sparklePhase ? 0.88 : 0.10)
            .animation(
                .easeInOut(duration: 1.15)
                    .delay(Double(index) * 0.24)
                    .repeatForever(autoreverses: true),
                value: sparklePhase
            )
    }

    private func playRarityHaptic() {
        switch prize.rarity {
        case 5...:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case 4:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: 0.82)
        case 3:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: 0.72)
        default:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
}

private struct GachaReceiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.78),
                value: configuration.isPressed
            )
    }
}

#Preview {
    NavigationStack {
        GachaView()
    }
}
