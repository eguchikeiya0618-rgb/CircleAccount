//
//  SlotBlackoutOverlay.swift
//  CircleAccount
//

import SwiftUI

struct SlotBlackoutOverlay: View {
    let trigger: Int

    @State private var blackoutOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var titleScale: CGFloat = 0.58
    @State private var warningFlashOpacity = 0.0
    @State private var lineWidth: CGFloat = 0
    @State private var sequenceToken = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(blackoutOpacity)

                RadialGradient(
                    colors: [
                        Color.red.opacity(0.42 * warningFlashOpacity),
                        Color.orange.opacity(0.16 * warningFlashOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )
                .blendMode(.screen)

                VStack(spacing: 13) {
                    warningLine

                    Text("激アツ")
                        .font(
                            .system(
                                size: 52,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    .yellow,
                                    .orange,
                                    .red
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red, radius: 18)
                        .shadow(color: .yellow, radius: 7)
                        .scaleEffect(titleScale)
                        .opacity(titleOpacity)

                    Text("PREMIUM CHANCE")
                        .font(
                            .system(
                                size: 11,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .tracking(3.2)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .opacity(titleOpacity)

                    warningLine
                }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            playSequence()
        }
    }

    private var warningLine: some View {
        ZStack {
            Capsule()
                .fill(Color.red.opacity(0.36))
                .frame(width: 245, height: 4)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white,
                            Color.yellow,
                            Color.white,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: lineWidth, height: 3)
                .shadow(color: .yellow, radius: 8)
        }
        .opacity(titleOpacity)
    }

    private func playSequence() {
        sequenceToken += 1
        let token = sequenceToken

        blackoutOpacity = 0
        titleOpacity = 0
        titleScale = 0.58
        warningFlashOpacity = 0
        lineWidth = 0

        withAnimation(.easeOut(duration: 0.08)) {
            blackoutOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            guard token == sequenceToken else { return }

            warningFlashOpacity = 1
            titleOpacity = 1
            lineWidth = 245

            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.48
                )
            ) {
                titleScale = 1
            }

            withAnimation(.easeOut(duration: 0.24)) {
                warningFlashOpacity = 0.32
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            guard token == sequenceToken else { return }

            withAnimation(.easeInOut(duration: 0.07)) {
                titleOpacity = 0.18
                blackoutOpacity = 0.84
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.67) {
            guard token == sequenceToken else { return }

            withAnimation(.easeInOut(duration: 0.07)) {
                titleOpacity = 1
                blackoutOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.08) {
            guard token == sequenceToken else { return }

            withAnimation(.easeOut(duration: 0.32)) {
                titleOpacity = 0
                blackoutOpacity = 0
                warningFlashOpacity = 0
                lineWidth = 0
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.08, green: 0.02, blue: 0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        SlotBlackoutOverlay(trigger: 1)
            .frame(height: 520)
            .padding()
    }
}
