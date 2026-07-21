import SwiftUI

struct PushButtonView: View {
    let isVisible: Bool
    let isEnabled: Bool
    let heatLevel: SlotHeatLevel
    let machineGlow: Color
    let onPush: () -> Void
    let onImpact: (_ horizontalOffset: CGFloat) -> Void

    @State private var heartbeat = false
    @State private var ringProgress: CGFloat = 0
    @State private var pressed = false
    @State private var flashOpacity = 0.0
    @State private var rainbowRotation = 0.0
    @State private var shockwaveScale: CGFloat = 0.62
    @State private var shockwaveOpacity = 0.0
    @State private var shockwaveRotation = 0.0

    var body: some View {
        Button(action: handlePush) {
            ZStack {
                shockwaveEffect

                if isVisible {
                    Circle()
                        .stroke(
                            heatLevel == .premium
                                ? AnyShapeStyle(
                                    AngularGradient(
                                        colors: [
                                            .red, .orange, .yellow, .green,
                                            .cyan, .blue, .purple, .red
                                        ],
                                        center: .center,
                                        angle: .degrees(rainbowRotation)
                                    )
                                )
                                : AnyShapeStyle(machineGlow.opacity(0.85)),
                            lineWidth: 3
                        )
                        .frame(width: 76, height: 76)
                        .scaleEffect(0.72 + ringProgress * 0.52)
                        .opacity(1.0 - Double(ringProgress))
                        .shadow(color: machineGlow, radius: 12)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: isVisible
                                ? [Color.white, heatLevel.lampColor, machineGlow, Color.black]
                                : [Color.gray.opacity(0.52), Color.black],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 42
                        )
                    )

                if heatLevel == .premium && isVisible {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .red, .orange, .yellow, .green,
                                    .cyan, .blue, .purple, .red
                                ],
                                center: .center,
                                angle: .degrees(rainbowRotation)
                            ),
                            lineWidth: 4
                        )
                } else {
                    Circle()
                        .stroke(
                            isVisible
                                ? Color.white.opacity(0.78)
                                : Color.white.opacity(0.20),
                            lineWidth: 3
                        )
                }

                Circle()
                    .fill(Color.white.opacity(flashOpacity))
                    .blur(radius: 2)

                VStack(spacing: -2) {
                    Text("PUSH")
                        .font(.system(size: 13, weight: .black, design: .rounded))

                    Text("BUTTON")
                        .font(.system(size: 6, weight: .black, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(
                    isVisible
                        ? Color.white
                        : Color.white.opacity(0.32)
                )
                .shadow(
                    color: isVisible ? Color.white.opacity(0.7) : Color.clear,
                    radius: 4
                )
            }
            .frame(width: 59, height: 59)
            .scaleEffect(
                pressed
                    ? 0.88
                    : (isVisible && heartbeat ? 1.11 : 1.0)
            )
            .offset(y: pressed ? 4 : 0)
            .shadow(
                color: isVisible
                    ? machineGlow.opacity(0.95)
                    : Color.clear,
                radius: heartbeat ? 20 : 12
            )
            .shadow(
                color: heatLevel == .premium && isVisible
                    ? heatLevel.lampColor.opacity(0.9)
                    : Color.clear,
                radius: 17
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("PUSHボタン")
        .onAppear {
            startContinuousAnimations()
        }
    }

    private var shockwaveEffect: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.white,
                                heatLevel.lampColor,
                                Color.yellow,
                                Color.white
                            ],
                            center: .center
                        ),
                        lineWidth: CGFloat(3 - index)
                    )
                    .frame(
                        width: CGFloat(78 + index * 17),
                        height: CGFloat(78 + index * 17)
                    )
                    .scaleEffect(
                        shockwaveScale
                            + CGFloat(index) * 0.07
                    )
                    .opacity(
                        shockwaveOpacity
                            * (1.0 - Double(index) * 0.22)
                    )
                    .rotationEffect(
                        .degrees(
                            shockwaveRotation
                                * (index.isMultiple(of: 2) ? 1 : -1)
                        )
                    )
                    .shadow(
                        color: heatLevel.lampColor.opacity(0.85),
                        radius: 12
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            heatLevel.lampColor.opacity(0.46),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 58
                    )
                )
                .frame(width: 118, height: 118)
                .scaleEffect(shockwaveScale)
                .opacity(shockwaveOpacity * 0.72)
                .blendMode(.screen)
        }
        .allowsHitTesting(false)
    }

    private func startContinuousAnimations() {
        withAnimation(
            .easeInOut(duration: 0.72)
                .repeatForever(autoreverses: true)
        ) {
            heartbeat = true
        }

        withAnimation(
            .linear(duration: 1.15)
                .repeatForever(autoreverses: false)
        ) {
            ringProgress = 1
        }

        withAnimation(
            .linear(duration: 2.8)
                .repeatForever(autoreverses: false)
        ) {
            rainbowRotation = 360
        }
    }

    private func handlePush() {
        guard isEnabled else { return }

        playShockwave()

        withAnimation(.easeOut(duration: 0.055)) {
            pressed = true
            flashOpacity = 0.92
        }

        onImpact(-4)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.48)) {
                pressed = false
            }

            onImpact(3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.22)) {
                flashOpacity = 0
            }

            onImpact(0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) {
            onPush()
        }
    }

    private func playShockwave() {
        shockwaveScale = 0.58
        shockwaveOpacity = 1
        shockwaveRotation = 0

        withAnimation(.easeOut(duration: 0.44)) {
            shockwaveScale = 1.55
            shockwaveRotation = 72
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.34)) {
                shockwaveOpacity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PushButtonView(
            isVisible: true,
            isEnabled: true,
            heatLevel: .premium,
            machineGlow: .purple,
            onPush: {},
            onImpact: { _ in }
        )
    }
}
