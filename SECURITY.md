# Security

GravityWell is designed as a local-first utility for private networks.

## Security Model

- No telemetry.
- No analytics.
- No cloud services.
- No external requests except the configured Pi-hole instance.
- Pi-hole credentials are stored only in macOS Keychain.
- Pi-hole session IDs are stored only in memory.
- Session IDs are sent with `X-FTL-SID`, not query parameters.
- Self-signed TLS certificates are rejected by default.
- Self-signed TLS certificates are accepted only when explicitly enabled.

## Reporting Issues

Do not open public issues containing credentials, private hostnames, Tailscale hostnames, logs with secrets, or Pi-hole session IDs.

For now, report security issues privately to the repository owner.
