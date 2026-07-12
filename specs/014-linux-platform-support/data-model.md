# Data Model: Linux Desktop Platform Support

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

This change is **platform enablement**, not new feature surface area. The data-model changes are limited to:

- One new platform-predicate helper module (`lib/core/platform/`).
- One new entry in the `dl.enjoy.bot/player/latest.json` release manifest.
- A constitutional amendment (no new tables, no schema changes).
- A new `linux/` Flutter desktop folder (no Dart data).

No Drift tables, DAOs, or schema migrations are introduced. The existing Drift `AppDatabase` and `path_provider` paths already work on Linux because `getApplicationDocumentsDirectory()` returns `~/.local/share/<bundle id>/` on Linux, which is the same logical "documents" location the other desktops use.

---

## Entities

### LinuxPlatformAvailability (new helper)

A small set of platform-predicate getters centralized in a new module so the audit (FR-013) has one source of truth instead of scattering `Platform.isLinux` checks across the codebase.

| Getter | Type | Description |
|--------|------|-------------|
| `isLinux` | `bool` | True on `Platform.isLinux`; false elsewhere. The only place this should be hard-coded is inside this module — every other call site uses the named getters below. |
| `isLinuxDesktop` | `bool` | Convenience alias: `isLinux && !kIsWeb` (defensive; `kIsWeb` is always false on Linux today, but the guard makes the intent explicit). |
| `youtubeEngineAvailableOnLinux` | `bool` | **False** for v1 (see R6). Centralizes the "is YouTube opt-in?" decision so a future ADR can flip it without touching call sites. |
| `googleSignInAvailableOnLinux` | `bool` | **True** for v1 (see R10). |
| `autoUpdaterAvailableOnLinux` | `bool` | **False** for v1 (see R7). |
| `echoRecordingAvailableOnLinux` | `bool` | **True** if the `record` package's Linux backend passes first smoke; defaults to `true`, can be flipped to `false` if first smoke shows a crash. |
| `nativeLinuxAsrAvailable` | `bool` | **True** if the ASR audio extractor's Linux FFmpeg path works; defaults to `true`, flips to `false` if smoke shows a regression. |

**Module path**: `lib/core/platform/linux_platform_availability.dart`

**Storage**: pure compile-time constants. No persistence.

**Validation**: each getter is a constant; if a getter ever becomes dynamic, the corresponding test must move to a runtime test (currently all are unit-tested with `debugDefaultTargetPlatformOverride`).

---

### ReleaseManifestEntry (extended)

The existing `dl.enjoy.bot/player/latest.json` shape. The current keys (`windows`, `macos`, `android_arm64_v8a`) live under `assets`. After this change, a new `linux` key is added.

| Field | Type | Description |
|-------|------|-------------|
| `version` | `string` | Already present. The semver of the release. |
| `assets.windows` | `AssetEntry?` | Already present. Windows installer URL + sha256. |
| `assets.macos` | `AssetEntry?` | Already present. macOS notarized zip URL + sha256. |
| `assets.android_arm64_v8a` | `AssetEntry?` | Already present. Android sideload APK URL + sha256. |
| `assets.linux` | `AssetEntry?` | **NEW.** Linux AppImage URL + sha256 + format hint. |

`AssetEntry` shape (unchanged):

| Field | Type | Description |
|-------|------|-------------|
| `url` | `string` | HTTPS URL on `dl.enjoy.bot`. |
| `sha256` | `string?` | Optional SHA-256 of the artifact (hex). The Windows / macOS / Android entries include it; the Linux entry includes it from the first release. |
| `format` | `string?` | **NEW, optional, Linux-only.** One of `"appimage"`, `"tar.gz"`, `"deb"`, `"rpm"`. v1 is always `"appimage"`. Informational; the landing page does not branch on it. |

**Schema version**: the existing manifest has no `schemaVersion` field. This change does not introduce one (the manifest is forward-compatible by virtue of "ignore unknown keys"). A follow-up ADR may add `schemaVersion: "1.1.0"` when the second non-trivial schema change lands.

**Persistence**: the manifest is fetched at runtime by `landing/main.js` (no caching beyond the browser's HTTP cache). The Flutter app does not consume the manifest.

---

### LandingPageCard (extended)

The existing DOM structure for the platform cards (`#card-windows`, `#card-macos`, `#card-android`, `#card-ios`) under `.platform-grid` in `landing/index.html`. A new `#card-linux` is added with the same `class="card"` structure.

| Card | Title (`data-i18n`) | Subtitle | Download button id | Disabled? |
|------|---------------------|----------|--------------------|-----------|
| `#card-windows` | `download.windows.title` | "Windows 10 / 11 · x64" | `#btn-windows` | no |
| `#card-macos` | `download.macos.title` | "macOS 10.15+ · Universal" | `#btn-macos` | no |
| `#card-android` | `download.android.title` | "Android 8.0+" | `#btn-android`, `#btn-play-beta` | Play: yes (until filled) |
| `#card-ios` | `download.ios.title` | "iOS 14.0+" | `#btn-testflight` | yes (until filled) |
| `#card-linux` | `download.linux.title` | "Ubuntu 22.04 LTS · x86_64" | `#btn-linux` | no (filled by `applyManifest()` from the manifest's `linux.url`) |

**i18n keys added** (in `landing/i18n.js`):

| Key | English | Chinese |
|-----|---------|---------|
| `download.linux.title` | "Linux" | "Linux" |
| `download.linux.subtitle` | "Ubuntu 22.04 LTS · x86_64" | "Ubuntu 22.04 LTS · x86_64" |
| `download.linux.btn` | "Download for Linux" | "下载 Linux 版" |
| `download.linux.note` | "AppImage: `chmod +x enjoy-player-*.AppImage && ./enjoy-player-*.AppImage`" | "AppImage: `chmod +x enjoy-player-*.AppImage && ./enjoy-player-*.AppImage`" |

**Detection contract**: `landing/main.js → detectOS()` returns `'linux'` for `navigator.userAgent` matching `/linux/i`. The same function returns `'ios'`, `'macos'`, `'windows'`, `'android'` for the other UAs. `highlightPlatform('linux')` reorders the card grid and adds the "Recommended" badge, identical to the other platforms.

**Manifest application contract**: `applyManifest(manifest)` updates `#btn-linux`'s `href`, adds the `download` attribute, and reads `assets.linux.url`. Mirrors the existing `#btn-windows`, `#btn-macos`, `#btn-android` handling.

---

### PlatformConditionalSite (audit-only)

A non-Dart entity: a row in the `plan.md` "Platform-conditional audit" table. Each row documents an existing Dart site that branches on a platform, the current Linux behavior, and the action this change takes (EDIT / REVIEW / no change). The audit table is the source of truth for FR-013 and is included in the plan for accountability.

| Field | Description |
|-------|-------------|
| `file` | Relative path under `lib/`. |
| `line` | Line number in that file. |
| `currentBehavior` | What the code does today for Linux. |
| `action` | EDIT, REVIEW, or no-change. |

**Persistence**: none. The audit lives in `plan.md` and is the input to the task list (`tasks.md`) when this change is decomposed.

---

## State Transitions

There are no new state machines. The existing transitions for the player engine, the YouTube WebView controller, the update strategy, the recovery flow, and the auth flow are all preserved.

The one new transition is a **"Linux first-run" cold-start sequence**, which is identical to the Windows/macOS cold-start:

```
[User double-clicks the AppImage]
        │
        ▼
[AppImage mounts, runs the embedded enjoy_player binary]
        │
        ▼
[lib/main.dart → _bootstrap()]
        │
        ▼
[WidgetsFlutterBinding.ensureInitialized()]
        │
        ▼
[setupAppLogging()]    ← writes to ~/.local/share/.../logs/
        │
        ▼
[windowManager.ensureInitialized() for desktop]    ← Linux is in the desktop branch
        │
        ▼
[MediaKit.ensureInitialized()]
        │
        ▼
[ProviderScope(child: EnjoyApp())]
        │
        ▼
[EnjoyApp → appPreferencesCtrlProvider → AppDatabase (Drift)]
        │
        ▼
[Library / Discover / Player UI rendered]
```

The Linux-specific cold-start budget (SC-003) is the time from "double-click" to "first frame of the library page rendered". The current Windows budget (recorded in `docs/features/player.md`) is ~2 s on a recent desktop; the Linux budget is **≤ 6 s median on Ubuntu 22.04 LTS x86_64** (per spec SC-003) because the cold-start is dominated by `WindowManager` initialization, libmpv prebinding, and the Drift database open — all of which are slightly slower on Linux + Wayland than on Windows. The actual median value is recorded in `docs/features/linux-platform.md` after the first release.

---

## Database Changes

**None.** The existing Drift `AppDatabase` and `path_provider` paths work on Linux out of the box. No new tables, no new columns, no new DAOs, no schema migration.

If a future change requires a Linux-only schema tweak (e.g. a new `linux_appimage_paths` table for AppImage signature verification), it is a follow-up and gets its own migration + ADR.

---

## Localization

The landing page's `app_en.arb` and `app_zh.arb` (or, for the landing page specifically, the `en` and `zh` branches of `landing/i18n.js`) get the four new keys above. The Flutter app's ARB files are **not** modified — the new in-app Linux behaviors (e.g. "YouTube is not yet available on Linux") reuse the existing `app_localizations` keys (e.g. `youtubeComingSoon` if it exists, otherwise a generic `comingSoon` key). If neither exists, a new key is added to the ARB files in the same change.

The recovery surface, the about page, and the settings page are **not** modified for v1; they inherit the same strings on Linux as on Windows/macOS. If a follow-up wants a "platform" line in the about page (e.g. "Platform: Linux (x86_64)"), it is a follow-up.

---

## Distribution / Packaging Schema

The Linux AppImage artifact is named:

```
enjoy-player-<version>-x86_64.AppImage
```

Where `<version>` is the full semver from `pubspec.yaml` (e.g. `0.5.0`). The `linux/scripts/build_linux.sh` (new) and the `release_linux.sh` (new) enforce this naming. The manifest's `assets.linux.url` matches this naming.

**Symlinks** for the latest release (e.g. `enjoy-player-latest-x86_64.AppImage`) are **not** introduced for v1; users always get a versioned filename. This matches the existing Windows / macOS / Android artifact naming.
