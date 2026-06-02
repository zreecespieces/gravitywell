import Foundation

enum MonitoringProviderError: LocalizedError, Equatable, Sendable {
    case offline
    case authenticationFailed(String?)
    case tlsError
    case apiError(String?)
    case unknown(String)

    var status: MonitoringServiceStatus {
        switch self {
        case .offline:
            .offline
        case .authenticationFailed:
            .authenticationFailed
        case .tlsError:
            .tlsError
        case .apiError:
            .apiError
        case .unknown:
            .unknownError
        }
    }

    var errorDescription: String? {
        switch self {
        case .offline:
            "Could not reach Pi-hole. Check that the URL is correct and your Mac can access the server."
        case .authenticationFailed(let message):
            message ?? "Authentication failed. Check your Pi-hole API credential."
        case .tlsError:
            "TLS certificate rejected. Use a trusted HTTPS certificate or enable self-signed certificates in settings."
        case .apiError(let message):
            message ?? "Pi-hole returned an API error."
        case .unknown(let message):
            message
        }
    }
}
