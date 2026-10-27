# Agentic workflows (gh-aw)

Eight agentic workflows run on the Linux self-hosted agentic pool. Their prompts are
**upstream-owned** — they live in `githubnext/agentics` and are pulled in by commit SHA —
while the runner, engine, and shared components are **local**.

Runner labels, image baking, and pool layout are documented in
[ci-self-hosted-runners.md](../ci-self-hosted-runners.md). This file covers the workflow
sources, the update procedure, and the safe-update gate.

## Workflow sources

| Workflow | Upstream source | Trigger |
|---|---|---|
| `grumpy-reviewer` | `githubnext/agentics/workflows/grumpy-reviewer.md` | `/grumpy` slash command on PRs |
| `repo-assist` | `githubnext/agentics/workflows/repo-assist.md` | every 12 h + `/repo-assist` |
| `repo-status` | `githubnext/agentics/workflows/repo-status.md` | scheduled status report |
| `weekly-repo-map` | `githubnext/agentics/workflows/weekly-repo-map.md` | scheduled repo map |
| `weekly-research` | `githubnext/agentics/workflows/weekly-research.md` | scheduled research |
| `perf-improver` | `githubnext/agentics/workflows/perf-improver.md` | scheduled perf pass |
| `duplicate-code-detector` | `githubnext/agentics/workflows/duplicate-code-detector.md` | scheduled duplicate scan |
| `large-file-simplifier` | `githubnext/agentics/workflows/large-file-simplifier.md` | scheduled file-size pass |

The upstream commit SHA is pinned in each workflow's `source:` frontmatter field. Local
changes live in the same file — the Flutter pre-agent steps and `runs-on` sit between the
`# ==== customized start ====` / `# ==== customized end ====` markers — and the shared
engine and helper blocks are pulled in through `imports:` (for example
`shared/engine-minimax.md`).

`gh aw update` performs a three-way merge, so local customizations survive an upstream
bump. The compiled `agentic_commands.yml` is the issue-comment slash-command front for
all eight and is generated, not hand-edited.

### Sandbox network allowlist

The sandbox firewall only reaches the domains of the ecosystems listed in a workflow's
`network.allowed`. Only `repo-assist` and `perf-improver` declare `dart` (which resolves
to `pub.dev` / `pub.dartlang.org`), because they are the two workflows that run
`flutter pub get`. The analysis-only workflows (`repo-status`, `weekly-repo-map`,
`weekly-research`, `duplicate-code-detector`) read the tree without running the
toolchain, and `large-file-simplifier`'s `tools.bash` allowlist cannot invoke `flutter`
at all, so none of them needs `dart`. Adding a language without recompiling leaves the
lock file — which is what actually runs — without the domain; verify with:

```bash
grep -c "pub.dev" .github/workflows/perf-improver.lock.yml   # must be > 0
```

## Updating

```bash
gh aw update                    # fetch upstream for every workflow with a `source:` field
gh aw compile --validate        # regenerate the .lock.yml files
```

`gh aw update` also re-pins referenced third-party actions to their latest release and
refreshes the container digests in `.github/aw/actions-lock.json`. Commit the regenerated
`.lock.yml` files with the `.md` sources — the compiler embeds a `gh-aw-manifest` header
in each lock file and that manifest is the baseline the next compile compares against.

If one workflow fails to download, re-run it on its own — a download failure is a
transient network fault, not a content mismatch:

```bash
gh aw update grumpy-reviewer
```

Upstream may also leave a workflow byte-identical across two SHAs. The `source:` field
still advances to the newer SHA; only the pinned commit moves.

## The safe-update gate

Strict mode is on by default, so every compile compares the workflow against the
`gh-aw-manifest` embedded in the **committed** lock file (git `HEAD`) and warns when any
of these change:

- a restricted secret is added
- an action repo is added or removed (a version bump within an existing repo is not flagged)
- a `redirect:` target is added or removed
- `pull_request` is replaced by `pull_request_target`
- a memory validation script's content changes

A mismatch is a **warning, not an error** — compilation still succeeds and the lock file
is still written. The three remediations are `--approve`, revert the change, or review
it and approve it.

**The baseline is git `HEAD`, not the working tree.** The warning therefore keeps firing
on an uncommitted tree even after the lock file has been regenerated. It clears once the
approved lock file is committed, because that commit becomes the new baseline. A local
`gh aw compile --validate` that still warns after a reviewed and approved change is
expected until the commit lands.

`--approve` disables enforcement for that run only. It is not a substitute for the
review: the approval that the gate is really asking for is the review plus the commit.

## Pre-commit secret scanner and OCI digests

[`.githooks/pre-commit`](../../.githooks/pre-commit) blocks commits that introduce
publish credentials (AWS / R2 keys, 64-hex R2 secret access keys, the local credential
files). It matches any 64-char lowercase-hex run, which is also the shape of an OCI
content digest — so a `gh aw update` that refreshes the container pins in
`.github/aw/actions-lock.json` used to be blocked as a leaked credential.

The scanner now masks `sha256:<64 hex>` before the scan, which keeps digest-pinning
commits committable without weakening the credential check: a real 64-hex secret is not
`sha256:`-prefixed, and a secret sharing a line with a digest is still matched.

Manually verified against the staged diff after the change:

| Input | Result |
|---|---|
| `sha256:` + 64 hex only | passes (the fix) |
| bare 64-hex secret | blocked |
| `AKIA…` key id | blocked |
| `AWS_SECRET_ACCESS_KEY="…"` | blocked |
| `r2.cloudflarestorage.com/<hex>` | blocked |
| digest and bare secret on one line | blocked |

## Security review notes

### 2026-10-22 — upstream bump to `b4e175b`

Upstream moved from `055e901` / `4bc8419` to `b4e175b` for all eight workflows. Six of
them changed only their `source:` SHA. `repo-assist` and `grumpy-reviewer` were reviewed
in full.

**Secrets — none added, none removed.** The manifest secret set is byte-identical in all
eight lock files: `COPILOT_GITHUB_TOKEN`, `GH_AW_CI_TRIGGER_TOKEN`,
`GH_AW_DEFAULT_OTLP_ENDPOINT`, `GH_AW_DEFAULT_OTLP_HEADERS`,
`GH_AW_GITHUB_MCP_SERVER_TOKEN`, `GH_AW_GITHUB_TOKEN`, `GITHUB_TOKEN`, `MINIMAX_API_KEY`.
`MINIMAX_API_KEY` is the only project-owned secret and it was already present.

**Actions — no repo added or removed.** Every change is a re-pin of a repo that was
already in the baseline:

| Action | Before | After | Assessment |
|---|---|---|---|
| `actions/setup-node` | v7.0.0 | v7.1.0 | trusted `actions/*`, patch bump |
| `github/gh-aw-actions/setup` | v0.89.21 | v0.92.0 | gh-aw infrastructure, matches CLI v0.92.0 |
| `jdx/mise-action` | v5.0.1 | v5.2.2 | `repo-assist` only, same major; `with: version: 2026.9.1` unchanged |
| `actions/upload-artifact` | v7.0.1 and v7.0.2 both referenced | v7.0.2 only | duplicate reference dropped, repo still present |

**Redirects — none.** No workflow declares a `redirect:` frontmatter field, and none was
added.

**Memory validation script — one change, `repo-assist` → `repo-memory:default`**
(`ee19c879…` → `bf0981ae…`). The script validates `notes.json`; the change adds a
directory guard ahead of the existing schema checks:

```js
const memoryEntries = fs.readdirSync(memoryRoot, { withFileTypes: true })
  .filter(entry => entry.name !== ".git");
if (memoryEntries.length !== 1 || !memoryEntries[0].isFile() || memoryEntries[0].name !== "notes.json") {
  fail(`must be the only file in repo memory; found: ${memoryEntries.map(entry => entry.name).join(", ") || "(none)"}`);
}
```

Review: the script runs inside the agentic job sandbox and has only `node:fs` and
`node:path` in scope. The added code lists the memory directory and requires `notes.json`
to be its only entry. It is strictly **more** restrictive than the previous check, which
only asserted that `notes.json` existed and matched the schema — it now fails closed when
the memory directory holds anything else, so an agent cannot smuggle extra files (scripts,
symlinks, config) into the `memory/repo-assist-memory` branch that later runs consume. It
adds no `require` beyond the two already present, no `child_process` or `eval`, no
network call, and no secret access. The thrown error interpolates only file names from
the agent's own memory directory into the workflow log.

**Containers — digest-pinned, all refreshed:**

| Image | Before | After |
|---|---|---|
| `ghcr.io/github/gh-aw-firewall/agent` | 0.28.23 | 0.28.57 |
| `ghcr.io/github/gh-aw-firewall/api-proxy` | 0.28.23 | 0.28.57 |
| `ghcr.io/github/gh-aw-firewall/squid` | 0.28.23 | 0.28.57 |
| `ghcr.io/github/gh-aw-mcpg` | 0.4.25 | 0.4.31 |
| `ghcr.io/github/github-mcp-server` | v1.12.2 | **v2.0.2** |
| `ghcr.io/github/gh-aw-node` | `sha256:11c2c544…` | `sha256:23746305…` |

**Other upstream changes in `repo-assist`, reviewed although the gate did not flag them:**

- `permissions: read-all` became an explicit read-only list. No `write` scope is
  introduced and `copilot-requests` stays `none`.
- A new pre-agent step, `Initialize Repo Assist memory`, seeds `notes.json` into
  `/tmp/gh-aw/repo-memory/default` when it is absent.
- `tools.repo-memory.branch-name` pins the memory branch to `memory/repo-assist-memory`
  instead of leaving it to a default.
- The prompt gains a `jq empty` + `push_repo_memory` verification step.
- `threat_detection.mode` is now `enabled` in the compiled manifest of all eight lock
  files; it was previously absent. This turns a security control on.

**Flagged for a human reviewer:**

1. `github-mcp-server` moves **v1.12.2 → v2.0.2**, a major bump of the GitHub MCP server
   image. This is the privileged tool surface the agents use. It is an official
   `ghcr.io/github/` image and it is digest-pinned, but a major bump is not verifiable
   from this repository alone — confirm it against the upstream release notes before
   merging.
2. The `gh-aw-mcpg` and firewall images move within the same `ghcr.io/github/` org. Every
   image is digest-pinned, so the exact bytes are auditable from the lock file manifest.
