# ADR-0101: Prefetch the Flutter engine Android artifacts into a local Maven repository

## Status

Accepted (amends [ADR-0097](0097-ci-dependency-cache-and-cn-mirrors.md) — the
CI dependency cache saved its contents before the build and could therefore
never capture the artifacts the build downloaded)

## Context

The Android APK smoke build failed on `main` with

```
> Could not resolve all files for configuration ':app:storeDebugCompileClasspath'.
   > Failed to transform armeabi_v7a_debug-1.0.0-<engine>.jar (io.flutter:armeabi_v7a_debug:1.0.0-<engine>)
      > Could not download armeabi_v7a_debug-1.0.0-<engine>.jar
         > Could not HEAD 'https://storage.flutter-io.cn/download.flutter.io/io/flutter/...'
            > Remote host terminated the handshake
```

Two independent problems produced that failure.

1. **Gradle cannot retry.** The Flutter Gradle plugin resolves the engine
   artifacts — the embedding plus one `libflutter.so` jar per ABI — from
   `$FLUTTER_STORAGE_BASE_URL/download.flutter.io`. Gradle downloads them
   without a retry, and the China mirror that serves them resets the TLS
   handshake in bursts: measured from a host on the same network as the
   runner, 6 of 8 consecutive requests failed in one window and 10 of 10
   succeeded in the next. One reset fails the whole build, and the artifacts
   total ~520 MB (3 ABIs × debug/release), so a restart is expensive.

2. **The artifacts were re-fetched on every run.** [ADR-0097](0097-ci-dependency-cache-and-cn-mirrors.md)
   splits `actions/cache` into a restore and a save, with the save guarded on
   `cache-hit != 'true'`, "so an exact hit writes nothing back; only a miss, or
   a prefix restore that pulled in new packages, saves". Both steps sat
   *before* `flutter pub get` and the Gradle build, so a save captured only
   the restored snapshot — never the packages the build had just downloaded.
   The Gradle cache key is
   `gradle-<os>-<hash(gradle-wrapper.properties)>-<hash(pubspec.lock)>` and does
   not mention the Flutter version, which is exactly what the `io.flutter`
   artifact versions are keyed on. The cache therefore stayed frozen at the
   contents of its first write, and the engine artifacts were re-downloaded
   from the flaky mirror on every single build.

The two problems compound: the fragile download was both frequent and
unretried.

## Decision

1. **Prefetch the engine artifacts into a local Maven repository.**
   [`tool/prefetch_flutter_engine_android_libs.sh`](../../tool/prefetch_flutter_engine_android_libs.sh)
   downloads the `io.flutter` artifacts with `curl` — retries, `--continue-at -`
   so a truncated transfer resumes instead of restarting, and a speed limit so
   a stalled transfer aborts instead of hanging for half an hour — into
   `build/flutter-engine-maven/` in Maven layout. The artifact version is read
   from the installed Flutter SDK (`bin/cache/engine.stamp`), so a Flutter bump
   moves to a new engine version automatically instead of leaving the script
   pinned to a stale one. The China mirror is tried first (it is routed DIRECT
   and costs no proxy bytes) and the upstream bucket is the fallback.

2. **Resolve the engine artifacts from disk.**
   [`android/build.gradle.kts`](../../android/build.gradle.kts) lists that
   directory first in `allprojects.repositories`, so Gradle resolves `io.flutter:*`
   from the local repository and never contacts the mirror. The directory is
   absent on a checkout that did not run the prefetch, in which case the
   mirror remains the source.

3. **Cache the prefetched artifacts under their own key.**
   They are a function of the Flutter version alone, so they get a
   `flutter-engine-<os>-<flutter-version>` cache entry rather than riding
   along with the Gradle module cache. The ~520 MB is fetched once per Flutter
   version instead of once per run.

4. **Save the dependency caches after the build.**
   The pub and Gradle cache saves move to the end of the job so they capture
   what the build actually downloaded, and each targets the *primary* key: an
   exact hit skips the save, and a prefix restore writes the primary key so the
   next run hits exactly. (Writing the matched prefix key instead would fail,
   because that key already exists.)

5. **Put the Flutter version in the Gradle cache key.**
   A save is skipped on an exact hit, so a key that never changes means a
   cache that never learns what the build downloaded. The engine's dependency
   set — the androidx versions it pins, among others — follows the Flutter
   version, so the key carries it: `gradle-<os>-<hash(gradle-wrapper.properties)>-<hash(pubspec.lock)>-<flutter-version>`.
   A Flutter bump now rotates the key, the save fires, and the artifacts the
   build fetched are captured instead of being re-fetched on every run.

## Consequences

- The Android build no longer depends on the mirror for its largest and most
  failure-prone downloads. The one-time cost per Flutter version is a
  retrying, resumable fetch instead of a single unretried Gradle download.
- The engine artifacts are fetched once per Flutter version rather than once
  per run, which also removes ~520 MB of mirror traffic per Android build.
- The dependency caches now capture what the build downloaded, so a dependency
  bump — or a Flutter bump — is a single cold run rather than a permanent
  cold path. The first run after such a bump still fetches the full set.
- The local Maven repository adds a copy of the engine artifacts to the job's
  workspace (~520 MB) alongside the Gradle module cache. The Gradle cache
  itself does not grow by that amount: Gradle resolves a `file://` repository
  in place rather than copying the artifact into its own file store.
- The prefetch script verifies what it downloads — a complete zip for jars, the
  expected artifact and version for POMs — and writes the SHA-1/MD5 sidecars
  Gradle checks, so a truncated transfer cannot reach the build.
- The prefetch is a dependency of the local Maven repository, not of the
  mirror: if the prefetch is skipped the build still works, it just falls back
  to resolving the engine artifacts from the mirror.
- The Gradle cache gains one dimension, so a Flutter bump leaves an extra
  ~2.4 GB entry behind until the cache server evicts it. The per-repository
  limit is 10 GB and eviction is LRU, so this is bounded, but the entries are
  worth watching.
