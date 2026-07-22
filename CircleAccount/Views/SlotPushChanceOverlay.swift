//
//  SlotPushChanceOverlay.swift
//  CircleAccount
//

import SwiftUI

struct SlotPushChanceOverlay: View {
    let isVisible: Bool
    let isEnabled: Bool
    let appearanceTrigger: Int
    let pressTrigger: Int
    let isPremium: Bool
    let onPush: () -> Void

    @State private var overlayOpacity = 0.0
    @State private var titleScale: CGFloat = 0.62
    @State private var buttonScale: CGFloat = 0.74
    @State private var auraScale: CGFloat = 0.72
    @State private var auraOpacity = 0.0
    @State private var ringRotation = 0.0
    @State private var pulse = false
    @State private var sweepOffset: CGFloat = -1.5
    @State private var pressFlashOpacity = 0.0
    @State private var pressedScale: CGFloat = 1.0
    @State private var sequenceToken = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(0.46 * overlayOpacity)
                    .contentShape(Rectangle())

                RadialGradient(
                    colors: [
                        glowColor.opacity(0.34 * auraOpacity),
                        glowColor.opacity(0.10 * auraOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.68
                )
                .blendMode(.screen)

                VStack(spacing: 18) {
                    Text(isPremium ? "PREMIUM CHANCE" : "CHANCE")
                        .font(
                            .system(
                                size: 12,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .tracking(3.4)
                        .foregroundStyle(Color.white.opacity(0.92))

                    Text("PUSH!!")
                        .font(
                            .system(
                                size: 49,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(3)
                        .foregroundStyle(titleStyle)
                        .shadow(color: glowColor, radius: 18)
                        .shadow(color: .white.opacity(0.82), radius: 5)
                        .scaleEffect(titleScale)

                    Button(action: push) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.45),
                                            glowColor.opacity(0.22),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 4,
                                        endRadius: 96
                                    )
                                )
                                .frame(width: 205, height: 205)
                                .scaleEffect(auraScale)
                                .opacity(auraOpacity)
                                .blur(radius: 2)

                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: ringColors,
                                        center: .center
                                    ),
                                    lineWidth: 9
                                )
                                .frame(width: 155, height: 155)
                                .rotationEffect(.degrees(ringRotation))
                                .shadow(color: glowColor, radius: 15)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            glowColor,
                                            isPremium ? Color.orange : Color.red,
                                            Color.black
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 126, height: 126)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(0.92), lineWidth: 4)
                                }
                                .shadow(color: glowColor, radius: 20)
                                .scaleEffect(pulse ? 1.05 : 0.96)

                            Text("PUSH")
                                .font(
                                    .system(
                                        size: 25,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .tracking(1.4)
                                .foregroundStyle(.white)
                                .shadow(color: .black, radius: 3, y: 2)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.92),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 90, height: 15)
                                .blur(radius: 2)
                                .offset(x: sweepOffset * 95)
                                .mask {
                                    Circle()
                                        .frame(width: 126, height: 126)
                                }
                        }
                        .scaleEffect(buttonScale * pressedScale)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)

                    Text(isEnabled ? "ボタンを押せ！" : "FINAL JUDGEMENT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .opacity(overlayOpacity)

                Color.white
                    .opacity(pressFlashOpacity)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(isVisible && isEnabled)
        .opacity(isVisible ? 1 : 0)
        .onChange(of: appearanceTrigger) { _, value in
            guard value > 0, isVisible else { return }
            playAppearance()
        }
        .onChange(of: pressTrigger) { _, value in
            guard value > 0 else { return }
            playPress()
        }
        .onChange(of: isVisible) { _, visible in
            if !visible {
                reset()
            }
        }
    }

    private var glowColor: Color {
        isPremium ? .yellow : .red
    }

    private var titleStyle: AnyShapeStyle {
        if isPremium {
            return AnyShapeStyle(
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
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white,
                    .orange,
                    .red
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var ringColors: [Color] {
        if isPremium {
            return [
                .white,
                .yellow,
                .orange,
                .red,
                .yellow,
                .white
            ]
        }

        return [
            .white,
            .red,
            .orange,
            .red,
            .white
        ]
    }

    private func push() {
        guard isEnabled else { return }
        onPush()
    }

    private func playAppearance() {
        sequenceToken += 1
        let token = sequenceToken

        overlayOpacity = 0
        titleScale = 0.62
        buttonScale = 0.74
        auraScale = 0.72
        auraOpacity = 0
        ringRotation = 0
        sweepOffset = -1.5
        pressedScale = 1

        withAnimation(.easeOut(duration: 0.12)) {
            overlayOpacity = 1
            auraOpacity = 1
        }

        withAnimation(
            .spring(
                response: 0.42,
                dampingFraction: 0.48
            )
        ) {
            titleScale = 1
            buttonScale = 1
            auraScale = 1.12
        }

        withAnimation(
            .linear(duration: 1.45)
                .repeatForever(autoreverses: false)
        ) {
            ringRotation = 360
        }

        withAnimation(
            .easeInOut(duration: 0.34)
                .repeatForever(autoreverses: true)
        ) {
            pulse = true
            auraScale = 1.24
            auraOpacity = 0.64
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard token == sequenceToken else { return }

            withAnimation(
                .linear(duration: 0.72)
                    .repeatForever(autoreverses: false)
            ) {
                sweepOffset = 1.5
            }
        }
    }

    private func playPress() {
        pressFlashOpacity = 1
        pressedScale = 0.78

        withAnimation(.easeOut(duration: 0.10)) {
            pressedScale = 1.18
        }

        withAnimation(.easeOut(duration: 0.28)) {
            pressFlashOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.46
                )
            ) {
                pressedScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.22)) {
                overlayOpacity = 0
                auraOpacity = 0
            }
        }
    }

    private func reset() {
        sequenceToken += 1
        overlayOpacity = 0
        titleScale = 0.62
        buttonScale = 0.74
        auraScale = 0.72
        auraOpacity = 0
        ringRotation = 0
        pulse = false
        sweepOffset = -1.5
        pressFlashOpacity = 0
        pressedScale = 1
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SlotPushChanceOverlay(
            isVisible: true,
            isEnabled: true,
            appearanceTrigger: 1,
            pressTrigger: 0,
            isPremium: true,
            onPush: {}
        )
        .frame(height: 520)
        .padding()
    }
}
