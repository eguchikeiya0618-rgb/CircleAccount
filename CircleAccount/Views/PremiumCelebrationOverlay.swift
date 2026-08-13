//
//  PremiumCelebrationOverlay.swift
//  CircleAccount
//

import SwiftUI

struct PremiumCelebrationOverlay: View {
    let flashOpacity: Double

    @State private var auraPulse = false
    @State private var rainbowRotation = 0.0
    @State private var shuttleTravel = false

    private let shuttleCount = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .red, .orange, .yellow, .green,
                                .cyan, .blue, .purple, .pink, .red
                            ],
                            center: .center,
                            angle: .degrees(rainbowRotation)
                        ),
                        lineWidth: auraPulse ? 7 : 4
                    )
                    .blur(radius: auraPulse ? 3 : 1)
                    .opacity(auraPulse ? 0.95 : 0.55)
                    .scaleEffect(auraPulse ? 1.025 : 1.0)

                ForEach(0..<shuttleCount, id: \.self) { index in
                    flyingShuttle(index: index, size: proxy.size)
                }

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(flashOpacity))
                    .blendMode(.screen)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: 370)
        .onAppear {
            startContinuousAnimations()
        }
    }

    private func flyingShuttle(
        index: Int,
        size: CGSize
    ) -> some View {
        let direction = index % 4
        let start = startPoint(direction: direction, size: size)
        let end = endPoint(direction: direction, size: size)

        let progress: CGFloat = shuttleTravel ? 1 : 0
        let x = start.x + (end.x - start.x) * progress
        let y = start.y + (end.y - start.y) * progress

        let width = CGFloat(66 + (index % 3) * 16)
        let duration = 2.8 + Double(index % 4) * 0.38
        let delay = Double(index) * 0.34

        return Image(shuttleImageName(for: direction))
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width)
            .shadow(color: rainbowColor(index).opacity(0.90), radius: 13)
            .shadow(color: Color.white.opacity(0.72), radius: 4)
            .position(x: x, y: y)
            .opacity(auraPulse ? 0.96 : 0.66)
            .animation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: shuttleTravel
            )
    }

    private func startPoint(
        direction: Int,
        size: CGSize
    ) -> CGPoint {
        switch direction {
        case 0:
            return CGPoint(x: -85, y: size.height + 85)
        case 1:
            return CGPoint(x: size.width + 85, y: size.height + 85)
        case 2:
            return CGPoint(x: -85, y: -85)
        default:
            return CGPoint(x: size.width + 85, y: -85)
        }
    }

    private func endPoint(
        direction: Int,
        size: CGSize
    ) -> CGPoint {
        switch direction {
        case 0:
            return CGPoint(x: size.width + 85, y: -85)
        case 1:
            return CGPoint(x: -85, y: -85)
        case 2:
            return CGPoint(x: size.width + 85, y: size.height + 85)
        default:
            return CGPoint(x: -85, y: size.height + 85)
        }
    }

    private func shuttleImageName(for direction: Int) -> String {
        let images = [
            "RainbowShuttleNE",
            "RainbowShuttleNW",
            "RainbowShuttleSE",
            "RainbowShuttleSW"
        ]

        return images[direction % images.count]
    }

    private func rainbowColor(_ index: Int) -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green,
            .cyan, .blue, .purple, .pink
        ]

        return colors[index % colors.count]
    }

    private func startContinuousAnimations() {
        shuttleTravel = false
        auraPulse = false

        DispatchQueue.main.async {
            shuttleTravel = true
        }

        withAnimation(
            .easeInOut(duration: 0.58)
                .repeatForever(autoreverses: true)
        ) {
            auraPulse = true
        }

        withAnimation(
            .linear(duration: 3.2)
                .repeatForever(autoreverses: false)
        ) {
            rainbowRotation = 360
        }

    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PremiumCelebrationOverlay(
            flashOpacity: 0.18
        )
        .frame(height: 520)
        .padding()
    }
}
