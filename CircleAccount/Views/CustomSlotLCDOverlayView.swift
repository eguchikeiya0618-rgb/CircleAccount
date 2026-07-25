//
//  CustomSlotLCDOverlayView.swift
//  CircleAccount
//
//  古いSlotLCDOverlayViewを一切使わない独立版。
//  .superHotではユーザー作成の画像演出だけを表示する。
//

import SwiftUI
import UIKit

struct CustomSlotLCDOverlayView: View {
    let trigger: Int
    let presentation: SlotLCDPresentation?

    @State private var visiblePresentation: SlotLCDPresentation?
    @State private var overlayOpacity = 0.0
    @State private var animationToken = 0

    @State private var titleScale: CGFloat = 0.62
    @State private var titleRotation = -4.0
    @State private var scanOffset: CGFloat = -1.3
    @State private var ringScale: CGFloat = 0.40
    @State private var ringOpacity = 0.0
    @State private var glitchOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            if let current = visiblePresentation {
                Group {
                    if current == .superHot {
                        EguchiCustomGekiAtsuView()
                            .id(animationToken)
                    } else {
                        normalLCD(
                            presentation: current,
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

    private func normalLCD(
        presentation: SlotLCDPresentation,
        size: CGSize
    ) -> some View {
        ZStack {
            normalBackground(for: presentation)

            VStack(spacing: 5) {
                Image(systemName: presentation.symbol)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(titleStyle(for: presentation))
                    .shadow(color: presentation.accentColor, radius: 12)

                Text(presentation.title)
                    .font(
                        .system(
                            size: titleSize(for: presentation),
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .tracking(2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(titleStyle(for: presentation))
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                    .shadow(
                        color: presentation.accentColor.opacity(0.95),
                        radius: 16
                    )

                Text(presentation.subtitle)
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(2)
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
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .stroke(
                        titleStyle(for: presentation),
                        lineWidth: 2
                    )
                }
            )
            .scaleEffect(titleScale)
            .rotationEffect(.degrees(titleRotation))
            .offset(x: glitchOffset)

            Circle()
                .stroke(
                    titleStyle(for: presentation),
                    lineWidth: presentation.isRainbow ? 12 : 7
                )
                .frame(width: 178, height: 178)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blendMode(.screen)

            LinearGradient(
                colors: [
                    .clear,
                    Color.white.opacity(0.68),
                    presentation.accentColor.opacity(0.55),
                    .clear
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
    private func normalBackground(
        for presentation: SlotLCDPresentation
    ) -> some View {
        if presentation.isRainbow {
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
                .opacity(0.24)
                .blendMode(.screen)
        } else {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.32),
                    presentation.accentColor.opacity(0.30),
                    presentation.accentColor.opacity(0.09),
                    Color.black.opacity(0.18),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
        }
    }

    private func titleStyle(
        for presentation: SlotLCDPresentation
    ) -> AnyShapeStyle {
        if presentation.isRainbow {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .red, .orange, .yellow, .green,
                        .cyan, .blue, .purple, .pink
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

                withAnimation(.easeOut(duration: 0.22)) {
                    overlayOpacity = 0
                }

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.22
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

        DispatchQueue.main.asyncAfter(
            deadline: .now() + max(presentation.displayDuration - 0.42, 0.35)
        ) {
            guard token == animationToken else { return }

            withAnimation(.easeOut(duration: 0.42)) {
                overlayOpacity = 0
                titleScale = 1.12
                ringOpacity = 0
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

        CustomSlotLCDOverlayView(
            trigger: 1,
            presentation: .superHot
        )
        .frame(width: 370, height: 520)
    }
}
