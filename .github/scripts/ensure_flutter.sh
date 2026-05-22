#!/usr/bin/env bash
# Optional manual check: verify the runner Flutter SDK matches .github/flutter-version.
set -euo pipefail

expected="$(tr -d ' \n\r' < .github/flutter-version)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "::error::Flutter is not on PATH. Install Flutter ${expected} on this self-hosted runner (see docs/ci-self-hosted-runners.md)."
  exit 1
fi

actual="$(flutter --version | head -n1 | sed -nE 's/^Flutter ([^ ]+).*/\1/p')"

if [ -z "${actual}" ] || [ "${actual}" != "${expected}" ]; then
  echo "::error::Expected Flutter ${expected}, found '${actual:-unknown}'. Pin the runner to .github/flutter-version."
  exit 1
fi

echo "Flutter ${actual} (matches .github/flutter-version)"
