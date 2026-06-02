# Homebrew Cask

GravityWell v1.0 uses a personal tap before attempting submission to upstream `homebrew-cask`.

## Tap Repository

Create this repository:

```text
zacharyreece/homebrew-gravitywell
```

Homebrew resolves that as:

```sh
brew tap zacharyreece/gravitywell
```

## Cask

Create `Casks/gravitywell.rb` in the tap repository:

```ruby
cask "gravitywell" do
  version "1.0.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/zacharyreece/gravitywell/releases/download/v#{version}/GravityWell-#{version}.dmg"
  name "GravityWell"
  desc "Native macOS menu bar companion for Pi-hole"
  homepage "https://gravitywell.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "GravityWell.app"

  zap trash: [
    "~/Library/Preferences/com.zacharyreece.GravityWell.plist",
    "~/Library/Application Support/GravityWell",
    "~/Library/Caches/com.zacharyreece.GravityWell",
  ]
end
```

## Install Command

```sh
brew tap zacharyreece/gravitywell
brew install --cask gravitywell
```

## Release Automation

After the public signing/notarization workflow is finished, update `.github/workflows/release.yml` to:

- Compute the DMG SHA256.
- Clone `zacharyreece/homebrew-gravitywell` using a fine-grained PAT.
- Update `version` and `sha256` in `Casks/gravitywell.rb`.
- Commit and push the cask bump.

Use a separate token with write access only to the tap repository.
