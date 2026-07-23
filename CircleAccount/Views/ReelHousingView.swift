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

    @State private var stoppedFlashIndex: Int? = nil
    @State private var stoppedFlashOpacity: Double = 0
    @State private var wholeReelFlashOpacity: Double = 0

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

            reelGlassDepth
                .allowsHitTesting(false)

            reelGlassReflection
                .allowsHitTesting(false)

            reelStopStrobe
                .allowsHitTesting(false)

            stopSparkOverlay
                .allowsHitTesting(false)

            premiumReelBacklight
                .allowsHitTesting(false)

            reelInteriorLighting
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
        .onChange(of: stoppedReelCount) { oldValue, newValue in
            guard newValue > oldValue else {
                if newValue == 0 {
                    stoppedFlashIndex = nil
                    stoppedFlashOpacity = 0
                    wholeReelFlashOpacity = 0
                }
                return
            }

            playStopStrobe(for: min(newValue - 1, 2))
        }
    }

    private var reelGlassDepth: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            Color.white.opacity(0.07),
                            Color.black.opacity(0.55),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.28),
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.34)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 3)

                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.20)
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.035),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: proxy.size.width * 0.92,
                        height: proxy.size.height * 0.58
                    )
                    .offset(y: -proxy.size.height * 0.26)
                    .blur(radius: 7)
                    .blendMode(.screen)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: proxy.size.width * 0.74,
                        height: 1.2
                    )
                    .offset(y: proxy.size.height * 0.31)
                    .blur(radius: 0.7)
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

    private var reelStopStrobe: some View {
        GeometryReader { proxy in
            ZStack {
                if let index = stoppedFlashIndex {
                    let width = proxy.size.width / 3

                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: strobeColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: max(width - 9, 0),
                        height: max(proxy.size.height - 18, 0)
                    )
                    .position(
                        x: width * (CGFloat(index) + 0.5),
                        y: proxy.size.height / 2
                    )
                    .opacity(stoppedFlashOpacity)
                    .blendMode(.screen)
                    .shadow(
                        color: machineGlow.opacity(0.95),
                        radius: 18
                    )
                }

                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .fill(
                    heatLevel == .premium
                        ? AnyShapeStyle(
                            AngularGradient(
                                colors: [
                                    .red, .orange, .yellow,
                                    .green, .cyan, .blue,
                                    .purple, .red
                                ],
                                center: .center
                            )
                        )
                        : AnyShapeStyle(Color.white)
                )
                .opacity(wholeReelFlashOpacity)
                .blendMode(.screen)
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

    private var strobeColors: [Color] {
        if heatLevel == .premium {
            return [
                Color.white,
                Color.cyan.opacity(0.95),
                Color.purple.opacity(0.85),
                Color.white
            ]
        }

        return [
            Color.white,
            machineGlow.opacity(0.82),
            Color.white.opacity(0.92)
        ]
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


    private var reelInteriorLighting: some View {
        GeometryReader { proxy in
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 30.0,
                    paused: !isSpinning
                )
            ) { context in
                let time =
                    context.date
                        .timeIntervalSinceReferenceDate

                ZStack {
                    reelFrameGlow(
                        size: proxy.size,
                        time: time
                    )

                    reelSeparatorLights(
                        size: proxy.size,
                        time: time
                    )

                    outerGlassGlow(
                        size: proxy.size,
                        time: time
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

    private func reelFrameGlow(
        size: CGSize,
        time: Double
    ) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                let active =
                    isSpinning
                    && stoppedReelCount <= index

                let pulse =
                    0.78
                    + 0.22
                    * sin(
                        time * 5.2
                        + Double(index) * 1.35
                    )

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .stroke(
                    reelLightGradient(
                        index: index,
                        time: time
                    ),
                    lineWidth: active ? 1.35 : 0.65
                )
                .opacity(
                    active
                        ? 0.24 + pulse * 0.16
                        : 0.06
                )
                .shadow(
                    color:
                        reelLampColor(
                            index: index,
                            time: time
                        )
                        .opacity(
                            active
                                ? 0.38
                                : 0
                        ),
                    radius: active ? 5 : 0
                )
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 7)
    }

    private func reelSeparatorLights(
        size: CGSize,
        time: Double
    ) -> some View {
        let innerWidth =
            max(size.width - 26, 0)

        let reelWidth =
            max(
                (innerWidth - 14) / 3,
                0
            )

        let firstX =
            13 + reelWidth + 3.5

        let secondX =
            firstX + reelWidth + 7

        return ZStack {
            separatorLight(
                xPosition: firstX,
                active:
                    isSpinning
                    && stoppedReelCount <= 0,
                time: time,
                phase: 0
            )

            separatorLight(
                xPosition: secondX,
                active:
                    isSpinning
                    && stoppedReelCount <= 1,
                time: time,
                phase: 1.2
            )
        }
    }

    private func separatorLight(
        xPosition: CGFloat,
        active: Bool,
        time: Double,
        phase: Double
    ) -> some View {
        let travellingPosition =
            (
                sin(
                    time * 3.6 + phase
                )
                + 1
            )
            / 2

        return ZStack {
            Capsule()
                .fill(
                    Color.black.opacity(0.82)
                )
                .frame(
                    width: 5,
                    height: 116
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            reelLampColor(
                                index: Int(phase),
                                time: time
                            )
                            .opacity(active ? 0.10 : 0),
                            Color.white.opacity(
                                active ? 0.40 : 0
                            ),
                            reelLampColor(
                                index: Int(phase),
                                time: time
                            )
                            .opacity(active ? 0.12 : 0),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: 1.5,
                    height: 94
                )
                .opacity(active ? 0.55 : 0)

            Capsule()
                .fill(
                    reelLampColor(
                        index: Int(phase),
                        time: time
                    )
                )
                .frame(
                    width: 2.2,
                    height: 18
                )
                .blur(radius: 1.2)
                .offset(
                    y:
                        CGFloat(
                            travellingPosition
                        )
                        * 76
                        - 38
                )
                .opacity(active ? 0.72 : 0)
                .shadow(
                    color:
                        reelLampColor(
                            index: Int(phase),
                            time: time
                        )
                        .opacity(0.72),
                    radius: 4
                )
        }
        .position(
            x: xPosition,
            y: 69
        )
    }

    private func outerGlassGlow(
        size: CGSize,
        time: Double
    ) -> some View {
        let pulse =
            0.72
            + 0.28
            * sin(time * 3.8)

        return RoundedRectangle(
            cornerRadius: 15,
            style: .continuous
        )
        .stroke(
            LinearGradient(
                colors: [
                    Color.clear,
                    machineGlow.opacity(
                        isSpinning
                            ? 0.13 + pulse * 0.08
                            : 0.03
                    ),
                    Color.white.opacity(
                        isSpinning
                            ? 0.10
                            : 0.02
                    ),
                    machineGlow.opacity(
                        isSpinning
                            ? 0.13 + pulse * 0.08
                            : 0.03
                    ),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 1
        )
        .padding(2)
        .shadow(
            color:
                machineGlow.opacity(
                    isSpinning
                        ? 0.15
                        : 0
                ),
            radius: 7
        )
    }

    private func reelLightGradient(
        index: Int,
        time: Double
    ) -> LinearGradient {
        if heatLevel == .premium {
            let colors = premiumColors(
                index: index,
                time: time
            )

            return LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.clear,
                heatLevel.lampColor.opacity(0.38),
                Color.white.opacity(0.42),
                heatLevel.lampColor.opacity(0.32),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func reelLampColor(
        index: Int,
        time: Double
    ) -> Color {
        guard heatLevel == .premium else {
            return heatLevel.lampColor
        }

        let colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .cyan,
            .blue,
            .purple
        ]

        let movingIndex =
            positiveModulo(
                Int(time * 4.5)
                + index * 2,
                colors.count
            )

        return colors[movingIndex]
    }

    private func premiumColors(
        index: Int,
        time: Double
    ) -> [Color] {
        let colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .cyan,
            .blue,
            .purple
        ]

        let offset =
            positiveModulo(
                Int(time * 4.0)
                + index * 2,
                colors.count
            )

        return (0..<5).map { step in
            colors[
                positiveModulo(
                    offset + step,
                    colors.count
                )
            ]
            .opacity(0.40)
        }
    }

    private func playStopStrobe(
        for index: Int
    ) {
        stoppedFlashIndex = index
        stoppedFlashOpacity = 0
        wholeReelFlashOpacity = 0

        withAnimation(.easeOut(duration: 0.035)) {
            stoppedFlashOpacity =
                index == 2
                    ? 0.92
                    : 0.68
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.045
        ) {
            withAnimation(.easeOut(duration: 0.16)) {
                stoppedFlashOpacity = 0
            }
        }

        guard index == 2 else {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.22
            ) {
                stoppedFlashIndex = nil
            }
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.055
        ) {
            withAnimation(.easeOut(duration: 0.04)) {
                wholeReelFlashOpacity =
                    heatLevel == .premium
                        ? 0.72
                        : 0.38
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.11
        ) {
            withAnimation(.easeOut(duration: 0.24)) {
                wholeReelFlashOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.34
        ) {
            stoppedFlashIndex = nil
        }
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
