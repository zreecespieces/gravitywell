# Changelog

All notable changes to GravityWell will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses semantic versioning.

## [Unreleased]

### Added

- Vite + React + TypeScript + MUI website in `website/`.
- Launch asset directories for screenshots, GIFs, logo exports, and social assets.
- GitHub issue templates, pull request template, build workflow, and release workflow scaffold.
- Sparkle appcast placeholder at `website/public/appcast.xml`.
- Shared Xcode scheme for CI.
- Minimal sandbox entitlements and Release hardened-runtime configuration.
- Signing, notarization, Sparkle, and Homebrew tap documentation.

### Changed

- README updated from MVP developer documentation to product-launch documentation.
- `.gitignore`, release checklist, QA checklist, contribution guide, and security policy updated for launch prep.

### Known Issues

- Sparkle is not yet wired into the macOS app.
- Release workflow currently produces unsigned fallback artifacts only.
- Final PNG screenshots and `demo.gif` still need to be captured from the app with mock data.
- Homebrew personal tap repository still needs to be created.

## [1.0.0] - TBD

### Added

- Native macOS menu bar app for Pi-hole.
- Pi-hole v6 authentication and API integration.
- Live DNS summary statistics.
- Top blocked domains.
- Top clients with hostname enrichment.
- Last-hour query activity sparkline.
- Pause and resume blocking controls.
- Keychain-backed credential storage.
- Launch at login.
- Local-first privacy model with no telemetry.

### Changed

- Initial public release.

### Fixed

- Not applicable.

### Known Issues

- Pi-hole 2FA is not directly supported. Use an application password where possible.
- Multiple Pi-hole instances are not yet supported.
- Historical graphs and query explorer are planned for future releases.
