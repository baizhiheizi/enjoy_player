# ADR-0094: fastlane for store uploads and review actions

**Status**: Accepted (2026-10-09)

## Context

Two store-upload paths had grown bespoke implementations:

1. **Google Play** — a 318-line Python script (`upload_play_aab.py`) plus a venv bootstrapper (`ensure_play_upload_tooling.sh`) that installed `google-auth` / `google-api-python-client` into a repo-local virtualenv at release time, duplicating auth decoding, chunked upload, and retry logic that fastlane `supply` maintains upstream.
2. **TestFlight** — `xcrun altool --upload-app` inside `release_lib.sh`. `altool` is macOS-only, reports only upload success (no processing state, no dSYMs, no tester handling), and pins the re-upload path (`--publish-only --testflight --skip-build`) to a Mac host.

The first App Store submission also entered review, making two more flows relevant: submitting a new build for review after a rejection, and observing the review state. Both are plain App Store Connect API calls that hand-rolled `curl`/Python would have to reinvent.

## Decision

Adopt fastlane as the single client for store-facing APIs, scoped strictly to **uploads and store actions** — builds, signing, notarization, and desktop publishing stay with the existing release scripts (ADR-0020 model unchanged).

1. **Layout**: one root [`Gemfile`](../../Gemfile) + [`fastlane/Fastfile`](../../fastlane/Fastfile) with `platform :android` / `platform :ios` blocks. The per-platform `android/fastlane` + `ios/fastlane` layout from `fastlane init` is deliberately not used: fastlane never owns builds here, so per-platform Appfiles and duplicate Gemfiles would be ceremony without benefit. Lanes: `android beta` (`upload_to_play_store`), `ios beta` (`pilot`), `ios submit_review` (`deliver` with `submit_for_review` + `submission_information`), `ios review_status` (spaceship: `app_store_state` of the edit version).
2. **Upgrades**: `Gemfile` pins `fastlane "~> 2.240"`; `Gemfile.lock` is committed with all four platforms (`ruby`, `x86_64-linux`, `aarch64-linux`, `arm64-darwin`) so no runner mutates the lock. Bumping is a one-line lock refresh.
3. **Toolchain**: Ruby 3.4 is pinned in [`mise.toml`](../../mise.toml) (fastlane requires ≥ 3.2). `ensure_fastlane_tooling.sh` installs gems into `.github/scripts/.fastlane-bundle` (gitignored) and fails fast with an install hint when Ruby/Bundler is missing. Non-mise hosts (the self-hosted Mac) need `brew install ruby` once.
4. **Entry points unchanged**: `upload_play_aab.sh` and `release_lib.sh::release_upload_testflight_ipa` keep their names, flags, exit semantics, and environment-variable contracts (`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON{,_PATH,_BASE64}`, `APP_STORE_CONNECT_*`). The Python uploader and its venv bootstrapper are deleted. `release.sh` flags (`--play`, `--testflight`), workflows, and GitHub secrets require zero changes.
5. **Review feedback stays manual by API boundary**: Apple exposes the submission *state* (`REJECTED`, `IN_REVIEW`, …) but not Resolution Center messages; `review_status` prints state, rejection notes are read by a human. Google Play has no equivalent human-review surface — `supply` release status is the whole story.

## Consequences

- The Play upload dependency surface shrinks from two Python packages to the fastlane gem; upload retries/timeouts are upstream's problem (the bespoke `GOOGLE_PLAY_UPLOAD_*` env knobs are gone with the script).
- TestFlight re-uploads (and `review_status` / `submit_review`) now run on any host with Ruby — including the Linux dev box — instead of requiring macOS `altool`.
- `submit_review` hard-codes the submission questionnaire answers (no encryption beyond HTTPS; third-party content present — the app embeds GPL FFmpeg / eSpeak-NG per ADR-0072). If those answers ever change, the lane is the single place to edit.
- One more pinned toolchain (Ruby) in `mise.toml`; `ci.yml`'s mise action installs it (cached on the self-hosted runner).

## Alternatives considered

- **Keep the Python uploader**: zero migration, but permanent maintenance of auth/retry/chunking code against two store APIs; rejected.
- **Full `fastlane init` adoption (per-platform dirs, `gym`, `match`, `snapshot`)**: `gym` rebuilds what `flutter build` already produces; `match` solves multi-machine cert sync this repo does not have (one self-hosted Mac, `APPLE_USE_RUNNER_KEYCHAIN=true`); rejected as out of scope.
- **Codemagic / Bitrise**: replaces the whole GitHub Actions release design (ADR-0067) rather than the upload step; rejected.
