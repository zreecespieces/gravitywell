import Foundation

struct TopDomain: Decodable, Identifiable, Sendable {
    var id: String { domain }

    let domain: String
    let count: Int
}

struct TopDomainsResponse: Decodable, Sendable {
    let domains: [TopDomain]
    let totalQueries: Int
    let blockedQueries: Int

    private enum CodingKeys: String, CodingKey {
        case domains
        case totalQueries = "total_queries"
        case blockedQueries = "blocked_queries"
    }
}
