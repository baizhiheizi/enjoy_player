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

- **macOS**: each cache hit restored a **~1013 MB** pub-cache archive (plus a
  ~47 MB CocoaPods archive) from GitHub's cache service through the per-GB WAN
  proxy — `Cache Size: ~1013 MB` / `Cache restored successfully` in the run
  log, roughly 8 minutes per hit — while `~/.pub-cache` (2.9 GB),
  `~/.cocoapods` and `~/Library/Caches/CocoaPods` already sat on the same
  disk. On a lock-hash miss the guarded save step re-uploaded ~1 GB (on an exact
  hit it was skipped). Measured on the clash traffic tracker: ~2.6 GB/day down
  + ~1.2 GB/day up of pure `productionresultssa*` cache churn from the mac.
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

   `flutter pub get` and `pod install` reuse what those stores already hold, so
   a lockfile / `Podfile.lock` bump costs one network pass on the native
   runner, not a full re-download.
2. **Keep `actions/cache` for the container pool** (ADR-0097). The per-job
   reset makes it necessary there, and the LAN `gh-sr-cache` server makes it
   free of WAN bytes.
3. **Mirror only the Flutter SDK in the Apple/Windows release workflows.**
   `FLUTTER_STORAGE_BASE_URL` (`https://storage.flutter-io.cn`) matches the
   build twins, so a tag build with a cold Flutter SDK (version bump, wiped
   tool cache) pulls from the mirrored bucket instead of
   `storage.googleapis.com` through the proxy. `PUB_HOSTED_URL` is deliberately
   **not** set on releases (unlike the build/CI workflows): changing pub's
   default hosted source makes `pub get` re-resolve the committed
   `pubspec.lock` against the mirror — entries rewritten pub.dev → mirror, and
   versions moved within constraints (16 packages when measured, e.g.
   `archive` 4.5.1 → 4.5.2) — so a release could ship versions that are not in
   the tag's lock. Releases are rare, so the extra proxy traffic of a cold
   pub cache is acceptable for lock fidelity. Neither setting reintroduces a
   cache: the release workflows still use no `actions/cache`.
4. **Build/CI keeps `PUB_HOSTED_URL` (ADR-0097 §4) and therefore accepts lock
   re-resolution.** On those workflows the mirror is the cache-miss fallback,
   and the side-effect is that `pub get` re-resolves the committed lock against
   the mirror (same 16-package drift). That behavior predates this ADR and is
   unchanged; release builds deliberately do not share it (decision 3).

## Consequences

- macOS jobs save the ~8 min pub-cache restore and the ~1 GB/job download;
  Windows jobs lose two no-op steps and the failing cache post-step.
- This ADR **supersedes** the `build_apple` / `build_windows` rows of
  ADR-0097's cache table (ADR-0097 itself stays immutable); its reasoning still
  stands for the four container-pool workflows that keep caching.
- **Risk — cold native runner:** a re-provisioned or wiped runner (new machine,
  `gh sr update`, reinstalled tool cache) starts cold. `pub get` / `pod
  install` then go to the mirrors / CDN once and rebuild the on-disk stores; no
  workflow fails and the shipped artifacts are unchanged (releases keep
  resolving the committed lock — decision 3).
- **Risk — stale on-disk store:** the native stores are not keyed by
  `pubspec.lock` / `Podfile.lock`. Pub and CocoaPods re-resolve against the
  committed manifests (the build workflows' mirror env can move versions within
  constraints; releases cannot — decision 3), so staleness costs time, not
  correctness.
- Docs: [`docs/ci-self-hosted-runners.md`](../ci-self-hosted-runners.md) now
  scopes `actions/cache` to container jobs and describes the native-runner
  persistence.
