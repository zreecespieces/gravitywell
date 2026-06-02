import Foundation

enum MonitoringControl: Sendable, Equatable {
    case disableBlocking(seconds: Int)
    case enableBlocking
}
