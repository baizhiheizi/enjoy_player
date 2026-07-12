# Contract: Release Manifest Linux Entry

**Feature**: [spec.md](../spec.md) | **Date**: 2026-07-12

## Endpoint

`GET https://dl.enjoy.bot/player/latest.json`

Same-origin proxy at `https://get.enjoy.bot/player/latest.json` is the URL the landing page reads (today). The schema below adds a `linux` entry; the existing entries are unchanged.

## Schema

```json
{
  "$schema": "https://json-schema.org/draft-07/schema",
  "title": "Enjoy Player release manifest",
  "type": "object",
  "required": ["version", "assets"],
  "additionalProperties": false,
  "properties": {
    "version": {
      "type": "string",
      "description": "Semver of the release (e.g. \"0.5.0\"). Matches pubspec.yaml."
    },
    "assets": {
      "type": "object",
      "description": "Per-platform artifact entries. Each value is optional; an empty object is valid for a release that ships only one platform.",
      "additionalProperties": false,
      "properties": {
        "windows":             { "$ref": "#/definitions/assetEntry" },
        "macos":               { "$ref": "#/definitions/assetEntry" },
        "android_arm64_v8a":   { "$ref": "#/definitions/assetEntry" },
        "android_armeabi_v7a": { "$ref": "#/definitions/assetEntry" },
        "android_x86_64":      { "$ref": "#/definitions/assetEntry" },
        "linux":               { "$ref": "#/definitions/linuxAssetEntry" }
      }
    }
  },
  "definitions": {
    "assetEntry": {
      "type": "object",
      "required": ["url"],
      "properties": {
        "url":    { "type": "string", "format": "uri" },
        "sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" }
      }
    },
    "linuxAssetEntry": {
      "type": "object",
      "required": ["url"],
      "properties": {
        "url":    { "type": "string", "format": "uri" },
        "sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" },
        "format": {
          "type": "string",
          "enum": ["appimage", "tar.gz", "deb", "rpm"],
          "default": "appimage",
          "description": "Informational only; the landing page does not branch on it."
        }
      }
    }
  }
}
```

## Example (v1 Linux release)

```json
{
  "version": "0.5.0",
  "assets": {
    "windows": {
      "url": "https://dl.enjoy.bot/player/v0.5.0/EnjoyPlayerSetup-0.5.0.exe",
      "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    },
    "macos": {
      "url": "https://dl.enjoy.bot/player/v0.5.0/enjoy-player-0.5.0-macos.zip",
      "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    },
    "android_arm64_v8a": {
      "url": "https://dl.enjoy.bot/player/v0.5.0/enjoy-player-0.5.0-arm64.apk",
      "sha256": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9"
    },
    "linux": {
      "url": "https://dl.enjoy.bot/player/v0.5.0/enjoy-player-0.5.0-x86_64.AppImage",
      "sha256": "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
      "format": "appimage"
    }
  }
}
```

## Consumer (landing page JS)

`landing/main.js → applyManifest(manifest)` reads `manifest.assets.linux.url` and updates `#btn-linux.href` and adds the `download` attribute. The function is forward-compatible: an empty `assets.linux` (or a missing `linux` key) leaves the button pointing at the fallback `https://dl.enjoy.bot/player/` directory listing, the same as the other platforms do today.

`landing/main.js → detectOS()` returns `'linux'` for any `navigator.userAgent` matching `/linux/i`. `highlightPlatform('linux')` reorders the card grid and adds the "Recommended" badge.

## Producer (release script)

`.github/scripts/release_linux.sh` (new) is the only producer. It:

1. Runs `flutter build linux --release` to produce `build/linux/x64/release/bundle/`.
2. Runs `linux/packaging/make_appimage.sh` to wrap the bundle into `enjoy-player-<version>-x86_64.AppImage`.
3. Computes the SHA-256 of the AppImage.
4. Writes (or merges into) `dl.enjoy.bot/player/latest.json` with the new `linux` entry, leaving the other entries untouched.
5. Uploads the AppImage to `dl.enjoy.bot/player/v<version>/` via the existing S3 publisher (the same publisher the other release scripts use).

The script is idempotent: re-running it with `--publish-only` re-uploads the existing AppImage and re-writes the manifest entry without rebuilding. This matches the `--publish-only` semantics of the other release scripts.

## Backward compatibility

- The new `linux` key is **additive**; existing consumers that ignore unknown keys are unaffected.
- The new optional `format` field on `linuxAssetEntry` is **additive**; consumers that don't read it are unaffected.
- The schema does not bump a `schemaVersion` field; this is intentional for v1. A follow-up ADR will introduce `schemaVersion: "1.1.0"` if/when the next non-trivial change lands.

## Out of scope (v1)

- AppImage GPG signature in the manifest (deferred; v1 ships unsigned AppImages).
- Per-architecture manifest entries (`linux-aarch64`, etc.) — aarch64 is out of scope for v1.
- Per-distribution manifest entries (`linux-ubuntu-2204`, `linux-fedora-39`, etc.) — v1 is a single AppImage that runs on all three.
