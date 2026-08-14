//
//  ReelHousingView.swift
//  CircleAccount
//

import SwiftUI

/// Owns the physical reel window. The drums only render moving belt content;
/// clipping, cylinder walls, glass and cabinet effects belong here.
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
    let reelSlipTrigger: Int
    let reelSlipIndex: Int
    let reelSlipIntensity: CGFloat
    var showsHousingDecoration = true

    @State private var stoppedFlashIndex: Int?
    @State private var stoppedFlashOpacity = 0.0
    @State private var wholeWindowFlashOpacity = 0.0
    @State private var slipEnergyOffset: CGFloat = -52
    @State private var slipEnergyOpacity = 0.0

    private enum Metrics {
        static let housingWidth: CGFloat = 280
        static let housingHeight: CGFloat = 162
        static let apertureWidth: CGFloat = 78
        static let apertureHeight: CGFloat = 150
        static let apertureSpacing: CGFloat = 5
        static let apertureCornerRadius: CGFloat = 9
        static let housingCornerRadius: CGFloat = 20
        static let glassCornerRadius: CGFloat = 15
    }

    private var safeResultSymbols: [String] {
        (0..<3).map { index in
            resultSymbols.indices.contains(index) ? resultSymbols[index] : "7"
        }
    }

    private var safeDisplaySymbols: [String] {
        let fallback = ["⭐", "🏸", "💰"]
        return (0..<3).map { index in
            displaySymbols.indices.contains(index) ? displaySymbols[index] : fallback[index]
        }
    }

    var body: some View {
        ZStack {
            housingBackground

            HStack(spacing: Metrics.apertureSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    reelAperture(index: index)
                }
            }

            separatorAssembly
            centerPayLine
            stopFlashOverlay
            slipEnergyOverlay
            sparkOverlay
            sharedGlass
            housingBorder
        }
        .frame(width: Metrics.housingWidth, height: Metrics.housingHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Metrics.housingCornerRadius,
                style: .continuous
            )
        )
        .onChange(of: stoppedReelCount) { oldValue, newValue in
            guard newValue > oldValue, newValue > 0 else { return }
            playStopFlash(for: min(newValue - 1, 2))
        }
        .onChange(of: reelSlipTrigger) { _, trigger in
            guard trigger > 0, reelSlipIndex >= 0 else { return }
            playSlipEnergy()
        }
    }

    private func reelAperture(index: Int) -> some View {
        ZStack {
            CylinderSurface()

            PremiumReelColumn(
                finalSymbol: safeResultSymbols[index],
                initialDisplaySymbol: safeDisplaySymbols[index],
                symbolPool: reelPool,
                isSpinning: isSpinning && stoppedReelCount <= index,
                isStopped: stoppedReelCount > index,
                reelIndex: index
            )

            CylinderApertureOptics(
                isSpinning: isSpinning && stoppedReelCount <= index,
                glowColor: reelGlowColor(index: index)
            )
        }
        .frame(width: Metrics.apertureWidth, height: Metrics.apertureHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Metrics.apertureCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: Metrics.apertureCornerRadius,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        Color.black.opacity(0.72),
                        Color.white.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.1
            )
        }
    }

    @ViewBuilder
    private var housingBackground: some View {
        if showsHousingDecoration {
            RoundedRectangle(
                cornerRadius: Metrics.housingCornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.38, green: 0.39, blue: 0.43),
                        Color(red: 0.075, green: 0.08, blue: 0.10),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            Color.black.opacity(0.90)
        }
    }

    private var separatorAssembly: some View {
        HStack(spacing: 0) {
            Spacer()
            separator(index: 0)
            Spacer().frame(width: Metrics.apertureWidth)
            separator(index: 1)
            Spacer()
        }
        .frame(width: 174, height: Metrics.apertureHeight)
        .allowsHitTesting(false)
    }

    private func separator(index: Int) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.90),
                        Color.white.opacity(0.16),
                        machineGlow.opacity(
                            isSpinning && stoppedReelCount <= index ? 0.20 : 0.04
                        ),
                        Color.black.opacity(0.92)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 4, height: Metrics.apertureHeight - 6)
            .shadow(color: .black.opacity(0.82), radius: 2)
    }

    private var centerPayLine: some View {
        HStack(spacing: Metrics.apertureSpacing) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.80), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: Metrics.apertureWidth - 7, height: 1)
            }
        }
        .opacity(0.18 + stopLineFlashOpacity * 0.82)
        .shadow(
            color: machineGlow.opacity(stopLineFlashOpacity),
            radius: 5
        )
        .allowsHitTesting(false)
    }

    private var stopFlashOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                if let stoppedFlashIndex {
                    let reelStride = Metrics.apertureWidth + Metrics.apertureSpacing
                    RoundedRectangle(
                        cornerRadius: Metrics.apertureCornerRadius,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, reelGlowColor(index: stoppedFlashIndex), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: Metrics.apertureWidth,
                        height: Metrics.apertureHeight
                    )
                    .position(
                        x: proxy.size.width / 2
                            + CGFloat(stoppedFlashIndex - 1) * reelStride,
                        y: proxy.size.height / 2
                    )
                    .opacity(stoppedFlashOpacity)
                    .blendMode(.screen)
                }

                Color.white
                    .opacity(wholeWindowFlashOpacity)
                    .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }

    private var slipEnergyOverlay: some View {
        GeometryReader { proxy in
            let safeIndex = min(max(reelSlipIndex, 0), 2)
            let stride = Metrics.apertureWidth + Metrics.apertureSpacing
            let centerX = proxy.size.width / 2 + CGFloat(safeIndex - 1) * stride

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.86), machineGlow.opacity(0.52), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: Metrics.apertureWidth * 0.72, height: 56)
                    .position(x: centerX, y: proxy.size.height / 2 + slipEnergyOffset)
                    .blur(radius: 2)

                ForEach(0..<4, id: \.self) { line in
                    Capsule()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: Metrics.apertureWidth * 0.62, height: 1.2)
                        .position(
                            x: centerX,
                            y: proxy.size.height / 2
                                + slipEnergyOffset
                                + CGFloat(line * 9 - 14)
                        )
                }
            }
            .opacity(slipEnergyOpacity)
        }
        .allowsHitTesting(false)
    }

    private var sparkOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    let angle = Double(index) * 45
                    let radians = angle * .pi / 180
                    let distance = CGFloat(20 + index % 6 * 7) * sparkBurstProgress

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white, reelGlowColor(index: index), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(7 + index % 3 * 2), height: 1.1)
                        .rotationEffect(.degrees(angle))
                        .position(
                            x: proxy.size.width / 2 + cos(radians) * distance,
                            y: proxy.size.height / 2 + sin(radians) * distance
                        )
                }
            }
            .opacity(
                sparkBurstOpacity * 0.26
                    * max(0, 1 - Double(sparkBurstProgress) * 0.72)
            )
        }
        .allowsHitTesting(false)
    }

    private var sharedGlass: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.30), location: 0),
                        .init(color: .clear, location: 0.22),
                        .init(color: .clear, location: 0.76),
                        .init(color: Color.black.opacity(0.34), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [.clear, .white.opacity(0.05), .white.opacity(0.28), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width * 0.32, height: proxy.size.height * 1.7)
                .rotationEffect(.degrees(18))
                .offset(
                    x: proxy.size.width * glassSweepOffset,
                    y: -proxy.size.height * 0.34
                )
                .blendMode(.screen)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.025), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width * 0.90, height: 58)
                    .offset(y: -44)
                    .blur(radius: 7)
                    .blendMode(.screen)
            }
        }
        .padding(6)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Metrics.glassCornerRadius,
                style: .continuous
            )
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var housingBorder: some View {
        if showsHousingDecoration {
            RoundedRectangle(
                cornerRadius: Metrics.housingCornerRadius,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.58), .gray.opacity(0.24), .black],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 3
            )
            .allowsHitTesting(false)
        }
    }

    private func reelGlowColor(index: Int) -> Color {
        guard heatLevel == .premium else { return heatLevel.lampColor }
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
        return colors[(max(index, 0) + reelSlipTrigger) % colors.count]
    }

    private func playStopFlash(for index: Int) {
        stoppedFlashIndex = index
        stoppedFlashOpacity = 0

        withAnimation(.easeOut(duration: 0.04)) {
            stoppedFlashOpacity = index == 2 ? 0.88 : 0.62
        }
        withAnimation(.easeOut(duration: 0.17).delay(0.045)) {
            stoppedFlashOpacity = 0
        }

        if index == 2 {
            withAnimation(.easeOut(duration: 0.045).delay(0.05)) {
                wholeWindowFlashOpacity = heatLevel == .premium ? 0.58 : 0.28
            }
            withAnimation(.easeOut(duration: 0.22).delay(0.10)) {
                wholeWindowFlashOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if stoppedFlashIndex == index {
                stoppedFlashIndex = nil
            }
        }
    }

    private func playSlipEnergy() {
        slipEnergyOffset = -52
        slipEnergyOpacity = 0

        withAnimation(.easeOut(duration: 0.045)) {
            slipEnergyOpacity = min(1, 0.52 + Double(reelSlipIntensity) * 0.36)
        }
        withAnimation(
            .easeIn(duration: 0.16 + Double(reelSlipIntensity) * 0.08)
            .delay(0.035)
        ) {
            slipEnergyOffset = 54 + reelSlipIntensity * 20
            slipEnergyOpacity = 0
        }
    }
}

private struct CylinderSurface: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.48, green: 0.49, blue: 0.48), location: 0),
                        .init(color: Color(red: 0.90, green: 0.90, blue: 0.86), location: 0.13),
                        .init(color: Color(red: 1.00, green: 0.995, blue: 0.96), location: 0.50),
                        .init(color: Color(red: 0.89, green: 0.89, blue: 0.85), location: 0.87),
                        .init(color: Color(red: 0.44, green: 0.45, blue: 0.44), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.34),
                        .clear,
                        .clear,
                        Color.black.opacity(0.37)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

private struct CylinderApertureOptics: View {
    let isSpinning: Bool
    let glowColor: Color

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.74), .black.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 12)

                Spacer(minLength: 0)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.12), .black.opacity(0.74)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 12)
            }

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.58), .black.opacity(0.16), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 19)

                Spacer(minLength: 0)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.17), .black.opacity(0.60)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 19)
            }

            LinearGradient(
                colors: [.clear, .white.opacity(isSpinning ? 0.11 : 0.07), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 19)
            .blur(radius: 4)
            .blendMode(.screen)

            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(glowColor.opacity(isSpinning ? 0.10 : 0.025), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }
}
