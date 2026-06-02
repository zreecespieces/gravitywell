import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case blockPercentage
    case blockedQueries
    case totalQueries
    case iconOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blockPercentage:
            "Block percentage"
        case .blockedQueries:
            "Blocked queries"
        case .totalQueries:
            "Total queries"
        case .iconOnly:
            "Icon only"
        }
    }
}
