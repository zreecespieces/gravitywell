# GravityWell Release Checklist

## Before Tagging

- Run `xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' build`.
- Run `xcodebuild -project GravityWell.xcodeproj -scheme GravityWell -configuration Debug -destination 'platform=macOS' test`.
- Run `cd website && npm run build`.
- Complete `QA_CHECKLIST.md`.
- Confirm no credentials, private hostnames, private IPs, Tailscale hostnames, certificates, private keys, or session IDs are committed.
- Confirm `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, and `CHANGELOG.md` are up to date.
- Confirm app version matches the intended tag.
- Confirm final release screenshots and GIF are present.
- Confirm `website/public/appcast.xml` is valid if Sparkle is enabled.

## Signing And Notarization

- Confirm Apple Developer Program membership is active.
- Confirm Developer ID Application certificate is available.
- Confirm GitHub Actions signing secrets are configured.
- Confirm notarytool credentials are configured.
- Confirm Release build has Hardened Runtime enabled.
- Confirm sandbox entitlements are validated.
- Confirm notarization succeeds.
- Confirm stapling succeeds.

## Homebrew Tap

- Confirm `zacharyreece/homebrew-gravitywell` exists.
- Confirm `Casks/gravitywell.rb` points to the v1.0.0 DMG.
- Confirm SHA256 matches the release artifact.
- Test `brew install --cask zacharyreece/gravitywell/gravitywell`.
- Test `brew uninstall --cask gravitywell`.

## Website

- Confirm Vercel project root is `website/`.
- Confirm `gravitywell.app` points to Vercel.
- Confirm production deploy succeeds.
- Confirm `https://gravitywell.app/appcast.xml` resolves.
- Confirm `https://gravitywell.app` loads on mobile and desktop.

## Tag And Release

```sh
git tag v1.0.0
git push origin v1.0.0
```

After the release workflow completes:

- Confirm GitHub Release exists.
- Confirm DMG is attached.
- Confirm ZIP is attached.
- Confirm release notes are correct.
- Confirm DMG install works on a clean Mac.
- Confirm Homebrew install works.
- Confirm Sparkle update check works if enabled.

## Launch Order

1. GitHub Release
2. Pi-hole Community Forum
3. Reddit `r/pihole`
4. Reddit `r/selfhosted`
5. Hacker News Show HN
6. Reddit `r/homelab`
7. Reddit `r/macapps`
8. Tailscale Community
