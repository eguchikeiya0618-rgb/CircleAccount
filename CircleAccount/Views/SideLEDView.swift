import SwiftUI

struct SideLEDView: View {
    let heatLevel: SlotHeatLevel
    let machineGlow: Color
    let isSpinning: Bool

    @State private var flowPhase = 0.0
    @State private var breathing = false

    var body: some View {
        HStack {
            ledColumn(isLeft: true)

            Spacer()

            ledColumn(isLeft: false)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 24)
        .allowsHitTesting(false)
        .onAppear {
            startAnimations()
        }
    }

    private func ledColumn(isLeft: Bool) -> some View {
        VStack(spacing: 8) {
            ForEach(0..<18, id: \.self) { index in
                ledBulb(
                    index: index,
                    isLeft: isLeft
                )
            }
        }
    }

    private func ledBulb(
        index: Int,
        isLeft: Bool
    ) -> some View {
        let offset = isLeft ? 0.0 : 5.0
        let wave = sin(
            flowPhase
                + Double(index) * 0.72
                + offset
        )
        let intensity = (wave + 1) / 2

        let premiumColors: [Color] = [
            .red, .orange, .yellow, .green,
            .cyan, .blue, .purple, .pink
        ]

        let bulbColor =
            heatLevel == .premium
                ? premiumColors[index % premiumColors.count]
                : (
                    index.isMultiple(of: 3)
                        ? heatLevel.lampColor
                        : machineGlow
                )

        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(
                            0.42 + intensity * 0.58
                        ),
                        bulbColor,
                        bulbColor.opacity(0.34),
                        Color.black
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 9
                )
            )
            .frame(
                width: 8 + intensity * 3.5,
                height: 8 + intensity * 3.5
            )
            .overlay {
                Circle()
                    .stroke(
                        Color.white.opacity(
                            0.18 + intensity * 0.42
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(
                color: bulbColor.opacity(
                    0.22 + intensity * 0.92
                ),
                radius:
                    heatLevel == .premium
                        ? 8 + intensity * 8
                        : 4 + intensity * 6
            )
            .opacity(
                isSpinning
                    ? 0.40 + intensity * 0.60
                    : (
                        breathing
                            ? 0.92
                            : 0.52
                    )
            )
            .scaleEffect(
                heatLevel == .premium
                    ? 1.0 + intensity * 0.13
                    : 1.0
            )
    }

    private func startAnimations() {
        flowPhase = 0
        breathing = false

        withAnimation(
            .linear(duration: 1.45)
                .repeatForever(autoreverses: false)
        ) {
            flowPhase = .pi * 2
        }

        withAnimation(
            .easeInOut(duration: 0.82)
                .repeatForever(autoreverses: true)
        ) {
            breathing = true
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        RoundedRectangle(cornerRadius: 34)
            .fill(Color.black.opacity(0.85))
            .frame(width: 370, height: 520)
            .overlay {
                SideLEDView(
                    heatLevel: .premium,
                    machineGlow: .purple,
                    isSpinning: true
                )
            }
    }
}
