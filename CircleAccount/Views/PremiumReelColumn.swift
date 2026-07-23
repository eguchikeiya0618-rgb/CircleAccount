//
//  PremiumReelColumn.swift
//  CircleAccount
//

import SwiftUI

struct PremiumReelColumn: View {
    let finalSymbol: String
    let initialDisplaySymbol: String
    let symbolPool: [String]
    let isSpinning: Bool
    let isStopped: Bool
    let reelIndex: Int
    let glowColor: Color

    @State private var stopBounce = false
    @State private var settlingOffset: CGFloat = 0
    @State private var flashOpacity = 0.0
    @State private var slipOpacity = 0.0
    @State private var slipOffset: CGFloat = -34
    @State private var reelCompression: CGFloat = 1.0

    // 回転中だけ使用するダミー絵柄列
    @State private var rollingPool: [String] = []
    @State private var spinStartDate = Date()
    @State private var spinStartOffset = 0
    @State private var hasStartedCurrentSpin = false

    // 停止直前の慣性回転
    @State private var isDecelerating = false
    @State private var decelerationStartDate = Date()
    @State private var decelerationStartPhase = 0.0

    private let visibleRows = 7
    private let rowHeight: CGFloat = 50

    var body: some View {
        GeometryReader { proxy in
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 60.0,
                    paused: !(isSpinning || isDecelerating)
                )
            ) { context in
                let phase = spinPhase(at: context.date)
                let baseIndex = Int(floor(phase))
                let fractional = phase - floor(phase)
                let verticalOffset = CGFloat(fractional) * rowHeight

                ZStack {
                    reelBackground

                    if isSpinning || isDecelerating {
                        spinningReel(
                            baseIndex: baseIndex,
                            verticalOffset: verticalOffset
                        )
                    } else {
                        stoppedReel
                    }

                    if slipOpacity > 0 {
                        slipTrail
                    }

                    Rectangle()
                        .fill(glowColor.opacity(flashOpacity))
                        .blendMode(.screen)

                    reelShade
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .scaleEffect(
                    x: 1,
                    y: reelCompression,
                    anchor: .center
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                )
            }
        }
        .onAppear {
            prepareRollingPool()
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                isDecelerating = false
                hasStartedCurrentSpin = true
                prepareRollingPool()
                resetStopAnimation()
            }
        }
        .onChange(of: finalSymbol) { _, _ in
            if !isSpinning {
                hasStartedCurrentSpin = false
                resetStopAnimation()
            }
        }
        .onChange(of: isStopped) { _, stopped in
            guard stopped else {
                isDecelerating = false
                resetStopAnimation()
                return
            }

            beginDecelerationAndStop()
        }
    }

    private var reelBackground: some View {
        RoundedRectangle(
            cornerRadius: 11,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.95),
                    Color(red: 0.94, green: 0.94, blue: 0.90),
                    Color(red: 0.98, green: 0.98, blue: 0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func spinningReel(
        baseIndex: Int,
        verticalOffset: CGFloat
    ) -> some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<visibleRows, id: \.self) { row in
                    let distanceFromCenter = abs(row - 3)

                    let symbol = symbolForRollingRow(
                        baseIndex: baseIndex,
                        row: row
                    )

                    reelSymbolView(
                        symbol: symbol,
                        size: distanceFromCenter == 0 ? 42 : 29
                    )
                    .frame(height: rowHeight)
                    .frame(maxWidth: .infinity)
                    .opacity(
                        distanceFromCenter == 0
                            ? 0.82
                            : distanceFromCenter == 1
                                ? 0.42
                                : 0.20
                    )
                    .blur(
                        radius:
                            distanceFromCenter == 0
                                ? 1.35
                                : 2.4
                    )
                    .scaleEffect(
                        x: distanceFromCenter == 0 ? 0.96 : 0.88,
                        y: distanceFromCenter == 0 ? 1.08 : 1.18
                    )
                }
            }
            .offset(
                y: -rowHeight * 2 - verticalOffset
            )

            VStack(spacing: 7) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(
                                        index.isMultiple(of: 2)
                                            ? 0.22
                                            : 0.12
                                    ),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 1.2)
                }
            }
            .padding(.horizontal, 5)
            .opacity(0.78)
            .blendMode(.screen)
        }
        .compositingGroup()
        .blur(radius: 0.35)
    }

    private var visibleStoppedSymbol: String {
        if hasStartedCurrentSpin && isStopped {
            return finalSymbol
        }

        return initialDisplaySymbol
    }

    private var stoppedReel: some View {
        let visibleSymbol = visibleStoppedSymbol

        return VStack(spacing: 0) {
            reelSymbolView(
                symbol: previousSymbol(for: visibleSymbol),
                size: 25
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .opacity(0.16)

            reelSymbolView(
                symbol: visibleSymbol,
                size: 54
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .scaleEffect(
                stopBounce ? 1.17 : 1.0
            )
            .shadow(
                color:
                    isStopped
                        ? glowColor.opacity(0.68)
                        : Color.clear,
                radius: 9
            )

            reelSymbolView(
                symbol: nextSymbol(for: visibleSymbol),
                size: 30
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .opacity(0.16)
        }
        .offset(y: settlingOffset)
    }
    private var slipTrail: some View {
        VStack(spacing: 0) {
            reelSymbolView(
                symbol: previousSymbol(for: finalSymbol),
                size: 25
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)

            reelSymbolView(
                symbol: finalSymbol,
                size: 46
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)

            reelSymbolView(
                symbol: nextSymbol(for: finalSymbol),
                size: 25
            )
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
        }
        .offset(y: slipOffset)
        .opacity(slipOpacity)
        .blur(radius: 4.5)
        .scaleEffect(x: 0.92, y: 1.16)
        .blendMode(.plusLighter)
    }

    private var reelShade: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.36),
                Color.clear,
                Color.clear,
                Color.black.opacity(0.36)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }


    @ViewBuilder
    private func reelSymbolView(
        symbol: String,
        size: CGFloat
    ) -> some View {
        if let assetName = imageAssetName(for: symbol) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth: imageMaximumWidth(
                        for: symbol,
                        baseSize: size
                    ),
                    maxHeight: size
                )
        } else {
            Text(symbol)
                .font(
                    .system(
                        size: size,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .minimumScaleFactor(0.45)
                .lineLimit(1)
        }
    }

    private func imageAssetName(
        for symbol: String
    ) -> String? {
        switch symbol {
        case "7", "7️⃣":
            return "symbol_red7"

        case "🌈7", "🌈7️⃣":
            return "symbol_rainbow7"

        case "BAR":
            return "symbol_bar"

        case "🔔":
            return "symbol_bell"

        case "🍇":
            return "symbol_grape"

        case "🍒":
            return "symbol_cherry"

        default:
            return nil
        }
    }

    private func imageMaximumWidth(
        for symbol: String,
        baseSize: CGFloat
    ) -> CGFloat {
        switch symbol {
        case "BAR":
            return baseSize * 2.0

        case "🍇":
            return baseSize * 1.20

        case "🔔":
            return baseSize * 1.12

        case "🍒":
            return baseSize * 1.12

        default:
            return baseSize
        }
    }

    private func spinPhase(at date: Date) -> Double {
        if isDecelerating {
            let duration = decelerationDuration
            let elapsed = min(
                max(date.timeIntervalSince(decelerationStartDate), 0),
                duration
            )
            let progress = duration > 0 ? elapsed / duration : 1

            // 線形減速を積分し、止まる直前まで滑らかに回す
            let easedDistance =
                decelerationInitialSpeed
                * duration
                * (progress - 0.5 * progress * progress)

            return decelerationStartPhase + easedDistance
        }

        let elapsed = max(
            date.timeIntervalSince(spinStartDate),
            0
        )

        let baseSpeed =
            20.0 + Double(reelIndex) * 3.1

        let microVariation =
            sin(
                elapsed * 6.2
                    + Double(reelIndex) * 1.7
            ) * 0.55

        return
            Double(spinStartOffset)
            + elapsed * (baseSpeed + microVariation)
    }

    private var decelerationDuration: Double {
        switch reelIndex {
        case 0:
            return 0.16
        case 1:
            return 0.20
        default:
            return 0.28
        }
    }

    private var decelerationInitialSpeed: Double {
        20.0 + Double(reelIndex) * 3.1
    }

    private func symbolForRollingRow(
        baseIndex: Int,
        row: Int
    ) -> String {
        let pool = rollingPool.isEmpty
            ? fallbackRollingPool
            : rollingPool

        guard !pool.isEmpty else {
            return "🍒"
        }

        let index = positiveModulo(
            baseIndex + row + reelIndex * 3,
            pool.count
        )

        return pool[index]
    }

    private var fallbackRollingPool: [String] {
        let filtered = symbolPool.filter {
            !$0.isEmpty && $0 != finalSymbol
        }

        var pool = filtered.isEmpty
            ? [
                "7", "🌈7", "BAR",
                "🔔", "🍇", "🍒"
            ].filter { $0 != finalSymbol }
            : filtered

        if !initialDisplaySymbol.isEmpty,
           initialDisplaySymbol != finalSymbol {
            pool.insert(initialDisplaySymbol, at: 0)
        }

        return pool.isEmpty ? ["🍒"] : pool
    }

    private func prepareRollingPool() {
        var pool = fallbackRollingPool.shuffled()

        if !initialDisplaySymbol.isEmpty,
           initialDisplaySymbol != finalSymbol {
            pool.removeAll { $0 == initialDisplaySymbol }
            pool.insert(initialDisplaySymbol, at: 0)
        }

        // 同じ絵柄が少ない場合でも十分な長さを確保
        while pool.count < visibleRows + 4 {
            pool.append(contentsOf: fallbackRollingPool.shuffled())
        }

        // 回転開始時の中央位置に最終結果が来ないよう調整
        let randomOffset = Int.random(
            in: 0..<max(pool.count, 1)
        )

        var safeOffset = randomOffset
        let centerRow = 3
        let centerIndex = positiveModulo(
            safeOffset + centerRow + reelIndex * 3,
            pool.count
        )

        if pool.count > 1,
           pool[centerIndex] == finalSymbol {
            safeOffset = positiveModulo(
                safeOffset + 1,
                pool.count
            )
        }

        rollingPool = pool
        spinStartOffset = safeOffset
        spinStartDate = Date()
    }

    private func beginDecelerationAndStop() {
        guard !isDecelerating else { return }

        decelerationStartPhase = spinPhase(at: Date())
        decelerationStartDate = Date()
        isDecelerating = true

        let duration = decelerationDuration

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard isStopped else {
                isDecelerating = false
                return
            }

            isDecelerating = false
            playStopAnimation()
        }
    }

    private func playStopAnimation() {
        stopBounce = false

        let drop: CGFloat
        let rebound: CGFloat
        let compressStart: CGFloat
        let compressEnd: CGFloat

        switch reelIndex {
        case 0:
            drop = -24
            rebound = 8
            compressStart = 1.05
            compressEnd = 0.95
        case 1:
            drop = -32
            rebound = 11
            compressStart = 1.08
            compressEnd = 0.92
        default:
            drop = -42
            rebound = 15
            compressStart = 1.12
            compressEnd = 0.88
        }

        settlingOffset = drop
        slipOffset = drop - 18
        slipOpacity = 0.9
        flashOpacity = reelIndex == 2 ? 0.95 : 0.65
        reelCompression = compressStart

        withAnimation(.easeOut(duration: 0.08)) {
            settlingOffset = rebound
            slipOffset = rebound + 6
            reelCompression = compressEnd
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.34)) {
                stopBounce = true
                self.settlingOffset = -6
                self.reelCompression = 1.03
            }
            withAnimation(.easeOut(duration: 0.10)) {
                self.slipOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
                self.settlingOffset = 0
                self.reelCompression = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.68)) {
                self.stopBounce = false
            }
            withAnimation(.easeOut(duration: 0.24)) {
                self.flashOpacity = 0
            }
        }
    }

    private func resetStopAnimation() {
        isDecelerating = false
        stopBounce = false
        settlingOffset = 0
        slipOpacity = 0
        slipOffset = -34
        flashOpacity = 0
        reelCompression = 1
    }

    private func previousSymbol(
        for symbol: String
    ) -> String {
        guard
            let index = symbolPool.firstIndex(of: symbol),
            !symbolPool.isEmpty
        else {
            return "🍒"
        }

        let previous = positiveModulo(
            index - 1,
            symbolPool.count
        )

        return symbolPool[previous]
    }

    private func nextSymbol(
        for symbol: String
    ) -> String {
        guard
            let index = symbolPool.firstIndex(of: symbol),
            !symbolPool.isEmpty
        else {
            return "🔔"
        }

        return symbolPool[
            (index + 1) % symbolPool.count
        ]
    }

    private func positiveModulo(
        _ value: Int,
        _ divisor: Int
    ) -> Int {
        guard divisor > 0 else {
            return 0
        }

        let remainder = value % divisor

        return
            remainder >= 0
                ? remainder
                : remainder + divisor
    }
}
