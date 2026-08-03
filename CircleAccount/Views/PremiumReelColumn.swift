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

    @State private var stopBounce = false
    @State private var settlingOffset: CGFloat = 0
    @State private var slipOpacity = 0.0
    @State private var slipOffset: CGFloat = -34
    @State private var reelCompression: CGFloat = 1.0
    @State private var horizontalShake: CGFloat = 0
    @State private var lockKickOffset: CGFloat = 0
    @State private var stopGlowScale: CGFloat = 1.0

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

    // PremiumCabinetの1リール窓に合わせた固定表示領域。
    private let reelWindowWidth: CGFloat = 78
    private let reelWindowHeight: CGFloat = 184
    private let reelWindowOffsetX: CGFloat = 0
    private let reelWindowOffsetY: CGFloat = -2

    var body: some View {
        GeometryReader { _ in
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
                let currentVelocity = spinVelocity(at: context.date)
                let velocityBlur = motionBlurRadius(for: currentVelocity)

                ZStack {
                    reelBackground

                    if isSpinning || isDecelerating {
                        spinningReel(
                            baseIndex: baseIndex,
                            verticalOffset: verticalOffset,
                            motionBlur: velocityBlur
                        )
                    } else {
                        stoppedReel
                    }

                    if slipOpacity > 0 {
                        slipTrail
                    }

                    reelShade
                }
                .frame(
                    width: reelWindowWidth,
                    height: reelWindowHeight
                )
                // 停止時の圧縮アニメーションだけは既存仕様を維持する。
                .scaleEffect(
                    x: 1,
                    y: reelCompression,
                    anchor: .center
                )
                .offset(
                    x: horizontalShake + reelWindowOffsetX,
                    y: lockKickOffset + reelWindowOffsetY
                )
                .mask {
                    Rectangle()
                        .frame(
                            width: reelWindowWidth,
                            height: reelWindowHeight
                        )
                }
            }
        }
        .frame(
            width: reelWindowWidth,
            height: reelWindowHeight
        )
        // 下端位置を維持し、高さ増加分を上方向だけへ広げる。
        .offset(y: 0)
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
        verticalOffset: CGFloat,
        motionBlur: CGFloat
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
        .blur(radius: motionBlur)
    }

    private var visibleStoppedSymbol: String {
        if hasStartedCurrentSpin && isStopped {
            return finalSymbol
        }

        return initialDisplaySymbol
    }

    private var stoppedReel: some View {
        let visibleSymbol = visibleStoppedSymbol

        return reelSymbolView(
            symbol: visibleSymbol,
            size: 54
        )
        .frame(
            width: reelWindowWidth,
            height: reelWindowHeight
        )
        .scaleEffect(
            (stopBounce ? 1.17 : 1.0) * stopGlowScale
        )
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
            let displaySize = size * 1.05

            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth: imageMaximumWidth(
                        for: symbol,
                        baseSize: displaySize
                    ),
                    maxHeight: displaySize
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
                max(
                    date.timeIntervalSince(
                        decelerationStartDate
                    ),
                    0
                ),
                duration
            )

            let progress =
                duration > 0
                    ? elapsed / duration
                    : 1

            /*
             実機風の減速カーブ。

             速度:
             v(p) = v0 × (1 - p)^2

             距離は速度を積分した値:
             v0 × duration ×
             (p - p² + p³ / 3)

             停止直前まで少し回転が残るため、
             線形減速よりも重量感が出る。
             */
            let easedDistance =
                decelerationInitialSpeed
                * duration
                * (
                    progress
                    - progress * progress
                    + (
                        progress
                        * progress
                        * progress
                        / 3.0
                    )
                )

            /*
             最後の約18%で、ごく小さな
             「歯車が噛み合う揺れ」を加える。
             */
            let lockStart = 0.82

            let lockProgress =
                max(
                    0,
                    min(
                        1,
                        (progress - lockStart)
                        / (1 - lockStart)
                    )
                )

            let lockJitter =
                sin(
                    lockProgress
                    * .pi
                    * 3.0
                )
                * (1 - lockProgress)
                * 0.055

            return
                decelerationStartPhase
                + easedDistance
                + lockJitter
        }

        let elapsed = max(
            date.timeIntervalSince(spinStartDate),
            0
        )

        let targetSpeed =
            20.5 + Double(reelIndex) * 2.75

        /*
         回転開始から最高速までの加速時間。
         左→中→右で少しだけ差をつけ、
         3本が完全同期して見えないようにする。
         */
        let accelerationDuration =
            0.58 + Double(reelIndex) * 0.055

        let accelerationProgress =
            min(
                1,
                elapsed / accelerationDuration
            )

        /*
         smoothstep:
         3p² - 2p³

         開始直後と最高速到達時の速度変化を
         滑らかにする。
         */
        let smoothAcceleration =
            accelerationProgress
            * accelerationProgress
            * (
                3
                - 2 * accelerationProgress
            )

        /*
         加速区間の移動距離は、
         smoothstepを積分した値を使う。

         ∫(3p² - 2p³)dp
         = p³ - 0.5p⁴
         */
        let acceleratedDistance =
            targetSpeed
            * accelerationDuration
            * (
                pow(accelerationProgress, 3)
                - 0.5
                * pow(accelerationProgress, 4)
            )

        let cruisingElapsed =
            max(
                0,
                elapsed - accelerationDuration
            )

        /*
         最高速中は一定速度に見えすぎないよう、
         モーターの微妙な速度揺らぎを距離へ加える。
         */
        let motorVariation =
            sin(
                cruisingElapsed * 6.4
                + Double(reelIndex) * 1.45
            )
            * 0.075
            + sin(
                cruisingElapsed * 15.2
                + Double(reelIndex) * 0.82
            )
            * 0.022

        let cruisingDistance =
            cruisingElapsed
            * targetSpeed
            + motorVariation

        return
            Double(spinStartOffset)
            + acceleratedDistance
            + cruisingDistance
    }


    private func spinVelocity(at date: Date) -> Double {
        if isDecelerating {
            let duration = decelerationDuration
            let elapsed = min(
                max(date.timeIntervalSince(decelerationStartDate), 0),
                duration
            )
            let progress = duration > 0 ? elapsed / duration : 1
            return decelerationInitialSpeed * pow(max(0, 1 - progress), 2)
        }

        guard isSpinning else { return 0 }

        let elapsed = max(date.timeIntervalSince(spinStartDate), 0)
        let targetSpeed = 20.5 + Double(reelIndex) * 2.75
        let accelerationDuration = 0.58 + Double(reelIndex) * 0.055
        let progress = min(1, elapsed / accelerationDuration)
        let smoothAcceleration = progress * progress * (3 - 2 * progress)
        return targetSpeed * smoothAcceleration
    }

    private func motionBlurRadius(for velocity: Double) -> CGFloat {
        guard velocity > 0 else { return 0 }

        let normalized = min(max(velocity / 26.0, 0), 1)

        if isDecelerating {
            // 停止直前に輪郭が戻り、ロックする瞬間を見やすくする。
            return CGFloat(0.15 + normalized * 1.75)
        }

        return CGFloat(0.25 + normalized * 2.05)
    }

    private var decelerationDuration: Double {
        switch reelIndex {
        case 0:
            return 0.34
        case 1:
            return 0.40
        default:
            return 0.50
        }
    }

    private var decelerationInitialSpeed: Double {
        20.5 + Double(reelIndex) * 2.75
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
        horizontalShake = 0
        lockKickOffset = 0
        stopGlowScale = 1.0

        let drop: CGFloat
        let rebound: CGFloat
        let compressStart: CGFloat
        let compressEnd: CGFloat
        let firstShake: CGFloat
        let secondShake: CGFloat

        switch reelIndex {
        case 0:
            drop = -20
            rebound = 6
            compressStart = 1.045
            compressEnd = 0.955
            firstShake = -1.2
            secondShake = 0.8

        case 1:
            drop = -27
            rebound = 8
            compressStart = 1.065
            compressEnd = 0.935
            firstShake = 1.6
            secondShake = -1.0

        default:
            drop = -36
            rebound = 11
            compressStart = 1.095
            compressEnd = 0.905
            firstShake = -2.1
            secondShake = 1.25
        }

        /*
         停止直前に一コマ滑ったように見せる。
         その後「ガクッ」と噛み合い、
         小さく左右へ揺れて静止する。
         */
        settlingOffset = drop
        slipOffset = drop - 20
        slipOpacity = 0.86

        reelCompression = compressStart
        horizontalShake = firstShake
        lockKickOffset = -2
        stopGlowScale = 0.985

        // まず停止位置を少し通り過ぎる。実機の慣性を表現する。
        withAnimation(.easeOut(duration: 0.072)) {
            settlingOffset = rebound
            slipOffset = rebound + 9
            reelCompression = compressEnd
            horizontalShake = secondShake
            lockKickOffset = 5
            stopGlowScale = 1.035
        }

        // 約0.28コマだけ逆方向へ戻し、歯車が噛み合うロック感を作る。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.072) {
            withAnimation(.easeInOut(duration: 0.060)) {
                settlingOffset = -rowHeight * 0.28
                lockKickOffset = -4
                reelCompression = 1.035
                horizontalShake = -secondShake * 0.86
                stopGlowScale = 1.075
            }

            withAnimation(.easeOut(duration: 0.115)) {
                slipOpacity = 0
            }
        }

        // ロック後の小さな反発。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.132) {
            withAnimation(
                .spring(response: 0.17, dampingFraction: 0.34)
            ) {
                stopBounce = true
                settlingOffset = -4
                lockKickOffset = 2
                reelCompression = 0.985
                horizontalShake = secondShake * 0.42
                stopGlowScale = 1.025
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.205) {
            withAnimation(.easeOut(duration: 0.065)) {
                horizontalShake = -secondShake * 0.24
                lockKickOffset = -1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.265) {
            withAnimation(
                .spring(response: 0.24, dampingFraction: 0.60)
            ) {
                settlingOffset = 0
                reelCompression = 1
                horizontalShake = 0
                lockKickOffset = 0
                stopGlowScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            withAnimation(
                .spring(response: 0.24, dampingFraction: 0.72)
            ) {
                stopBounce = false
            }

        }
    }

    private func resetStopAnimation() {
        isDecelerating = false
        stopBounce = false
        settlingOffset = 0
        slipOpacity = 0
        slipOffset = -34
        reelCompression = 1
        horizontalShake = 0
        lockKickOffset = 0
        stopGlowScale = 1.0
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

