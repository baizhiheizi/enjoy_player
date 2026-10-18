# ADR-0099: Native macOS/Windows runners keep their dependency caches on disk

**Status**: Accepted (2026-10-18)
**Amends**: [ADR-0097](0097-ci-dependency-cache-and-cn-mirrors.md) — its
dependency-caching decision applies to the gh-sr **container** pool only; the
native macOS and Windows runners keep their package stores on the runner's
persistent disk and must not use `actions/cache` for them.

## Context

ADR-0097 introduced `actions/cache` for dependency stores after observing that
gh-sr resets each job's "inner environment" to a pristine state, so
`~/.pub-cache`, `~/.gradle` and the CocoaPods stores do not survive between
jobs.

That observation is specific to `runner_mode: container` (the Linux pool:
`ci`, `codegen_drift`, `build_linux`, `android_apk_smoke`, `release_linux`,
`release_android`). The per-job reset is a runner **hook shipped inside the
gh-sr agentic container image** (`gh-sr`:
`internal/runner/agentic-runner-image/hooks/job-started.sh`, wired through
`ACTIONS_RUNNER_HOOK_JOB_STARTED`), so it only runs for container jobs. The
macOS and Windows runners are **native** (`~/.gh-sr/runners.yml`: no
`runner_mode`, and gh-sr defaults to `native`) — there is no inner environment
to reset. Their job process runs directly as the host user, so `$HOME` /
`%USERPROFILE%` and the local tool cache persist between jobs.

`build_apple` and `build_windows` nevertheless carried
`actions/cache/restore` + `actions/cache/save` pairs copied from the container
workflows. The measured effects on the native runners were:

- **macOS**: every job restored a **~1013 MB** pub-cache archive (plus a
  ~47 MB CocoaPods archive) from GitHub's cache service through the per-GB WAN
  proxy — `Cache Size: ~1013 MB` / `Cache restored successfully` in the run
  log, roughly 8 minutes per job — while `~/.pub-cache` (2.9 GB),
  `~/.cocoapods` and `~/Library/Caches/CocoaPods` already sat on the same
  disk. The save step then re-uploaded ~1 GB. Measured on the clash traffic
  tracker: ~2.6 GB/day down + ~1.2 GB/day up of pure
  `productionresultssa*` cache churn from the mac.
- **Windows**: pub's cache lives at `%LOCALAPPDATA%\Pub\Cache`, not
  `~/.pub-cache`, so the restore never hit and every save failed with
  `[warning]Path Validation Error: Path(s) specified in the action for caching
  do(es) not exist, hence no cache is being saved.` The pair was dead weight
  that also left a warning on the job.
- The native runner has no `gh-sr-cache` backend anyway: the cache-URL
  redirect comes from the container runner fork/image; a stock native runner
  receives GitHub's cache service URL from the Actions service.

The container-pool workflows are unaffected and keep their restore/save pairs:
there the per-job reset is real and `gh-sr-cache` serves hits at zero proxy
bytes.

## Decision

1. **No dependency-store caching on the native runners.** `build_apple` and
   `build_windows` use no `actions/cache` for pub or CocoaPods. They rely on
   the runner's persistent filesystem:
   - macOS: `~/.pub-cache`, `~/.cocoapods`, `~/Library/Caches/CocoaPods`
   - Windows: `%LOCALAPPDATA%\Pub\Cache`

   `flutter pub get` and `pod install` fetch only what those stores are
   missing, so a lockfile / `Podfile.lock` bump costs one network pass on the
   native runner, not a full re-download.
2. **Keep `actions/cache` for the container pool** (ADR-0097). The per-job
   reset makes it necessary there, and the LAN `gh-sr-cache` server makes it
   free of WAN bytes.
3. **Set the China mirrors in the Apple/Windows release workflows too**, matching
   their build twins: `PUB_HOSTED_URL` (`https://pub.flutter-io.cn`) and
   `FLUTTER_STORAGE_BASE_URL` (`https://storage.flutter-io.cn`). A tag build
   with a cold Flutter SDK (version bump, wiped tool cache) then pulls from the
   mirrored bucket instead of `storage.googleapis.com` through the proxy.
   Mirrors are the cold-start path; they do not reintroduce a cache (the
   release workflows still use no `actions/cache`).

## Consequences

- macOS jobs save the ~8 min pub-cache restore and the ~1 GB/job download;
  Windows jobs lose two no-op steps and the failing cache post-step.
- ADR-0097's cache table no longer lists `build_apple` / `build_windows`; its
  reasoning still stands for the four container-pool workflows that keep
  caching.
- **Risk — cold native runner:** a re-provisioned or wiped runner (new machine,
  `gh sr update`, reinstalled tool cache) starts cold. `pub get` / `pod
  install` then go to the mirrors / CDN once and rebuild the on-disk stores; no
  workflow fails and no artifact changes.
- **Risk — stale on-disk store:** the native stores are not keyed by
  `pubspec.lock` / `Podfile.lock`. Pub and CocoaPods re-resolve against the
  committed lock files and fetch only missing versions, so staleness costs
  time, not correctness.
- Docs: [`docs/ci-self-hosted-runners.md`](../ci-self-hosted-runners.md) now
  scopes `actions/cache` to container jobs and describes the native-runner
  persistence.
