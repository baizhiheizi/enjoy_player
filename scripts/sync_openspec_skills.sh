#!/usr/bin/env bash
# Recreate OpenSpec skill symlinks from .claude/skills/ into vendor dirs.
# Usage: bash scripts/sync_openspec_skills.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

skills=(openspec-propose openspec-apply-change openspec-archive-change openspec-explore)
vendors=(.cursor/skills .opencode/skills)

for vendor in "${vendors[@]}"; do
  mkdir -p "$vendor"
  for skill in "${skills[@]}"; do
    target="../../.claude/skills/$skill"
    link="$vendor/$skill"
    rm -rf "$link"
    ln -s "$target" "$link"
    echo "linked $link -> $target"
  done
done

echo "sync_openspec_skills: done."
