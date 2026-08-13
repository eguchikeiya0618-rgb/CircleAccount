//
//  PremiumReelColumn.swift
//  CircleAccount
//
//  SiriUS Reel Engine v2 compatibility facade.
//

import SwiftUI

struct PremiumReelColumn: View {
    let finalSymbol: String
    let initialDisplaySymbol: String
    let symbolPool: [String]
    let isSpinning: Bool
    let isStopped: Bool
    let reelIndex: Int

    var body: some View {
        SiriUSV2ReelDrumView(
            inputs: SiriUSV2ReelInputs(
                finalSymbol: finalSymbol,
                initialDisplaySymbol: initialDisplaySymbol,
                symbolPool: symbolPool,
                isSpinning: isSpinning,
                isStopped: isStopped,
                reelIndex: reelIndex
            )
        )
        .frame(width: 78, height: 150)
        .accessibilityElement()
        .accessibilityLabel("リール\(reelIndex + 1)")
        .accessibilityValue(isSpinning ? "回転中" : displayedSymbol)
    }

    private var displayedSymbol: String {
        isStopped ? finalSymbol : initialDisplaySymbol
    }
}
