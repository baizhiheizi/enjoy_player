# Windows release CI setup

Guide for configuring [`.github/workflows/release_windows.yml`](../.github/workflows/release_windows.yml) on GitHub.

The workflow runs on the **self-hosted** `enjoy-player-win` runner (`runs-on: [self-hosted, windows, flutter]`), the same dedicated Windows runner used by [Build Windows smoke](../.github/workflows/build_windows.yml). It is managed via `gh-sr` — see [ci-self-hosted-runners.md](ci-self-hosted-runners.md).

## What the release workflow does

1. `flutter analyze` + `flutter test`
2. Builds **Windows release** (`flutter build windows --release`)
3. Syncs **Inno Setup** `AppVersion` from `pubspec.yaml`
4. Builds **EnjoyPlayerSetup-vX.Y.Z.exe** installer (optional on manual runs)
5. Optionally **publishes** to dl.enjoy.bot (S3/R2) when the publish input is enabled — no GitHub artifact upload (avoids storage billing)

**Triggers**

- **Manual only**: GitHub → Actions → **Release Windows** → **Run workflow**. There is no tag-push trigger — releases are always started explicitly.

---

## Step 1 — Prerequisites

One-time setup on the `enjoy-player-win` runner host (see [ci-self-hosted-runners.md](ci-self-hosted-runners.md#windows-runner-checklist) for the full checklist):

- **Visual Studio Build Tools** with the "Desktop development with C++" workload (required by `flutter build windows`)
- **Flutter** (pinned via [`.github/flutter-version`](../.github/flutter-version)) — installed automatically by [`setup-flutter`](../.github/actions/setup-flutter) on first run and reused from local disk afterward
- **NuGet CLI** on `PATH` (WebView2 restore) — the workflow runs [`ensure_nuget_feed.ps1`](../.github/scripts/ensure_nuget_feed.ps1), which configures the feed but does not install `nuget` itself
- **Chocolatey** — **Inno Setup 6** installs automatically via [`ensure_inno_setup.ps1`](../.github/scripts/ensure_inno_setup.ps1) (`choco install innosetup`) if `iscc` isn't already on `PATH`; installing Inno Setup from [jrsoftware.org](https://jrsoftware.org/isinfo.php) ahead of time works too

### Bundled FFmpeg

The release workflow runs [`windows/scripts/fetch_ffmpeg.ps1`](../windows/scripts/fetch_ffmpeg.ps1) before `flutter build windows --release`, downloading and verifying **ffmpeg-release-essentials** into **`windows/ffmpeg/ffmpeg.exe`** (see [windows/ffmpeg/README.md](../windows/ffmpeg/README.md)). Self-hosted runners need outbound HTTPS to `www.gyan.dev`; no manual copy is required unless you use an offline mirror.

---

## Step 2 — GitHub Secrets

No secrets are required for unsigned release builds. **Authenticode signing** stays outside this repo — sign `EnjoyPlayerSetup-vX.Y.Z.exe` locally with `signtool` or Inno Sign Tools (copy from the runner workspace or from dl.enjoy.bot after publish).

---

## Step 3 — Self-hosted runner

Already configured: the workflow's `runs-on: [self-hosted, windows, flutter]` targets the `enjoy-player-win` runner registered via `gh-sr` (see [ci-self-hosted-runners.md](ci-self-hosted-runners.md)). If you need to re-provision that runner or add another one:

1. Add/update the runner block in `runners.yml` and run `gh sr setup <name> && gh sr up <name>`.
2. Complete the manual host prerequisites in Step 1 above (gh-sr does not automate native Windows dependency installation).
3. Match the runner's labels to `[self-hosted, windows, flutter]` so it's picked up by `build_windows.yml` and `release_windows.yml`.

---

## Step 4 — Run a release

1. Bump `version:` in `pubspec.yaml` if needed.
2. GitHub → **Actions** → **Release Windows** → **Run workflow**.
3. Toggle **Build Inno Setup installer** and **Publish** as needed.
4. Collect outputs from the runner workspace (self-hosted) or check dl.enjoy.bot when **Publish** was enabled:
   - `build/windows/x64/runner/Release/` — portable app folder
   - `build/windows/installer/EnjoyPlayerSetup-vX.Y.Z.exe` — when the installer step ran

---

## Code signing (manual, post-CI)

After obtaining `EnjoyPlayerSetup-vX.Y.Z.exe` (from the runner or dl.enjoy.bot):

```powershell
signtool sign /fd SHA256 /a "EnjoyPlayerSetup-v0.6.0.exe"
```

Configure certificate thumbprint or HSM details per your vendor. See [windows/installer/README.md](../windows/installer/README.md).

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| *nuget is not on PATH* | Install NuGet CLI on the `enjoy-player-win` runner |
| *iscc not found* | Install Inno Setup 6, or ensure Chocolatey is present so `ensure_inno_setup.ps1` can install it automatically |
| Missing subtitles on end-user machines | Ensure `windows/scripts/fetch_ffmpeg.ps1` ran before `flutter build windows` (CI does this automatically) |
| WebView2 errors at runtime | End users need [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) |

---

## Local release (without CI)

Same commands, documented in [packaging.md](packaging.md):

```powershell
flutter build windows --release
pwsh .github/scripts/sync_windows_installer_version.ps1
iscc windows\installer\enjoy_player.iss
```
