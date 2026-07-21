//
//  PremiumReelColumn.swift
//  CircleAccount
//

import SwiftUI

struct PremiumReelColumn: View {
    let finalSymbol: String
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

    private let visibleRows = 7
    private let rowHeight: CGFloat = 50

    var body: some View {
        GeometryReader { proxy in
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 60.0,
                    paused: !isSpinning
                )
            ) { context in
                let phase = spinPhase(at: context.date)
                let baseIndex = Int(floor(phase))
                let fractional = phase - floor(phase)
                let verticalOffset = CGFloat(fractional) * rowHeight

                ZStack {
                    reelBackground

                    if isSpinning {
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
        .onChange(of: isStopped) { _, stopped in
            guard stopped else {
                resetStopAnimation()
                return
            }

            playStopAnimation()
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
                    Color.white,
                    Color(
                        red: 0.90,
                        green: 0.91,
                        blue: 0.94
                    ),
                    Color.white
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

                    Text(
                        symbolForRollingRow(
                            baseIndex: baseIndex,
                            row: row
                        )
                    )
                    .font(
                        .system(
                            size: distanceFromCenter == 0 ? 43 : 29
                        )
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

    private var stoppedReel: some View {
        VStack(spacing: 0) {
            Text(previousSymbol(for: finalSymbol))
                .font(.system(size: 25))
                .frame(height: rowHeight)
                .opacity(0.16)

            Text(finalSymbol)
                .font(.system(size: 49))
                .frame(height: rowHeight)
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

            Text(nextSymbol(for: finalSymbol))
                .font(.system(size: 25))
                .frame(height: rowHeight)
                .opacity(0.16)
        }
        .offset(y: settlingOffset)
    }

    private var slipTrail: some View {
        VStack(spacing: 0) {
            Text(previousSymbol(for: finalSymbol))
                .font(.system(size: 25))
                .frame(height: rowHeight)

            Text(finalSymbol)
                .font(.system(size: 47))
                .frame(height: rowHeight)

            Text(nextSymbol(for: finalSymbol))
                .font(.system(size: 25))
                .frame(height: rowHeight)
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

    private func spinPhase(at date: Date) -> Double {
        let baseSpeed =
            20.0 + Double(reelIndex) * 3.1

        let microVariation =
            sin(
                date.timeIntervalSinceReferenceDate * 6.2
                    + Double(reelIndex) * 1.7
            ) * 0.55

        return
            date.timeIntervalSinceReferenceDate
            * (baseSpeed + microVariation)
    }

    private func symbolForRollingRow(
        baseIndex: Int,
        row: Int
    ) -> String {
        guard !symbolPool.isEmpty else {
            return finalSymbol
        }

        let index = positiveModulo(
            baseIndex + row + reelIndex * 3,
            symbolPool.count
        )

        return symbolPool[index]
    }

    private func playStopAnimation() {
        stopBounce = false
        settlingOffset = -30
        slipOffset = -48
        slipOpacity = 0.86
        flashOpacity = 0.58
        reelCompression = 1.08

        withAnimation(
            .easeOut(duration: 0.11)
        ) {
            settlingOffset = 11
            slipOffset = 16
            reelCompression = 0.92
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.10
        ) {
            withAnimation(
                .spring(
                    response: 0.20,
                    dampingFraction: 0.38
                )
            ) {
                stopBounce = true
                settlingOffset = -5
                reelCompression = 1.035
            }

            withAnimation(
                .easeOut(duration: 0.12)
            ) {
                slipOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.21
        ) {
            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.64
                )
            ) {
                settlingOffset = 0
                reelCompression = 1
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.29
        ) {
            withAnimation(
                .spring(
                    response: 0.27,
                    dampingFraction: 0.70
                )
            ) {
                stopBounce = false
            }

            withAnimation(
                .easeOut(duration: 0.22)
            ) {
                flashOpacity = 0
            }
        }
    }

    private func resetStopAnimation() {
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
            return "⭐"
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
            return "🎁"
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
