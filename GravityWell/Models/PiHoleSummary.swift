import Foundation

struct PiHoleSummary: Decodable, Sendable {
    let totalQueries: Int
    let blockedQueries: Int
    let percentBlocked: Double
    let uniqueDomains: Int
    let activeClients: Int
    let totalClients: Int
    let domainsBeingBlocked: Int
    let gravityLastUpdate: Date?

    private enum CodingKeys: String, CodingKey {
        case queries
        case clients
        case gravity
    }

    private enum QueryKeys: String, CodingKey {
        case total
        case blocked
        case percentBlocked = "percent_blocked"
        case uniqueDomains = "unique_domains"
    }

    private enum ClientKeys: String, CodingKey {
        case active
        case total
    }

    private enum GravityKeys: String, CodingKey {
        case domainsBeingBlocked = "domains_being_blocked"
        case lastUpdate = "last_update"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let queries = try container.nestedContainer(keyedBy: QueryKeys.self, forKey: .queries)
        totalQueries = try queries.decodeIfPresent(Int.self, forKey: .total) ?? 0
        blockedQueries = try queries.decodeIfPresent(Int.self, forKey: .blocked) ?? 0
        percentBlocked = try queries.decodeIfPresent(Double.self, forKey: .percentBlocked) ?? 0
        uniqueDomains = try queries.decodeIfPresent(Int.self, forKey: .uniqueDomains) ?? 0

        let clients = try container.nestedContainer(keyedBy: ClientKeys.self, forKey: .clients)
        activeClients = try clients.decodeIfPresent(Int.self, forKey: .active) ?? 0
        totalClients = try clients.decodeIfPresent(Int.self, forKey: .total) ?? 0

        if container.contains(.gravity) {
            let gravity = try container.nestedContainer(keyedBy: GravityKeys.self, forKey: .gravity)
            domainsBeingBlocked = try gravity.decodeIfPresent(Int.self, forKey: .domainsBeingBlocked) ?? 0

            if let timestamp = try gravity.decodeIfPresent(Int.self, forKey: .lastUpdate), timestamp > 0 {
                gravityLastUpdate = Date(timeIntervalSince1970: TimeInterval(timestamp))
            } else {
                gravityLastUpdate = nil
            }
        } else {
            domainsBeingBlocked = 0
            gravityLastUpdate = nil
        }
    }
}
