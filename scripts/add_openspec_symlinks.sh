#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

skills=(openspec-propose openspec-apply-change openspec-archive-change openspec-explore)
vendors=(.cursor/skills .opencode/skills)

mkdir -p "${vendors[@]}"

for vendor in "${vendors[@]}"; do
  for skill in "${skills[@]}"; do
    path="$vendor/$skill"
    target="../../.claude/skills/$skill"
    hash=$(printf '%s' "$target" | git hash-object -w --stdin)
    git update-index --add --cacheinfo "120000,$hash,$path"
    echo "indexed symlink $path -> $target"
  done
done
