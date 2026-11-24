# ADR-0107: Fetch the Gradle wrapper distribution with retries and an integrity check

## Status

Accepted (2026-11-24)

## Context

The Android APK smoke job on `main` failed on 2026-11-24 at the very first
Gradle invocation:

```
Running Gradle task 'assembleStoreDebug'...
Exception in thread "main" java.util.zip.ZipException: zip END header not found
  at java.base/java.util.zip.ZipFile$Source.findEND(ZipFile.java:1637)
  at org.gradle.wrapper.Install.unzip(Install.java:214)
```

The stack points at `org.gradle.wrapper.Install.unzip`: the **Gradle wrapper's
own distribution archive** was truncated. The same job log shows the network
that produced it:

```
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443
```

The Gradle wrapper downloads its distribution with a plain `URLConnection`:
no retry, no integrity check, and no cleanup of a partial file. It then fails
to unzip the archive it just wrote.

That makes the failure *sticky*. The truncated zip stays in
`~/.gradle/wrapper/dists/`, and the Android workflow restores exactly that
directory from `actions/cache`:

```yaml
- name: Restore Gradle distribution and dependency caches
  with:
    path: |
      ~/.gradle/wrapper/dists
      ~/.gradle/caches/modules-2
```

So one brownout writes a corrupt archive into the cache, and every later run
re-serves the same corrupt archive and fails identically — until the cache
entry is evicted by a cache-key rotation. The failure looks like a broken
build because the error mentions a zip, not a network.

This is the same shape as the engine-artifact failure
([ADR-0101](0101-flutter-engine-artifact-prefetch.md)): a download with no
retry and no verification, on a route that drops transfers.

## Decision

1. **Fetch the distribution ourselves, with retries and a verification step.**
   [`tool/prefetch_gradle_distribution.sh`](../../tool/prefetch_gradle_distribution.sh)
   reads `distributionUrl` from `android/gradle/wrapper/gradle-wrapper.properties`
   and ensures a *readable* archive is in place before the build starts:

   - it sweeps `~/.gradle/wrapper/dists` and deletes any distribution zip
     that is not a valid archive — this is the corrupt file a cache restore
     hands back;
   - it downloads the distribution with `curl` (retries, `--retry-all-errors`,
     `--continue-at -` so a truncated transfer resumes) and verifies the
     archive with `unzip -t` before accepting it;
   - the wrapper then only has to unzip a good archive.

   The wrapper's dist directory is named with a hash of the distribution URL.
   Rather than re-deriving Gradle's own hash, the script lets the wrapper
   create the directory (one `gradlew --version` attempt) and then looks the
   directory up.

2. **Run it before every Android build.**
   `android_apk_smoke.yml` and `release_android.yml` both run the prefetch
   after the Android SDK is ready and before the build step, so neither job
   depends on the wrapper's no-retry download.

3. **The prefetch is a dependency of the build, not of the network.** If the
   distribution is already present and valid, the script is a no-op; if the
   download cannot succeed, it fails with a clear message instead of letting
   the build fail with `ZipException`.

## Consequences

- A truncated distribution download can no longer reach the build, and the
  corrupt archive a cache restore returns is removed instead of being
  re-served on every subsequent run.
- The Android job's cold path grows by one download of the Gradle
  distribution (~200 MB), which is already restored from the cache in the
  common case.
- The wrapper's own distribution download is still the fallback: the script
  runs `gradlew --version` first, so a runner that already has the
  distribution never downloads anything.
- The script needs `curl` and `unzip` on the runner, both of which the Linux
  container image already provides (`ensure_linux_tooling.sh` installs the
  build essentials).
- Unlike the engine artifacts, the Gradle distribution is not pinned by
  checksum here: `gradle-wrapper.properties` carries no SHA-256, and the
  archive's integrity is verified structurally (it must unzip) rather than
  against a published digest.

## Alternatives considered

- **Delete the whole `~/.gradle/wrapper/dists` cache on failure.** Rejected:
  it throws away a ~200 MB download to fix a problem that deleting one
  corrupt file solves, and it turns a cache hit into a cold fetch.
- **Pin the distribution's SHA-256.** Deferred: the wrapper's
  `distributionSha256Sum` property would be the stronger guarantee, but it
  needs the digest for every Gradle bump to be maintained in this repo, and
  the observed failure was truncation, not substitution.
- **Let Gradle retry the download.** Not possible: the wrapper performs the
  download itself, before Gradle starts.
