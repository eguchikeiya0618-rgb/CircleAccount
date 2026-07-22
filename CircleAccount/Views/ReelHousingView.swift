//
//  ReelHousingView.swift
//  CircleAccount
//

import SwiftUI

struct ReelHousingView: View {
    let resultSymbols: [String]
    let displaySymbols: [String]
    let reelPool: [String]
    let isSpinning: Bool
    let stoppedReelCount: Int
    let heatLevel: SlotHeatLevel
    let machineGlow: Color
    let stopLineFlashOpacity: Double
    let glassSweepOffset: CGFloat
    let sparkBurstProgress: CGFloat
    let sparkBurstOpacity: Double
    let premiumBacklightPhase: Double
    let reachPulse: Bool
    let reachOverlayOpacity: Double
    let reachOverlayScale: CGFloat

    private var safeResultSymbols: [String] {
        [
            resultSymbols.indices.contains(0) ? resultSymbols[0] : "7",
            resultSymbols.indices.contains(1) ? resultSymbols[1] : "7",
            resultSymbols.indices.contains(2) ? resultSymbols[2] : "7"
        ]
    }

    private var safeDisplaySymbols: [String] {
        [
            displaySymbols.indices.contains(0) ? displaySymbols[0] : "⭐",
            displaySymbols.indices.contains(1) ? displaySymbols[1] : "🏸",
            displaySymbols.indices.contains(2) ? displaySymbols[2] : "💰"
        ]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.34, green: 0.35, blue: 0.39),
                            Color(red: 0.07, green: 0.075, blue: 0.095),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.black)
                .padding(8)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    PremiumReelColumn(
                        finalSymbol: safeResultSymbols[index],
                        initialDisplaySymbol: safeDisplaySymbols[index],
                        symbolPool: reelPool,
                        isSpinning: isSpinning && stoppedReelCount <= index,
                        isStopped: stoppedReelCount > index,
                        reelIndex: index,
                        glowColor: machineGlow
                    )
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 15)

            GeometryReader { proxy in
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.red.opacity(0.30),
                                    Color.white.opacity(0.92),
                                    Color.red.opacity(0.30),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(proxy.size.width - 42, 0),
                            height: 2
                        )
                        .opacity(0)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    machineGlow.opacity(0.46),
                                    Color.white,
                                    machineGlow.opacity(0.46),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(proxy.size.width - 42, 0),
                            height: stopLineFlashOpacity > 0 ? 3 : 1
                        )
                        .opacity(stopLineFlashOpacity)
                        .shadow(
                            color: machineGlow.opacity(0.95),
                            radius: 10
                        )
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
            .padding(8)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
            )
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    Color.white.opacity(stopLineFlashOpacity * 0.85),
                    lineWidth: 3
                )
                .padding(8)
                .allowsHitTesting(false)

            reelGlassReflection
                .allowsHitTesting(false)

            stopSparkOverlay
                .allowsHitTesting(false)

            premiumReelBacklight
                .allowsHitTesting(false)

            reachOverlay
                .allowsHitTesting(false)
        }
        .frame(height: 154)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.gray.opacity(0.25),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
        }
    }

    private var reelGlassReflection: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.04),
                    Color.white.opacity(0.28),
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(
                width: proxy.size.width * 0.34,
                height: proxy.size.height * 1.7
            )
            .rotationEffect(.degrees(18))
            .offset(
                x: proxy.size.width * glassSweepOffset,
                y: -proxy.size.height * 0.35
            )
            .blendMode(.screen)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
        )
        .padding(8)
    }

    private var stopSparkOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<28, id: \.self) { index in
                    let angle = Double(index) * (360.0 / 28.0)
                    let radians = angle * .pi / 180
                    let distance =
                        CGFloat(24 + (index % 7) * 7)
                        * sparkBurstProgress

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    index.isMultiple(of: 2)
                                        ? Color.yellow
                                        : heatLevel.lampColor,
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: CGFloat(10 + index % 5 * 4),
                            height: 2.4
                        )
                        .rotationEffect(.degrees(angle))
                        .position(
                            x: proxy.size.width / 2
                                + cos(radians) * distance,
                            y: proxy.size.height / 2
                                + sin(radians) * distance
                        )
                        .opacity(
                            sparkBurstOpacity
                                * (1 - Double(sparkBurstProgress) * 0.72)
                        )
                        .shadow(
                            color:
                                index.isMultiple(of: 2)
                                    ? Color.yellow.opacity(0.9)
                                    : heatLevel.lampColor.opacity(0.9),
                            radius: 5
                        )
                }
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
        )
        .padding(8)
    }

    private var premiumReelBacklight: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    let wave = sin(
                        premiumBacklightPhase
                            + Double(index) * 1.55
                    )
                    let strength = (wave + 1) / 2

                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.red.opacity(0.18 + strength * 0.34),
                            Color.yellow.opacity(0.16 + strength * 0.38),
                            Color.green.opacity(0.14 + strength * 0.34),
                            Color.cyan.opacity(0.16 + strength * 0.36),
                            Color.purple.opacity(0.18 + strength * 0.36),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(width: proxy.size.width / 3)
                    .blur(radius: 14)
                    .opacity(
                        heatLevel == .premium
                            ? 0.55 + strength * 0.45
                            : 0
                    )
                }
            }
            .blendMode(.screen)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
        )
        .padding(8)
    }

    private var reachOverlay: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
            .stroke(
                AngularGradient(
                    colors: [
                        Color.red,
                        Color.orange,
                        Color.yellow,
                        Color.white,
                        Color.red
                    ],
                    center: .center
                ),
                lineWidth: 5
            )
            .scaleEffect(reachOverlayScale)
            .opacity(reachOverlayOpacity)
            .shadow(
                color: Color.red.opacity(0.85),
                radius: 18
            )

            Text(
                heatLevel == .premium
                    ? "SUPER REACH"
                    : "REACH"
            )
            .font(
                .system(
                    size: heatLevel == .premium ? 26 : 22,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(1.2)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        heatLevel == .premium
                            ? Color.yellow
                            : Color.red,
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.black, radius: 2, y: 2)
            .shadow(
                color:
                    heatLevel == .premium
                        ? Color.yellow.opacity(0.95)
                        : Color.red.opacity(0.90),
                radius: reachPulse ? 16 : 8
            )
            .scaleEffect(reachPulse ? 1.08 : 0.96)
            .opacity(reachOverlayOpacity)
        }
        .padding(8)
    }
}
