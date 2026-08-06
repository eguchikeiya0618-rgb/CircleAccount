//
//  PremiumTypewriterOverlay.swift
//  CircleAccount
//

import SwiftUI

struct PremiumTypewriterOverlay: View {
    let onFinished: () -> Void

    private struct CharacterImage: Identifiable {
        let id: Int
        let assetName: String
    }

    private let characterImages = [
        CharacterImage(id: 0, assetName: "typewriter_next"),
        CharacterImage(id: 1, assetName: "typewriter_time"),
        CharacterImage(id: 2, assetName: "typewriter_destiny"),
        CharacterImage(id: 3, assetName: "typewriter_fate"),
        CharacterImage(id: 4, assetName: "typewriter_awake"),
        CharacterImage(id: 5, assetName: "typewriter_awakening"),
        CharacterImage(id: 6, assetName: "typewriter_exclamation")
    ]

    private let characterDisplayDuration: Duration = .milliseconds(250)
    private let exclamationDisplayDuration: Duration = .milliseconds(350)
    private let fullImageDuration: Duration = .seconds(3)

    @State private var visibleCharacterIndex: Int?
    @State private var isFullImageVisible = false
    @State private var flashOpacity = 0.0
    @State private var sequenceID = UUID()

    var body: some View {
        ZStack {
            Color.black
                .offset(y: 11)
            
            if !isFullImageVisible,
               let visibleCharacterIndex {
                Image(characterImages[visibleCharacterIndex].assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(
                        maxWidth: visibleCharacterIndex == 6 ? 280 : 220,
                        maxHeight: 240
                    )
                    .padding(.horizontal, 24)
                    .offset(y: 11)
                    .id(visibleCharacterIndex)
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.95)
                        )
                    )
            }
            
            if isFullImageVisible {
                Image("typewriter_full")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(
                            width: 348,
                            height: 314
                        )
                        .offset(y: 11)
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.95)
                        )
                    )
            }
            
            Color.white
                .opacity(flashOpacity)
            
                .allowsHitTesting(false)
        }
        
        
        
        .allowsHitTesting(false)
        .frame(
            width: 348,
            height: 286
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: sequenceID) {
            await playSequence()
        }
    }
    
    @MainActor
    private func playSequence() async {
        visibleCharacterIndex = nil
        isFullImageVisible = false
        flashOpacity = 0

        for index in characterImages.indices {
            guard !Task.isCancelled else { return }

            SlotSoundManager.shared.playTypewriter()

            withAnimation(.easeOut(duration: 0.14)) {
                visibleCharacterIndex = index
            }

            let displayDuration = index == characterImages.count - 1
                ? exclamationDisplayDuration
                : characterDisplayDuration

            try? await Task.sleep(for: displayDuration)
            guard !Task.isCancelled else { return }

            withAnimation(.easeIn(duration: 0.08)) {
                visibleCharacterIndex = nil
            }

            try? await Task.sleep(for: .milliseconds(80))
        }

        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.06)) {
            flashOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(70))
        guard !Task.isCancelled else { return }

        SlotSoundManager.shared.playTypewriterImpact()

        withAnimation(.easeOut(duration: 0.16)) {
            flashOpacity = 0
            visibleCharacterIndex = nil
            isFullImageVisible = true
        }

        try? await Task.sleep(for: fullImageDuration)
        guard !Task.isCancelled else { return }

        onFinished()
    }
}

#Preview("Premium Typewriter Overlay") {
    PremiumTypewriterOverlay {
        // Previewでは完了後も最終フレームを表示します。
    }
    .frame(width: 390, height: 300)
}
