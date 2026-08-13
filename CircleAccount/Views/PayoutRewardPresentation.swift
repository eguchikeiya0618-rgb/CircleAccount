//
//  PayoutRewardPresentation.swift
//  CircleAccount
//

import SwiftUI

struct PayoutRewardPresentation: Equatable {
    let icon: String
    let title: String
    let subtitle: String
    let accentColors: [Color]

    static func from(symbols: [String]) -> PayoutRewardPresentation? {
        switch symbols {
        case ["7", "7", "BAR"]:
            return PayoutRewardPresentation(
                icon: "50%",
                title: "HALF PRICE GET!!",
                subtitle: "参加費半額券を獲得",
                accentColors: [.yellow, .orange, .red]
            )

        case ["BAR", "BAR", "BAR"]:
            return PayoutRewardPresentation(
                icon: "¥500",
                title: "500円 TICKET GET!!",
                subtitle: "参加費500円券を獲得",
                accentColors: [.white, .yellow, .orange]
            )

        case ["🔔", "🔔", "🔔"]:
            return PayoutRewardPresentation(
                icon: "🔔",
                title: "CHALLENGE TICKET GET!!",
                subtitle: "対戦指名券を獲得",
                accentColors: [.yellow, .orange, .pink]
            )

        case ["🍇", "🍇", "🍇"]:
            return PayoutRewardPresentation(
                icon: "🍇",
                title: "PRIORITY TICKET GET!!",
                subtitle: "優先ゲーム券を獲得",
                accentColors: [.purple, .pink, .cyan]
            )

        default:
            return nil
        }
    }

    var primaryColor: Color {
        accentColors.first ?? .yellow
    }

    var secondaryColor: Color {
        accentColors.indices.contains(1)
            ? accentColors[1]
            : primaryColor
    }

    var finalColor: Color {
        accentColors.last ?? primaryColor
    }

    func color(at index: Int) -> Color {
        guard !accentColors.isEmpty else {
            return .yellow
        }

        return accentColors[index % accentColors.count]
    }
}
