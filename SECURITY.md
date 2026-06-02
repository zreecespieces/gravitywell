# Security

GravityWell is designed as a local-first utility for private networks.

## Supported Versions

| Version | Supported |
| --- | --- |
| 1.x | Yes |
| < 1.0 | No |

## Security Model

- No telemetry.
- No analytics.
- No cloud services.
- No external requests except the configured Pi-hole instance.
- Pi-hole credentials are stored only in macOS Keychain.
- Pi-hole session IDs are stored only in memory.
- Session IDs are sent with `X-FTL-SID`, not query parameters.
- Non-sensitive settings are stored in UserDefaults.
- Self-signed TLS certificates are rejected by default.
- Self-signed TLS certificates are accepted only when explicitly enabled.

## Reporting Vulnerabilities

Use GitHub private vulnerability reporting:

```text
https://github.com/zacharyreece/gravitywell/security/advisories/new
```

Do not open public issues containing credentials, private hostnames, private IPs, Tailscale hostnames, logs with secrets, or Pi-hole session IDs.

If GitHub private vulnerability reporting is unavailable, open a public issue that says only that you need a private security contact. Do not include exploit details or private network information in that issue.

## Disclosure Expectations

- Please allow reasonable time to investigate and prepare a fix before public disclosure.
- Security fixes will be published through GitHub Releases.
- Release notes will describe the impact and remediation when safe to do so.
