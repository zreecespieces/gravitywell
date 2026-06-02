# GravityWell Website

Vite + React + TypeScript + MUI landing page for `gravitywell.app`.

## Development

```sh
npm install
npm run dev
```

## Production Build

```sh
npm run build
```

Vercel should use `website/` as the project root, `npm run build` as the build command, and `dist` as the output directory.

## Sparkle Appcast

`public/appcast.xml` is the stable Sparkle update feed served at:

```text
https://gravitywell.app/appcast.xml
```

The release workflow should replace this placeholder with a signed Sparkle appcast when Sparkle is fully wired into the macOS app.
