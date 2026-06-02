# Signing And Notarization

GravityWell can build unsigned fallback artifacts, but the public v1.0 install experience should use Developer ID signing and notarization.

## Required Apple Setup

- Active Apple Developer Program membership.
- Developer ID Application certificate.
- App-specific password for notarization.
- Apple Team ID.

## GitHub Actions Secrets

Add these only when ready to ship notarized builds:

| Secret | Purpose |
| --- | --- |
| `DEVELOPER_ID_CERT_P12_BASE64` | Base64-encoded Developer ID Application certificate export |
| `DEVELOPER_ID_CERT_PASSWORD` | Password for the `.p12` export |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password |
| `NOTARYTOOL_APPLE_ID` | Apple ID email |
| `NOTARYTOOL_TEAM_ID` | Apple Team ID |
| `NOTARYTOOL_PASSWORD` | App-specific password |

## Local Export

Export the Developer ID certificate from Keychain Access as a `.p12`, then base64 encode it:

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

Never commit certificates, private keys, app-specific passwords, provisioning profiles, or notarytool credentials.

## Entitlements

`GravityWell/App/GravityWell.entitlements` enables:

- App Sandbox
- Outbound network client access

The Release configuration enables Hardened Runtime. Re-test Keychain, LocalAuthentication, networking, launch-at-login, and Sparkle after any entitlement changes.
