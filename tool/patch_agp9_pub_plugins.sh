#!/usr/bin/env bash
# Delegates to the single-source Dart patcher in tool/patch_agp9_pub_plugins.dart.
# This wrapper exists so the release scripts and docs keep one stable entry point.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_dart() {
  if command -v dart >/dev/null 2>&1; then
    command -v dart
    return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    local flutter_bin sdk_dir
    flutter_bin="$(command -v flutter)"
    sdk_dir="$(cd "$(dirname "${flutter_bin}")/cache/dart-sdk/bin" 2>/dev/null && pwd || true)"
    if [[ -n "${sdk_dir}" && -x "${sdk_dir}/dart" ]]; then
      echo "${sdk_dir}/dart"
      return 0
    fi
  fi
  return 1
}

dart_bin="$(resolve_dart)" || {
  echo "patch_agp9_pub_plugins: no Dart SDK found (need dart on PATH or a Flutter SDK)" >&2
  exit 1
}

exec "${dart_bin}" "${root}/tool/patch_agp9_pub_plugins.dart" "$@"
