//
//  MachineControlPanelView.swift
//  CircleAccount
//

import SwiftUI

struct MachineControlPanelView: View {
    let isSpinning: Bool
    let stoppedReelCount: Int
    let flashingStopIndex: Int?
    let heatLevel: SlotHeatLevel
    let machineGlow: Color
    let isPushVisible: Bool
    let isPushEnabled: Bool
    let onPush: () -> Void
    let onImpact: (CGFloat) -> Void

    var body: some View {
        HStack(spacing: 13) {
            ForEach(0..<3, id: \.self) { index in
                StopLampView(
                    index: index,
                    isSpinning: isSpinning,
                    stoppedReelCount: stoppedReelCount,
                    flashingStopIndex: flashingStopIndex,
                    heatLevel: heatLevel
                )
            }

            Spacer(minLength: 3)

            PushButtonView(
                isVisible: isPushVisible,
                isEnabled: isPushEnabled,
                heatLevel: heatLevel,
                machineGlow: machineGlow,
                onPush: onPush,
                onImpact: onImpact
            )
        }
        .frame(height: 74)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.13, blue: 0.17),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                }
        )
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        MachineControlPanelView(
            isSpinning: true,
            stoppedReelCount: 1,
            flashingStopIndex: 0,
            heatLevel: .premium,
            machineGlow: .purple,
            isPushVisible: true,
            isPushEnabled: true,
            onPush: {},
            onImpact: { _ in }
        )
        .padding()
    }
}
