import Foundation

enum PollInterval: Int, CaseIterable, Identifiable {
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60
    case fiveMinutes = 300

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fifteenSeconds:
            "15 seconds"
        case .thirtySeconds:
            "30 seconds"
        case .sixtySeconds:
            "60 seconds"
        case .fiveMinutes:
            "5 minutes"
        }
    }
}
