# Proposal: linux-runner-toolchain-bake

## Why

Every Linux CI job re-provisions its toolchain from a flaky network: `ensure_linux_tooling.sh` apt-installs ~19 packages with sudo, `setup-flutter` downloads a ~700 MB tarball from storage.googleapis.com on first job after each container rebuild, `setup-java` fetches Temurin from adoptium.net (which redirects to GitHub release assets — the host with multi-hour TLS-reset windows that already forced the Ruby/Node toolcache pre-seed), and `setup-android` bootstrap hits `dl.google.com`, which is TLS-reset by the GFW on this network and only survives via retry loops. The gh-sr runner image supports baking toolchains at attended image-build time (`container_runner_image.toolcache`), but the repo's workflows and runner config don't use it yet — and the bake feature itself still lives on an unmerged gh-sr branch (prerequisite change in the gh-sr repo, `toolcache-bake-xz-strip`).

## What Changes

- Update `~/.gh-sr/runners.yml` (external ops file, applied via `gh sr setup/up/rebuild`):
  - `container_runner_image.extra_apt_packages`: add the Flutter/Linux desktop build stack (clang, cmake, ninja-build, zip, libgtk-3-dev, liblzma-dev, libsqlite3-dev, libgstreamer1.0-dev, libgstreamer-plugins-base1.0-dev, libsecret-1-dev, libmpv-dev) so `ensure_linux_tooling.sh` becomes a no-op safety net on this pool.
  - `container_runner_image.toolcache`: add Flutter 3.44.0 stable (linux x64 tar.xz, dir `flutter-3.44.0-stable` — matches `.github/actions/setup-flutter`'s persistent-install layout exactly) and a pinned Temurin JDK 17 tarball (strip-components 1, lands at `jdk-temurin-17/bin/java` — matches `.github/actions/setup-java`). Keep the existing Ruby 4.0.5 / Node 24.21.0 entries.
  - Correct the stale header comments (one shared pool is the decided topology; no CI/agents split).
- Harden `.github/actions/setup-android` against the GFW: default `SDK_TEST_BASE_URL` to the Tencent Android SDK mirror (env-overridable) so both the `sdkmanager` package installs and license acceptance survive a cold container after `gh sr rebuild`.
- Rebuild the runner image (`gh sr rebuild baizhiheizi`) and verify with `gh sr doctor --strict`, then smoke-run `ci.yml`, `build_linux.yml`, and `android_apk_smoke.yml` via `workflow_dispatch`, confirming cold-start jobs skip the previously-downloaded toolchains.

Out of scope: agentic (gh-aw) workflow sources, engine/egress configuration, and the stale compiled agentic artifacts (`agentic_commands.yml`, `agentics-maintenance.yml`, `.github/aw/actions-lock.json`) — those belong to the follow-up agentic-workflows change. Prerequisite: gh-sr change `toolcache-bake-xz-strip` (rebase + tar.xz + strip support), merged and the `gh sr` extension reinstalled, before the rebuild step.

## Capabilities

### New Capabilities
- `ci-runner-toolchain`: How the Linux self-hosted runner pool is provisioned for this repo's CI — baked toolchains in the gh-sr runner image keyed to the repo's version pins, mirror-resilient Android SDK setup, and the demoted role of the runtime `ensure_linux_tooling.sh` fallback.

### Modified Capabilities
<!-- none — agentic-workflows-runtime is intentionally untouched (out of scope) -->

## Impact

- **Files**: `.github/actions/setup-android/action.yml`; `~/.gh-sr/runners.yml` (outside the repo — ops state, not version-controlled here).
- **Systems**: baizhiheizi org runner pool on host `x1` (4× DinD containers, image `gh-sr/agentic-runner`); requires the merged gh-sr `toolcache-bake-xz-strip` feature and a locally reinstalled `gh sr` extension; one attended image rebuild.
- **Workflows affected indirectly**: `ci.yml`, `build_linux.yml`, `codegen_drift.yml`, `release_linux.yml`, `android_apk_smoke.yml`, `release_android.yml` — no YAML edits, but their setup steps change behavior (skip downloads when the toolcache probe hits).
- **Risk**: bake entries pin exact tool versions; a `.github/flutter-version` bump changes `setup-flutter`'s probe path and falls back to the existing runtime download (safe), but the bake entry should be updated in the same PR to keep cold starts fast.
