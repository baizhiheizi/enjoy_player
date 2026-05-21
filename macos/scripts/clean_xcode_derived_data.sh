#!/usr/bin/env bash
# Remove stale global Xcode DerivedData for this project's Runner targets.
# Flutter CLI builds under build/macos; leftover ~/Library/.../DerivedData/Runner-*
# triggers "Stale file … outside of the allowed root paths" on the next build.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DD="${HOME}/Library/Developer/Xcode/DerivedData"

echo "Cleaning Flutter build output…"
(cd "$ROOT" && flutter clean)

if [[ -d "$DD" ]]; then
  echo "Removing global DerivedData entries matching Runner-* …"
  find "$DD" -maxdepth 1 -type d -name 'Runner-*' -print -exec rm -rf {} +
fi

echo "Done. Rebuild with: flutter run -d macos"
