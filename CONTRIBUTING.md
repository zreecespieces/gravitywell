# Contributing

GravityWell is early-stage software. Contributions should keep the app native, local-first, and dependency-light.

## Principles

- Prefer native macOS APIs for the app.
- Avoid telemetry and analytics.
- Do not introduce cloud dependencies.
- Keep credentials in Keychain only.
- Keep Pi-hole API details isolated behind provider/client boundaries.
- Prefer small, focused changes.
- Update documentation when behavior, installation, or security expectations change.

## macOS App Development

Build:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' build
```

Test:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' test
```

If local signing fails, open the project in Xcode and set your Development Team for the GravityWell target. Do not commit personal signing identities, provisioning profiles, certificates, `.p12` files, `.p8` files, or app-specific passwords.

## Website Development

The website lives in `website/` and uses Vite, React, TypeScript, and MUI.

```sh
cd website
npm install
npm run dev
```

Build the production site:

```sh
cd website
npm run build
```

## Release Notes

For user-visible changes, update `CHANGELOG.md` under `[Unreleased]`.

Use these headings when applicable:

- Added
- Changed
- Fixed
- Known Issues

## Security Hygiene

Do not commit:

- Pi-hole credentials
- Session IDs
- Private hostnames
- Private IP addresses
- Tailscale hostnames
- Certificates or private keys
- App-specific passwords
- Notarization credentials
- Sparkle private keys

Report vulnerabilities through GitHub private vulnerability reporting. See `SECURITY.md`.

## Pull Requests

- Keep PRs focused.
- Include tests for app logic when practical.
- Run the relevant build/test command before opening the PR.
- Update screenshots or website copy if the user-facing experience changes.
- Preserve the local-first/no-telemetry model.
