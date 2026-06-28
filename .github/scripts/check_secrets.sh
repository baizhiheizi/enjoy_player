#!/usr/bin/env bash
# Fail CI when tracked files contain likely plaintext credentials.
# Usage: bash .github/scripts/check_secrets.sh
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

# Paths excluded from scanning (examples, lockfiles, generated assets).
exclude=(
  ':(exclude).github/scripts/publish_env.example.*'
  ':(exclude).github/scripts/publish_env.local.*'
  ':(exclude)**/*.lock'
  ':(exclude)**/*.g.dart'
  ':(exclude)**/Podfile.lock'
  ':(exclude)docs/**'
  ':(exclude).github/workflows/*.lock.yml'
)

patterns=(
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
  'ghp_[A-Za-z0-9]{20,}'
  'gho_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'sk-[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
)

violations=0
for pattern in "${patterns[@]}"; do
  while IFS= read -r -d '' file; do
    echo "check_secrets: possible secret in $file (pattern: $pattern)" >&2
    violations=$((violations + 1))
  done < <(
    git grep -l -z -E "$pattern" -- "${exclude[@]}" -- . 2>/dev/null || true
  )
done

if [ "$violations" -gt 0 ]; then
  echo "check_secrets: $violations file(s) matched credential patterns." >&2
  exit 1
fi

echo "check_secrets: no plaintext credential patterns in tracked files."
