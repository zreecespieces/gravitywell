import Foundation

enum PiHoleStatus: String, Decodable, Sendable {
    case enabled
    case disabled
    case failed
    case unknown
}

struct PiHoleBlockingStatus: Decodable, Sendable {
    let blocking: PiHoleStatus
    let timer: Double?
}
