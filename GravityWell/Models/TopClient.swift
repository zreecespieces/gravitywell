import Foundation

struct TopClient: Decodable, Identifiable, Sendable {
    var id: String { "\(ip)-\(name ?? "")" }
    var displayName: String { name?.isEmpty == false ? name! : ip }

    let ip: String
    let name: String?
    let count: Int
}

struct TopClientsResponse: Decodable, Sendable {
    let clients: [TopClient]
    let totalQueries: Int
    let blockedQueries: Int

    private enum CodingKeys: String, CodingKey {
        case clients
        case totalQueries = "total_queries"
        case blockedQueries = "blocked_queries"
    }
}

struct NetworkDevice: Decodable, Sendable {
    let hwaddr: String?
    let ips: [NetworkDeviceAddress]

    private enum CodingKeys: String, CodingKey {
        case hwaddr
        case ips
    }

    init(hwaddr: String? = nil, ips: [NetworkDeviceAddress]) {
        self.hwaddr = hwaddr
        self.ips = ips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hwaddr = try container.decodeIfPresent(String.self, forKey: .hwaddr)
        ips = try container.decodeIfPresent([NetworkDeviceAddress].self, forKey: .ips) ?? []
    }
}

struct NetworkDeviceAddress: Decodable, Sendable {
    let ip: String
    let name: String?
}

struct NetworkDevicesResponse: Decodable, Sendable {
    let devices: [NetworkDevice]

    private enum CodingKeys: String, CodingKey {
        case devices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        devices = try container.decodeIfPresent([NetworkDevice].self, forKey: .devices) ?? []
    }
}

struct PiHoleManagedClient: Decodable, Sendable {
    let client: String
    let name: String?
    let comment: String?

    init(client: String, name: String? = nil, comment: String? = nil) {
        self.client = client
        self.name = name
        self.comment = comment
    }
}

struct PiHoleManagedClientsResponse: Decodable, Sendable {
    let clients: [PiHoleManagedClient]

    private enum CodingKeys: String, CodingKey {
        case clients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clients = try container.decodeIfPresent([PiHoleManagedClient].self, forKey: .clients) ?? []
    }
}

struct PiHoleClientSuggestion: Decodable, Sendable {
    let addresses: String?
    let names: String?

    init(addresses: String? = nil, names: String? = nil) {
        self.addresses = addresses
        self.names = names
    }
}

struct PiHoleClientSuggestionsResponse: Decodable, Sendable {
    let clients: [PiHoleClientSuggestion]

    private enum CodingKeys: String, CodingKey {
        case clients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clients = try container.decodeIfPresent([PiHoleClientSuggestion].self, forKey: .clients) ?? []
    }
}

struct PiHoleDHCPLease: Decodable, Sendable {
    let ip: String
    let name: String?

    init(ip: String, name: String? = nil) {
        self.ip = ip
        self.name = name
    }
}

struct PiHoleDHCPLeasesResponse: Decodable, Sendable {
    let leases: [PiHoleDHCPLease]

    private enum CodingKeys: String, CodingKey {
        case leases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        leases = try container.decodeIfPresent([PiHoleDHCPLease].self, forKey: .leases) ?? []
    }
}

struct PiHoleQuery: Decodable, Sendable {
    let time: TimeInterval
    let client: PiHoleQueryClient?

    init(time: TimeInterval, client: PiHoleQueryClient? = nil) {
        self.time = time
        self.client = client
    }
}

struct PiHoleQueryClient: Decodable, Sendable {
    let ip: String
    let name: String?
}

struct PiHoleQueriesResponse: Decodable, Sendable {
    let queries: [PiHoleQuery]
}
