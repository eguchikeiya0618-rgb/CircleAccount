//
//  PayoutRewardCardView.swift
//  CircleAccount
//

import SwiftUI

struct PayoutRewardCardView: View {
    let presentation: PayoutRewardPresentation
    let cardOffsetY: CGFloat
    let cardScale: CGFloat
    let cardOpacity: Double
    let glowScale: CGFloat
    let glowOpacity: Double
    let shineOffset: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            iconSection
            titleSection
            subtitleSection
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: 320)
        .background(cardBackground)
        .overlay(cardBorder)
        .overlay(shineLayer)
        .shadow(
            color: presentation.primaryColor.opacity(0.45),
            radius: 24,
            y: 12
        )
        .scaleEffect(cardScale)
        .offset(y: cardOffsetY)
        .opacity(cardOpacity)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            presentation.primaryColor.opacity(0.72),
                            presentation.secondaryColor.opacity(0.30),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 76
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 6)

            Text(presentation.icon)
                .font(
                    .system(
                        size: iconFontSize,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(width: 104, height: 104)
                .background(iconBackground)
                .overlay(iconBorder)
                .shadow(
                    color: presentation.primaryColor.opacity(0.75),
                    radius: 18
                )
        }
    }

    private var titleSection: some View {
        Text(presentation.title)
            .font(
                .system(
                    size: 20,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(0.7)
            .multilineTextAlignment(.center)
            .foregroundStyle(titleGradient)
            .shadow(
                color: Color.black.opacity(0.75),
                radius: 4,
                y: 2
            )
    }

    private var subtitleSection: some View {
        Text(presentation.subtitle)
            .font(
                .system(
                    size: 13,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(Color.white.opacity(0.88))
    }

    private var iconFontSize: CGFloat {
        presentation.icon.hasPrefix("¥")
        || presentation.icon == "50%"
            ? 34
            : 58
    }

    private var iconBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: presentation.accentColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var iconBorder: some View {
        Circle()
            .stroke(
                Color.white.opacity(0.86),
                lineWidth: 3
            )
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.white] + presentation.accentColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 26,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.94),
                    presentation.finalColor.opacity(0.34),
                    Color.black.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(
            cornerRadius: 26,
            style: .continuous
        )
        .stroke(
            LinearGradient(
                colors: [.white] + presentation.accentColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 2.5
        )
    }

    private var shineLayer: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.75),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 46)
                .rotationEffect(.degrees(18))
                .offset(
                    x: proxy.size.width * shineOffset
                )
                .mask(
                    RoundedRectangle(
                        cornerRadius: 26,
                        style: .continuous
                    )
                )
        }
        .allowsHitTesting(false)
    }
}
