import SwiftUI

enum SlotHeatLevel: Equatable {
    case normal
    case chance
    case superChance
    case warning
    case premium

    var glowColor: Color {
        switch self {
        case .normal:
            return Color(red: 1.00, green: 0.67, blue: 0.13)
        case .chance:
            return Color(red: 1.00, green: 0.18, blue: 0.08)
        case .superChance:
            return Color(red: 1.00, green: 0.76, blue: 0.05)
        case .warning:
            return .red
        case .premium:
            return .purple
        }
    }

    var lampColor: Color {
        switch self {
        case .normal:
            return Color(red: 1.00, green: 0.76, blue: 0.19)
        case .chance:
            return .red
        case .superChance:
            return .yellow
        case .warning:
            return Color(red: 1.00, green: 0.05, blue: 0.02)
        case .premium:
            return .white
        }
    }

    var displayColor: Color {
        switch self {
        case .normal:
            return Color(red: 0.38, green: 1.00, blue: 0.75)
        case .chance:
            return .red
        case .superChance:
            return .yellow
        case .warning:
            return .white
        case .premium:
            return .white
        }
    }
}
