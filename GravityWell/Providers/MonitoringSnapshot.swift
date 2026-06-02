import Foundation

struct MonitoringSnapshot: Sendable {
    let providerName: String
    let status: MonitoringServiceStatus
    let totalQueries: Int
    let blockedQueries: Int
    let percentBlocked: Double
    let clientsSeen: Int
    let topBlockedDomains: [MonitoringTopItem]
    let topClients: [MonitoringTopItem]
    let queryActivity: [Int]
    let lastUpdated: Date
}

struct MonitoringTopItem: Identifiable, Sendable, Equatable {
    var id: String { name }

    let name: String
    let count: Int
}

enum MonitoringServiceStatus: String, Sendable {
    case online
    case blockingDisabled
    case offline
    case authenticationFailed
    case tlsError
    case apiError
    case unknownError

    var title: String {
        switch self {
        case .online:
            "Online"
        case .blockingDisabled:
            "Blocking Disabled"
        case .offline:
            "Offline"
        case .authenticationFailed:
            "Authentication Failed"
        case .tlsError:
            "TLS Error"
        case .apiError:
            "API Error"
        case .unknownError:
            "Unknown Error"
        }
    }
}
