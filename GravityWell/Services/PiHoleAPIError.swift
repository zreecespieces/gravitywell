import Foundation

enum PiHoleAPIError: LocalizedError, Equatable, Sendable {
    case invalidBaseURL
    case missingCredential
    case invalidResponse
    case authenticationFailed(String?)
    case twoFactorUnsupported
    case tlsError
    case offline
    case apiError(statusCode: Int, message: String?)
    case decodingFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            "Enter a valid Pi-hole URL."
        case .missingCredential:
            "Enter a Pi-hole password or application password."
        case .invalidResponse:
            "Pi-hole returned an invalid response."
        case .authenticationFailed:
            "Authentication failed. Check your Pi-hole API credential."
        case .twoFactorUnsupported:
            "This Pi-hole account requires 2FA. GravityWell MVP supports application passwords or standard authentication only."
        case .tlsError:
            "TLS certificate rejected. Use a trusted HTTPS certificate or enable self-signed certificates in settings."
        case .offline:
            "Could not reach Pi-hole. Check that the URL is correct and your Mac can access the server."
        case .apiError(_, let message):
            message ?? "Pi-hole returned an API error."
        case .decodingFailed:
            "Pi-hole returned data GravityWell could not read."
        case .unknown(let message):
            message
        }
    }
}
