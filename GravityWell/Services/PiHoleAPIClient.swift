import Foundation
import OSLog

actor PiHoleAPIClient: PiHoleAPIProviding {
    private let baseURL: URL
    private let password: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private var sid: String?
    private var hasAuthenticated = false
    private var authenticationTask: Task<String?, Error>?

    init(baseURL: URL, password: String, allowsSelfSignedCertificates: Bool) {
        self.baseURL = baseURL
        self.password = password

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = [
            "User-Agent": "GravityWell/0.1.0"
        ]

        let trustService = NetworkTrustService(allowsSelfSignedCertificates: allowsSelfSignedCertificates)
        session = URLSession(configuration: configuration, delegate: trustService, delegateQueue: nil)

        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    func authenticate() async throws {
        try await authenticateIfNeeded()
    }

    private func authenticateIfNeeded(force: Bool = false) async throws {
        if !force, hasAuthenticated {
            return
        }

        if let authenticationTask {
            sid = try await authenticationTask.value
            hasAuthenticated = true
            return
        }

        let task = Task { try await self.performAuthentication() }
        authenticationTask = task

        do {
            sid = try await task.value
            hasAuthenticated = true
            authenticationTask = nil
        } catch {
            authenticationTask = nil
            throw error
        }
    }

    private func performAuthentication() async throws -> String? {
        let body = AuthRequest(password: password)
        let response: AuthResponse = try await send(
            path: "/auth",
            method: "POST",
            body: body,
            requiresAuthentication: false,
            retryOnUnauthorized: false
        )

        guard response.session.valid else {
            if response.session.totp {
                throw PiHoleAPIError.twoFactorUnsupported
            }

            throw PiHoleAPIError.authenticationFailed(response.session.message)
        }

        return response.session.sid
    }

    func fetchSummary() async throws -> PiHoleSummary {
        try await authenticatedRequest(path: "/stats/summary")
    }

    func fetchTopBlockedDomains() async throws -> [TopDomain] {
        let response: TopDomainsResponse = try await authenticatedRequest(
            path: "/stats/top_domains",
            queryItems: [
                URLQueryItem(name: "blocked", value: "true"),
                URLQueryItem(name: "count", value: "10")
            ]
        )

        return response.domains
    }

    func fetchTopClients() async throws -> [TopClient] {
        let response: TopClientsResponse = try await authenticatedRequest(
            path: "/stats/top_clients",
            queryItems: [
                URLQueryItem(name: "blocked", value: "false"),
                URLQueryItem(name: "count", value: "10")
            ]
        )

        return response.clients
    }

    func fetchNetworkDevices() async throws -> [NetworkDevice] {
        let response: NetworkDevicesResponse = try await authenticatedRequest(
            path: "/network/devices",
            queryItems: [
                URLQueryItem(name: "max_devices", value: "100"),
                URLQueryItem(name: "max_addresses", value: "10")
            ]
        )

        return response.devices
    }

    func fetchClients() async throws -> [PiHoleManagedClient] {
        let response: PiHoleManagedClientsResponse = try await authenticatedRequest(path: "/clients")

        return response.clients
    }

    func fetchClientSuggestions() async throws -> [PiHoleClientSuggestion] {
        let response: PiHoleClientSuggestionsResponse = try await authenticatedRequest(path: "/clients/_suggestions")

        return response.clients
    }

    func fetchDHCPLeases() async throws -> [PiHoleDHCPLease] {
        let response: PiHoleDHCPLeasesResponse = try await authenticatedRequest(path: "/dhcp/leases")

        return response.leases
    }

    func fetchQueries(from startDate: Date, until endDate: Date, length: Int) async throws -> [PiHoleQuery] {
        let response: PiHoleQueriesResponse = try await authenticatedRequest(
            path: "/queries",
            queryItems: [
                URLQueryItem(name: "from", value: String(startDate.timeIntervalSince1970)),
                URLQueryItem(name: "until", value: String(endDate.timeIntervalSince1970)),
                URLQueryItem(name: "length", value: String(length))
            ]
        )

        return response.queries
    }

    func fetchQueries(forClientIP ip: String, length: Int) async throws -> [PiHoleQuery] {
        let response: PiHoleQueriesResponse = try await authenticatedRequest(
            path: "/queries",
            queryItems: [
                URLQueryItem(name: "client_ip", value: ip),
                URLQueryItem(name: "length", value: String(length))
            ]
        )

        return response.queries
    }

    func disableBlocking(seconds: Int) async throws {
        let body = BlockingRequest(blocking: false, timer: seconds)
        let _: PiHoleBlockingStatus = try await authenticatedRequest(path: "/dns/blocking", method: "POST", body: body)
    }

    func enableBlocking() async throws {
        let body = BlockingRequest(blocking: true, timer: nil)
        let _: PiHoleBlockingStatus = try await authenticatedRequest(path: "/dns/blocking", method: "POST", body: body)
    }

    private func authenticatedRequest<Response: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: (some Encodable)? = Optional<EmptyBody>.none
    ) async throws -> Response {
        try await authenticateIfNeeded()

        do {
            return try await send(
                path: path,
                method: method,
                queryItems: queryItems,
                body: body,
                requiresAuthentication: true,
                retryOnUnauthorized: true
            )
        } catch PiHoleAPIError.authenticationFailed {
            sid = nil
            hasAuthenticated = false
            try await authenticateIfNeeded(force: true)

            return try await send(
                path: path,
                method: method,
                queryItems: queryItems,
                body: body,
                requiresAuthentication: true,
                retryOnUnauthorized: false
            )
        }
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body?,
        requiresAuthentication: Bool,
        retryOnUnauthorized: Bool
    ) async throws -> Response {
        var request = try makeRequest(path: path, method: method, queryItems: queryItems)

        if requiresAuthentication, let sid {
            request.setValue(sid, forHTTPHeaderField: "X-FTL-SID")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw PiHoleAPIError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PiHoleAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                Logger.api.warning("Pi-hole decode failed for \(path, privacy: .public): \(String(describing: error), privacy: .public)")
                throw PiHoleAPIError.decodingFailed
            }
        case 401:
            let message = decodeAPIErrorMessage(from: data)
            if retryOnUnauthorized {
                throw PiHoleAPIError.authenticationFailed(message)
            } else {
                throw PiHoleAPIError.authenticationFailed(message)
            }
        case 400:
            let message = decodeAPIErrorMessage(from: data)
            if path == "/auth", message?.localizedCaseInsensitiveContains("2FA") == true {
                throw PiHoleAPIError.twoFactorUnsupported
            }

            throw PiHoleAPIError.apiError(statusCode: httpResponse.statusCode, message: message)
        case 402...599:
            throw PiHoleAPIError.apiError(
                statusCode: httpResponse.statusCode,
                message: decodeAPIErrorMessage(from: data)
            )
        default:
            throw PiHoleAPIError.invalidResponse
        }
    }

    private func makeRequest(path: String, method: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        let apiBaseURL = Self.apiBaseURL(from: baseURL)
        let url = apiBaseURL.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PiHoleAPIError.invalidBaseURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let requestURL = components.url else {
            throw PiHoleAPIError.invalidBaseURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return request
    }

    private static func apiBaseURL(from baseURL: URL) -> URL {
        let path = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path == "api" || path.hasSuffix("/api") {
            return baseURL
        }

        return baseURL.appending(path: "api")
    }

    private func decodeAPIErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        return try? decoder.decode(APIErrorResponse.self, from: data).error.message
    }

    private func mapURLError(_ error: URLError) -> PiHoleAPIError {
        switch error.code {
        case .serverCertificateHasBadDate,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid,
             .secureConnectionFailed,
             .clientCertificateRejected,
             .clientCertificateRequired:
            return .tlsError
        case .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .networkConnectionLost,
             .notConnectedToInternet,
             .timedOut:
            return .offline
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

private struct AuthRequest: Encodable, Sendable {
    let password: String
}

private struct AuthResponse: Decodable, Sendable {
    let session: AuthSession
}

private struct AuthSession: Decodable, Sendable {
    let valid: Bool
    let totp: Bool
    let sid: String?
    let validity: Int
    let message: String?
}

private struct BlockingRequest: Encodable, Sendable {
    let blocking: Bool
    let timer: Int?
}

private struct EmptyBody: Encodable, Sendable {}

private struct APIErrorResponse: Decodable, Sendable {
    let error: APIError
}

private struct APIError: Decodable, Sendable {
    let key: String
    let message: String
}
