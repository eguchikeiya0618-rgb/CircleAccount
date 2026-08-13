//
//  SlotBlackoutOverlay.swift
//  CircleAccount
//
//  激アツ暗転専用。
//  古い文字演出は一切表示せず、
//  EguchiCustomGekiAtsuViewだけを表示する。
//

import SwiftUI

struct SlotBlackoutOverlay: View {
    let trigger: Int

    @State private var isVisible = false
    @State private var overlayOpacity = 0.0
    @State private var animationToken = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isVisible {
                    EguchiCustomGekiAtsuView()
                        .id(animationToken)
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                        .opacity(overlayOpacity)
                        .transition(.opacity)
                }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            playSequence()
        }
    }

    private func playSequence() {
        animationToken += 1
        let token = animationToken

        isVisible = true
        overlayOpacity = 1

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.22
        ) {
            guard token == animationToken else { return }

            withAnimation(
                .easeOut(duration: 0.24)
            ) {
                overlayOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.50
        ) {
            guard token == animationToken else { return }

            isVisible = false
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        SlotBlackoutOverlay(
            trigger: 1
        )
        .frame(
            width: 370,
            height: 520
        )
        .padding()
    }
}
