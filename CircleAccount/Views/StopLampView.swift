import SwiftUI

struct StopLampView: View {
    let index: Int
    let isSpinning: Bool
    let stoppedReelCount: Int
    let flashingStopIndex: Int?
    let heatLevel: SlotHeatLevel

    @State private var pulse = false

    private var isStopped: Bool {
        stoppedReelCount > index
    }

    private var isFlashing: Bool {
        flashingStopIndex == index
    }

    private var isNext: Bool {
        isSpinning
            && !isStopped
            && stoppedReelCount == index
    }

    private var lampColor: Color {
        if isStopped {
            return .green
        }

        if isNext {
            return heatLevel.lampColor
        }

        return Color.red.opacity(0.72)
    }

    private var lampStatusText: String {
        if isStopped {
            return "STOP"
        }

        if isNext {
            return "READY"
        }

        return "WAIT"
    }

    private var positionText: String {
        ["LEFT", "CENTER", "RIGHT"][safe: index] ?? "REEL"
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.96))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }

                if isNext {
                    Circle()
                        .stroke(lampColor.opacity(0.75), lineWidth: 2)
                        .frame(width: 42, height: 42)
                        .scaleEffect(pulse ? 1.20 : 0.90)
                        .opacity(pulse ? 0.08 : 0.90)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(
                                    isStopped || isNext
                                        ? 0.98
                                        : 0.20
                                ),
                                lampColor,
                                lampColor.opacity(
                                    isStopped || isNext
                                        ? 0.45
                                        : 0.12
                                ),
                                Color.black
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 23
                        )
                    )
                    .frame(width: 34, height: 34)
                    .scaleEffect(
                        isFlashing
                            ? 1.22
                            : (
                                isNext && pulse
                                    ? 1.10
                                    : 1.0
                            )
                    )
                    .shadow(
                        color: lampColor.opacity(
                            isStopped
                                ? 0.88
                                : (
                                    isNext
                                        ? 0.98
                                        : 0.12
                                )
                        ),
                        radius:
                            isFlashing
                                ? 20
                                : (
                                    isNext
                                        ? 14
                                        : (
                                            isStopped
                                                ? 10
                                                : 2
                                        )
                                )
                    )

                Circle()
                    .stroke(
                        Color.white.opacity(
                            isStopped || isNext
                                ? 0.62
                                : 0.15
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: 34, height: 34)

                Text("\(index + 1)")
                    .font(
                        .system(
                            size: 13,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        isStopped || isNext
                            ? Color.black.opacity(0.78)
                            : Color.white.opacity(0.38)
                    )
            }
            .animation(
                .easeInOut(duration: 0.16),
                value: stoppedReelCount
            )

            Text(lampStatusText)
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .tracking(0.7)
                .foregroundStyle(
                    isStopped
                        ? Color.green.opacity(0.95)
                        : (
                            isNext
                                ? lampColor
                                : Color.white.opacity(0.32)
                        )
                )

            Text(positionText)
                .font(.system(size: 6, weight: .black, design: .rounded))
                .tracking(0.45)
                .foregroundStyle(Color.white.opacity(0.42))
        }
        .onAppear {
            startPulse()
        }
    }

    private func startPulse() {
        pulse = false

        withAnimation(
            .easeInOut(duration: 0.34)
                .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        HStack(spacing: 13) {
            StopLampView(
                index: 0,
                isSpinning: true,
                stoppedReelCount: 0,
                flashingStopIndex: nil,
                heatLevel: .premium
            )

            StopLampView(
                index: 1,
                isSpinning: true,
                stoppedReelCount: 1,
                flashingStopIndex: 0,
                heatLevel: .premium
            )

            StopLampView(
                index: 2,
                isSpinning: true,
                stoppedReelCount: 1,
                flashingStopIndex: nil,
                heatLevel: .premium
            )
        }
        .padding()
    }
}
