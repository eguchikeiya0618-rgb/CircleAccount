//
//  SlotLCDOverlayView.swift
//  CircleAccount
//

import SwiftUI
import UIKit

enum SlotLCDPresentation: Equatable {
    case start
    case chance
    case reach
    case superHot
    case push
    case redSeven
    case rainbowJackpot
    case blackoutReturn

    var title: String {
        switch self {
        case .start:
            return "SPIN START"
        case .chance:
            return "CHANCE"
        case .reach:
            return "REACH"
        case .superHot:
            return "激 熱"
        case .push:
            return "PUSH"
        case .redSeven:
            return "777"
        case .rainbowJackpot:
            return "RAINBOW"
        case .blackoutReturn:
            return "覚 醒"
        }
    }

    var subtitle: String {
        switch self {
        case .start:
            return "PREMIUM REEL"
        case .chance:
            return "期待度上昇"
        case .reach:
            return "LAST REEL"
        case .superHot:
            return "PREMIUM CHANCE"
        case .push:
            return "DECIDE YOUR FATE"
        case .redSeven:
            return "RED SEVEN JACKPOT"
        case .rainbowJackpot:
            return "PREMIUM JACKPOT"
        case .blackoutReturn:
            return "SYSTEM REBOOT"
        }
    }

    var symbol: String {
        switch self {
        case .start:
            return "bolt.fill"
        case .chance:
            return "sparkles"
        case .reach:
            return "scope"
        case .superHot:
            return "flame.fill"
        case .push:
            return "hand.tap.fill"
        case .redSeven:
            return "7.circle.fill"
        case .rainbowJackpot:
            return "crown.fill"
        case .blackoutReturn:
            return "power"
        }
    }

    var displayDuration: Double {
        switch self {
        case .start:
            return 0.80
        case .chance:
            return 0.95
        case .reach:
            return 1.15
        case .superHot:
            return 2.22
        case .push:
            return 1.50
        case .redSeven:
            return 2.15
        case .rainbowJackpot:
            return 2.60
        case .blackoutReturn:
            return 1.40
        }
    }

    var isRainbow: Bool {
        self == .rainbowJackpot
    }

    var accentColor: Color {
        switch self {
        case .start:
            return .cyan
        case .chance:
            return .yellow
        case .reach:
            return Color(red: 0.42, green: 0.78, blue: 1.0)
        case .superHot:
            return .red
        case .push:
            return .orange
        case .redSeven:
            return Color(red: 1.0, green: 0.12, blue: 0.08)
        case .rainbowJackpot:
            return .white
        case .blackoutReturn:
            return .purple
        }
    }
}

struct SlotLCDOverlayView: View {
    let trigger: Int
    let presentation: SlotLCDPresentation?

    @State private var visiblePresentation: SlotLCDPresentation?
    @State private var overlayOpacity = 0.0
    @State private var titleScale: CGFloat = 0.62
    @State private var titleRotation = -4.0
    @State private var scanOffset: CGFloat = -1.3
    @State private var ringScale: CGFloat = 0.40
    @State private var ringOpacity = 0.0
    @State private var glitchOffset: CGFloat = 0
    @State private var animationToken = 0

    var body: some View {
        GeometryReader { proxy in
            if let current = visiblePresentation {
                Group {
                    if current == .superHot {
                        EguchiCustomGekiAtsuView()
                            .id(animationToken)
                    } else {
                        normalLCDView(
                            current: current,
                            size: proxy.size
                        )
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .opacity(overlayOpacity)
                .compositingGroup()
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0, let presentation else { return }
            play(presentation)
        }
    }

    private func normalLCDView(
        current: SlotLCDPresentation,
        size: CGSize
    ) -> some View {
        ZStack {
            background(for: current)

            scanLines

            Circle()
                .stroke(
                    titleStyle(for: current),
                    lineWidth: current.isRainbow ? 12 : 7
                )
                .frame(width: 178, height: 178)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blur(radius: 0.6)
                .blendMode(.screen)

            VStack(spacing: 5) {
                Image(systemName: current.symbol)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(titleStyle(for: current))
                    .shadow(color: current.accentColor, radius: 12)

                Text(current.title)
                    .font(
                        .system(
                            size: titleSize(for: current),
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .tracking(2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(titleStyle(for: current))
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                    .shadow(
                        color: current.accentColor.opacity(0.95),
                        radius: 16
                    )

                Text(current.subtitle)
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(2.0)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.black.opacity(0.50))
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .stroke(
                        titleStyle(for: current),
                        lineWidth: 2
                    )
                )
            )
            .scaleEffect(titleScale)
            .rotationEffect(.degrees(titleRotation))
            .offset(x: glitchOffset)
            .shadow(
                color: current.accentColor.opacity(0.72),
                radius: 24
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.68),
                    current.accentColor.opacity(0.55),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 54)
            .offset(y: scanOffset * size.height)
            .blur(radius: 4)
            .blendMode(.screen)
        }
    }

    @ViewBuilder
    private func background(
        for presentation: SlotLCDPresentation
    ) -> some View {
        if presentation.isRainbow {
            Rectangle()
                .fill(
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
                    )
                )
                .opacity(0.24)
                .blendMode(.screen)
        } else {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.32),
                    presentation.accentColor.opacity(0.30),
                    presentation.accentColor.opacity(0.09),
                    Color.black.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
        }
    }

    private var scanLines: some View {
        VStack(spacing: 5) {
            ForEach(0..<35, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.055))
                    .frame(height: 1)
            }
        }
        .blendMode(.screen)
    }

    private func titleStyle(
        for presentation: SlotLCDPresentation
    ) -> AnyShapeStyle {
        if presentation.isRainbow {
            return AnyShapeStyle(
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
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white,
                    presentation.accentColor,
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func titleSize(
        for presentation: SlotLCDPresentation
    ) -> CGFloat {
        switch presentation {
        case .rainbowJackpot:
            return 29
        case .redSeven:
            return 45
        default:
            return 34
        }
    }

    private func play(
        _ presentation: SlotLCDPresentation
    ) {
        animationToken += 1
        let token = animationToken

        visiblePresentation = presentation
        overlayOpacity = 1

        if presentation == .superHot {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + presentation.displayDuration
            ) {
                guard token == animationToken else { return }

                withAnimation(.easeOut(duration: 0.18)) {
                    overlayOpacity = 0
                }

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.18
                ) {
                    guard token == animationToken else { return }
                    visiblePresentation = nil
                }
            }

            return
        }

        titleScale = 0.62
        titleRotation = -4
        scanOffset = -1.3
        ringScale = 0.40
        ringOpacity = 1
        glitchOffset = -8

        withAnimation(
            .spring(
                response: 0.34,
                dampingFraction: 0.52
            )
        ) {
            titleScale = 1
            titleRotation = 0
            ringScale = 1.34
            glitchOffset = 0
        }

        withAnimation(
            .easeOut(duration: presentation.displayDuration * 0.72)
        ) {
            scanOffset = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard token == animationToken else { return }

            withAnimation(.easeInOut(duration: 0.045)) {
                glitchOffset = 6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            guard token == animationToken else { return }

            withAnimation(.easeInOut(duration: 0.055)) {
                glitchOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            guard token == animationToken else { return }

            withAnimation(.easeOut(duration: 0.55)) {
                ringOpacity = 0
            }
        }

        let fadeStart = max(
            presentation.displayDuration - 0.42,
            0.35
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeStart) {
            guard token == animationToken else { return }

            withAnimation(.easeOut(duration: 0.42)) {
                overlayOpacity = 0
                titleScale = 1.12
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + presentation.displayDuration
        ) {
            guard token == animationToken else { return }
            visiblePresentation = nil
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        SlotLCDOverlayView(
            trigger: 1,
            presentation: .superHot
        )
        .frame(width: 370, height: 520)
    }
}

