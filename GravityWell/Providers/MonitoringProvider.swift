import Foundation

protocol MonitoringProvider: Sendable {
    var name: String { get }

    func authenticate() async throws
    func fetchSnapshot() async throws -> MonitoringSnapshot
    func performControl(_ control: MonitoringControl) async throws
}
