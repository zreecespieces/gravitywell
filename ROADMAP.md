# GravityWell Build Plan Roadmap

GravityWell is a native macOS menu bar companion for Pi-hole. The MVP focuses on a clean, secure, local-first Pi-hole monitoring experience while leaving enough architectural room for future homelab integrations.

## Product Decisions

- Product name: GravityWell
- Repository name: GravityWell
- Xcode project name: GravityWell.xcodeproj
- Swift module name: GravityWell
- Deployment target: macOS 14.0+
- App type: native macOS SwiftUI menu bar app
- Primary integration: Pi-hole v6+
- Authentication MVP: standard Pi-hole password or application password
- 2FA support: post-MVP
- Credential storage: macOS Keychain only
- Non-sensitive settings: UserDefaults / AppStorage
- Telemetry: none
- External network requests: only the configured Pi-hole instance

## Target Repository Structure

```text
GravityWell/
├── GravityWell.xcodeproj
├── GravityWell/
│   ├── App/
│   │   ├── GravityWellApp.swift
│   │   └── AppState.swift
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   ├── DashboardPopoverView.swift
│   │   ├── SettingsView.swift
│   │   ├── StatsCardView.swift
│   │   ├── TopListView.swift
│   │   └── ErrorStateView.swift
│   ├── Providers/
│   │   ├── MonitoringProvider.swift
│   │   ├── MonitoringSnapshot.swift
│   │   ├── MonitoringControl.swift
│   │   └── PiHoleProvider.swift
│   ├── Services/
│   │   ├── PiHoleAPIClient.swift
│   │   ├── KeychainService.swift
│   │   ├── PollingService.swift
│   │   ├── LaunchAtLoginService.swift
│   │   └── NetworkTrustService.swift
│   ├── Models/
│   │   ├── PiHoleSummary.swift
│   │   ├── TopDomain.swift
│   │   ├── TopClient.swift
│   │   ├── PiHoleStatus.swift
│   │   ├── AppSettings.swift
│   │   ├── PollInterval.swift
│   │   └── MenuBarDisplayMode.swift
│   ├── Utilities/
│   │   ├── Formatters.swift
│   │   ├── Logger.swift
│   │   └── Constants.swift
│   └── Assets.xcassets/
├── GravityWellTests/
├── GravityWellUITests/
└── README.md
```

## Architecture Direction

GravityWell should be built as a small monitoring platform rather than a Pi-hole-only app, but the MVP should avoid unnecessary multi-provider UI complexity.

The application should have one active provider for MVP: Pi-hole. The UI should consume normalized monitoring data through a provider boundary, not raw Pi-hole API response models.

```swift
protocol MonitoringProvider {
    var name: String { get }

    func authenticate() async throws
    func fetchSnapshot() async throws -> MonitoringSnapshot
    func performControl(_ control: MonitoringControl) async throws
}
```

Pi-hole-specific networking remains isolated behind a Pi-hole API protocol.

```swift
protocol PiHoleAPIProviding {
    func authenticate() async throws
    func fetchSummary() async throws -> PiHoleSummary
    func fetchTopBlockedDomains() async throws -> [TopDomain]
    func fetchTopClients() async throws -> [TopClient]
    func disableBlocking(seconds: Int) async throws
    func enableBlocking() async throws
}
```

## MVP Acceptance Criteria

The MVP is complete when all of the following are true:

- User can enter a Pi-hole base URL.
- User can enter a Pi-hole password or application password.
- Credential is stored securely in macOS Keychain.
- Base URL and non-sensitive settings survive app restart.
- App verifies the Pi-hole connection successfully.
- Menu bar item displays live Pi-hole stats.
- Popover displays queries today, blocked today, percent blocked, clients seen, top blocked domains, top clients, and last updated time.
- User can manually refresh data.
- User can open the Pi-hole dashboard from GravityWell.
- User can disable blocking for 5, 30, or 60 minutes.
- User can re-enable blocking.
- App gracefully reports offline, authentication failed, TLS error, API error, and unknown error states.
- App works with a Pi-hole instance reachable at a Tailscale HTTPS URL.
- App makes no external requests except to the configured Pi-hole instance.
- App does not log credentials, SIDs, or secret-bearing URLs.

## Phase 0: Project Initialization

Goal: create a clean, native macOS app foundation.

Tasks:

- Create a new Xcode macOS SwiftUI app named GravityWell.
- Set deployment target to macOS 14.0.
- Configure the app as a menu bar-first app using MenuBarExtra.
- Disable any unnecessary document-based app behavior.
- Add app groups or entitlements only if needed later.
- Create the initial folder structure under the GravityWell source directory.
- Add a basic README.md with project description and local-first security stance.
- Add ROADMAP.md to document the build plan.

Implementation notes:

- Use SwiftUI and Observation for state management.
- Avoid adding third-party dependencies during MVP unless there is a strong need.
- Prefer simple native APIs over package dependencies.
- Keep the first app launch simple: if unconfigured, show settings/setup content in the popover.

Deliverables:

- GravityWell.xcodeproj exists.
- App builds and launches.
- Menu bar item appears.
- Popover opens when clicking the menu bar item.
- Basic README exists.

Verification:

- Run the app from Xcode.
- Confirm no dock icon is shown if the app is intended to behave purely as a menu bar app.
- Confirm the menu bar item remains available after closing settings/popover windows.

## Phase 1: App Settings And Secure Storage

Goal: allow the user to configure Pi-hole connection details securely.

Tasks:

- Create AppSettings model for non-sensitive settings.
- Store base URL in UserDefaults or AppStorage.
- Store poll interval in UserDefaults or AppStorage.
- Store menu bar display mode in UserDefaults or AppStorage.
- Store compact mode in UserDefaults or AppStorage.
- Store self-signed certificate allowance in UserDefaults or AppStorage.
- Build KeychainService for saving, reading, and deleting the Pi-hole credential.
- Build SettingsView with fields for base URL and API credential.
- Add poll interval picker with 15 seconds, 30 seconds, 60 seconds, and 5 minutes.
- Add menu bar display mode picker with block percentage, blocked queries, total queries, and icon only.
- Add compact mode toggle.
- Add self-signed certificate toggle, default off.
- Add launch-at-login toggle placeholder or disabled control until Phase 7.

Implementation notes:

- Never store the Pi-hole credential in UserDefaults.
- The credential field should not display the stored credential after relaunch.
- Use a save/test flow that validates settings before marking the app configured.
- Normalize base URL input by trimming whitespace and removing trailing slashes.
- Require a valid URL scheme, ideally https by default.
- Allow http only if explicitly accepted as a private-network use case.

Deliverables:

- Settings screen exists.
- User can enter and save base URL.
- User can enter and save credential to Keychain.
- User can change poll interval.
- User can change menu bar display mode.
- User can enable optional compact mode.

Verification:

- Save settings, quit app, relaunch, and confirm non-sensitive settings are restored.
- Confirm credential can be retrieved from Keychain by app code.
- Confirm credential is not visible in UserDefaults.
- Confirm deleting/replacing credential works.

## Phase 2: Pi-hole v6 API Client

Goal: implement Pi-hole v6 authentication and data fetching behind an isolated API client.

Tasks:

- Create PiHoleAPIProviding protocol.
- Create PiHoleAPIClient implementation.
- Implement POST /api/auth using password/application password payload.
- Store returned SID in memory only.
- Send SID using X-FTL-SID header for authenticated requests.
- Avoid putting SID or secrets in query strings.
- Add session refresh behavior when 401 is returned.
- Implement standard API error decoding.
- Map HTTP status codes to typed client errors.
- Add TLS error detection.
- Add optional self-signed certificate handling only when enabled in settings.
- Discover exact Pi-hole v6 summary/top-list endpoints from the local Pi-hole /api/docs or generated API docs.
- Implement fetchSummary.
- Implement fetchTopBlockedDomains.
- Implement fetchTopClients.
- Implement disableBlocking(seconds:).
- Implement enableBlocking.

Implementation notes:

- Pi-hole v6 uses session-based authentication, not static token authentication.
- Users should use an application password where possible.
- 2FA is explicitly out of scope for MVP.
- The API client should own endpoint paths and request construction.
- UI code should never construct Pi-hole API URLs.
- Decode responses into Pi-hole-specific models first, then map them into normalized provider snapshots later.

Deliverables:

- PiHoleAPIClient authenticates successfully against a configured Pi-hole.
- PiHoleAPIClient fetches summary stats.
- PiHoleAPIClient fetches top blocked domains.
- PiHoleAPIClient fetches top clients.
- PiHoleAPIClient can disable blocking for a specified duration.
- PiHoleAPIClient can re-enable blocking.

Verification:

- Test against a real Pi-hole v6 instance if available.
- Test with bad URL.
- Test with bad credential.
- Test with unreachable host.
- Test with invalid TLS certificate and self-signed disabled.
- Test with invalid TLS certificate and self-signed enabled.
- Confirm logs never include credential or SID.

## Phase 3: Provider Abstraction And Snapshot Mapping

Goal: make the UI depend on normalized monitoring data instead of Pi-hole API shapes.

Tasks:

- Create MonitoringProvider protocol.
- Create MonitoringSnapshot model.
- Create MonitoringControl enum.
- Create normalized service status enum.
- Create PiHoleProvider that wraps PiHoleAPIProviding.
- Map PiHoleSummary, TopDomain, and TopClient into MonitoringSnapshot.
- Map controls to Pi-hole actions.
- Add provider-level error mapping for user-facing app state.
- Keep one active provider for MVP.

Implementation notes:

- Do not build multiple-provider settings UI in MVP.
- Do not create generic dashboards before a second provider exists.
- Keep the abstraction thin and practical.
- The app should be able to swap PiHoleProvider for another MonitoringProvider in the future without rewriting the core dashboard.

Deliverables:

- UI-facing data model exists.
- Pi-hole data maps into normalized snapshot data.
- Dashboard can be built without importing Pi-hole-specific API response models.

Verification:

- Add unit tests for mapping Pi-hole models to MonitoringSnapshot.
- Confirm provider errors map to expected user-facing states.

## Phase 4: Polling And App State

Goal: keep the menu bar and dashboard updated with live data.

Tasks:

- Create PollingService.
- Poll active MonitoringProvider at configured interval.
- Default poll interval to 30 seconds.
- Support 15 seconds, 30 seconds, 60 seconds, and 5 minutes.
- Pause polling when app is not configured.
- Pause polling when Mac is asleep if system notifications are available.
- Resume polling after wake.
- Retry polling when network connectivity returns.
- Add manual refresh that bypasses timer delay.
- Track last successful refresh time.
- Track current loading/error/success state.
- Avoid overlapping poll requests.
- Cancel in-flight polling tasks when settings change.

Implementation notes:

- Use async/await and Task cancellation carefully.
- Keep polling state on the main actor only where UI updates are required.
- Do not block the main thread for network work.
- If a poll fails, keep the previous successful snapshot visible while showing current error state.

Deliverables:

- App automatically refreshes data at selected interval.
- Manual refresh works.
- Polling stops when configuration is invalid.
- Polling resumes after settings are fixed.
- Last updated time is shown.

Verification:

- Test default 30-second polling.
- Change poll interval and confirm timer updates.
- Disconnect network or use unreachable URL and confirm offline state.
- Restore network or valid URL and confirm recovery.
- Confirm rapid manual refresh clicks do not create overlapping request storms.

## Phase 5: Menu Bar Item And Dashboard Popover

Goal: deliver the primary user experience for quick Pi-hole visibility.

Tasks:

- Build MenuBarView.
- Add display mode for block percentage today.
- Add display mode for blocked queries today.
- Add display mode for total queries today.
- Add display mode for simple icon only.
- Add offline/auth/TLS/API visual indicators.
- Build DashboardPopoverView.
- Add title: GravityWell.
- Add status row.
- Add queries today.
- Add blocked today.
- Add percent blocked.
- Add clients seen.
- Add top blocked domains list.
- Add top clients list.
- Add last updated row.
- Add compact mode layout variations.
- Add setup prompt when app is unconfigured.
- Add concise error messages for failure states.

Implementation notes:

- Keep the UI native and minimal.
- Use system materials where appropriate.
- Use subtle sci-fi/gravity well identity without loud styling.
- Use monospaced digits for numeric stats.
- Use a circular progress ring for block percentage if it remains visually clean at popover size.
- Ensure dark mode looks intentional.
- Ensure the popover is usable on small laptop screens.

Deliverables:

- Menu bar item shows current selected display mode.
- Dashboard popover shows live snapshot data.
- Dashboard handles loading, unconfigured, success, and error states.
- Dashboard remains readable in light and dark mode.

Verification:

- Test all display modes.
- Test empty top-domain and top-client lists.
- Test very long domain names.
- Test very long client names.
- Test high query counts.
- Test offline state.
- Test authentication failed state.
- Test TLS error state.

## Phase 6: Quick Controls

Goal: let the user perform common Pi-hole control actions from the popover.

Tasks:

- Add Refresh button.
- Add Open Pi-hole Dashboard button.
- Add Disable Blocking for 5 Minutes button.
- Add Disable Blocking for 30 Minutes button.
- Add Disable Blocking for 1 Hour button.
- Add Re-enable Blocking button.
- Add confirmation or clear pending state for disable/enable actions.
- Refresh snapshot after each successful control action.
- Show concise failure feedback when a control action fails.

Implementation notes:

- Open dashboard using the configured base URL.
- Do not append secrets or auth state to dashboard URL.
- Keep controls disabled while app is unconfigured.
- Keep controls disabled during in-flight control action to prevent duplicate requests.
- Consider showing active blocking state if the API exposes it reliably.

Deliverables:

- User can refresh stats manually.
- User can open configured Pi-hole dashboard.
- User can disable blocking for 5, 30, or 60 minutes.
- User can re-enable blocking.
- UI updates after successful control actions.

Verification:

- Test each disable duration against a real Pi-hole instance.
- Test re-enable after disable.
- Test action failures with bad credential.
- Test action failures with unreachable Pi-hole.
- Confirm dashboard opens expected URL.

## Phase 7: macOS System Integrations

Goal: make GravityWell feel like a real macOS utility app.

Tasks:

- Implement LaunchAtLoginService.
- Add launch-at-login toggle to SettingsView.
- Configure LSUIElement or equivalent menu bar app behavior if appropriate.
- Add app icon.
- Add menu commands for Settings, Refresh, and Quit if needed.
- Add privacy/security usage notes to README.
- Add app version/build metadata if useful.

Implementation notes:

- Use ServiceManagement APIs appropriate for macOS 14.
- Keep launch-at-login state synchronized with settings UI.
- Avoid adding sandbox exceptions unless needed.
- If sandboxing is enabled, confirm network and Keychain behavior still work.

Deliverables:

- Launch at login works.
- App has a recognizable icon.
- App behaves like a menu bar utility.
- User can quit the app clearly.

Verification:

- Toggle launch at login on and off.
- Restart Mac or simulate login flow if practical.
- Confirm app starts without requiring user interaction.
- Confirm settings persist across relaunch.

## Phase 8: Testing And Hardening

Goal: reduce integration risk and catch common regressions before release.

Tasks:

- Add unit tests for formatters.
- Add unit tests for AppSettings defaults.
- Add unit tests for Pi-hole API response decoding.
- Add unit tests for provider snapshot mapping.
- Add unit tests for error mapping.
- Add KeychainService tests where practical.
- Add mocked MonitoringProvider for UI previews and state testing.
- Add dashboard previews for configured, unconfigured, loading, offline, auth failed, TLS error, and success states.
- Add manual QA checklist.
- Run xcodebuild locally.

Implementation notes:

- Avoid relying on a live Pi-hole in automated tests.
- Use fixtures for Pi-hole API JSON responses.
- Keep real Pi-hole testing as manual/integration validation.
- Test data should not contain real credentials, SIDs, private hostnames, or tokens.

Deliverables:

- Core formatting and mapping tests pass.
- API fixture decoding tests pass.
- UI previews cover important states.
- Manual QA checklist exists.

Verification:

- Run unit tests.
- Run app manually.
- Test with a real Tailscale HTTPS Pi-hole URL.
- Test failure modes.

## Phase 9: UI Polish And Open Source Release Prep

Goal: prepare GravityWell for public release.

Tasks:

- Polish typography, spacing, materials, and dark-mode behavior.
- Add final app icon assets.
- Add README installation and setup instructions.
- Add screenshots or placeholder screenshot instructions.
- Add security model explanation.
- Add no-telemetry statement.
- Add license.
- Add contribution guidelines if desired.
- Add issue templates if desired.
- Add initial release checklist.

Implementation notes:

- Keep the README direct and useful for homelab users.
- Include Tailscale HTTPS setup guidance at a high level, but do not duplicate Tailscale documentation.
- Be explicit that Pi-hole does not need public exposure.
- Be explicit that credentials are stored in Keychain.

Deliverables:

- README is release-ready.
- LICENSE exists.
- App has final icon assets.
- Release checklist exists.
- Project is ready for an initial GitHub push.

Verification:

- Fresh clone builds locally.
- README setup instructions are accurate.
- No credentials or private hostnames are committed.
- Git status contains only intended files.

## Post-MVP Roadmap

These features should not block the MVP.

### Authentication Enhancements

- Add Pi-hole 2FA support.
- Add credential validation improvements.
- Add explicit application password guidance in setup UI.
- Add session logout on app quit if appropriate.

### Multi-Provider Platform

- Add multiple active providers.
- Add provider selection UI.
- Add provider-specific settings screens.
- Add Tailscale status provider.
- Add Home Assistant provider.
- Add Synology provider.
- Add Jellyfin provider.
- Add per-provider menu bar display options.

### Pi-hole Enhancements

- Add Pi-hole CPU temperature.
- Add DNS health check.
- Add blocklist update trigger.
- Add today/last-hour toggle.
- Add historical mini charts.
- Add query search.
- Add allow/deny domain management.
- Add multiple Pi-hole instances.

### Notifications And Alerts

- Notify when Pi-hole goes offline.
- Notify when blocking is disabled longer than expected.
- Notify on unusually high query volume.
- Notify on unusually high block rate.

### Sync And Distribution

- Add iCloud settings sync for non-sensitive settings.
- Add signed and notarized builds.
- Add Homebrew Cask distribution.
- Add Sparkle updater if appropriate.

## Security Checklist

- Credentials stored only in Keychain.
- Base URL stored only as non-sensitive setting.
- SID stored only in memory.
- SID sent using request header, not query string.
- No telemetry.
- No analytics.
- No crash-reporting service unless explicitly added later with user consent.
- No external requests except the configured Pi-hole instance.
- No logging of credentials.
- No logging of SIDs.
- No logging of full secret-bearing URLs.
- Self-signed TLS disabled by default.
- Self-signed TLS allowed only by explicit user setting.
- Authentication errors shown concisely to user.
- TLS errors shown concisely to user.

## Manual QA Checklist

- Fresh launch with no settings shows setup state.
- Invalid URL is rejected or clearly reported.
- Bad credential shows authentication failed.
- Unreachable Pi-hole shows offline state.
- Invalid TLS certificate shows TLS error when self-signed is disabled.
- Self-signed certificate works only when explicitly enabled.
- Successful connection shows live stats.
- Menu bar display mode updates immediately.
- Poll interval updates without relaunch.
- Manual refresh updates dashboard.
- Open dashboard button opens configured Pi-hole URL.
- Disable blocking for 5 minutes works.
- Disable blocking for 30 minutes works.
- Disable blocking for 1 hour works.
- Re-enable blocking works.
- Settings survive app restart.
- Credential survives app restart through Keychain.
- App works with a Tailscale HTTPS URL.
- App works in dark mode.
- App works in light mode.
- App does not expose credential in logs.
- App does not expose SID in logs.

## Initial Release Definition

GravityWell v0.1.0 is ready when:

- MVP acceptance criteria are complete.
- Manual QA checklist passes.
- Unit tests for core formatting, decoding, and mapping pass.
- README is accurate.
- License is present.
- App icon is present.
- Project builds from a fresh clone.
- No secrets or private environment details are committed.
