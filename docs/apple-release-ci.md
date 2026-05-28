# Apple release CI setup

Guide for configuring [`.github/workflows/release_apple.yml`](../.github/workflows/release_apple.yml) on GitHub.

The workflow runs on your **self-hosted macOS runner** (`runs-on: [self-hosted, macos]`) — the same machine you use for local Xcode builds. Smoke builds stay in [`build_apple.yml`](../.github/workflows/build_apple.yml).

## What the release workflow does

1. `flutter analyze` + `flutter test`
2. Builds signed **iOS IPA** (`flutter build ipa`)
3. Optionally uploads to **TestFlight**
4. Builds **macOS release** `.app`
5. Optionally **notarizes** macOS for direct download
6. Uploads **artifacts** (`EnjoyPlayer-vX.Y.Z.ipa` + `EnjoyPlayer-macOS-vX.Y.Z.zip`) to the GitHub Actions run

**Triggers**

- Push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
- Manual: GitHub → Actions → **Release Apple** → **Run workflow**

---

## Step 1 — Apple Developer / App Store Connect (one-time)

### 1a. App Store Connect app record

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → New App.
2. Bundle ID: **`ai.enjoy.player`**
3. If the bundle ID is missing, create it first in [Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list).

Without this record, IPA export/upload fails with *Error Downloading App Information*.

### 1b. App Store Connect API key (required for CI upload + notarization)

1. [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click **+** to generate a key.
3. Name: e.g. `Enjoy Player CI`
4. Access: **App Manager** (or **Admin**)
5. Download the **`.p8`** file — **you can only download it once**.
6. Note:
   - **Issuer ID** (top of the API page, UUID)
   - **Key ID** (10 characters, e.g. `AB12CD34EF`)
   - **Team ID**: `46X685R747`

Add these three values as GitHub **Secrets** (see table below).

---

## Step 2 — Signing certificates

You need two certificates in [Developer → Certificates](https://developer.apple.com/account/resources/certificates/list):

| Certificate | Used for |
|-------------|----------|
| **Apple Distribution** | iOS App Store / TestFlight |
| **Developer ID Application** | macOS direct download |

### Option A — Self-hosted Mac already has certs (recommended for you)

If your Mac runner already has both certs in Keychain (from local Xcode work), **you do not need to export `.p12` files**.

Set a GitHub **Repository variable**:

| Variable | Value |
|----------|-------|
| `APPLE_USE_RUNNER_KEYCHAIN` | `true` |

The workflow will use the login keychain on the runner.

Verify on the Mac:

```bash
security find-identity -v -p codesigning
```

You should see:

- `Apple Distribution: … (46X685R747)`
- `Developer ID Application: … (46X685R747)`

Also ensure Xcode is signed in with the Enjoy team and **Automatically manage signing** is enabled for `ai.enjoy.player`.

### Option B — Import certs from GitHub Secrets (portable runners)

Export each certificate from Keychain Access:

1. Open **Keychain Access** → **My Certificates**.
2. Expand **Apple Distribution: …** → select **both** the cert and private key → Export → `.p12`.
3. Repeat for **Developer ID Application: …**.
4. Choose an export password (remember it for GitHub Secrets).

Base64-encode for GitHub (run on Mac):

```bash
base64 -i AppleDistribution.p12 | pbcopy    # paste into secret
base64 -i DeveloperIDApplication.p12 | pbcopy
```

Set repository variable `APPLE_USE_RUNNER_KEYCHAIN` to `false` (or delete it).

---

## Step 3 — GitHub Secrets & variables

Open the repo on GitHub → **Settings** → **Secrets and variables** → **Actions**.

### Required secrets (minimum for TestFlight + notarization)

| Secret name | Where to get it | Example / notes |
|-------------|-----------------|-----------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API page | `AB12CD34EF` |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API page (Issuer ID) | `69a6de8e-…` UUID |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Entire contents of downloaded `AuthKey_XXXX.p8` | Paste full file including `BEGIN/END PRIVATE KEY` lines |

### Optional secrets (only if `APPLE_USE_RUNNER_KEYCHAIN` is not `true`)

| Secret name | Where to get it |
|-------------|-----------------|
| `KEYCHAIN_PASSWORD` | Any strong random string (temp CI keychain only) |
| `IOS_DISTRIBUTION_CERT_BASE64` | Base64 of Apple Distribution `.p12` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | Password you set when exporting `.p12` |
| `MACOS_DEVELOPER_ID_CERT_BASE64` | Base64 of Developer ID Application `.p12` |
| `MACOS_DEVELOPER_ID_CERT_PASSWORD` | Password you set when exporting `.p12` |

### Repository variables

| Variable | Recommended value |
|----------|-------------------|
| `APPLE_USE_RUNNER_KEYCHAIN` | `true` on your self-hosted Mac |

---

## Step 4 — Self-hosted runner checklist

All workflows use repo self-hosted runners. Setup, labels, and per-OS toolchains are documented in [ci-self-hosted-runners.md](ci-self-hosted-runners.md).

On the Mac that runs GitHub Actions:

```bash
# Labels must include: self-hosted, macos
# Register via: GitHub repo → Settings → Actions → Runners

flutter doctor
xcodebuild -version
pod --version
brew bundle install --file=macos/Brewfile
```

Runner user must be able to run `codesign`, `xcrun notarytool`, and access Keychain certs.

---

## Step 5 — Run a release

### Manual test (no tag)

1. Bump version in `pubspec.yaml` if needed.
2. GitHub → **Actions** → **Release Apple** → **Run workflow**.
3. Toggle **Upload TestFlight** / **Notarize macOS** as needed.
4. Download artifacts from the completed run.

### Tag release

```bash
git tag v1.0.0
git push origin v1.0.0
```

Tag pushes always attempt TestFlight upload and macOS notarization (when secrets are configured).

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| *Error Downloading App Information* on IPA | Create App Store Connect app for `ai.enjoy.player` |
| *No profiles for 'ai.enjoy.player'* | Open Xcode on runner, build once with automatic signing |
| *notarytool* auth failed | Re-check API key ID, Issuer ID, and full `.p8` secret content |
| macOS DYLD / `libz` missing | Run `brew bundle install --file=macos/Brewfile` on runner |
| Upload skipped | API secrets missing — workflow logs *Skipping TestFlight upload* |

---

## Local release (without CI)

Same commands, documented in [packaging.md](packaging.md):

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.export.plist
flutter build macos --release
./macos/scripts/notarize_release.sh "build/macos/Build/Products/Release/Enjoy Player.app"
```

For local notarization with Apple ID instead of API key, see [packaging.md § Direct release](packaging.md#direct-release-developer-id--notarization).
