import SwiftUI

struct SlotStatusPanelView: View {
    let statusText: String
    let subStatusText: String
    let heatLevel: SlotHeatLevel
    let machineGlow: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(statusText)
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .tracking(1.3)
                .foregroundStyle(heatLevel.displayColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .shadow(color: machineGlow, radius: 6)

            Text(subStatusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            machineGlow.opacity(0.10),
                            Color.black
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                }
        )
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        SlotStatusPanelView(
            statusText: "PREMIUM LOCK",
            subStatusText: "JACKPOT APPROACHING",
            heatLevel: .premium,
            machineGlow: .purple
        )
        .padding()
    }
}
