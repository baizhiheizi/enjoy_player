#!/usr/bin/env bash
# Regenerates build_runner outputs and fails if generated files drift.
# Mirrors .github/workflows/codegen_drift.yml.
#
# Only generated outputs are considered (*.g.dart, *.freezed.dart, and
# untracked files matching those patterns). Unrelated dirty docs/scripts do
# not fail the gate — that keeps the check usable locally while editing.
#
# Usage: bash .github/scripts/check_codegen_drift.sh
#        bash .github/scripts/check_codegen_drift.sh --fix
#          # regenerate and leave changes for you to commit (does not fail on drift)

set -euo pipefail

fix=0
if [[ "${1:-}" == "--fix" ]]; then
  fix=1
fi

generated_pathspecs=(
  '*.g.dart'
  '*.freezed.dart'
  '**/*.g.dart'
  '**/*.freezed.dart'
)

echo "check_codegen_drift: build_runner (root)..."
dart run build_runner build

for pkg in packages/*/; do
  [ -f "${pkg}pubspec.yaml" ] || continue
  if grep -qE '^[[:space:]]*build_runner:' "${pkg}pubspec.yaml"; then
    echo "check_codegen_drift: build_runner (${pkg})..."
    (cd "$pkg" && flutter pub get && dart run build_runner build)
  fi
done

if [[ "$fix" -eq 1 ]]; then
  if ! git diff --quiet HEAD -- "${generated_pathspecs[@]}" \
    || [ -n "$(git ls-files --others --exclude-standard -- "${generated_pathspecs[@]}")" ]; then
    echo "check_codegen_drift: regenerated files differ from HEAD — stage and commit them." >&2
    git --no-pager diff --stat HEAD -- "${generated_pathspecs[@]}" || true
    untracked=$(git ls-files --others --exclude-standard -- "${generated_pathspecs[@]}" || true)
    if [ -n "$untracked" ]; then
      echo "Untracked generated files:" >&2
      echo "$untracked" >&2
    fi
    exit 0
  fi
  echo "check_codegen_drift: ok (no generated drift after --fix)"
  exit 0
fi

status=0
if ! git diff --exit-code HEAD -- "${generated_pathspecs[@]}"; then
  echo "" >&2
  echo "::error::Working tree differs from HEAD after build_runner (regenerate and commit)." >&2
  echo "check_codegen_drift: generated files differ from HEAD after build_runner." >&2
  echo "  Fix with: bash .github/scripts/check_codegen_drift.sh --fix" >&2
  echo "  Then stage and commit the regenerated *.g.dart / *.freezed.dart files." >&2
  git --no-pager diff --stat HEAD -- "${generated_pathspecs[@]}" >&2 || true
  git --no-pager diff HEAD -- "${generated_pathspecs[@]}" >&2 || true
  status=1
fi

untracked=$(git ls-files --others --exclude-standard -- "${generated_pathspecs[@]}")
if [ -n "$untracked" ]; then
  echo "" >&2
  echo "::error::Unexpected untracked generated files after codegen:" >&2
  echo "check_codegen_drift: unexpected untracked generated files after codegen:" >&2
  echo "$untracked" >&2
  status=1
fi

if [[ "$status" -ne 0 ]]; then
  exit 1
fi

echo "check_codegen_drift: ok"
