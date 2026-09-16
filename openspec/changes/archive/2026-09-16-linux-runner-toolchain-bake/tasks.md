# Tasks: linux-runner-toolchain-bake

## 1. Prerequisites (external)

- [x] 1.1 Confirm gh-sr change `toolcache-bake-xz-strip` is merged to main with tar.xz + strip support, and the `gh sr` extension is reinstalled from it (`gh sr version` / `gh extension list`; bake smoke: `gh sr setup --help` accepts updated config schema). Verify: `gh sr doctor` runs clean on config validation.
- [x] 1.2 Spike: confirm the pinned cmdline-tools zip and the target `platforms;android-36` / `build-tools;36.0.0` paths exist on the Tencent mirror (`repository2-3.xml`), and record the exact mirror cmdline-tools filename + sha1. Verify: checksum match on a downloaded archive.
  - Findings (2026-09-16): `commandlinetools-linux-12266719_latest.zip` present (HTTP 200, 165,618,711 B) — the workflow's pinned version. `platform-36_r02.zip` sha1 `2c1a80dd4d9f7d0e6dd336ec603d9b5c55a6f576` verified by download. `build-tools_r36_linux.zip` listed (63,737,259 B, sha1 `b0b6376977657e8ad9b969bacf4093601da2c6fb`). `repository2-3.xml` served (413 KB).

## 2. Runner configuration (`~/.gh-sr/runners.yml`)

- [x] 2.1 Extend `container_runner_image.extra_apt_packages` with `clang cmake ninja-build zip libgtk-3-dev liblzma-dev libsqlite3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsecret-1-dev libmpv-dev` (keep `librsvg2-bin`). Verify: `gh sr doctor` config validation passes.
- [x] 2.2 Add toolcache entry for Flutter: `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.0-stable.tar.xz`, dir `flutter-3.44.0-stable` (no strip). Verify: YAML valid; `gh sr doctor` accepts the entry set.
- [x] 2.3 Add toolcache entry for Temurin JDK 17: pinned `OpenJDK17U-jdk_x64_linux_hotspot_<version>.tar.gz` release asset (exact version resolved from adoptium/temurin17-binaries latest 17 GA), dir `jdk-temurin-17`, strip 1. Record the resolved version in a YAML comment. Verify: URL downloads and `tar -tzf` lists `jdk-*/bin/java` at top level.
- [x] 2.4 Fix the stale header comments: one shared pool (CI + agents, no split), bake list points at `.github/flutter-version` and the JDK pin for same-PR updates. Verify: comment text reviewed in final diff.
  - 2.3 resolved pin: Temurin 17 latest GA `jdk-17.0.20.1+1`, asset `OpenJDK17U-jdk_x64_linux_hotspot_17.0.20.1_1.tar.gz` (193,252,603 B).

## 3. Repo-side: mirror-resilient setup-android

- [x] 3.1 Add `sdk_mirror_base_url` input (default `https://mirrors.cloud.tencent.com/AndroidSDK/`) to `.github/actions/setup-android`; export `SDK_TEST_BASE_URL` (env override wins) before license acceptance and package install steps. Verify: step logs show the mirror env; grep no remaining unconditional dl.google.com dependency in the install path.
- [x] 3.2 Add cmdline-tools bootstrap bypass: when no `sdkmanager` is found under `$ANDROID_HOME/cmdline-tools`, download the pinned cmdline-tools zip from the mirror (sha1-verified, per spike 1.2), unpack to `$ANDROID_HOME/cmdline-tools/<version>`, then continue with the existing flow. Verify: simulate a cold container locally (`docker run` with empty HOME) and confirm sdkmanager lands without dl.google.com.
  - Design refinement during implementation: mirror-first, android-actions demoted to last-resort fallback (probe → mirror bypass → upstream action), so a cold GFW'd container never waits on a doomed dl.google.com attempt first. Integrity = zip CRC via unzip (dynamic sha1 lookup from the XML dropped; the mirror-fidelity checksum was proven in spike 1.2). Simulation: mirror zip → unpack → `sdkmanager --list` with `SDK_TEST_BASE_URL` fetches the remote repository fully mirror-backed.
- [x] 3.3 Confirm the retry wrapper still guards the mirror path (retries retained for transient mirror errors) and the idempotent skip path is untouched. Verify: re-read action flow; run `actionlint` if available.
  - actionlint 1.7.12 (mise x): 0 errors on android_apk_smoke.yml, release_android.yml, build_linux.yml (includes local composite-action input checks).

## 4. Rebuild and verify

- [x] 4.1 `gh sr rebuild baizhiheizi` (attended; image rebuilds with bake entries, containers recreated, registrations preserved). Verify: `gh sr status` shows BUILD `ok` for all 4 instances.
  - Two rebuilds: (1) initial — revealed a gh-sr writer bug (below); (2) with explicit JDK `complete` marker — image `2.337.0-x451aaa21`, BUILD `ok (a3f6e3c0)` ×4.
  - **gh-sr bug found (upstream fix pending)**: `containerToolcacheExtraFile` renders `complete`-unset + `strip`-set entries as 3 fields (`url dir 1`), which the bake loop misreads (`complete="1"`, strip 0) — stray `1` marker file, wrapper dir preserved. Worked around by declaring `complete: jdk-temurin-17.complete` explicitly (4-field form is unambiguous).
- [x] 4.2 `gh sr doctor --strict` — all checks green (node/npm, zstd, docker-socket-user, cache-env, hygiene). Verify: exit 0.
  - One transient FAIL on baizhiheizi-2 (registration race during first boot, `.runner` appeared seconds later); clean on re-run: 0 failed, 0 warnings.
- [x] 4.3 Inspect baked toolcache inside a container: `docker exec gh-sr-baizhiheizi-1 ls /home/runner/.toolcache` shows `flutter-3.44.0-stable`, `jdk-temurin-17`, `Ruby`, `node`; and `docker exec ... bash -c 'dpkg-query -W clang cmake ninja-build libmpv-dev'` shows installed. Verify: all present.
  - All four toolcache entries + markers present; `jdk-temurin-17/bin/java` runs (OpenJDK 17.0.20.1); flutter bin + `.git` probe paths intact; all 12 apt stack packages installed.
- [x] 4.4 Smoke `ci.yml` via workflow_dispatch on a branch; confirm `Ensure Linux tooling` reports "already installed", `setup-flutter` skips the download, tests pass. Verify: green run with skip logs.
  - Run 35052082114 ✓. setup-flutter: 74 ms, version banner from the baked SDK, `FLUTTER_ROOT=/home/runner/.toolcache/flutter-3.44.0-stable/flutter`, zero download. Gap found: `python3-venv` (script list, not in core manifest nor bake list) was runtime-installed → bake list amended (with `xz-utils` for explicitness), re-verified after rebuild.
- [x] 4.5 Smoke `build_linux.yml`; confirm debug+release builds succeed from the baked stack. Verify: green run.
  - Run 35052084601 ✓ (9m05s). Debug+release builds green against baked Flutter + gtk/gstreamer/mpv stack.
- [x] 4.6 Smoke `android_apk_smoke.yml` from a cold container (recreate one instance first if needed); confirm android setup completes mirror-backed without dl.google.com and the APK assembles. Verify: green run; setup logs show mirror base URL.
  - Run 35053153736 on branch `ci/android-sdk-mirror-tooling` ✓ (21m51s, cold container post-rebuild). Logs show `SDK_TEST_BASE_URL=https://mirrors.cloud.tencent.com/AndroidSDK/` active; the android-actions bootstrap — now mirror-env'd too — succeeded in this dl.google.com window and installed the packages, and the install step verified presence and skipped. The cmdline-tools mirror bypass itself was exercised end-to-end in the local simulation (task 3.2). Branch left pushed for merge.
