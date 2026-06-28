#!/usr/bin/env bash
# Verify OpenSpec CLI works and report status for every active (non-archived) change.
set -euo pipefail

if ! command -v openspec >/dev/null 2>&1; then
  echo "::error::openspec CLI not found on PATH"
  exit 1
fi

openspec --version

changes_dir="openspec/changes"
if [[ ! -d "${changes_dir}" ]]; then
  echo "No openspec/changes directory — nothing to check."
  exit 0
fi

found=0
failed=0

for change_path in "${changes_dir}"/*; do
  [[ -d "${change_path}" ]] || continue
  name="$(basename "${change_path}")"
  [[ "${name}" == "archive" ]] && continue
  [[ -f "${change_path}/.openspec.yaml" ]] || continue

  found=$((found + 1))
  echo "── openspec status --change ${name} ──"
  if ! openspec status --change "${name}" --json > "/tmp/openspec-${name}.json"; then
    echo "::error::openspec status failed for change '${name}'"
    failed=$((failed + 1))
    continue
  fi

  cat "/tmp/openspec-${name}.json"
  echo
done

if [[ "${found}" -eq 0 ]]; then
  echo "No active OpenSpec changes under ${changes_dir}/ (excluding archive/)."
  exit 0
fi

if [[ "${failed}" -gt 0 ]]; then
  echo "::error::OpenSpec status check failed for ${failed} change(s)."
  exit 1
fi

echo "OpenSpec status OK for ${found} active change(s)."
