import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let keychain: KeychainService
    @ObservationIgnored private let launchAtLoginService: LaunchAtLoginService
    @ObservationIgnored private let pollingService = PollingService()
    @ObservationIgnored private var activeProvider: (any MonitoringProvider)?
    @ObservationIgnored private var cachedCredential: String?

    var baseURLString: String {
        didSet {
            defaults.set(baseURLString, forKey: DefaultsKey.baseURLString)
            resetActiveProvider()
        }
    }

    var pollInterval: PollInterval {
        didSet {
            defaults.set(pollInterval.rawValue, forKey: DefaultsKey.pollInterval)
            restartPollingIfConfigured()
        }
    }

    var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: DefaultsKey.menuBarDisplayMode) }
    }

    var selfSignedCertificatesAllowed: Bool {
        didSet {
            defaults.set(selfSignedCertificatesAllowed, forKey: DefaultsKey.selfSignedCertificatesAllowed)
            resetActiveProvider()
            restartPollingIfConfigured()
        }
    }

    var launchAtLoginEnabled: Bool {
        didSet {
            defaults.set(launchAtLoginEnabled, forKey: DefaultsKey.launchAtLoginEnabled)

            do {
                try launchAtLoginService.setEnabled(launchAtLoginEnabled)
                launchAtLoginErrorMessage = nil
            } catch {
                launchAtLoginErrorMessage = error.localizedDescription
            }
        }
    }

    var hasStoredCredential: Bool
    var snapshot: MonitoringSnapshot?
    var displayStatus: MonitoringServiceStatus = .unknownError
    var errorMessage: String?
    var launchAtLoginErrorMessage: String?
    var blockingDisabledUntil: Date?
    var controlFeedback: MonitoringControlFeedback?
    var isRefreshing = false
    var isControlInFlight = false

    var isConfigured: Bool {
        normalizedBaseURL != nil && hasStoredCredential
    }

    var normalizedBaseURL: URL? {
        Self.normalizedURL(from: baseURLString)
    }

    init(
        defaults: UserDefaults = .standard,
        keychain: KeychainService = KeychainService(),
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.defaults = defaults
        self.keychain = keychain
        self.launchAtLoginService = launchAtLoginService

        baseURLString = defaults.string(forKey: DefaultsKey.baseURLString) ?? ""

        let storedPollInterval = defaults.integer(forKey: DefaultsKey.pollInterval)
        pollInterval = PollInterval(rawValue: storedPollInterval) ?? .thirtySeconds

        let storedDisplayMode = defaults.string(forKey: DefaultsKey.menuBarDisplayMode)
        menuBarDisplayMode = storedDisplayMode.flatMap(MenuBarDisplayMode.init(rawValue:)) ?? .blockPercentage

        selfSignedCertificatesAllowed = defaults.bool(forKey: DefaultsKey.selfSignedCertificatesAllowed)
        launchAtLoginEnabled = launchAtLoginService.isEnabled
        hasStoredCredential = keychain.hasCredential()

        if hasStoredCredential && normalizedBaseURL != nil {
            Task { @MainActor [weak self] in
                self?.startPollingIfConfigured()
            }
        }
    }

    func saveConnection(credentialDraft: String) async throws {
        guard let normalizedBaseURL else {
            throw AppSettingsError.invalidBaseURL
        }

        baseURLString = Self.removingTrailingSlashes(from: normalizedBaseURL.absoluteString)

        let trimmedCredential = credentialDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCredential.isEmpty {
            try await keychain.saveCredential(
                trimmedCredential,
                reason: "Use Touch ID to save your Pi-hole password in GravityWell."
            )
            cachedCredential = trimmedCredential
            hasStoredCredential = true
        }

        if !hasStoredCredential {
            throw AppSettingsError.missingCredential
        }

        resetActiveProvider()
        startPollingIfConfigured()
    }

    func deleteCredential() throws {
        try keychain.deleteCredential()
        cachedCredential = nil
        hasStoredCredential = false
        stopPolling()
    }

    func storedCredential() async throws -> String? {
        if let cachedCredential {
            return cachedCredential
        }

        let credential = try await keychain.readCredential(reason: "Use Touch ID to unlock your Pi-hole password in GravityWell.")
        cachedCredential = credential
        return credential
    }

    func makePiHoleAPIClient(credentialOverride: String? = nil) async throws -> PiHoleAPIClient {
        guard let normalizedBaseURL else {
            throw PiHoleAPIError.invalidBaseURL
        }

        let trimmedOverride = credentialOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        let credential: String?
        if let trimmedOverride, !trimmedOverride.isEmpty {
            credential = trimmedOverride
        } else if let cachedCredential {
            credential = cachedCredential
        } else {
            credential = try await keychain.readCredential(reason: "Use Touch ID to unlock your Pi-hole password in GravityWell.")
            cachedCredential = credential
        }

        guard let credential, !credential.isEmpty else {
            throw PiHoleAPIError.missingCredential
        }

        return PiHoleAPIClient(
            baseURL: normalizedBaseURL,
            password: credential,
            allowsSelfSignedCertificates: selfSignedCertificatesAllowed
        )
    }

    func makeActiveMonitoringProvider(credentialOverride: String? = nil) async throws -> any MonitoringProvider {
        PiHoleProvider(client: try await makePiHoleAPIClient(credentialOverride: credentialOverride))
    }

    func startPollingIfConfigured() {
        guard isConfigured else {
            stopPolling()
            return
        }

        pollingService.start(interval: TimeInterval(pollInterval.rawValue)) { [weak self] in
            await self?.refreshSnapshot()
        }
    }

    func stopPolling() {
        pollingService.stop()
        resetActiveProvider()
        snapshot = nil
        blockingDisabledUntil = nil
        controlFeedback = nil
        displayStatus = .unknownError
        errorMessage = nil
        isRefreshing = false
        isControlInFlight = false
    }

    func refreshSnapshot() async {
        guard isConfigured else {
            stopPolling()
            return
        }

        guard !isRefreshing else { return }

        isRefreshing = true

        do {
            let provider = try await configuredMonitoringProvider()
            let nextSnapshot = try await provider.fetchSnapshot()
            snapshot = nextSnapshot
            displayStatus = effectiveStatus(for: nextSnapshot.status)
            errorMessage = nil
        } catch {
            applyMonitoringError(error)
        }

        isRefreshing = false
    }

    func performControl(_ control: MonitoringControl) async {
        guard isConfigured, !isControlInFlight else { return }

        isControlInFlight = true
        controlFeedback = nil

        do {
            let provider = try await configuredMonitoringProvider()
            try await provider.performControl(control)
            await refreshSnapshot()
            applySuccessfulControl(control)
        } catch {
            controlFeedback = .failed(error.localizedDescription)
            applyMonitoringError(error)
        }

        isControlInFlight = false
    }

    func openDashboard() {
        guard var components = normalizedBaseURL.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else { return }

        components.path = "/admin"
        guard let url = components.url else { return }

        NSWorkspace.shared.open(url)
    }

    func menuBarStatusText() -> String {
        guard isConfigured else { return "Setup" }
        if displayStatus == .blockingDisabled {
            return "Disabled"
        }

        guard let snapshot else {
            return errorMessage == nil ? "Loading" : displayStatus.title
        }

        switch menuBarDisplayMode {
        case .blockPercentage:
            return Formatters.percent(snapshot.percentBlocked)
        case .blockedQueries:
            return Formatters.compactInteger(snapshot.blockedQueries)
        case .totalQueries:
            return Formatters.compactInteger(snapshot.totalQueries)
        case .iconOnly:
            return ""
        }
    }

    private func configuredMonitoringProvider() async throws -> any MonitoringProvider {
        if let activeProvider {
            return activeProvider
        }

        let provider = try await makeActiveMonitoringProvider()
        activeProvider = provider
        return provider
    }

    private func resetActiveProvider() {
        activeProvider = nil
    }

    private func applySuccessfulControl(_ control: MonitoringControl) {
        switch control {
        case .disableBlocking(let seconds):
            let disabledUntil = Date().addingTimeInterval(TimeInterval(seconds))
            blockingDisabledUntil = disabledUntil
            controlFeedback = .blockingDisabled(until: disabledUntil)
            displayStatus = .blockingDisabled
        case .enableBlocking:
            blockingDisabledUntil = nil
            controlFeedback = .blockingEnabled
            displayStatus = snapshot?.status ?? .online
        }
    }

    private func effectiveStatus(for status: MonitoringServiceStatus) -> MonitoringServiceStatus {
        if let blockingDisabledUntil {
            if blockingDisabledUntil > Date() {
                return .blockingDisabled
            }

            self.blockingDisabledUntil = nil
        }

        return status
    }

    private func restartPollingIfConfigured() {
        guard isConfigured else { return }
        startPollingIfConfigured()
    }

    private func applyMonitoringError(_ error: Error) {
        if let error = error as? MonitoringProviderError {
            displayStatus = error.status
            errorMessage = error.localizedDescription
            return
        }

        displayStatus = .unknownError
        errorMessage = error.localizedDescription
    }

    private static func normalizedURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme: String
        if trimmed.localizedCaseInsensitiveContains("://") {
            withScheme = trimmed
        } else {
            withScheme = "https://\(trimmed)"
        }

        guard var components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              components.host != nil
        else {
            return nil
        }

        components.scheme = scheme

        return components.url
    }

    private static func removingTrailingSlashes(from input: String) -> String {
        var output = input
        while output.last == "/" {
            output.removeLast()
        }
        return output
    }
}

enum MonitoringControlFeedback: Equatable {
    case blockingDisabled(until: Date)
    case blockingEnabled
    case failed(String)
}

enum AppSettingsError: LocalizedError {
    case invalidBaseURL
    case missingCredential

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            "Enter a valid Pi-hole URL. HTTPS is recommended."
        case .missingCredential:
            "Enter a Pi-hole password or application password."
        }
    }
}

private enum DefaultsKey {
    static let baseURLString = "baseURLString"
    static let pollInterval = "pollInterval"
    static let menuBarDisplayMode = "menuBarDisplayMode"
    static let selfSignedCertificatesAllowed = "selfSignedCertificatesAllowed"
    static let launchAtLoginEnabled = "launchAtLoginEnabled"
}
