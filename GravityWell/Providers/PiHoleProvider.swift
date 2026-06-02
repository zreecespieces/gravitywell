import Foundation
import Darwin
import OSLog

struct PiHoleProvider: MonitoringProvider {
    let name = "Pi-hole"

    private let client: any PiHoleAPIProviding
    private let localHostnameResolver: @Sendable (String) async -> String?

    init(
        client: any PiHoleAPIProviding,
        localHostnameResolver: @escaping @Sendable (String) async -> String? = LocalHostnameResolver.resolve
    ) {
        self.client = client
        self.localHostnameResolver = localHostnameResolver
    }

    func authenticate() async throws {
        do {
            try await client.authenticate()
        } catch {
            throw Self.mapError(error)
        }
    }

    func fetchSnapshot() async throws -> MonitoringSnapshot {
        do {
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-3_600)

            async let summary = client.fetchSummary()
            async let topBlockedDomains = client.fetchTopBlockedDomains()
            async let topClients = client.fetchTopClients()
            async let networkDevices = client.fetchNetworkDevices()
            async let managedClients = client.fetchClients()
            async let clientSuggestions = client.fetchClientSuggestions()
            async let dhcpLeases = client.fetchDHCPLeases()
            async let recentQueries = client.fetchQueries(from: startDate, until: endDate, length: 5_000)

            let resolvedSummary = try await summary
            let resolvedTopBlockedDomains = try await topBlockedDomains
            let resolvedTopClients = try await topClients

            let resolvedNetworkDevices: [NetworkDevice]
            do {
                resolvedNetworkDevices = try await networkDevices
            } catch {
                resolvedNetworkDevices = []
                Logger.api.warning("Pi-hole hostname source /network/devices failed: \(error.localizedDescription, privacy: .public)")
            }

            let resolvedManagedClients: [PiHoleManagedClient]
            do {
                resolvedManagedClients = try await managedClients
            } catch {
                resolvedManagedClients = []
                Logger.api.warning("Pi-hole hostname source /clients failed: \(error.localizedDescription, privacy: .public)")
            }

            let resolvedClientSuggestions: [PiHoleClientSuggestion]
            do {
                resolvedClientSuggestions = try await clientSuggestions
            } catch {
                resolvedClientSuggestions = []
                Logger.api.warning("Pi-hole hostname source /clients/_suggestions failed: \(error.localizedDescription, privacy: .public)")
            }

            let resolvedDHCPLeases: [PiHoleDHCPLease]
            do {
                resolvedDHCPLeases = try await dhcpLeases
            } catch {
                resolvedDHCPLeases = []
                Logger.api.warning("Pi-hole hostname source /dhcp/leases failed: \(error.localizedDescription, privacy: .public)")
            }

            let resolvedRecentQueries: [PiHoleQuery]
            do {
                resolvedRecentQueries = try await recentQueries
            } catch {
                resolvedRecentQueries = []
                Logger.api.warning("Pi-hole hostname source /queries failed: \(error.localizedDescription, privacy: .public)")
            }

            let networkHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(networkDevices: resolvedNetworkDevices)
            let managedClientHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(managedClients: resolvedManagedClients)
            let managedClientMACHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(
                managedClients: resolvedManagedClients,
                networkDevices: resolvedNetworkDevices
            )
            let suggestionHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(clientSuggestions: resolvedClientSuggestions)
            let dhcpLeaseHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(dhcpLeases: resolvedDHCPLeases)
            let recentQueryHostnamesByIPAddress = Self.hostnameResolutionsByIPAddress(queries: resolvedRecentQueries, source: "/queries")

            var hostnamesByIPAddress: [String: HostnameResolution] = [:]
            Self.mergeHostnameResolutions(networkHostnamesByIPAddress, into: &hostnamesByIPAddress)
            Self.mergeHostnameResolutions(managedClientHostnamesByIPAddress, into: &hostnamesByIPAddress)
            Self.mergeHostnameResolutions(managedClientMACHostnamesByIPAddress, into: &hostnamesByIPAddress)
            Self.mergeHostnameResolutions(dhcpLeaseHostnamesByIPAddress, into: &hostnamesByIPAddress)
            Self.mergeHostnameResolutions(suggestionHostnamesByIPAddress, into: &hostnamesByIPAddress)
            Self.mergeHostnameResolutions(recentQueryHostnamesByIPAddress, into: &hostnamesByIPAddress)

            let targetedHostnamesByIPAddress = await Self.hostnameResolutionsByIPAddress(
                forTopClients: resolvedTopClients,
                existingHostnamesByIPAddress: hostnamesByIPAddress,
                client: client
            )
            Self.mergeHostnameResolutions(targetedHostnamesByIPAddress, into: &hostnamesByIPAddress)

            let localHostnamesByIPAddress = await Self.hostnameResolutionsByIPAddress(
                forTopClients: resolvedTopClients,
                existingHostnamesByIPAddress: hostnamesByIPAddress,
                localHostnameResolver: localHostnameResolver
            )
            Self.mergeHostnameResolutions(localHostnamesByIPAddress, into: &hostnamesByIPAddress)

            Logger.api.info("Hostname enrichment counts: network=\(networkHostnamesByIPAddress.count, privacy: .public), clients=\(managedClientHostnamesByIPAddress.count, privacy: .public), clientMACs=\(managedClientMACHostnamesByIPAddress.count, privacy: .public), dhcp=\(dhcpLeaseHostnamesByIPAddress.count, privacy: .public), suggestions=\(suggestionHostnamesByIPAddress.count, privacy: .public), recentQueries=\(recentQueryHostnamesByIPAddress.count, privacy: .public), targetedQueries=\(targetedHostnamesByIPAddress.count, privacy: .public), localReverseDNS=\(localHostnamesByIPAddress.count, privacy: .public)")
            Self.logHostnameSource("/network/devices", hostnamesByIPAddress: networkHostnamesByIPAddress)
            Self.logHostnameSource("/clients", hostnamesByIPAddress: managedClientHostnamesByIPAddress)
            Self.logHostnameSource("/clients via /network/devices", hostnamesByIPAddress: managedClientMACHostnamesByIPAddress)
            Self.logHostnameSource("/dhcp/leases", hostnamesByIPAddress: dhcpLeaseHostnamesByIPAddress)
            Self.logHostnameSource("/clients/_suggestions", hostnamesByIPAddress: suggestionHostnamesByIPAddress)
            Self.logHostnameSource("/queries", hostnamesByIPAddress: recentQueryHostnamesByIPAddress)
            Self.logHostnameSource("/queries?client_ip", hostnamesByIPAddress: targetedHostnamesByIPAddress)
            Self.logHostnameSource("local reverse DNS", hostnamesByIPAddress: localHostnamesByIPAddress)
            Self.logHostnameResolution(topClients: resolvedTopClients, hostnamesByIPAddress: hostnamesByIPAddress)

            return MonitoringSnapshot(
                providerName: name,
                status: .online,
                totalQueries: resolvedSummary.totalQueries,
                blockedQueries: resolvedSummary.blockedQueries,
                percentBlocked: resolvedSummary.percentBlocked,
                clientsSeen: resolvedSummary.activeClients,
                topBlockedDomains: resolvedTopBlockedDomains.map {
                    MonitoringTopItem(name: $0.domain, count: $0.count)
                },
                topClients: resolvedTopClients.map {
                    MonitoringTopItem(name: Self.displayName(for: $0, hostnamesByIPAddress: hostnamesByIPAddress), count: $0.count)
                },
                queryActivity: Self.queryActivity(from: resolvedRecentQueries, startDate: startDate, endDate: endDate),
                lastUpdated: endDate
            )
        } catch {
            throw Self.mapError(error)
        }
    }

    func performControl(_ control: MonitoringControl) async throws {
        do {
            switch control {
            case .disableBlocking(let seconds):
                try await client.disableBlocking(seconds: seconds)
            case .enableBlocking:
                try await client.enableBlocking()
            }
        } catch {
            throw Self.mapError(error)
        }
    }

    private static func mapError(_ error: Error) -> MonitoringProviderError {
        if let error = error as? MonitoringProviderError {
            return error
        }

        guard let apiError = error as? PiHoleAPIError else {
            return .unknown(error.localizedDescription)
        }

        switch apiError {
        case .authenticationFailed(let message):
            return .authenticationFailed(message)
        case .twoFactorUnsupported:
            return .authenticationFailed(apiError.localizedDescription)
        case .tlsError:
            return .tlsError
        case .offline:
            return .offline
        case .apiError(_, let message):
            return .apiError(message)
        case .invalidBaseURL,
             .missingCredential,
             .invalidResponse,
             .decodingFailed,
             .unknown:
            return .unknown(apiError.localizedDescription)
        }
    }

    private struct HostnameResolution: Sendable {
        let name: String
        let source: String
    }

    private static func hostnameResolutionsByIPAddress(networkDevices: [NetworkDevice]) -> [String: HostnameResolution] {
        var hostnamesByIPAddress: [String: HostnameResolution] = [:]

        networkDevices.forEach { device in
            device.ips.forEach { address in
                guard let key = normalizedIPAddress(address.ip),
                      let name = normalizedHostname(address.name, fallbackIP: address.ip)
                else {
                    return
                }

                hostnamesByIPAddress[key] = HostnameResolution(name: name, source: "/network/devices")
            }
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(managedClients: [PiHoleManagedClient]) -> [String: HostnameResolution] {
        var hostnamesByIPAddress: [String: HostnameResolution] = [:]

        managedClients.forEach { managedClient in
            guard let key = normalizedIPAddress(managedClient.client) else { return }

            if let name = normalizedHostname(managedClient.name, fallbackIP: managedClient.client) {
                hostnamesByIPAddress[key] = HostnameResolution(name: name, source: "/clients.name")
            } else if let comment = normalizedHostname(managedClient.comment, fallbackIP: managedClient.client) {
                hostnamesByIPAddress[key] = HostnameResolution(name: comment, source: "/clients.comment")
            }
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(
        managedClients: [PiHoleManagedClient],
        networkDevices: [NetworkDevice]
    ) -> [String: HostnameResolution] {
        var hostnamesByMACAddress: [String: HostnameResolution] = [:]

        managedClients.forEach { managedClient in
            guard let key = normalizedMACAddress(managedClient.client) else { return }

            if let name = normalizedHostname(managedClient.name, fallbackIP: managedClient.client) {
                hostnamesByMACAddress[key] = HostnameResolution(name: name, source: "/clients.name via /network/devices")
            } else if let comment = normalizedHostname(managedClient.comment, fallbackIP: managedClient.client) {
                hostnamesByMACAddress[key] = HostnameResolution(name: comment, source: "/clients.comment via /network/devices")
            }
        }

        guard !hostnamesByMACAddress.isEmpty else { return [:] }

        var hostnamesByIPAddress: [String: HostnameResolution] = [:]
        networkDevices.forEach { device in
            guard let key = normalizedMACAddress(device.hwaddr), let resolution = hostnamesByMACAddress[key] else { return }

            device.ips.forEach { address in
                guard let ip = normalizedIPAddress(address.ip) else { return }

                hostnamesByIPAddress[ip] = resolution
            }
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(clientSuggestions: [PiHoleClientSuggestion]) -> [String: HostnameResolution] {
        var hostnamesByIPAddress: [String: HostnameResolution] = [:]

        clientSuggestions.forEach { suggestion in
            let addresses = splitCommaSeparatedList(suggestion.addresses)
            let names = splitCommaSeparatedList(suggestion.names)
            guard !addresses.isEmpty, !names.isEmpty else { return }

            if addresses.count == names.count {
                zip(addresses, names).forEach { address, name in
                    guard let key = normalizedIPAddress(address),
                          let hostname = normalizedHostname(name, fallbackIP: address)
                    else {
                        return
                    }

                    hostnamesByIPAddress[key] = HostnameResolution(name: hostname, source: "/clients/_suggestions")
                }
            } else {
                guard let hostname = normalizedHostname(names[0]) else { return }

                addresses.forEach { address in
                    guard let key = normalizedIPAddress(address),
                          normalizedHostname(hostname, fallbackIP: address) != nil
                    else {
                        return
                    }

                    hostnamesByIPAddress[key] = HostnameResolution(name: hostname, source: "/clients/_suggestions")
                }
            }
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(dhcpLeases: [PiHoleDHCPLease]) -> [String: HostnameResolution] {
        var hostnamesByIPAddress: [String: HostnameResolution] = [:]

        dhcpLeases.forEach { lease in
            guard let key = normalizedIPAddress(lease.ip),
                  let name = normalizedHostname(lease.name, fallbackIP: lease.ip)
            else {
                return
            }

            hostnamesByIPAddress[key] = HostnameResolution(name: name, source: "/dhcp/leases")
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(queries: [PiHoleQuery], source: String) -> [String: HostnameResolution] {
        var hostnamesByIPAddress: [String: HostnameResolution] = [:]

        queries.forEach { query in
            guard let client = query.client,
                  let key = normalizedIPAddress(client.ip),
                  hostnamesByIPAddress[key] == nil,
                  let name = normalizedHostname(client.name, fallbackIP: client.ip)
            else {
                return
            }

            hostnamesByIPAddress[key] = HostnameResolution(name: name, source: source)
        }

        return hostnamesByIPAddress
    }

    private static func hostnameResolutionsByIPAddress(
        forTopClients topClients: [TopClient],
        existingHostnamesByIPAddress: [String: HostnameResolution],
        client: any PiHoleAPIProviding
    ) async -> [String: HostnameResolution] {
        let unresolvedClientIPs = Array(Set(topClients.compactMap { topClient -> String? in
            guard let key = normalizedIPAddress(topClient.ip),
                  normalizedHostname(topClient.name, fallbackIP: topClient.ip) == nil,
                  existingHostnamesByIPAddress[key] == nil
            else {
                return nil
            }

            return topClient.ip
        }))

        guard !unresolvedClientIPs.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, String)?.self) { group in
            unresolvedClientIPs.forEach { ip in
                group.addTask {
                    let queries: [PiHoleQuery]
                    do {
                        queries = try await client.fetchQueries(forClientIP: ip, length: 25)
                    } catch {
                        Logger.api.warning("Pi-hole hostname source /queries?client_ip failed for \(ip, privacy: .public): \(error.localizedDescription, privacy: .public)")
                        return nil
                    }

                    let names = queries.compactMap { query in
                        normalizedHostname(query.client?.name, fallbackIP: ip)
                    }

                    if names.isEmpty {
                        Logger.api.info("Pi-hole targeted query lookup for \(ip, privacy: .public) returned \(queries.count, privacy: .public) queries but no client names")
                    } else {
                        Logger.api.info("Pi-hole targeted query lookup for \(ip, privacy: .public) returned names: \(Array(Set(names)).sorted().joined(separator: ", "), privacy: .public)")
                    }

                    for query in queries {
                        guard let queryClient = query.client,
                              normalizedIPAddress(queryClient.ip) == normalizedIPAddress(ip),
                              let name = normalizedHostname(queryClient.name, fallbackIP: ip)
                        else {
                            continue
                        }

                        return (ip, name)
                    }

                    return nil
                }
            }

            var hostnamesByIPAddress: [String: HostnameResolution] = [:]
            for await result in group {
                guard let (ip, name) = result else { continue }
                guard let key = normalizedIPAddress(ip) else { continue }

                hostnamesByIPAddress[key] = HostnameResolution(name: name, source: "/queries?client_ip")
            }

            return hostnamesByIPAddress
        }
    }

    private static func hostnameResolutionsByIPAddress(
        forTopClients topClients: [TopClient],
        existingHostnamesByIPAddress: [String: HostnameResolution],
        localHostnameResolver: @escaping @Sendable (String) async -> String?
    ) async -> [String: HostnameResolution] {
        let unresolvedClientIPs = Array(Set(topClients.compactMap { topClient -> String? in
            guard let key = normalizedIPAddress(topClient.ip),
                  normalizedHostname(topClient.name, fallbackIP: topClient.ip) == nil,
                  existingHostnamesByIPAddress[key] == nil
            else {
                return nil
            }

            return topClient.ip
        }))

        guard !unresolvedClientIPs.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, String)?.self) { group in
            unresolvedClientIPs.forEach { ip in
                group.addTask {
                    guard let name = await localHostnameResolver(ip) else {
                        Logger.api.info("Local reverse DNS returned no name for \(ip, privacy: .public)")
                        return nil
                    }

                    Logger.api.info("Local reverse DNS resolved \(ip, privacy: .public) as \(name, privacy: .public)")
                    return (ip, name)
                }
            }

            var hostnamesByIPAddress: [String: HostnameResolution] = [:]
            for await result in group {
                guard let (ip, name) = result,
                      let key = normalizedIPAddress(ip),
                      let hostname = normalizedHostname(name, fallbackIP: ip)
                else {
                    continue
                }

                hostnamesByIPAddress[key] = HostnameResolution(name: hostname, source: "local reverse DNS")
            }

            return hostnamesByIPAddress
        }
    }

    private static func mergeHostnameResolutions(
        _ source: [String: HostnameResolution],
        into target: inout [String: HostnameResolution]
    ) {
        source.forEach { ip, resolution in
            guard target[ip] == nil else { return }

            target[ip] = resolution
        }
    }

    private static func displayName(for client: TopClient, hostnamesByIPAddress: [String: HostnameResolution]) -> String {
        if let apiName = normalizedHostname(client.name, fallbackIP: client.ip) {
            return apiName
        }

        guard let key = normalizedIPAddress(client.ip) else { return client.ip }

        return hostnamesByIPAddress[key]?.name ?? client.ip
    }

    private static func logHostnameResolution(
        topClients: [TopClient],
        hostnamesByIPAddress: [String: HostnameResolution]
    ) {
        var unresolvedClientIPs: [String] = []

        topClients.forEach { topClient in
            if let name = normalizedHostname(topClient.name, fallbackIP: topClient.ip) {
                Logger.api.info("Top client \(topClient.ip, privacy: .public) resolved as \(name, privacy: .public) from /stats/top_clients")
                return
            }

            guard let key = normalizedIPAddress(topClient.ip), let resolution = hostnamesByIPAddress[key] else {
                unresolvedClientIPs.append(topClient.ip)
                return
            }

            Logger.api.info("Top client \(topClient.ip, privacy: .public) resolved as \(resolution.name, privacy: .public) from \(resolution.source, privacy: .public)")
        }

        guard !unresolvedClientIPs.isEmpty else { return }

        Logger.api.info("Top clients unresolved after all Pi-hole hostname sources: \(unresolvedClientIPs.joined(separator: ", "), privacy: .public)")
    }

    private static func logHostnameSource(
        _ source: String,
        hostnamesByIPAddress: [String: HostnameResolution]
    ) {
        guard !hostnamesByIPAddress.isEmpty else {
            Logger.api.info("Pi-hole hostname source \(source, privacy: .public) mappings: none")
            return
        }

        let mappings = hostnamesByIPAddress
            .sorted { $0.key < $1.key }
            .prefix(20)
            .map { ip, resolution in "\(ip)=\(resolution.name)" }
            .joined(separator: ", ")

        Logger.api.info("Pi-hole hostname source \(source, privacy: .public) mappings: \(mappings, privacy: .public)")
    }

    private static func normalizedIPAddress(_ ip: String) -> String? {
        let trimmedIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        guard !trimmedIP.isEmpty else { return nil }

        return trimmedIP.lowercased()
    }

    private static func normalizedMACAddress(_ mac: String?) -> String? {
        let trimmedMAC = mac?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedMAC, !trimmedMAC.isEmpty else { return nil }

        let parts = trimmedMAC.split(separator: ":")
        let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard parts.count == 6,
              parts.allSatisfy({ part in
                  part.count == 2 && part.unicodeScalars.allSatisfy { hexDigits.contains($0) }
              })
        else {
            return nil
        }

        return parts.map { $0.lowercased() }.joined(separator: ":")
    }

    private static func normalizedHostname(_ name: String?, fallbackIP: String? = nil) -> String? {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedName, !trimmedName.isEmpty else { return nil }
        if let fallbackIP, normalizedIPAddress(trimmedName) == normalizedIPAddress(fallbackIP) { return nil }

        return trimmedName
    }

    private static func splitCommaSeparatedList(_ value: String?) -> [String] {
        value?.split(separator: ",").compactMap { item in
            let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedItem.isEmpty ? nil : trimmedItem
        } ?? []
    }

    private static func queryActivity(from queries: [PiHoleQuery], startDate: Date, endDate: Date) -> [Int] {
        let bucketCount = 60
        let duration = max(endDate.timeIntervalSince(startDate), 1)
        var buckets = Array(repeating: 0, count: bucketCount)

        queries.forEach { query in
            guard query.time >= startDate.timeIntervalSince1970, query.time <= endDate.timeIntervalSince1970 else { return }

            let offset = query.time - startDate.timeIntervalSince1970
            let index = min(max(Int(offset / duration * Double(bucketCount)), 0), bucketCount - 1)
            buckets[index] += 1
        }

        return buckets
    }
}

private enum LocalHostnameResolver {
    static func resolve(ipAddress: String) async -> String? {
        await Task.detached(priority: .utility) {
            resolveSynchronously(ipAddress: ipAddress)
        }.value
    }

    private static func resolveSynchronously(ipAddress: String) -> String? {
        let address = sanitizedIPAddress(ipAddress)
        guard !address.isEmpty else { return nil }

        if let hostname = resolveIPv4(address) {
            return hostname
        }

        return resolveIPv6(address)
    }

    private static func resolveIPv4(_ address: String) -> String? {
        var ipv4Address = in_addr()
        let parseResult = address.withCString { inet_pton(AF_INET, $0, &ipv4Address) }
        guard parseResult == 1 else { return nil }

        var socketAddress = sockaddr_in()
        socketAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        socketAddress.sin_family = sa_family_t(AF_INET)
        socketAddress.sin_addr = ipv4Address

        return withUnsafePointer(to: &socketAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketPointer in
                hostname(from: socketPointer, length: socklen_t(MemoryLayout<sockaddr_in>.size), address: address)
            }
        }
    }

    private static func resolveIPv6(_ address: String) -> String? {
        var ipv6Address = in6_addr()
        let parseResult = address.withCString { inet_pton(AF_INET6, $0, &ipv6Address) }
        guard parseResult == 1 else { return nil }

        var socketAddress = sockaddr_in6()
        socketAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        socketAddress.sin6_family = sa_family_t(AF_INET6)
        socketAddress.sin6_addr = ipv6Address

        return withUnsafePointer(to: &socketAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketPointer in
                hostname(from: socketPointer, length: socklen_t(MemoryLayout<sockaddr_in6>.size), address: address)
            }
        }
    }

    private static func hostname(from socketAddress: UnsafePointer<sockaddr>, length: socklen_t, address: String) -> String? {
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            socketAddress,
            length,
            &hostBuffer,
            socklen_t(hostBuffer.count),
            nil,
            0,
            NI_NAMEREQD
        )

        guard result == 0 else {
            Logger.api.info("Local reverse DNS lookup failed for \(address, privacy: .public): \(String(cString: gai_strerror(result)), privacy: .public)")
            return nil
        }

        let hostname = String(cString: hostBuffer)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))

        guard !hostname.isEmpty, hostname.lowercased() != address.lowercased() else { return nil }

        return hostname
    }

    private static func sanitizedIPAddress(_ ipAddress: String) -> String {
        let trimmedAddress = ipAddress
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))

        return trimmedAddress.split(separator: "%", maxSplits: 1).first.map(String.init) ?? trimmedAddress
    }
}
