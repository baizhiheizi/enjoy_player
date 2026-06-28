# Agent skills — canonical sources

Several AI vendors read skills from different directories. Avoid editing duplicates; update the **canonical** copy and sync symlinks.

## OpenSpec skills

| Skill | Canonical path |
|-------|----------------|
| `openspec-propose` | [`.claude/skills/openspec-propose/SKILL.md`](../.claude/skills/openspec-propose/SKILL.md) |
| `openspec-apply-change` | [`.claude/skills/openspec-apply-change/SKILL.md`](../.claude/skills/openspec-apply-change/SKILL.md) |
| `openspec-archive-change` | [`.claude/skills/openspec-archive-change/SKILL.md`](../.claude/skills/openspec-archive-change/SKILL.md) |
| `openspec-explore` | [`.claude/skills/openspec-explore/SKILL.md`](../.claude/skills/openspec-explore/SKILL.md) |

### Vendor directories

| Vendor | Directory | How it resolves |
|--------|-----------|-----------------|
| Claude Code | `.claude/skills/` | Canonical (edit here) |
| Cursor | `.cursor/skills/` | Symlink → `.claude/skills/<name>` |
| OpenCode | `.opencode/skills/` | Symlink → `.claude/skills/<name>` |

After changing a canonical skill, re-run on Unix:

```bash
bash scripts/sync_openspec_skills.sh
```

On Windows (or to refresh git symlink index entries without OS symlinks):

```bash
bash scripts/add_openspec_symlinks.sh
```

## Flutter / repo skills

Flutter-specific skills live only under [`.agents/skills/`](../.agents/skills/) (no cross-vendor duplication).

## gh-aw agentic workflows

Router skill: [`.github/skills/agentic-workflows/SKILL.md`](../.github/skills/agentic-workflows/SKILL.md)  
Copilot agent entry: [`.github/agents/agentic-workflows.md`](../.github/agents/agentic-workflows.md)

Prompt bodies are **not** copied into this repo; fetch from [`github/gh-aw`](https://github.com/github/gh-aw/tree/main/.github/aw) when an agent needs them.
