//
//  SlotSoundControlView.swift
//  CircleAccount
//

import SwiftUI

struct SlotSoundControlView: View {
    @Binding var isEnabled: Bool
    @Binding var volume: Double

    let glowColor: Color

    @State private var isSettingsPresented = false
    @State private var buttonPulse = false

    var body: some View {
        Button {
            isSettingsPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.black.opacity(0.86)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .stroke(
                        glowColor.opacity(
                            isEnabled ? 0.84 : 0.28
                        ),
                        lineWidth: 1.5
                    )

                Image(
                    systemName:
                        isEnabled && volume > 0.01
                        ? "speaker.wave.2.fill"
                        : "speaker.slash.fill"
                )
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(
                    isEnabled
                        ? Color.white
                        : Color.white.opacity(0.42)
                )
                .shadow(
                    color:
                        isEnabled
                        ? glowColor.opacity(0.85)
                        : Color.clear,
                    radius: 7
                )
            }
            .frame(width: 38, height: 38)
            .scaleEffect(buttonPulse ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("スロットのサウンド設定")
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.85)
                    .repeatForever(autoreverses: true)
            ) {
                buttonPulse = true
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            soundSettingsSheet
                .presentationDetents([.height(310)])
                .presentationDragIndicator(.visible)
        }
    }

    private var soundSettingsSheet: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(0.25),
                            glowColor,
                            glowColor.opacity(0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 96, height: 4)

            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(glowColor.opacity(0.16))

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(glowColor)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text("SOUND SETTINGS")
                        .font(
                            .system(
                                size: 16,
                                weight: .black,
                                design: .rounded
                            )
                        )

                    Text("スロットの効果音を調整")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Toggle(isOn: $isEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("効果音")
                        .font(.system(size: 15, weight: .bold))

                    Text(
                        isEnabled
                            ? "サウンド ON"
                            : "サウンド OFF"
                    )
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                }
            }
            .tint(glowColor)

            VStack(spacing: 9) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)

                    Slider(
                        value: $volume,
                        in: 0...1,
                        step: 0.05
                    )
                    .tint(glowColor)
                    .disabled(!isEnabled)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(
                            isEnabled
                                ? glowColor
                                : Color.secondary
                        )
                }

                HStack {
                    Text("音量")
                    Spacer()
                    Text("\(Int(volume * 100))%")
                }
                .font(
                    .system(
                        size: 11,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(.secondary)
            }
            .opacity(isEnabled ? 1 : 0.42)

            Button {
                isSettingsPresented = false
            } label: {
                Text("完了")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        glowColor
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
}

#Preview {
    SlotSoundControlPreview()
}

private struct SlotSoundControlPreview: View {
    @State private var enabled = true
    @State private var volume = 0.8

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SlotSoundControlView(
                isEnabled: $enabled,
                volume: $volume,
                glowColor: .cyan
            )
        }
    }
}
