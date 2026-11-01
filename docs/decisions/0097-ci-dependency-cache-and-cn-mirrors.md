# ADR-0097: CI dependency caching over the LAN cache server, with China mirrors on cache miss

## Status

Accepted (supersedes the "`actions/cache` is not used" policy in [docs/ci-self-hosted-runners.md](../ci-self-hosted-runners.md); implements issue #912)

## Context

Every workflow in this repo runs on self-hosted runners pooled behind a
per-GB OpenClash proxy, measured at ~55 GB/day of WAN traffic. Each dependency
download is paid for twice: once now, once on the next run.

The previous position was that GitHub Actions cache should not be used at all,
because `actions/cache` "bills for storage" and "adds a dependency on the
cache service". That position assumed two things that no longer hold:

1. **Dependencies stay on the runner's local disk between jobs.** They do not.
   gh-sr runs each job inside a fresh inner environment and logs
   `[gh-sr:job-started] resetting inner environment to a pristine state (image
   cache preserved)` before every run. Only the image cache survives — which is
   exactly why the Flutter SDK install in [`.github/actions/setup-flutter`](../../.github/actions/setup-flutter)
   persists (it installs under `RUNNER_TOOL_CACHE` / `~/.local/share/mise`)
   while `~/.pub-cache` and `~/.gradle` do not. A run log shows `Downloading
   packages...` and a full `(N available)` version query against pub.dev on
   every invocation.
2. **The cache backend is GitHub-hosted storage.** The pool is wired to the LAN
   **`gh-sr-cache`** server, so cache restores are served inside the LAN at
   **zero proxy cost**, and run logs report `Cache mode: write`.

So the cost the old policy was avoiding does not apply, while the problem it
assumed away is real and is the dominant line item.

## Decision

1. **Cache the dependency stores that do not survive the environment reset.**

   | Path | Workflows | Key |
   |------|-----------|-----|
   | `~/.pub-cache` | ci, codegen_drift, build_linux, build_windows, build_apple (both jobs), android_apk_smoke | `pub-<os>-<hash(pubspec.lock)>` + `pub-<os>-` prefix fallback |
   | `~/.gradle/wrapper/dists`, `~/.gradle/caches/modules-2` | android_apk_smoke | `gradle-<os>-<hash(**/gradle-wrapper.properties)>-<hash(**/pubspec.lock)>` + prefix fallbacks |
   | `~/Library/Caches/CocoaPods`, `~/.cocoapods` | build_apple (per job, keyed on `ios/` and `macos/Podfile.lock`) | `pods-<os>-<ios\|macos>-<hash(Podfile.lock)>` + prefix fallback |

2. **Gradle is cached by deliberate subset, not wholesale.** On this project
   `~/.gradle` measures ~6.1 GB, of which `caches/9.1.0` alone is ~3.8 GB of
   path-keyed, per-version script and plugin caches that are regenerated on
   every build and are not safe to replay onto a different workspace path.
   Only the two genuinely downloaded halves are cached (~740 MB distribution +
   ~1.6 GB of module artifacts), which keeps the job inside the 10 GB
   per-repository cache limit alongside the ~1.3 GB pub cache.
   `~/.android/build-cache` is **not** cached: `android/gradle.properties` does
   not enable `buildCache`, so the directory has no content to restore.

3. **Use split `actions/cache/restore` + `actions/cache/save`, guarded on
   `cache-hit != 'true'`.** A plain `actions/cache` step re-uploads the whole
   cache at post-job on every run, which would trade proxy traffic for LAN
   upload bandwidth for no gain. Splitting the pair means an exact hit writes
   nothing back; only a miss, or a prefix restore that pulled in new packages,
   saves.

4. **Mirrors are the cache-miss fallback, not the primary path.**
   `PUB_HOSTED_URL` (`https://pub.flutter-io.cn`) and `FLUTTER_STORAGE_BASE_URL`
   (`https://storage.flutter-io.cn`) are set as workflow-level `env:` on the six
   deterministic workflows, and `.github/actions/setup-flutter` now honors
   `FLUTTER_STORAGE_BASE_URL` when it has to (re)install an SDK, defaulting to
   the upstream bucket when unset.

   **Supply-chain note:** `pubspec.lock` pins every hosted package by `sha256`
   (254 entries at time of writing). A mirror serving different bytes fails the
   hash check rather than installing a different package, so routing fetches
   through a mirror does not weaken dependency integrity. This is why the mirror
   is acceptable here and would not be for an unpinned dependency.

5. **Flutter SDK installs and mise installs keep their existing disk-persistence
   behavior** (`cache: false` on the mise action stays). Those already survive
   in the preserved image cache, so caching them would only add a dependency on
   the cache service for an archive the pool fetches once per version bump.

## Consequences

- The six deterministic workflows stop re-downloading ~1.3 GB of pub packages
  and, for Android smoke, ~2.4 GB of Gradle distribution and modules on every
  run. Cache hits cost zero proxy bytes.
- `actions/cache` is now permitted for dependency stores, which reverses the
  prior policy. `docs/ci-self-hosted-runners.md` is updated to match. Build
  **artifacts** are unaffected and remain out of the cache.
- **Trade-off:** a pub-cache hit is only exact when `pubspec.lock` is unchanged.
  Every dependency bump is one cold run that writes the cache back. That is
  bounded by how often the lock file moves, and is the intended trade.
- **Risk — cache service:** if `gh-sr-cache` is unreachable, restore degrades to
  a miss and the job proceeds against the mirrors; no workflow fails on a cache
  error because both steps use the non-fatal defaults. Worth watching on the
  first runs.
- **Risk — cache size:** pub (~1.3 GB) + Gradle (~2.4 GB) live in one repo
  namespace against a 10 GB limit. If Android dependencies grow materially,
  the Gradle `modules-2` entry is the one to reconsider first.
- **Risk — CocoaPods staleness:** keyed on the committed `Podfile.lock`, so a
  pod version bump forces a new key. A prefix-only restore may still hand
  `pod install` a warm but older tree; `pod install` re-resolves against the
  lock and is idempotent, so this costs time rather than correctness.
- **Follow-up (not in this ADR):** the agentic workflows
  (`shared/runtime.md` + the gh-aw `.lock.yml` firewall allow-lists) still
  resolve from pub.dev directly and are the largest remaining per-day source of
  proxy traffic at ~12 runs/day. Moving them to the mirrors requires editing
  the allow-lists and recompiling the lock files, so it is deliberately left
  for a separate change.
- **Follow-up (not repo code):** issue #912's push-batching item — squashing
  per-session agent commits, and moving the platform build matrix to tags or a
  nightly schedule — is an operating-practice change, not a workflow edit.
  Reducing build coverage on `main` pushes was **not** done here.