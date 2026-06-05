# Android release CI setup

Guide for configuring [`.github/workflows/release_android.yml`](../.github/workflows/release_android.yml) on GitHub.

The workflow runs on your **self-hosted Linux runner** (`runs-on: [self-hosted, Linux]`) — the same machine as [Android APK smoke](../.github/workflows/android_apk_smoke.yml).

## What the release workflow does

1. `flutter analyze` + `flutter test`
2. Loads **upload keystore** from GitHub Secrets (or uses files already on the runner)
3. Builds signed **App Bundle** (`flutter build appbundle --release`) for Google Play
4. Optionally builds signed **per-ABI APKs** for sideload (`--split-per-abi`)
5. Optionally **publishes** sideload APKs to dl.enjoy.bot — no GitHub artifact upload (avoids storage billing)

**Triggers**

- Push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
- Manual: GitHub → Actions → **Release Android** → **Run workflow**

Smoke builds (debug keystore) stay in [`android_apk_smoke.yml`](../.github/workflows/android_apk_smoke.yml).

---

## Step 1 — Create upload keystore (one-time)

If you do not already have a Play upload key:

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the keystore and passwords **out of git**. See [packaging.md § Android signing](packaging.md#android-signing).

For local builds, copy [`android/key.properties.example`](../android/key.properties.example) to `android/key.properties` and point `storeFile` at your keystore.

---

## Step 2 — GitHub Secrets & variables

Open the repo on GitHub → **Settings** → **Secrets and variables** → **Actions**.

### Option A — Keystore on the self-hosted runner (recommended if you already release locally)

Place `android/key.properties` and the `.jks` file on the Linux runner (same layout as local release). Set a **Repository variable**:

| Variable | Value |
|----------|-------|
| `ANDROID_USE_RUNNER_KEYSTORE` | `true` |

No keystore secrets are required. The workflow cleans up only CI-generated `ci-release-keystore.jks` when using secrets import.

### Option B — Import keystore from GitHub Secrets (portable runners)

Base64-encode the keystore on a machine that has it:

```bash
base64 -w0 release-keystore.jks   # Linux
# or: base64 -i release-keystore.jks | pbcopy   # macOS
```

| Secret name | Where to get it |
|-------------|-----------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of your upload `.jks` / `.keystore` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `upload` from `key.properties.example`) |
| `ANDROID_KEY_PASSWORD` | Key password (often same as store password) |

Leave `ANDROID_USE_RUNNER_KEYSTORE` unset or set to `false`.

---

## Step 3 — Self-hosted runner checklist

See [ci-self-hosted-runners.md](ci-self-hosted-runners.md) for registration and labels (`self-hosted`, `Linux`).

```bash
flutter doctor
java -version   # 17+
echo "$ANDROID_SDK_ROOT"
sdkmanager "platforms;android-35" "build-tools;35.0.0"
```

---

## Step 4 — Run a release

### Manual test (no tag)

1. Bump `version:` in `pubspec.yaml` if needed.
2. GitHub → **Actions** → **Release Android** → **Run workflow**.
3. Toggle **Also build release APK** as needed.
4. Collect outputs from the runner workspace, or enable **Publish** to upload to dl.enjoy.bot:
   - `build/app/outputs/bundle/release/EnjoyPlayer-vX.Y.Z.aab`
   - `build/app/outputs/flutter-apk/EnjoyPlayer-vX.Y.Z-*.apk` (when APK step ran)

### Tag release

```bash
git tag v1.0.0
git push origin v1.0.0
```

Tag pushes build both **AAB** and **per-ABI APKs** (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

Most sideload users want **`EnjoyPlayer-vX.Y.Z-arm64-v8a.apk`** only.

---

## Upload to Google Play

CI produces signed artifacts only — **Play Console upload is manual** (or add a separate workflow with Play API credentials later).

1. Download `android-release-vX.Y.Z` (`.aab`) from the Actions run.
2. Play Console → **Release** → create production / internal testing release → upload AAB.

Ensure the upload key matches the app signing key registered in Play Console.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| *Missing ANDROID_KEYSTORE_* | Add secrets or set `ANDROID_USE_RUNNER_KEYSTORE=true` with local `key.properties` |
| *ANDROID_SDK_ROOT not set* | Set `ANDROID_SDK_ROOT` in runner service environment |
| AAB signed with debug key | Signing setup failed — check secrets / `key.properties` paths |
| R8 / ProGuard missing class | Extend [`proguard-rules.pro`](../android/app/proguard-rules.pro) per Gradle hint |

---

## Local release (without CI)

Same commands, documented in [packaging.md](packaging.md):

```bash
flutter build appbundle --release
flutter build apk --release --split-per-abi
```
