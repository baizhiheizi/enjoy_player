# ADR-0106: Disk headroom, bounded job budgets, and a retried release compile on the self-hosted runners

## Status

Accepted (2026-11-24)

## Context

Three platform builds on `main` failed on 2026-11-24, and none of them was a
code failure. Each failure mode was opaque: the job log named a symptom that
had nothing to do with the cause.

1. **The macOS smoke job ran out of disk.** It died 8 minutes into the
   Release compile with the runner's own exception:

   ```
   System.IO.IOException: No space left on device :
     '/Users/an-lee/.gh-sr/runners/mac-1/_diag/pages/…'
     at GitHub.Runner.Worker.ExecutionContext.Write(String tag, String message)
   ```

   The runner lost the volume while writing its own log pages, so the job log
   simply stops mid-`CompileC` with no error line. The macOS job had already
   passed its Debug build; the universal (x86_64 + arm64) Release build is the
   peak, and it ran on a runner whose workspace still held the iOS job's
   DerivedData and whose tool cache still held a superseded Flutter SDK
   (3.47.6, 3.9 GB, next to the pinned 3.50.1). On that host the macOS
   runner's `_work` tree had grown to 12 GB.

2. **The Linux build lost the runner.** GitHub reported "The self-hosted
   runner lost communication with the server" during
   `Flutter build linux (release)`, with no test output at all. This is the
   pool's documented starvation shape ([ADR-0105](0105-ci-test-sharding-and-host-lane-budget.md)),
   and the same push also pushed the `CI` workflow to 1 h 0 m against a 13.1
   minute solo reference — six workflows, one push, all on the shared pool.

3. **The Android APK job hit a truncated archive.**

   ```
   Exception in thread "main" java.util.zip.ZipException: zip END header not found
     at org.gradle.wrapper.Install.unzip(Install.java:214)
   ```

   The Gradle wrapper had downloaded a truncated distribution zip during a
   network brownout (`curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL`) and
   then failed to unzip it.

Two structural gaps turned these into mysteries:

- **The self-hosted platform jobs had no `timeout-minutes`.** `ci.yml` and
  `android_apk_smoke.yml` bound their jobs; `build_apple.yml`,
  `build_linux.yml` and `build_windows.yml` did not. Self-hosted jobs have no
  default timeout, so a starved or wedged build could hold a runner
  indefinitely.
- **Nothing checked the runner's disk before the expensive build.** The
  failure arrived at minute 8, inside an Xcode compile, in the form of an
  IOException from the runner's log writer.

A separate machine-level failure surfaced while verifying the builds locally:
`codesign` failed with `errSecInternalComponent` for *every* identity because
the login keychain was locked. A locked keychain still lists its certificates,
so `security find-identity` succeeds and the failure only appears at signing
time, as a Security framework error that names neither the keychain nor the
lock. The release workflow defaults to `APPLE_USE_RUNNER_KEYCHAIN=true`, which
means it signs from that same login keychain — so a locked keychain there
fails a release with the same opaque message.

## Decision

1. **Claim the disk before the Apple build.**
   [`.github/scripts/ensure_macos_disk_headroom.sh`](../../.github/scripts/ensure_macos_disk_headroom.sh)
   runs in `prune` mode at the start of both Apple smoke jobs and in the Apple
   release job. It removes what CI owns and nothing else — the superseded
   Flutter SDKs in `RUNNER_TOOL_CACHE` (the pinned version always survives)
   and the workspace's previous `build/ios` / `build/macos` DerivedData — and
   then requires `APPLE_DISK_HEADROOM_GIB` of free space on
   the workspace volume. A volume that cannot hold the build fails with an
   `::error::` line naming the numbers, before the build starts, instead of an
   IOException eight minutes into an Xcode compile.

   The floor defaults to **8 GiB**: twice the ~4 GB the macOS Release
   compile's DerivedData tree actually consumes. It is a safety floor, not a
   disk-hygiene quota — it has to catch the volume *before* the build reaches
   zero (where it failed on 2026-11-24) while still being reachable on a
   runner whose volume is tight for unrelated reasons. A floor the runner
   cannot reach without manual cleanup would block every Apple job, which is
   the opposite of what it is for. Raise it on a host with room.

2. **Re-check before the release build.** The same script runs in `check` mode
   (no deletion) immediately before each Release compile, because the Debug
   build's DerivedData is still on disk when the Release build starts and the
   universal Release build is the peak.

3. **Bound every self-hosted platform job.** `build_apple.yml` (both jobs),
   `build_linux.yml` and `build_windows.yml` now carry `timeout-minutes: 45`,
   matching the shape `ci.yml` and `android_apk_smoke.yml` already used. A
   wedged build can no longer hold a runner forever.

4. **Retry the expensive Linux compile.**
   [`.github/scripts/retry_command.sh`](../../.github/scripts/retry_command.sh)
   runs `flutter build linux --release` up to three times with escalating
   backoff. ADR-0105 already established that "lost communication" on this
   pool is host starvation rather than a broken build, and prescribed a retry
   before suspecting the suite; this makes that retry part of the job instead
   of a manual re-run.

5. **Report a locked keychain as a locked keychain.**
   `setup_apple_signing.sh` checks the login keychain before the release signs
   and fails with an actionable `::error::` when it is locked, and
   `packages/forced_alignment/native/bundle_into_app.sh` does the same before
   it re-signs `libespeak-ng.dylib` in a local macOS build. Both replace the
   opaque `errSecInternalComponent` with the actual cause and the fix.

## Consequences

- A full runner disk is now a clear, early, actionable failure instead of a
  truncated log and a mystery. The guard reclaimed 8 GB on the macOS runner
  (`_work` went from 12 GB to 4.3 GB) purely by dropping the superseded
  Flutter SDK and the previous run's DerivedData.
- The disk floor is a policy number, not a measurement. 8 GiB is twice the
  observed peak (the universal Release build's DerivedData is ~4 GB), so the
  build still has room to grow when the floor is met; `APPLE_DISK_HEADROOM_GIB`
  overrides it on a host with more or less to spare.
- The floor is deliberately not a disk-hygiene quota. The runner's volume is
  shared with the local checkout, the system asset store and the developer
  toolchain, and on this host ~25 GB of it sits in orphaned simulator-runtime
  assets that no supported command reaches. A floor the runner cannot reach
  would turn every Apple job red for a reason the guard cannot fix, so the
  host's own headroom is a separate problem — and the guard's job is to make
  it visible before the build, not to enforce it.
- The guard only deletes what CI owns. It never touches the user's
  `~/Library/Developer/Xcode` caches, the simulator runtimes, the pub cache
  or the CocoaPods store, so it cannot silently shrink a developer's machine.
- The `prune` step removes the workspace's `build/ios` and `build/macos`
  trees. `actions/checkout` already clears them with `git clean -ffdx`, so
  this is belt-and-braces for the case where the checkout's clean is skipped
  or the tree was written by an earlier step.
- The Linux release build can now take up to three times as long before it
  goes red. The retry is bounded and the backoff is 30 s, 60 s.
- A locked login keychain still fails the build — the guard only makes the
  message say so. Unlocking remains a machine-state operation
  (`security unlock-keychain`), not something the workflow can do for itself.
- The disk floor does not bound the *pool's* concurrency. Six workflows still
  start on one push and still contend for the same hosts; that remains the
  gh-sr-side lever ADR-0105 identified (more hosts, more instances per host
  within the lane budget), not a repo change.

## Alternatives considered

- **Retry the whole Apple job on failure.** Rejected: a retry re-runs an
  8-minute compile that was already going to fail the same way, and it does
  not tell the operator which disk ran out. Checking the volume first is
  cheaper and names the cause.
- **Prune the tool cache in `setup-flutter` itself.** Rejected: that action's
  contract is "install the pinned Flutter version", and version-keyed cache
  retention is its own concern. Keeping the prune in a separate script means
  the same sweep can run before the Flutter install (freeing room for a cold
  SDK download) without changing that action's contract.
- **Delete the simulator runtimes to reclaim ~27 GB.** Rejected: they are
  system-level, shared with local development, and need `sudo`. They are also
  not what the failed run needed — the failure was the build's own
  DerivedData.
- **Raise the pool's concurrency budget to stop the Linux starvation.**
  Rejected: the budget is the thing ADR-0105 exists to protect, and the
  choice of host topology is a gh-sr-side decision.
