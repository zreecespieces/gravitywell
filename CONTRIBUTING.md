# Contributing

GravityWell is early-stage software. Contributions should keep the app native, local-first, and dependency-light.

## Principles

- Prefer native macOS APIs.
- Avoid telemetry and analytics.
- Do not introduce external services.
- Keep credentials in Keychain only.
- Keep Pi-hole API details isolated behind provider/client boundaries.
- Prefer small, focused changes.

## Development

Build:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' build
```

Test:

```sh
xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' test
```
