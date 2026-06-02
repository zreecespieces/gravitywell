# Sparkle Updates

Sparkle uses an appcast feed to tell GravityWell when a new version is available.

## Appcast URL

```text
https://gravitywell.app/appcast.xml
```

This URL is stable and should not change after it ships in the app. It is served by Vercel from:

```text
website/public/appcast.xml
```

## What `appcast.xml` Contains

- Latest version number.
- Release notes URL.
- Download URL for the Sparkle update ZIP.
- File size.
- Minimum macOS version.
- Sparkle EdDSA signature.

The file contains no secrets.

## Required v1.0 Work

- Add Sparkle 2.x via Swift Package Manager.
- Generate an EdDSA key pair.
- Add the public key to the app Info.plist.
- Store the private key as a GitHub Actions secret for release signing.
- Embed Sparkle sandbox-compatible XPC services.
- Add a Check for Updates action in the app.
- Generate a signed appcast during release.
- Publish the updated appcast to `website/public/appcast.xml` or deploy it through Vercel.

Do not ship Sparkle without testing a real update from one version to another.
