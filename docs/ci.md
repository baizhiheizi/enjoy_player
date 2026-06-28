# Continuous integration

Enjoy Player uses a **hybrid runner strategy**: lightweight gates run on GitHub-hosted runners so PRs stay unblocked when self-hosted machines are offline; compile smokes and releases stay on self-hosted runners for speed, cached toolchains, and signing.

## PR gates (managed)

[`ci.yml`](../.github/workflows/ci.yml) runs on **`ubuntu-latest`**:

| Step | Purpose |
|------|---------|
| `flutter pub get` | Resolve dependencies |
| `check_no_new_path_deps.sh` | Block unapproved `path:` packages |
| `check_secrets.sh` | Fail on likely plaintext credentials in tracked files |
| `dart format --set-exit-if-changed` | Formatting gate |
| `flutter analyze` | Static analysis |
| `flutter test` | App + path-package unit tests |

These jobs do **not** depend on the self-hosted Linux runner. If the self-hosted fleet is down, analyze/test/format still pass on GitHub-hosted Ubuntu.

## Compile smokes & releases (self-hosted)

Heavy platform builds remain on self-hosted runners (see [ci-self-hosted-runners.md](ci-self-hosted-runners.md)):

| Workflow | Runner | Role |
|----------|--------|------|
| [codegen_drift.yml](../.github/workflows/codegen_drift.yml) | `self-hosted`, `Linux` | Drift codegen drift check |
| [android_apk_smoke.yml](../.github/workflows/android_apk_smoke.yml) | `self-hosted`, `Linux` | APK/AAB compile smoke |
| [build_windows.yml](../.github/workflows/build_windows.yml) | `self-hosted`, `Windows` | Windows debug + release smoke |
| [build_apple.yml](../.github/workflows/build_apple.yml) | `self-hosted`, `macOS` | iOS + macOS compile smoke |
| [release_android.yml](../.github/workflows/release_android.yml) | `self-hosted`, `Linux` | Signed Android release |
| [release_apple.yml](../.github/workflows/release_apple.yml) | `self-hosted`, `macOS` | TestFlight / notarized macOS |
| [release_windows.yml](../.github/workflows/release_windows.yml) | `windows-latest` | Windows release + Inno Setup (see below) |
| gh-aw agentic workflows | `self-hosted`, `linux`, `agentic` | AI-assisted maintenance |

### Failover when self-hosted is down

- **PR merge blockers**: `ci.yml` on `ubuntu-latest` — always available.
- **Platform compile smokes**: optional signal; re-run after runner recovery or validate locally before release.
- **Releases**: tag-triggered; wait for runner health or run [packaging.md](packaging.md) locally.

Register and maintain runners per [ci-self-hosted-runners.md](ci-self-hosted-runners.md).

## Windows runner split (build vs release)

| Workflow | Runner | Rationale |
|----------|--------|-----------|
| **Build Windows** (PR smoke) | `self-hosted`, `Windows` | Reuses cached Flutter/SDK on the team runner; supports short-path `subst` workaround for MAX_PATH |
| **Release Windows** (tags) | GitHub-hosted `windows-latest` | Isolated, reproducible release environment until the self-hosted Windows runner is promoted for publishing |

When the self-hosted Windows runner is stable for release signing and S3 publish, align `release_windows.yml` to `self-hosted`, `Windows` and update this table.

## Agentic workflows (gh-aw)

- **Slash-command router** ([`agentic_commands.yml`](../.github/workflows/agentic_commands.yml)) is **generated** by `gh aw compile`. The `route` job needs `actions: write` (workflow dispatch), `issues` / `pull-requests` write (comment reactions), and `discussions: write` (discussion slash commands). Do not hand-edit; recompile after changing workflow `.md` sources.
- **Prompt files** under `.github/aw/*.md` are **not vendored** in this repo. Agents load them from upstream [`github/gh-aw`](https://github.com/github/gh-aw/tree/main/.github/aw). See [`.github/skills/agentic-workflows/SKILL.md`](../.github/skills/agentic-workflows/SKILL.md) and [`.github/agents/agentic-workflows.md`](../.github/agents/agentic-workflows.md).

## Agent skills (vendor mapping)

OpenSpec skills are canonical in [`.claude/skills/`](../.claude/skills/). [`.cursor/skills/`](../.cursor/skills/) and [`.opencode/skills/`](../.opencode/skills/) symlink to the same files. See [agent-skills.md](agent-skills.md).

## Local verification

Same commands as CI:

```bash
flutter pub get
bash .github/scripts/check_no_new_path_deps.sh
bash .github/scripts/check_secrets.sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
