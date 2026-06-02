# GravityWell Release Checklist

## Before Release

- Run `xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' build`.
- Run `xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' test`.
- Complete `QA_CHECKLIST.md`.
- Confirm no credentials, private hostnames, Tailscale hostnames, or session IDs are committed.
- Confirm README setup instructions are accurate.
- Confirm `SECURITY.md` is up to date.
- Confirm `LICENSE` is present.
- Confirm app version is correct.

## Initial Release

- Tag release as `v0.1.0`.
- Include MVP limitations in release notes.
- Mention Pi-hole v6+ target support.
- Mention 2FA is post-MVP.
