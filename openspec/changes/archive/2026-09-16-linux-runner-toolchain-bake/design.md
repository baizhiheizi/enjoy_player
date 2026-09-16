# Design: linux-runner-toolchain-bake

## Context

The baizhiheizi org pool runs 4× DinD agentic-profile containers on host `x1` (gh-sr, image `gh-sr/agentic-runner`, layout v2). Container rootfs persists across jobs but is wiped on `gh sr rebuild`; `/runner-state/docker-data` persists across rebuilds. The image supports two attended build-time provisioning knobs from `runners.yml`: `extra_apt_packages` and — on the `feat/container-runner-toolcache-bake` branch, prerequisite change `toolcache-bake-xz-strip` — `toolcache` entries (`url`/`dir`/`complete`/`strip`) extracted into `/home/runner/.toolcache` with 8 retries. `RUNNER_TOOL_CACHE` is `/home/runner/.toolcache`; the repo's `setup-flutter` and `setup-java` actions already install into and probe version-keyed directories under it.

Network reality on this host: `dl.google.com` TLS-reset (GFW, blocks Android SDK and would block a Chrome bake); GitHub release-asset hosts TLS-reset in multi-hour windows (already forced the Ruby/Node bake); `storage.googleapis.com` and the Tencent Android mirror (`mirrors.cloud.tencent.com/AndroidSDK/`) work reliably. The mirror is a Nexus repo: direct file paths only, no directory listing; filenames + sha1 come from `repository2-3.xml`; classic `sdkmanager` honors `SDK_TEST_BASE_URL` for both the repo index and full component installs (proven on the host, see memory `android-sdk-gfw-mirror-setup`).

## Goals / Non-Goals

**Goals:**
- Cold container after `gh sr rebuild` reaches a green CI run with zero reliance on flaky hosts (release-asset TLS windows, dl.google.com).
- Version-pinned, reproducible image contents; bake entries updated in the same PR as pin bumps.
- `setup-flutter` / `setup-java` / `ensure_linux_tooling.sh` remain the source of truth for probing — no new repo-side cache logic beyond `setup-android`.

**Non-Goals:**
- Agentic workflow sources, engine/egress config, recompile of stale gh-aw artifacts (follow-up change).
- Pool topology changes (single shared pool stays; only the stale comment is corrected).
- Windows/macOS runner provisioning.
- Repackaging or forking the Flutter tarball (use upstream storage.googleapis.com artifact as-is).

## Decisions

1. **Apt stack via `extra_apt_packages`, not gh-sr's core manifest.** Core manifest stays org-agnostic (gh-sr upstream concern); the Flutter desktop stack is repo/org-specific. Core already covers pkg-config, python3, git, curl, jq, unzip, build-essential — so the extra list is: `clang cmake ninja-build zip libgtk-3-dev liblzma-dev libsqlite3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsecret-1-dev libmpv-dev` (plus existing `librsvg2-bin`). `ensure_linux_tooling.sh` is unchanged and demotes to safety net by virtue of the bake.

2. **Flutter baked as a toolcache entry with no strip.** Upstream tarball `flutter_linux_3.44.0-stable.tar.xz` contains top-level `flutter/`; extracting into dir `flutter-3.44.0-stable` yields `$RUNNER_TOOL_CACHE/flutter-3.44.0-stable/flutter` — exactly the probe path, and release tarballs are git checkouts so the `.git` check passes. The `.complete` marker default is harmless (setup-flutter ignores it). Requires the prerequisite's tar.xz support (`xz-utils` in core manifest).

3. **JDK baked as a pinned release tarball with `strip: 1`.** Adoptium `latest/ga` API URLs resolve under the image to moving targets — pin an exact `OpenJDK17U-jdk_x64_linux_hotspot_<ver>.tar.gz` release asset (top-level `jdk-<ver>+<b>/` dir, so strip-components 1 lands `bin/java` at `jdk-temurin-17/`). Exact version/filename resolved at implementation time and recorded in `runners.yml` comments.

4. **Android mirror default inside `setup-android`, not a gh-sr knob or warmup ritual.** The action exports `SDK_TEST_BASE_URL` defaulting to the Tencent mirror (input-overridable, env wins), which classic `sdkmanager` honors for manifests, component installs, and licenses. The remaining dl.google.com dependency is `android-actions/setup-android`'s cmdline-tools bootstrap; when no `sdkmanager` exists the action downloads the pinned cmdline-tools zip directly from the mirror and unpacks it into `$ANDROID_HOME/cmdline-tools/<version>` (same procedure proven on the host), then proceeds with the mirror-backed `sdkmanager`. Alternatives rejected: a warmup exec ritual after every rebuild (untracked, drifts silently); a gh-sr bake knob for arbitrary dirs (new upstream surface for one consumer).

5. **No workflow YAML label changes.** Single pool: `[self-hosted, Linux]` prefix-matches the pool's labels including `agentic`. Only the stale runners.yml header comment (pool-split rationale) is corrected to record the one-pool decision.

6. **Rollout order** (enforced in tasks): prerequisite gh-sr merge + `gh sr` extension reinstall → runners.yml edits → `gh sr rebuild baizhiheizi` → `gh sr doctor --strict` → smoke dispatches. Rollback = revert runners.yml + rebuild; repo-side setup-android change is independently revertible and safe without the bake.

## Risks / Trade-offs

- [Bake list drifts from `.github/flutter-version` / JDK pin] → setup actions fall back to runtime downloads (spec'd), so drift costs minutes, not failures; comment in runners.yml points at the pin files; bump PRs note the bake entry.
- [Image grows ~3 GB (Flutter) + JDK] → shared layer across all 4 instances; host has 1.6 TB free; rebuild is attended.
- [Tencent mirror unavailable/slow at rebuild or cold-start] → `SDK_TEST_BASE_URL` is env-overridable and `sdkmanager` retries remain; mirror loss degrades to today's behavior, never worse.
- [cmdline-tools version pin vs mirror availability] → the pinned version's zip must exist on the mirror; verified as an implementation task before relying on the bypass (fallback: the action's existing bootstrap + retry path).
- [Rebuild wipes container rootfs → Android SDK re-downloads on first android job] → accepted: a few minutes from the mirror, once per rebuild, per container.
- [`gh sr` extension temporarily differs from released v0.8.0] → extension reinstalled from merged main source; a gh-sr release/tag follows the prerequisite change so the pinned state is reproducible.

## Migration Plan

1. Land prerequisite gh-sr change (`toolcache-bake-xz-strip`): rebase onto main, tar.xz + strip support, tests, CHANGELOG; install extension from source.
2. Edit `~/.gh-sr/runners.yml` (bake lists + comment fix).
3. `gh sr rebuild baizhiheizi` (rebuilds image with bake entries; recreates containers; registrations preserved).
4. `gh sr doctor --strict` — expect node/npm, zstd, docker-socket, cache-env, hygiene green.
5. Smoke `ci.yml`, `build_linux.yml`, `android_apk_smoke.yml` via `workflow_dispatch`; verify setup steps log "already installed"/skip-download paths and android setup runs mirror-backed from cold.
6. Land the repo-side `setup-android` change (mirror default + cmdline-tools bypass) — independent revert path.

## Open Questions

- Exact pinned Temurin 17 release (latest `jdk-17.0.x+y`) and its release-asset filename — resolved at implementation; only affects the literal URL in `runners.yml`.
- Whether the exact pinned cmdline-tools version zip is present on the Tencent mirror — spike during implementation; if absent, pin the newest available version in the bypass (and workflow inputs stay compatible since only `sdkmanager` presence matters).
