import SwiftUI

struct MarqueeHeaderView: View {
    let heatLevel: SlotHeatLevel
    let machineGlow: Color

    @State private var lampPulse = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? heatLevel.lampColor
                                : machineGlow
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse ? machineGlow : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 1.0 : 0.48)
                }
            }

            VStack(spacing: -2) {
                Text("SiRiUS")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(Color.white.opacity(0.82))

                Text("LUCKY SLOT")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                heatLevel.lampColor,
                                machineGlow,
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: machineGlow, radius: 9)
            }

            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? machineGlow
                                : heatLevel.lampColor
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse
                                ? heatLevel.lampColor
                                : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 0.82 : 0.42)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(machineGlow.opacity(0.58), lineWidth: 1.5)
                }
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.62)
                    .repeatForever(autoreverses: true)
            ) {
                lampPulse = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        MarqueeHeaderView(
            heatLevel: .premium,
            machineGlow: .purple
        )
        .padding()
    }
}
