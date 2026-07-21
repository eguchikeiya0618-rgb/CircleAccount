//
//  MachineEffects.swift
//  CircleAccount
//

import SwiftUI

struct MachineOuterGlow: View {
    let glowColor: Color
    let isPulsing: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 38, style: .continuous)
            .fill(
                glowColor.opacity(
                    isPulsing ? 0.17 : 0.08
                )
            )
            .blur(radius: 20)
            .scaleEffect(isPulsing ? 1.035 : 1.0)
    }
}

struct MachineAnimatedBorder: View {
    let heatLevel: SlotHeatLevel
    let glowColor: Color
    let rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(
                AngularGradient(
                    colors: [
                        glowColor.opacity(0.25),
                        Color.white.opacity(0.80),
                        heatLevel.lampColor,
                        glowColor,
                        Color.white.opacity(0.35),
                        glowColor.opacity(0.25)
                    ],
                    center: .center,
                    angle: .degrees(rotation)
                ),
                lineWidth: heatLevel == .premium ? 4 : 2.5
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 29,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.09),
                    lineWidth: 1
                )
                .padding(7)
            }
    }
}

struct MovingMetalHighlight: View {
    let sweepOffset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.10),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(
                width: proxy.size.width * 0.28,
                height: proxy.size.height * 1.55
            )
            .rotationEffect(.degrees(14))
            .offset(
                x: proxy.size.width * sweepOffset,
                y: -proxy.size.height * 0.20
            )
            .blendMode(.screen)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
    }
}

struct RisingCabinetLight: View {
    let glowColor: Color
    let lightOffset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.clear,
                    glowColor.opacity(0.08),
                    Color.white.opacity(0.44),
                    glowColor.opacity(0.16),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(
                width: proxy.size.width,
                height: proxy.size.height * 0.36
            )
            .offset(
                y: proxy.size.height * lightOffset
            )
            .blur(radius: 10)
            .blendMode(.screen)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
    }
}

struct MachineFlashOverlay: View {
    let opacity: Double
    let glowColor: Color

    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.98),
                        glowColor.opacity(0.66),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 460
                )
            )
            .opacity(opacity)
            .blendMode(.screen)
            .ignoresSafeArea()
    }
}

struct JackpotWhiteoutOverlay: View {
    let opacity: Double

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .opacity(opacity)
            .blendMode(.screen)
            .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ZStack {
            MachineOuterGlow(
                glowColor: .purple,
                isPulsing: true
            )

            RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
            .fill(Color.black)

            MachineAnimatedBorder(
                heatLevel: .premium,
                glowColor: .purple,
                rotation: 120
            )

            MovingMetalHighlight(
                sweepOffset: 0.35
            )

            RisingCabinetLight(
                glowColor: .purple,
                lightOffset: 0.25
            )
        }
        .frame(width: 340, height: 500)
        .padding()
    }
}
