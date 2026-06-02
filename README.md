# GravityWell

GravityWell is a native macOS menu bar companion for Pi-hole.

It gives quick access to DNS filtering stats, top blocked domains, top clients, and blocking controls without opening the full Pi-hole dashboard. GravityWell is built for private homelabs, Tailscale networks, and local-first monitoring.

## Status

GravityWell is in MVP development.

Implemented:

- macOS 14+ SwiftUI menu bar app foundation
- Pi-hole connection settings
- Keychain-backed credential storage
- Pi-hole v6 API authentication and summary fetching
- Normalized monitoring provider abstraction
- Live polling
- Menu bar display modes
- Popover dashboard
- Blocking enable/disable controls
- Launch at login
- Unit test target

## Pi-hole API Support

GravityWell targets Pi-hole v6+ first.

Current API support:

- `POST /api/auth`
- `GET /api/stats/summary`
- `GET /api/stats/top_domains`
- `GET /api/stats/top_clients`
- `GET /api/network/devices`
- `GET /api/clients`
- `GET /api/clients/_suggestions`
- `GET /api/dhcp/leases`
- `GET /api/queries`
- `POST /api/dns/blocking`

MVP authentication supports standard Pi-hole authentication or application passwords. 2FA is deferred until a future release.

## Current App Features

- Configurable Pi-hole URL and credential
- Credential storage in macOS Keychain
- Poll interval settings
- Menu bar display modes
- Live popover dashboard
- Top blocked domains
- Top clients
- Client hostname enrichment from Pi-hole top-client, network-device, managed-client, DHCP lease, suggestion, and query data, with macOS local reverse-DNS fallback
- Last-hour query activity sparkline
- Manual refresh
- Open Pi-hole dashboard
- Disable blocking for 5, 30, or 60 minutes
- Re-enable blocking
- Launch at login

## Requirements

- macOS 14.0+
- Xcode 26.5 or compatible Swift 6 toolchain
- Pi-hole v6+
- Pi-hole reachable from the Mac over LAN, VPN, or Tailscale
- HTTPS recommended

## Setup

1. Launch GravityWell.
2. Open Settings from the menu bar popover.
3. Enter your Pi-hole base URL, for example `https://pi-hole.local`.
4. Enter a Pi-hole password or application password.
5. Use Test Connection to verify authentication and summary fetching.
6. Save the connection.

2FA is not part of the MVP. If your Pi-hole account requires 2FA, generate and use an application password where possible.

## Development

Build:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' build
```

Test:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' test
```

## Project Structure

```text
GravityWell/
├── GravityWell.xcodeproj
├── GravityWell/
│   ├── App/
│   ├── Models/
│   ├── Providers/
│   ├── Services/
│   ├── Utilities/
│   └── Views/
├── GravityWellTests/
├── CONTRIBUTING.md
├── LICENSE
├── QA_CHECKLIST.md
├── RELEASE_CHECKLIST.md
├── ROADMAP.md
├── SECURITY.md
└── README.md
```

## Security

- No telemetry
- No analytics
- No cloud services
- Credentials stored in macOS Keychain
- Session IDs stored in memory only
- Session IDs sent with `X-FTL-SID`, not query parameters
- Non-sensitive settings stored in UserDefaults
- No external requests except the configured Pi-hole instance
- Self-signed TLS certificates rejected by default

See `SECURITY.md` for more detail.

## Release Prep

- Manual QA checklist: `QA_CHECKLIST.md`
- Release checklist: `RELEASE_CHECKLIST.md`
- Contribution notes: `CONTRIBUTING.md`
- Roadmap: `ROADMAP.md`
