import XCTest
@testable import GravityWell

final class PiHoleProviderTests: XCTestCase {
    func testFetchSnapshotMapsPiHoleData() async throws {
        let provider = PiHoleProvider(client: MockPiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.providerName, "Pi-hole")
        XCTAssertEqual(snapshot.status, .online)
        XCTAssertEqual(snapshot.totalQueries, 12_483)
        XCTAssertEqual(snapshot.blockedQueries, 2_341)
        XCTAssertEqual(snapshot.percentBlocked, 18.7)
        XCTAssertEqual(snapshot.clientsSeen, 9)
        XCTAssertEqual(snapshot.topBlockedDomains.first?.name, "doubleclick.net")
        XCTAssertEqual(snapshot.topClients.first?.name, "zacharys-macbook-pro")
        XCTAssertEqual(snapshot.queryActivity.count, 60)
        XCTAssertEqual(snapshot.queryActivity.reduce(0, +), 3)
    }

    func testFetchSnapshotResolvesClientNameFromTargetedQueries() async throws {
        let provider = PiHoleProvider(client: MockTargetedClientLookupPiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.topClients.first?.name, "zacharys-macbook-pro")
    }

    func testFetchSnapshotResolvesClientNameFromManagedClientComment() async throws {
        let provider = PiHoleProvider(client: MockManagedClientPiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.topClients.first?.name, "Office Mac")
    }

    func testFetchSnapshotResolvesClientNameFromManagedClientMAC() async throws {
        let provider = PiHoleProvider(client: MockManagedClientMACPiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.topClients.first?.name, "MacBook Pro")
    }

    func testFetchSnapshotResolvesClientNameFromClientSuggestions() async throws {
        let provider = PiHoleProvider(client: MockClientSuggestionsPiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.topClients.first?.name, "media-server")
    }

    func testFetchSnapshotResolvesClientNameFromDHCPLeases() async throws {
        let provider = PiHoleProvider(client: MockDHCPLeasePiHoleAPIClient())

        let snapshot = try await provider.fetchSnapshot()

        XCTAssertEqual(snapshot.topClients.first?.name, "garage-camera")
    }
}

private actor MockPiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 12483,
                    "blocked": 2341,
                    "percent_blocked": 18.7,
                    "unique_domains": 445
                  },
                  "clients": {
                    "active": 9,
                    "total": 12
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        [
            TopDomain(domain: "doubleclick.net", count: 1_200),
            TopDomain(domain: "app-measurement.com", count: 840)
        ]
    }

    func fetchTopClients() async throws -> [TopClient] {
        [
            TopClient(ip: "192.168.1.20", name: nil, count: 4_000),
            TopClient(ip: "192.168.1.21", name: "iPhone", count: 1_200)
        ]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        []
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        []
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        []
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        []
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        [
            PiHoleQuery(
                time: startDate.addingTimeInterval(30).timeIntervalSince1970,
                client: PiHoleQueryClient(ip: "192.168.1.20", name: "zacharys-macbook-pro")
            ),
            PiHoleQuery(time: startDate.addingTimeInterval(90).timeIntervalSince1970),
            PiHoleQuery(time: endDate.addingTimeInterval(-30).timeIntervalSince1970)
        ]
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}

private actor MockTargetedClientLookupPiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 100,
                    "blocked": 20,
                    "percent_blocked": 20,
                    "unique_domains": 12
                  },
                  "clients": {
                    "active": 2,
                    "total": 2
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        []
    }

    func fetchTopClients() async throws -> [TopClient] {
        [TopClient(ip: "192.168.1.20", name: nil, count: 40)]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        []
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        []
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        []
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        []
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        [PiHoleQuery(time: startDate.addingTimeInterval(30).timeIntervalSince1970)]
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        [
            PiHoleQuery(
                time: Date().timeIntervalSince1970,
                client: PiHoleQueryClient(ip: ip, name: "zacharys-macbook-pro")
            )
        ]
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}

private actor MockManagedClientPiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 100,
                    "blocked": 20,
                    "percent_blocked": 20,
                    "unique_domains": 12
                  },
                  "clients": {
                    "active": 2,
                    "total": 2
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        []
    }

    func fetchTopClients() async throws -> [TopClient] {
        [TopClient(ip: "192.168.1.30", name: nil, count: 40)]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        []
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        [PiHoleManagedClient(client: "192.168.1.30", comment: "Office Mac")]
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        []
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        []
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}

private actor MockManagedClientMACPiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 100,
                    "blocked": 20,
                    "percent_blocked": 20,
                    "unique_domains": 12
                  },
                  "clients": {
                    "active": 2,
                    "total": 2
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        []
    }

    func fetchTopClients() async throws -> [TopClient] {
        [TopClient(ip: "192.168.0.207", name: nil, count: 40)]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        [
            NetworkDevice(
                hwaddr: "46:46:98:28:B0:06",
                ips: [NetworkDeviceAddress(ip: "192.168.0.207", name: nil)]
            )
        ]
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        [PiHoleManagedClient(client: "46:46:98:28:b0:06", comment: "MacBook Pro")]
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        []
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        []
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}

private actor MockClientSuggestionsPiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 100,
                    "blocked": 20,
                    "percent_blocked": 20,
                    "unique_domains": 12
                  },
                  "clients": {
                    "active": 2,
                    "total": 2
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        []
    }

    func fetchTopClients() async throws -> [TopClient] {
        [TopClient(ip: "192.168.1.40", name: nil, count: 40)]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        []
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        []
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        [PiHoleClientSuggestion(addresses: "192.168.1.40,192.168.1.41", names: "media-server,living-room-tv")]
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        []
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}

private actor MockDHCPLeasePiHoleAPIClient: PiHoleAPIProviding {
    func authenticate() async throws {}

    func fetchSummary() async throws -> PiHoleSummary {
        try JSONDecoder().decode(
            PiHoleSummary.self,
            from: Data(
                #"""
                {
                  "queries": {
                    "total": 100,
                    "blocked": 20,
                    "percent_blocked": 20,
                    "unique_domains": 12
                  },
                  "clients": {
                    "active": 2,
                    "total": 2
                  },
                  "gravity": {
                    "domains_being_blocked": 104756,
                    "last_update": 1725194639
                  },
                  "took": 0.003
                }
                """#.utf8
            )
        )
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        []
    }

    func fetchTopClients() async throws -> [TopClient] {
        [TopClient(ip: "192.168.1.50", name: nil, count: 40)]
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        []
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        []
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        []
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        [PiHoleDHCPLease(ip: "192.168.1.50", name: "garage-camera")]
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        []
    }

    func disableBlocking(seconds: Int) async throws {}

    func enableBlocking() async throws {}
}
