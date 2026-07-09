#!/usr/bin/env bash
# Local CI gate mirror for agents and humans.
# Runs the same cheap checks that fail CI most often: format + codegen drift.
# Optionally runs analyze / tests.
#
# Usage:
#   bash .github/scripts/validate_ci_gates.sh           # format + codegen
#   bash .github/scripts/validate_ci_gates.sh --fix     # auto-format + regen codegen
#   bash .github/scripts/validate_ci_gates.sh --analyze  # also flutter analyze
#   bash .github/scripts/validate_ci_gates.sh --test     # also flutter test
#   bash .github/scripts/validate_ci_gates.sh --all      # format + codegen + analyze + test

set -euo pipefail

fix=0
do_analyze=0
do_test=0

for arg in "$@"; do
  case "$arg" in
    --fix) fix=1 ;;
    --analyze) do_analyze=1 ;;
    --test) do_test=1 ;;
    --all)
      do_analyze=1
      do_test=1
      ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: bash .github/scripts/validate_ci_gates.sh [--fix] [--analyze] [--test] [--all]" >&2
      exit 2
      ;;
  esac
done

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if [[ "$fix" -eq 1 ]]; then
  bash .github/scripts/check_dart_format.sh --fix
  bash .github/scripts/check_codegen_drift.sh --fix
else
  bash .github/scripts/check_dart_format.sh
  bash .github/scripts/check_codegen_drift.sh
fi

if [[ "$do_analyze" -eq 1 ]]; then
  echo "validate_ci_gates: flutter analyze..."
  flutter analyze
fi

if [[ "$do_test" -eq 1 ]]; then
  echo "validate_ci_gates: flutter test..."
  flutter test
fi

echo "validate_ci_gates: all requested gates passed"
