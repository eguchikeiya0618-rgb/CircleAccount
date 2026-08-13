//
//  SlotEffectDirector.swift
//  CircleAccount
//

import Foundation

enum SlotSpinEffectLevel: Int, Comparable {
    case normal = 0
    case chance = 1
    case hot = 2
    case premium = 3

    static func < (
        lhs: SlotSpinEffectLevel,
        rhs: SlotSpinEffectLevel
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SlotSpinEffectPlan {
    let level: SlotSpinEffectLevel
    let startPresentation: SlotLCDPresentation?
    let firstStopPresentation: SlotLCDPresentation?
    let secondStopPresentation: SlotLCDPresentation?
    let usesWarningSound: Bool
    let intensifiesSpin: Bool
    let usesBlackoutTease: Bool
    let usesFakePremiumTease: Bool

    static let normal = SlotSpinEffectPlan(
        level: .normal,
        startPresentation: .start,
        firstStopPresentation: nil,
        secondStopPresentation: .reach,
        usesWarningSound: false,
        intensifiesSpin: false,
        usesBlackoutTease: false,
        usesFakePremiumTease: false
    )
}

enum SlotEffectDirector {
    static func makePlan(
        heatLevel: SlotHeatLevel,
        expectationLevel: SlotExpectationLevel,
        resultSymbols: [String]
    ) -> SlotSpinEffectPlan {
        let safeSymbols = Array(resultSymbols.prefix(3))

        let isRainbow =
            safeSymbols == ["🌈7", "🌈7", "🌈7"]

        let isRedSeven =
            safeSymbols == ["7", "7", "7"]

        // SSR系ルートは回転開始直後のheatLevelに依存させない。
        // Controllerが持つ期待度から、必ず第2停止後に新しい激アツカットインを出す。
        if expectationLevel == .gekiatsu
            || expectationLevel == .premium {
            return SlotSpinEffectPlan(
                level: .premium,
                startPresentation: .start,
                firstStopPresentation: .chance,
                secondStopPresentation: .superHot,
                usesWarningSound: true,
                intensifiesSpin: true,
                usesBlackoutTease: false,
                usesFakePremiumTease: false
            )
        }

        /*
         新しい激アツカットインは必ず第2リール停止後に1回だけ表示する。

         以前の設定では .superHot を
         ・回転開始
         ・第1リール停止
         ・第2リール停止
         の3回発火させていたため、後続の暗転復帰表示などに上書きされ、
         新しい爆発演出が途中で消える状態になっていた。
        */

        if isRainbow {
            return SlotSpinEffectPlan(
                level: .premium,
                startPresentation: .start,
                firstStopPresentation: .chance,
                secondStopPresentation: .superHot,
                usesWarningSound: true,
                intensifiesSpin: true,
                usesBlackoutTease: false,
                usesFakePremiumTease: false
            )
        }

        if isRedSeven {
            return weightedPlan(
                [
                    (
                        58,
                        SlotSpinEffectPlan(
                            level: .hot,
                            startPresentation: .chance,
                            firstStopPresentation: .chance,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: false
                        )
                    ),
                    (
                        27,
                        SlotSpinEffectPlan(
                            level: .hot,
                            startPresentation: .start,
                            firstStopPresentation: .chance,
                            secondStopPresentation: .reach,
                            usesWarningSound: false,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: true
                        )
                    ),
                    (
                        15,
                        SlotSpinEffectPlan(
                            level: .premium,
                            startPresentation: .chance,
                            firstStopPresentation: .reach,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: false
                        )
                    )
                ]
            )
        }

        switch heatLevel {
        case .premium:
            return weightedPlan(
                [
                    (
                        72,
                        SlotSpinEffectPlan(
                            level: .premium,
                            startPresentation: .chance,
                            firstStopPresentation: .reach,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: false
                        )
                    ),
                    (
                        28,
                        SlotSpinEffectPlan(
                            level: .hot,
                            startPresentation: .start,
                            firstStopPresentation: .chance,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: false
                        )
                    )
                ]
            )

        default:
            return weightedPlan(
                [
                    (
                        56,
                        .normal
                    ),
                    (
                        27,
                        SlotSpinEffectPlan(
                            level: .chance,
                            startPresentation: .start,
                            firstStopPresentation: .chance,
                            secondStopPresentation: .reach,
                            usesWarningSound: false,
                            intensifiesSpin: false,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: false
                        )
                    ),
                    (
                        12,
                        SlotSpinEffectPlan(
                            level: .hot,
                            startPresentation: .chance,
                            firstStopPresentation: .chance,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: true
                        )
                    ),
                    (
                        5,
                        SlotSpinEffectPlan(
                            level: .premium,
                            startPresentation: .chance,
                            firstStopPresentation: .reach,
                            secondStopPresentation: .superHot,
                            usesWarningSound: true,
                            intensifiesSpin: true,
                            usesBlackoutTease: false,
                            usesFakePremiumTease: true
                        )
                    )
                ]
            )
        }
    }

    private static func weightedPlan(
        _ entries: [(weight: Int, plan: SlotSpinEffectPlan)]
    ) -> SlotSpinEffectPlan {
        let totalWeight = entries.reduce(0) {
            $0 + max($1.weight, 0)
        }

        guard totalWeight > 0 else {
            return .normal
        }

        let roll = Int.random(in: 1...totalWeight)
        var cursor = 0

        for entry in entries {
            cursor += max(entry.weight, 0)

            if roll <= cursor {
                return entry.plan
            }
        }

        return entries.last?.plan ?? .normal
    }
}


