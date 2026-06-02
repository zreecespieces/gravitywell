import Foundation

protocol PiHoleAPIProviding: Sendable {
    func authenticate() async throws
    func fetchSummary() async throws -> PiHoleSummary
    func fetchTopBlockedDomains() async throws -> [TopDomain]
    func fetchTopClients() async throws -> [TopClient]
    func fetchNetworkDevices() async throws -> [NetworkDevice]
    func fetchClients() async throws -> [PiHoleManagedClient]
    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion]
    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease]
    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery]
    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery]
    func disableBlocking(seconds: Int) async throws
    func enableBlocking() async throws
}
