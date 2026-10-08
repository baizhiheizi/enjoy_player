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
#                                                              # the test files that
#                                                              # exist for changed
#                                                              # lib/test sources
#                                                              # (excludes --coverage)
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
      sed -n '2,23p' "$0"
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

if [[ "$do_changed_only" -eq 1 && "$do_coverage" -eq 1 ]]; then
  echo "validate_ci_gates: --changed-only cannot be combined with --coverage" >&2
  echo "  (a partial run cannot satisfy the whole-suite coverage gate; use" >&2
  echo "   --coverage without --changed-only, or --all)." >&2
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
    # Local-only speedup: run the test files that exist for the sources changed
    # since the merge-base with main. CI always runs the full suite, so a partial
    # run here can never let a regression into a PR — but it must also never
    # *report* a false pass, so a changed lib/ file with no matching test file is
    # dropped from the target list instead of being handed to `flutter test`.
    base_ref="$(git merge-base HEAD origin/main 2>/dev/null || true)"
    if [[ -z "$base_ref" ]]; then
      base_ref="origin/main"
    fi
    mapfile -t test_targets < <(
      git diff --name-only --diff-filter=ACMR "$base_ref" -- 'lib/*.dart' 'test/*.dart' 2>/dev/null || true \
        | awk '
            /\.dart$/ {
              if ($0 ~ /^test\// && $0 ~ /_test\.dart$/) print
              else if ($0 ~ /^lib\//) {
                candidate = $0
                sub(/^lib\//, "test/", candidate)
                sub(/\.dart$/, "_test.dart", candidate)
                print candidate
              }
            }
          ' \
        | sort -u \
        | while IFS= read -r candidate; do
            # `flutter test <missing path>` is a hard load error, not a skip, so
            # only real files may reach the test runner. Generated sources have
            # no test twin; their behavior is covered by the test beside them.
            if [[ "$candidate" == *.g.dart ]]; then
              continue
            fi
            if [[ -f "$candidate" ]]; then
              printf '%s\n' "$candidate"
            fi
          done
    )
    if [[ "${#test_targets[@]}" -eq 0 ]]; then
      echo "validate_ci_gates: --changed-only found no existing test targets" \
        "(skipping flutter test — run --test for the full suite)."
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
