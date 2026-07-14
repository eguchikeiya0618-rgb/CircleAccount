import SwiftUI
import FirebaseFirestore
import UIKit

struct GachaView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @State private var result: GachaPrize?
    @State private var showResult = false

    @State private var isLoading = false
    @State private var isRolling = false
    @State private var availablePoint = 0

    @State private var errorMessage = ""
    @State private var showError = false

    @State private var slotSymbol1 = "7"
    @State private var slotSymbol2 = "7"
    @State private var slotSymbol3 = "7"

    @State private var reel1Spinning = false
    @State private var reel2Spinning = false
    @State private var reel3Spinning = false

    @State private var reel1Slowing = false
    @State private var reel2Slowing = false
    @State private var reel3Slowing = false

    @State private var reel1Stopped = false
    @State private var reel2Stopped = false
    @State private var reel3Stopped = false

    @State private var machineScale: CGFloat = 1.0
    @State private var machineGlow = false
    @State private var machineShakeOffset: CGFloat = 0

    @State private var leverOffset: CGFloat = 0
    @State private var leverRotation = 0.0

    @State private var statusText = "レバーを引いてスタート"
    @State private var pendingPrize: GachaPrize?

    @State private var ssrMode = false
    @State private var ssrFlashVisible = false
    @State private var rainbowRotation = 0.0
    @State private var jackpotTextVisible = false

    private let slotSymbols = [
        "7",
        "⭐",
        "🎁",
        "🏸",
        "🚀",
        "💰",
        "🎾",
        "🧹"
    ]

    private var canRunGacha: Bool {
        availablePoint >= 100 && !isLoading
    }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 26) {
                        Spacer(minLength: 15)

                        gachaMachine
                            .id("gachaMachine")

                        VStack(spacing: 8) {
                            Text("SiRiUS GACHA")
                                .font(.system(size: 38, weight: .black))
                                .multilineTextAlignment(.center)

                            Text(statusText)
                                .font(.headline)
                                .foregroundStyle(
                                    ssrMode
                                        ? Color.yellow
                                        : isRolling
                                            ? Color.orange
                                            : Color.secondary
                                )
                                .multilineTextAlignment(.center)
                                .animation(
                                    .easeInOut(duration: 0.25),
                                    value: statusText
                                )
                        }

                        pointCard

                        prizeList

                        gachaButton(proxy: proxy)

                        Text("※獲得したチケットはマイページに反映されます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Spacer(minLength: 30)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }

            if ssrMode {
                ssrScreenAura
            }

            if ssrFlashVisible {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.94)
                    .allowsHitTesting(false)
            }

            if jackpotTextVisible {
                VStack {
                    Spacer()

                    Text("JACKPOT")
                        .font(
                            .system(
                                size: 50,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .red,
                                    .orange,
                                    .yellow,
                                    .green,
                                    .cyan,
                                    .blue,
                                    .purple,
                                    .pink
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white, radius: 8)
                        .shadow(color: .yellow, radius: 22)
                        .transition(
                            .scale.combined(with: .opacity)
                        )

                    Spacer()
                        .frame(height: 115)
                }
                .allowsHitTesting(false)
            }
        }
        .navigationTitle("ガチャ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResult) {
            if let result {
                GachaResultView(
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
            machineGlow = true

            withAnimation(
                .linear(duration: 4)
                    .repeatForever(autoreverses: false)
            ) {
                rainbowRotation = 360
            }
        }
        .onChange(of: showResult) { _, isShowing in
            if !isShowing {
                loadPoint()
                resetMachine()
            }
        }
    }

    // MARK: - ガチャ本体

    private var gachaMachine: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: ssrMode
                            ? [
                                Color.white.opacity(0.70),
                                Color.yellow.opacity(0.42),
                                Color.pink.opacity(0.32),
                                Color.cyan.opacity(0.24),
                                Color.clear
                            ]
                            : [
                                Color.orange.opacity(
                                    machineGlow ? 0.32 : 0.10
                                ),
                                Color.clear
                            ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 175
                    )
                )
                .frame(width: 355, height: 355)
                .scaleEffect(
                    ssrMode
                        ? 1.22
                        : machineGlow
                            ? 1.12
                            : 0.95
                )
                .animation(
                    .easeInOut(duration: ssrMode ? 0.22 : 0.75)
                        .repeatForever(autoreverses: true),
                    value: machineGlow
                )

            if ssrMode {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                .red,
                                .orange,
                                .yellow,
                                .green,
                                .cyan,
                                .blue,
                                .purple,
                                .pink,
                                .red
                            ],
                            center: .center
                        ),
                        lineWidth: 13
                    )
                    .frame(width: 330, height: 330)
                    .rotationEffect(.degrees(rainbowRotation))
                    .shadow(color: .white, radius: 8)
                    .shadow(color: .yellow, radius: 18)
            }

            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(
                            ssrMode
                                ? LinearGradient(
                                    colors: [
                                        Color.purple,
                                        Color.blue,
                                        Color.cyan,
                                        Color.green,
                                        Color.yellow,
                                        Color.orange,
                                        Color.red,
                                        Color.pink
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.96),
                                        Color.red.opacity(0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 285, height: 270)
                        .overlay {
                            RoundedRectangle(cornerRadius: 34)
                                .stroke(
                                    Color.white.opacity(
                                        ssrMode ? 0.85 : 0.24
                                    ),
                                    lineWidth: ssrMode ? 5 : 2
                                )
                        }
                        .shadow(
                            color: ssrMode
                                ? Color.white.opacity(0.85)
                                : Color.orange.opacity(0.38),
                            radius: ssrMode ? 35 : isRolling ? 30 : 14,
                            x: 0,
                            y: 10
                        )

                    VStack(spacing: 14) {
                        HStack(spacing: 7) {
                            machineLamp(isOn: isRolling)

                            Text(
                                ssrMode
                                    ? "JACKPOT"
                                    : "SiRiUS"
                            )
                            .font(.caption)
                            .bold()
                            .tracking(2)
                            .foregroundStyle(.white)

                            machineLamp(isOn: isRolling)
                        }

                        Text(
                            ssrMode
                                ? "RAINBOW BONUS"
                                : "LUCKY SLOT"
                        )
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .shadow(
                            color: ssrMode ? .yellow : .clear,
                            radius: 8
                        )

                        HStack(spacing: 8) {
                            SlotReelView(
                                finalSymbol: slotSymbol1,
                                symbols: slotSymbols,
                                isSpinning: reel1Spinning,
                                isSlowing: reel1Slowing,
                                isStopped: reel1Stopped,
                                speed: 1_200,
                                seed: 0.0
                            )

                            SlotReelView(
                                finalSymbol: slotSymbol2,
                                symbols: slotSymbols,
                                isSpinning: reel2Spinning,
                                isSlowing: reel2Slowing,
                                isStopped: reel2Stopped,
                                speed: 1_310,
                                seed: 2.3
                            )

                            SlotReelView(
                                finalSymbol: slotSymbol3,
                                symbols: slotSymbols,
                                isSpinning: reel3Spinning,
                                isSlowing: reel3Slowing,
                                isStopped: reel3Stopped,
                                speed: 1_420,
                                seed: 4.7
                            )
                        }

                        HStack(spacing: 14) {
                            stopIndicator(
                                title: "左",
                                isStopped: reel1Stopped
                            )

                            stopIndicator(
                                title: "中",
                                isStopped: reel2Stopped
                            )

                            stopIndicator(
                                title: "右",
                                isStopped: reel3Stopped
                            )
                        }
                    }
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.55))
                    .frame(width: 225, height: 22)
                    .offset(y: -3)
            }
            .scaleEffect(machineScale)
            .offset(x: machineShakeOffset)

            leverView
        }
        .frame(height: 365)
    }

    private var leverView: some View {
        HStack {
            Spacer()

            VStack(spacing: 0) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray,
                                Color.black.opacity(0.72)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 18, height: 88)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red,
                                Color.orange
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(
                                Color.white.opacity(0.35),
                                lineWidth: 2
                            )
                    }
                    .shadow(
                        color: Color.red.opacity(0.45),
                        radius: 10
                    )
            }
            .offset(
                x: 5,
                y: leverOffset
            )
            .rotationEffect(
                .degrees(leverRotation),
                anchor: .top
            )
        }
        .frame(width: 335)
    }

    private func machineLamp(
        isOn: Bool
    ) -> some View {
        Circle()
            .fill(
                ssrMode
                    ? Color.white
                    : isOn
                        ? Color.yellow
                        : Color.yellow.opacity(0.45)
            )
            .frame(width: 11, height: 11)
            .shadow(
                color: ssrMode
                    ? Color.white
                    : isOn
                        ? Color.yellow
                        : Color.clear,
                radius: ssrMode ? 14 : 8
            )
    }

    private func stopIndicator(
        title: String,
        isStopped: Bool
    ) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(
                    isStopped
                        ? Color.green
                        : Color.yellow.opacity(0.55)
                )
                .frame(width: 9, height: 9)
                .shadow(
                    color: isStopped
                        ? Color.green
                        : Color.clear,
                    radius: 7
                )

            Text(title)
                .font(.caption2)
                .bold()
                .foregroundStyle(.white.opacity(0.90))
        }
    }

    private var ssrScreenAura: some View {
        Rectangle()
            .fill(
                AngularGradient(
                    colors: [
                        Color.red.opacity(0.24),
                        Color.orange.opacity(0.24),
                        Color.yellow.opacity(0.24),
                        Color.green.opacity(0.24),
                        Color.cyan.opacity(0.24),
                        Color.blue.opacity(0.24),
                        Color.purple.opacity(0.24),
                        Color.pink.opacity(0.24),
                        Color.red.opacity(0.24)
                    ],
                    center: .center
                )
            )
            .ignoresSafeArea()
            .rotationEffect(.degrees(rainbowRotation))
            .scaleEffect(1.8)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    // MARK: - ポイント

    private var pointCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        availablePoint >= 100
                            ? Color.green.opacity(0.15)
                            : Color.red.opacity(0.12)
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(
                        availablePoint >= 100
                            ? Color.green
                            : Color.red
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("現在のポイント")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(availablePoint)pt")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(
                        availablePoint >= 100
                            ? Color.green
                            : Color.red
                    )
            }

            Spacer()

            if availablePoint >= 100 {
                Text("ガチャ可能")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.14))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else {
                Text("あと\(max(100 - availablePoint, 0))pt")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
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

    // MARK: - 排出一覧

    private var prizeList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(
                    "排出アイテム",
                    systemImage: "gift.fill"
                )
                .font(.title3)
                .bold()

                Spacer()

                Text("全7種類")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            prizeRow(
                icon: "🎾",
                title: "ガット張り工賃無料券",
                rarity: "SSR",
                rate: "1%",
                color: .yellow
            )

            prizeRow(
                icon: "🎁",
                title: "参加費無料券",
                rarity: "SSR",
                rate: "3%",
                color: .yellow
            )

            prizeRow(
                icon: "🏸",
                title: "参加費半額券",
                rarity: "SR",
                rate: "8%",
                color: .purple
            )

            prizeRow(
                icon: "💰",
                title: "参加費500円券",
                rarity: "R",
                rate: "18%",
                color: .orange
            )

            prizeRow(
                icon: "⭐",
                title: "対戦指名券",
                rarity: "R",
                rate: "20%",
                color: .orange
            )

            prizeRow(
                icon: "🚀",
                title: "優先ゲーム券",
                rarity: "R",
                rate: "20%",
                color: .orange
            )

            prizeRow(
                icon: "🧹",
                title: "片付けパス",
                rarity: "N",
                rate: "30%",
                color: .gray
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private func prizeRow(
        icon: String,
        title: String,
        rarity: String,
        rate: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(rarity)
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }

            Spacer()

            Text(rate)
                .font(.headline)
                .bold()
                .foregroundStyle(color)
        }
    }

    // MARK: - ガチャボタン

    private func gachaButton(
        proxy: ScrollViewProxy
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo(
                    "gachaMachine",
                    anchor: .top
                )
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.50
            ) {
                runGacha()
            }
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                }

                VStack(spacing: 2) {
                    Text(
                        isLoading
                            ? "リール回転中..."
                            : "レバーを引く"
                    )
                    .font(.headline)
                    .bold()

                    if !isLoading {
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
                        colors: [
                            Color.orange,
                            Color.red.opacity(0.88)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [
                            Color.gray,
                            Color.gray.opacity(0.75)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: canRunGacha
                    ? Color.orange.opacity(0.32)
                    : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!canRunGacha)
    }

    // MARK: - ガチャ実行

    private func runGacha() {
        guard !currentUserId.isEmpty else {
            errorMessage = "ユーザー情報を確認できませんでした。"
            showError = true
            return
        }

        guard availablePoint >= 100 else {
            errorMessage = "ガチャを回すには100pt必要です。"
            showError = true
            return
        }

        guard !isLoading else {
            return
        }

        prepareMachineForSpin()
        pullLever()

        PointService.shared.runGacha(
            memberId: currentUserId
        ) { gachaResult in
            DispatchQueue.main.async {
                switch gachaResult {
                case .success(let prize):
                    pendingPrize = prize

                    availablePoint = max(
                        availablePoint - 100,
                        0
                    )

                    startSequentialStops(
                        prize: prize
                    )

                case .failure(let error):
                    stopAllReels()

                    isLoading = false
                    isRolling = false
                    machineScale = 1.0
                    statusText = "レバーを引いてスタート"

                    slotSymbol1 = "7"
                    slotSymbol2 = "7"
                    slotSymbol3 = "7"

                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func prepareMachineForSpin() {
        result = nil
        pendingPrize = nil

        isLoading = true
        isRolling = true

        ssrMode = false
        ssrFlashVisible = false
        jackpotTextVisible = false

        reel1Stopped = false
        reel2Stopped = false
        reel3Stopped = false

        reel1Slowing = false
        reel2Slowing = false
        reel3Slowing = false

        reel1Spinning = false
        reel2Spinning = false
        reel3Spinning = false

        statusText = "レバーを引いています..."

        withAnimation(
            .spring(
                response: 0.25,
                dampingFraction: 0.55
            )
        ) {
            machineScale = 1.05
        }
    }

    private func pullLever() {
        let generator = UIImpactFeedbackGenerator(
            style: .heavy
        )

        generator.prepare()
        generator.impactOccurred()

        withAnimation(
            .easeIn(duration: 0.22)
        ) {
            leverOffset = 70
            leverRotation = 15
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.25
        ) {
            let secondGenerator =
                UIImpactFeedbackGenerator(style: .medium)

            secondGenerator.prepare()
            secondGenerator.impactOccurred()

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.48
                )
            ) {
                leverOffset = 0
                leverRotation = 0
            }

            startAllReels()
        }
    }

    private func startAllReels() {
        statusText = "リール高速回転中..."

        reel1Spinning = true
        reel2Spinning = true
        reel3Spinning = true

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.50
            )
        ) {
            machineScale = 1.02
        }
    }

    private func startSequentialStops(
        prize: GachaPrize
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.40
        ) {
            reel1Slowing = true
            statusText = "左リール減速..."
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.85
        ) {
            stopFirstReel(
                symbol: prize.icon
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.25
        ) {
            reel2Slowing = true
            statusText = "中央リール減速..."
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.75
        ) {
            stopSecondReel(
                symbol: prize.icon
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3.20
        ) {
            reel3Slowing = true
            statusText = "右リール減速..."
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3.85
        ) {
            stopThirdReel(
                symbol: prize.icon,
                prize: prize
            )
        }
    }

    private func stopFirstReel(
        symbol: String
    ) {
        reel1Spinning = false
        reel1Slowing = false
        slotSymbol1 = symbol
        reel1Stopped = true

        statusText = "左リール停止！"

        let generator = UIImpactFeedbackGenerator(
            style: .medium
        )

        generator.prepare()
        generator.impactOccurred()
    }

    private func stopSecondReel(
        symbol: String
    ) {
        reel2Spinning = false
        reel2Slowing = false
        slotSymbol2 = symbol
        reel2Stopped = true

        statusText = "中央リール停止！"

        let generator = UIImpactFeedbackGenerator(
            style: .medium
        )

        generator.prepare()
        generator.impactOccurred()
    }

    private func stopThirdReel(
        symbol: String,
        prize: GachaPrize
    ) {
        reel3Spinning = false
        reel3Slowing = false
        slotSymbol3 = symbol
        reel3Stopped = true

        if prize.rarity >= 5 {
            statusText = "🌈 SSR JACKPOT！"
            startSSRMachineEffect(prize: prize)
        } else {
            statusText = "🎉 \(prize.title) GET！"

            let generator =
                UINotificationFeedbackGenerator()

            generator.prepare()
            generator.notificationOccurred(.success)

            bounceMachine()

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.90
            ) {
                showPrizeResult(prize)
            }
        }
    }

    private func bounceMachine() {
        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.42
            )
        ) {
            machineScale = 1.11
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.34
        ) {
            withAnimation(
                .spring(
                    response: 0.32,
                    dampingFraction: 0.62
                )
            ) {
                machineScale = 1.0
            }
        }
    }

    private func startSSRMachineEffect(
        prize: GachaPrize
    ) {
        ssrMode = true

        withAnimation(
            .spring(
                response: 0.24,
                dampingFraction: 0.36
            )
        ) {
            machineScale = 1.13
            jackpotTextVisible = true
        }

        runSSRFlashSequence()
        runSSRShakeSequence()
        runSSRHapticSequence()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.70
        ) {
            withAnimation(
                .easeOut(duration: 0.25)
            ) {
                jackpotTextVisible = false
                machineScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.00
        ) {
            showPrizeResult(prize)
        }
    }

    private func runSSRFlashSequence() {
        ssrFlashVisible = true

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.14
        ) {
            ssrFlashVisible = false
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.32
        ) {
            ssrFlashVisible = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.43
        ) {
            ssrFlashVisible = false
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.66
        ) {
            ssrFlashVisible = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.77
        ) {
            ssrFlashVisible = false
        }
    }

    private func runSSRShakeSequence() {
        let positions: [CGFloat] = [
            -13,
            13,
            -11,
            11,
            -8,
            8,
            -5,
            5,
            0
        ]

        for (index, position) in positions.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.075
            ) {
                withAnimation(
                    .linear(duration: 0.07)
                ) {
                    machineShakeOffset = position
                }
            }
        }
    }

    private func runSSRHapticSequence() {
        let delays = [
            0.00,
            0.16,
            0.32,
            0.52,
            0.72,
            0.96
        ]

        for delay in delays {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay
            ) {
                let generator =
                    UIImpactFeedbackGenerator(
                        style: .heavy
                    )

                generator.prepare()
                generator.impactOccurred(
                    intensity: 1.0
                )
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.15
        ) {
            let generator =
                UINotificationFeedbackGenerator()

            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }

    private func showPrizeResult(
        _ prize: GachaPrize
    ) {
        result = prize
        isLoading = false
        isRolling = false
        showResult = true
    }

    private func stopAllReels() {
        reel1Spinning = false
        reel2Spinning = false
        reel3Spinning = false

        reel1Slowing = false
        reel2Slowing = false
        reel3Slowing = false
    }

    private func resetMachine() {
        stopAllReels()

        isLoading = false
        isRolling = false

        reel1Stopped = false
        reel2Stopped = false
        reel3Stopped = false

        slotSymbol1 = "7"
        slotSymbol2 = "7"
        slotSymbol3 = "7"

        leverOffset = 0
        leverRotation = 0

        machineScale = 1.0
        machineShakeOffset = 0

        ssrMode = false
        ssrFlashVisible = false
        jackpotTextVisible = false

        pendingPrize = nil
        statusText = "レバーを引いてスタート"
    }

    // MARK: - ポイント読み込み

    private func loadPoint() {
        guard !currentUserId.isEmpty else {
            return
        }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                guard
                    let data = snapshot?.data(),
                    error == nil
                else {
                    return
                }

                DispatchQueue.main.async {
                    availablePoint =
                        data["availablePoint"] as? Int ?? 0
                }
            }
    }
}
// MARK: - 縦回転リール

private struct SlotReelView: View {
    let finalSymbol: String
    let symbols: [String]

    let isSpinning: Bool
    let isSlowing: Bool
    let isStopped: Bool

    let speed: Double
    let seed: Double

    private let reelWidth: CGFloat = 67
    private let reelHeight: CGFloat = 88
    private let symbolHeight: CGFloat = 54

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)

            if isSpinning {
                TimelineView(
                    .animation(
                        minimumInterval: 1.0 / 45.0,
                        paused: false
                    )
                ) { timeline in
                    spinningSymbols(
                        date: timeline.date
                    )
                }
            } else {
                stoppedSymbol
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.16),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isStopped
                        ? Color.yellow
                        : Color.black.opacity(0.18),
                    lineWidth: isStopped ? 4 : 2
                )
                .shadow(
                    color: isStopped
                        ? Color.yellow.opacity(0.85)
                        : Color.clear,
                    radius: 8
                )
        }
        .frame(
            width: reelWidth,
            height: reelHeight
        )
        .clipped()
    }

    private func spinningSymbols(
        date: Date
    ) -> some View {
        let currentSpeed =
            isSlowing ? speed * 0.30 : speed

        let elapsed =
            date.timeIntervalSinceReferenceDate + seed

        let travel =
            elapsed * currentSpeed

        let baseIndex =
            Int(travel / Double(symbolHeight))

        let movement =
            CGFloat(
                travel.truncatingRemainder(
                    dividingBy: Double(symbolHeight)
                )
            )

        return ZStack {
            ForEach(-2...2, id: \.self) { position in
                let symbolIndex =
                    positiveModulo(
                        baseIndex + position,
                        symbols.count
                    )

                reelSymbol(
                    symbols[symbolIndex]
                )
                .offset(
                    y:
                        CGFloat(position) * symbolHeight
                        - movement
                )
            }
        }
        .frame(
            width: reelWidth,
            height: reelHeight
        )
        .blur(radius: isSlowing ? 0.35 : 0.85)
    }

    private var stoppedSymbol: some View {
        reelSymbol(finalSymbol)
            .scaleEffect(
                isStopped ? 1.12 : 1.0
            )
            .animation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.48
                ),
                value: isStopped
            )
    }

    private func reelSymbol(
        _ symbol: String
    ) -> some View {
        Text(symbol)
            .font(
                symbol == "7"
                    ? .system(
                        size: 43,
                        weight: .black,
                        design: .rounded
                    )
                    : .system(size: 34)
            )
            .foregroundStyle(
                symbol == "7"
                    ? Color.red
                    : Color.primary
            )
            .frame(
                width: reelWidth,
                height: symbolHeight
            )
    }

    private func positiveModulo(
        _ value: Int,
        _ divisor: Int
    ) -> Int {
        guard divisor > 0 else {
            return 0
        }

        let remainder = value % divisor
        return remainder >= 0
            ? remainder
            : remainder + divisor
    }
}

// MARK: - ガチャ結果画面

struct GachaResultView: View {
    let prize: GachaPrize

    @Binding var showResult: Bool

    @State private var showContent = false
    @State private var showFlash = false

    @State private var glowScale: CGFloat = 0.72
    @State private var iconScale: CGFloat = 0.15
    @State private var iconRotation = -20.0

    @State private var ringRotation = 0.0
    @State private var rainbowRotation = 0.0

    @State private var titleOffset: CGFloat = -30
    @State private var buttonOffset: CGFloat = 40

    @State private var lightningVisible = false
    @State private var screenShake: CGFloat = 0

    private var rarityText: String {
        switch prize.rarity {
        case 5:
            return "SSR"

        case 4:
            return "SR"

        case 3:
            return "R"

        default:
            return "N"
        }
    }

    private var rarityTitle: String {
        switch prize.rarity {
        case 5:
            return "ULTRA SUPER RARE！"

        case 4:
            return "SUPER RARE！"

        case 3:
            return "RARE！"

        default:
            return "GET！"
        }
    }

    private var resultColor: Color {
        switch prize.rarity {
        case 5:
            return .yellow

        case 4:
            return .purple

        case 3:
            return .orange

        default:
            return .blue
        }
    }

    private var secondaryColor: Color {
        switch prize.rarity {
        case 5:
            return .pink

        case 4:
            return .pink

        case 3:
            return .red

        default:
            return .cyan
        }
    }

    private var stars: String {
        String(
            repeating: "⭐",
            count: max(prize.rarity, 1)
        )
    }

    private var isSSR: Bool {
        prize.rarity >= 5
    }

    private var isSR: Bool {
        prize.rarity == 4
    }

    var body: some View {
        ZStack {
            backgroundView

            if isSSR {
                rainbowBackground
            }

            decorativeGlow

            if prize.rarity >= 4 {
                ConfettiView()
            }

            if isSR || isSSR {
                lightningLayer
            }

            mainContent
                .offset(x: screenShake)

            flashLayer
        }
        .interactiveDismissDisabled()
        .onAppear {
            startResultAnimation()
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                resultColor.opacity(isSSR ? 0.58 : 0.42),
                secondaryColor.opacity(0.22),
                Color(.systemBackground),
                resultColor.opacity(0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var rainbowBackground: some View {
        Rectangle()
            .fill(
                AngularGradient(
                    colors: [
                        Color.red.opacity(0.30),
                        Color.orange.opacity(0.30),
                        Color.yellow.opacity(0.30),
                        Color.green.opacity(0.30),
                        Color.cyan.opacity(0.30),
                        Color.blue.opacity(0.30),
                        Color.purple.opacity(0.30),
                        Color.pink.opacity(0.30),
                        Color.red.opacity(0.30)
                    ],
                    center: .center
                )
            )
            .ignoresSafeArea()
            .rotationEffect(.degrees(rainbowRotation))
            .scaleEffect(1.7)
            .blendMode(.screen)
    }

    private var decorativeGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            resultColor.opacity(0.48),
                            secondaryColor.opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 240
                    )
                )
                .frame(width: 480, height: 480)
                .scaleEffect(glowScale)
                .blur(radius: isSSR ? 4 : 12)

            Circle()
                .stroke(
                    isSSR
                        ? AngularGradient(
                            colors: [
                                .red,
                                .orange,
                                .yellow,
                                .green,
                                .cyan,
                                .blue,
                                .purple,
                                .pink,
                                .red
                            ],
                            center: .center
                        )
                        : AngularGradient(
                            colors: [
                                resultColor,
                                secondaryColor,
                                .white,
                                resultColor
                            ],
                            center: .center
                        ),
                    lineWidth: isSSR ? 10 : 4
                )
                .frame(width: 350, height: 350)
                .rotationEffect(.degrees(ringRotation))
                .opacity(
                    prize.rarity >= 4 ? 0.82 : 0.25
                )
                .shadow(
                    color: isSSR
                        ? Color.white
                        : resultColor.opacity(0.50),
                    radius: isSSR ? 15 : 8
                )
        }
    }

    private var lightningLayer: some View {
        ZStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 70))
                .foregroundStyle(resultColor)
                .offset(x: -145, y: -210)
                .rotationEffect(.degrees(-25))

            Image(systemName: "bolt.fill")
                .font(.system(size: 56))
                .foregroundStyle(secondaryColor)
                .offset(x: 150, y: -155)
                .rotationEffect(.degrees(22))

            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(.white)
                .offset(x: -135, y: 190)

            Image(systemName: "sparkles")
                .font(.system(size: 45))
                .foregroundStyle(resultColor)
                .offset(x: 145, y: 240)
        }
        .opacity(
            lightningVisible ? 1 : 0.1
        )
        .animation(
            .easeInOut(duration: isSSR ? 0.10 : 0.18)
                .repeatForever(autoreverses: true),
            value: lightningVisible
        )
    }

    private var mainContent: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 10) {
                Text(
                    isSSR
                        ? "✨ JACKPOT ✨"
                        : "🎉 ACHIEVEMENT GET！"
                )
                .font(.headline)
                .bold()
                .tracking(1.3)
                .foregroundStyle(
                    isSSR
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    .red,
                                    .orange,
                                    .yellow,
                                    .green,
                                    .cyan,
                                    .blue,
                                    .purple,
                                    .pink
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(resultColor)
                )

                Text(rarityText)
                    .font(
                        .system(
                            size: isSSR ? 72 : 52,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        isSSR
                            ? LinearGradient(
                                colors: [
                                    .red,
                                    .orange,
                                    .yellow,
                                    .green,
                                    .cyan,
                                    .blue,
                                    .purple,
                                    .pink
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    resultColor,
                                    secondaryColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: isSSR
                            ? Color.white
                            : resultColor.opacity(0.65),
                        radius: isSSR ? 22 : 10
                    )
                    .shadow(
                        color: isSSR
                            ? Color.yellow
                            : Color.clear,
                        radius: 35
                    )

                Text(rarityTitle)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(resultColor)

                Text(stars)
                    .font(.title2)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: titleOffset)

            prizeIconView

            VStack(spacing: 10) {
                Text("GET！")
                    .font(.headline)
                    .bold()
                    .tracking(1)
                    .foregroundStyle(resultColor)

                Text(prize.title)
                    .font(
                        .system(
                            size: 30,
                            weight: .black
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("チケットを1枚獲得しました")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            Button {
                showResult = false
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")

                    Text("受け取る")
                        .bold()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    isSSR
                        ? LinearGradient(
                            colors: [
                                .red,
                                .orange,
                                .yellow,
                                .green,
                                .cyan,
                                .blue,
                                .purple,
                                .pink
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                resultColor,
                                secondaryColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 21)
                )
                .shadow(
                    color: isSSR
                        ? Color.white.opacity(0.80)
                        : resultColor.opacity(0.38),
                    radius: isSSR ? 22 : 15,
                    x: 0,
                    y: 7
                )
            }
            .buttonStyle(.plain)
            .opacity(showContent ? 1 : 0)
            .offset(y: buttonOffset)
        }
        .padding(28)
    }

    private var prizeIconView: some View {
        ZStack {
            Circle()
                .fill(resultColor.opacity(0.18))
                .frame(
                    width: isSSR ? 270 : 225,
                    height: isSSR ? 270 : 225
                )
                .scaleEffect(glowScale)

            Circle()
                .stroke(
                    isSSR
                        ? AngularGradient(
                            colors: [
                                .red,
                                .orange,
                                .yellow,
                                .green,
                                .cyan,
                                .blue,
                                .purple,
                                .pink,
                                .red
                            ],
                            center: .center
                        )
                        : AngularGradient(
                            colors: [
                                resultColor,
                                secondaryColor,
                                .white,
                                resultColor
                            ],
                            center: .center
                        ),
                    lineWidth: isSSR ? 11 : 4
                )
                .frame(
                    width: isSSR ? 235 : 200,
                    height: isSSR ? 235 : 200
                )
                .rotationEffect(
                    .degrees(ringRotation)
                )
                .shadow(
                    color: isSSR
                        ? Color.white
                        : Color.clear,
                    radius: 14
                )

            Circle()
                .fill(Color(.systemBackground))
                .frame(
                    width: isSSR ? 180 : 160,
                    height: isSSR ? 180 : 160
                )
                .shadow(
                    color: resultColor.opacity(0.68),
                    radius: isSSR ? 42 : 24
                )

            Text(prize.icon)
                .font(
                    .system(
                        size: isSSR ? 96 : 80
                    )
                )
                .scaleEffect(iconScale)
                .rotationEffect(
                    .degrees(iconRotation)
                )
        }
    }

    private var flashLayer: some View {
        Color.white
            .ignoresSafeArea()
            .opacity(showFlash ? 0.94 : 0)
            .allowsHitTesting(false)
    }

    private func startResultAnimation() {
        playHaptic()

        if prize.rarity >= 4 {
            runFlashAnimation()
        }

        withAnimation(
            .spring(
                response: 0.72,
                dampingFraction: 0.58
            )
        ) {
            showContent = true
            iconScale = 1
            iconRotation = 0
            titleOffset = 0
            buttonOffset = 0
            glowScale = 1
        }

        withAnimation(
            .linear(
                duration: isSSR ? 2.8 : 6.0
            )
            .repeatForever(
                autoreverses: false
            )
        ) {
            ringRotation = 360
            rainbowRotation = 360
        }

        withAnimation(
            .easeInOut(duration: isSSR ? 0.48 : 0.85)
                .repeatForever(autoreverses: true)
        ) {
            glowScale = isSSR ? 1.20 : 1.10
        }

        if isSR || isSSR {
            lightningVisible = true
        }

        if isSSR {
            runResultShake()
            runSSRResultHaptics()
        }
    }

    private func runFlashAnimation() {
        showFlash = true

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.16
        ) {
            showFlash = false
        }

        if isSSR {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.34
            ) {
                showFlash = true
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.45
            ) {
                showFlash = false
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.68
            ) {
                showFlash = true
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.79
            ) {
                showFlash = false
            }
        }
    }

    private func runResultShake() {
        let positions: [CGFloat] = [
            -12,
            12,
            -10,
            10,
            -7,
            7,
            -4,
            4,
            0
        ]

        for (index, position) in positions.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.07
            ) {
                withAnimation(
                    .linear(duration: 0.065)
                ) {
                    screenShake = position
                }
            }
        }
    }

    private func runSSRResultHaptics() {
        let delays = [
            0.15,
            0.34,
            0.55,
            0.80
        ]

        for delay in delays {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay
            ) {
                let generator =
                    UIImpactFeedbackGenerator(
                        style: .heavy
                    )

                generator.prepare()
                generator.impactOccurred(
                    intensity: 1.0
                )
            }
        }
    }

    private func playHaptic() {
        switch prize.rarity {
        case 5:
            let generator =
                UINotificationFeedbackGenerator()

            generator.prepare()
            generator.notificationOccurred(.success)

        case 4:
            let generator =
                UIImpactFeedbackGenerator(
                    style: .heavy
                )

            generator.prepare()
            generator.impactOccurred()

        case 3:
            let generator =
                UIImpactFeedbackGenerator(
                    style: .medium
                )

            generator.prepare()
            generator.impactOccurred()

        default:
            let generator =
                UIImpactFeedbackGenerator(
                    style: .light
                )

            generator.prepare()
            generator.impactOccurred()
        }
    }
}

#Preview {
    NavigationStack {
        GachaView()
    }
}
