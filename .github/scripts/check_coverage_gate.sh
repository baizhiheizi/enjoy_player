#!/usr/bin/env bash
# Fail when line coverage in coverage/lcov.info drops below MIN_COVERAGE (percent).
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
MIN_COVERAGE="${MIN_COVERAGE:-32}"

if [[ ! -f "$LCOV" ]]; then
  echo "Coverage gate: missing $LCOV (run flutter test --coverage first)" >&2
  exit 1
fi

read -r LF LH <<<"$(awk '
  /^LF:/ { lf += substr($0, 4) + 0 }
  /^LH:/ { lh += substr($0, 4) + 0 }
  END { printf "%d %d", lf, lh }
' "$LCOV")"

if [[ "$LF" -eq 0 ]]; then
  echo "Coverage gate: no line records in $LCOV" >&2
  exit 1
fi

pct="$(awk -v lh="$LH" -v lf="$LF" 'BEGIN { printf "%.2f", 100 * lh / lf }')"
echo "Coverage gate: ${LH}/${LF} lines (${pct}%) — minimum ${MIN_COVERAGE}%"

awk -v pct="$pct" -v min="$MIN_COVERAGE" 'BEGIN { exit (pct + 0 >= min + 0) ? 0 : 1 }' || {
  echo "Coverage gate FAILED: ${pct}% is below ${MIN_COVERAGE}%" >&2
  exit 1
}

echo "Coverage gate passed."
