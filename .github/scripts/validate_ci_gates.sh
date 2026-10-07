#!/usr/bin/env bash
# Local CI gate mirror for agents and humans.
# Runs the same cheap checks that fail CI most often: format + codegen drift
# + the no-new-path-deps governance gate.
# Optionally runs analyze / tests (with optional coverage gate) and the path
# package test suites.
#
# Usage:
#   bash .github/scripts/validate_ci_gates.sh           # format + codegen + path-deps
#   bash .github/scripts/validate_ci_gates.sh --fix     # auto-format + regen codegen
#   bash .github/scripts/validate_ci_gates.sh --analyze  # also flutter analyze
#   bash .github/scripts/validate_ci_gates.sh --test     # also flutter test
#   bash .github/scripts/validate_ci_gates.sh --coverage # with --test: instrumented
#                                                       # + enforce coverage gate
#   bash .github/scripts/validate_ci_gates.sh --packages # with --test: also path packages
#   bash .github/scripts/validate_ci_gates.sh --changed-only  # with --test: only run
#                                                              # tests for files
#                                                              # changed vs main
#   bash .github/scripts/validate_ci_gates.sh --all      # format + codegen + path-deps
#                                                       # + analyze + test + coverage + packages

set -euo pipefail

fix=0
do_analyze=0
do_test=0
do_coverage=0
do_packages=0
do_changed_only=0

for arg in "$@"; do
  case "$arg" in
    --fix) fix=1 ;;
    --analyze) do_analyze=1 ;;
    --test) do_test=1 ;;
    --coverage) do_coverage=1 ;;
    --packages) do_packages=1 ;;
    --changed-only) do_changed_only=1 ;;
    --all)
      do_analyze=1
      do_test=1
      do_coverage=1
      do_packages=1
      ;;
    -h|--help)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: bash .github/scripts/validate_ci_gates.sh [--fix] [--analyze] [--test] [--coverage] [--packages] [--changed-only] [--all]" >&2
      exit 2
      ;;
  esac
done

if [[ "$do_coverage" -eq 1 && "$do_test" -ne 1 ]]; then
  echo "validate_ci_gates: --coverage requires --test (or --all)." >&2
  exit 2
fi

if [[ "$do_packages" -eq 1 && "$do_test" -ne 1 ]]; then
  echo "validate_ci_gates: --packages requires --test (or --all)." >&2
  exit 2
fi

if [[ "$do_changed_only" -eq 1 && "$do_test" -ne 1 ]]; then
  echo "validate_ci_gates: --changed-only requires --test (or --all)." >&2
  exit 2
fi

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if [[ "$fix" -eq 1 ]]; then
  bash .github/scripts/check_dart_format.sh --fix
  bash .github/scripts/check_codegen_drift.sh --fix
else
  bash .github/scripts/check_dart_format.sh
  bash .github/scripts/check_codegen_drift.sh
fi

# Path-deps governance: ci.yml runs this on every PR; the local mirror used
# to skip it, which let agents push PRs that the governance gate would have
# rejected. Cheap enough to always run.
bash .github/scripts/check_no_new_path_deps.sh

if [[ "$do_analyze" -eq 1 ]]; then
  echo "validate_ci_gates: flutter analyze..."
  flutter analyze
fi

if [[ "$do_test" -eq 1 ]]; then
  if [[ "$do_changed_only" -eq 1 ]]; then
    # Local-only flag: run only tests for files changed since the merge-base
    # with main. Speeds up agent iteration; CI itself always runs the full
    # suite so we never lose coverage of unrelated tests in PRs.
    mapfile -t test_targets < <(
      git diff --name-only --diff-filter=ACMR origin/main -- 'lib/*.dart' 'test/*.dart' 2>/dev/null || true \
        | awk '
            /\.dart$/ {
              if ($0 ~ /^test\// && $0 ~ /_test\.dart$/) print
              else if ($0 ~ /^lib\//) {
                sub(/^lib\//, "test/")
                sub(/\.dart$/, "_test.dart")
                print
              }
            }
          ' \
        | sort -u
    )
    if [[ "${#test_targets[@]}" -eq 0 ]]; then
      echo "validate_ci_gates: --changed-only found no test targets (skipping flutter test)."
    else
      echo "validate_ci_gates: flutter test (changed-only, ${#test_targets[@]} file(s))..."
      flutter test "${test_targets[@]}"
    fi
  elif [[ "$do_coverage" -eq 1 ]]; then
    echo "validate_ci_gates: flutter test --coverage..."
    flutter test --coverage
    echo "validate_ci_gates: coverage gate..."
    bash .github/scripts/check_coverage_gate.sh coverage/lcov.info
  else
    echo "validate_ci_gates: flutter test..."
    flutter test
  fi
fi

if [[ "$do_packages" -eq 1 ]]; then
  echo "validate_ci_gates: path package tests..."
  set -e
  for pkg in packages/*/; do
    if [ -d "${pkg}test" ]; then
      (cd "$pkg" && flutter pub get && flutter test)
    fi
  done
fi

echo "validate_ci_gates: all requested gates passed"
