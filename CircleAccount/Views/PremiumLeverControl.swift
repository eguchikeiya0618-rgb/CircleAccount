//
//  PremiumLeverControl.swift
//  CircleAccount
//

import SwiftUI

struct PremiumLeverControl: View {
    let progress: CGFloat
    let glowColor: Color
    let enabled: Bool
    let onChanged: (CGFloat) -> Void
    let onReleased: () -> Void

    @State private var dragStartProgress: CGFloat?

    private var clampedProgress: CGFloat {
        min(1, max(0, progress))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.48),
                                Color.gray,
                                Color.black
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 18, height: 128)

                Capsule()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 6, height: 112)
                    .padding(.top, 8)

                leverKnob
                    .offset(y: clampedProgress * 82)
            }
            .frame(width: 60, height: 150)

            Text("LEVER")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard enabled else { return }

                    if dragStartProgress == nil {
                        dragStartProgress = clampedProgress
                    }

                    let startingProgress = dragStartProgress ?? 0
                    let nextProgress =
                        startingProgress + value.translation.height / 96

                    onChanged(min(1, max(0, nextProgress)))
                }
                .onEnded { _ in
                    guard enabled else {
                        dragStartProgress = nil
                        return
                    }

                    dragStartProgress = nil
                    onReleased()
                }
        )
        .accessibilityLabel("スロットレバー")
        .accessibilityHint("下に引いてガチャを開始します")
    }

    private var leverKnob: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.red,
                            Color(red: 0.43, green: 0.0, blue: 0.0)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 32
                    )
                )
                .frame(width: 52, height: 52)

            Circle()
                .stroke(Color.white.opacity(0.45), lineWidth: 2)
                .frame(width: 52, height: 52)

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 14, height: 8)
                .offset(x: -10, y: -11)
                .blur(radius: 1)
        }
        .shadow(color: Color.red.opacity(0.65), radius: 10)
        .shadow(color: glowColor.opacity(0.55), radius: 14)
        .opacity(enabled ? 1.0 : 0.58)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        PremiumLeverControl(
            progress: 0.35,
            glowColor: .purple,
            enabled: true,
            onChanged: { _ in },
            onReleased: {}
        )
    }
}
