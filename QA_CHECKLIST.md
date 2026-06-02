# GravityWell Manual QA Checklist

## Core App

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
- Open Dashboard opens the configured Pi-hole URL.
- Disable Blocking for 5 minutes works.
- Disable Blocking for 30 minutes works.
- Disable Blocking for 1 hour works.
- Re-enable Blocking works.
- Settings survive app restart.
- Credential survives app restart through Keychain.
- App works with a Tailscale HTTPS URL.
- App works in dark mode.
- App works in light mode.
- App does not expose credential in logs.
- App does not expose session ID in logs.
- App does not expose private hostnames or IPs at info log level.
- Launch at login can be enabled.
- Launch at login can be disabled.

## Release Artifact

- DMG opens successfully.
- DMG contains GravityWell.app and Applications shortcut.
- Drag-to-Applications install works.
- Fresh install launches from `/Applications`.
- Gatekeeper does not warn on notarized builds.
- Unsigned fallback builds include clear release-note warnings.
- ZIP artifact expands to a valid `GravityWell.app`.

## Sparkle

- `https://gravitywell.app/appcast.xml` is reachable over HTTPS.
- App can check for updates without crashing.
- Automatic update setting is persisted.
- Update ZIP signature validates.
- Update install flow works on a test release.

## Website

- `npm run build` succeeds in `website/`.
- Landing page works on desktop.
- Landing page works on mobile.
- Homebrew command is visible.
- Direct download link points to GitHub Releases.
- Privacy section is prominent.
- OpenGraph metadata is present.

## Launch Media

- `Assets/screenshots/01-dashboard.png` captured.
- `Assets/screenshots/02-menubar.png` captured.
- `Assets/screenshots/03-settings.png` captured.
- `Assets/screenshots/04-blocking-disabled.png` captured.
- `Assets/gifs/demo.gif` captured.
- Screenshots use dark mode.
- Screenshots use mock data only.
