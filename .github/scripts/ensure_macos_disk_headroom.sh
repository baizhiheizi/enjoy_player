#!/usr/bin/env bash
# Guarantee the self-hosted macOS runner has enough free disk for an Apple build.
#
# On 2026-11-24 the macOS smoke job died 8 minutes into the Release compile with
#
#   System.IO.IOException: No space left on device :
#     '/Users/an-lee/.gh-sr/runners/mac-1/_diag/pages/…'
#
# The runner lost the volume mid-compile while writing its own log pages: the
# universal (x86_64 + arm64) build's DerivedData tree plus the iOS job's
# leftovers filled the container, and the failure surfaced as an opaque
# IOException with no clue about which disk ran out. A build that cannot
# finish is indistinguishable from a build that is broken, so the runner now
# reclaims what CI owns and checks its headroom *before* the expensive build
# instead of dying inside it.
#
# Two modes:
#   prune  — reclaim CI-owned disk (superseded Flutter SDKs, the workspace's
#            previous iOS/macOS DerivedData), then require the headroom
#   check  — require the headroom only; safe to run between two builds
#
# The headroom floor is APPLE_DISK_HEADROOM_GIB (default 20 GiB). Override it
# with the environment variable when the runner's disk is genuinely smaller.
set -euo pipefail

log() {
  echo "[ensure_macos_disk_headroom] $*"
}

mode="${1:-check}"
case "${mode}" in
  prune | check) ;;
  *)
    echo "Usage: $0 [prune|check]" >&2
    exit 2
    ;;
esac

root="$(cd "$(dirname "$0")/../.." && pwd)"
required_gib="${APPLE_DISK_HEADROOM_GIB:-20}"
tool_cache="${RUNNER_TOOL_CACHE:-${RUNNER_TEMP:-/tmp}}"
# The workspace whose build trees may be pruned. It is the repository root in
# CI; APPLE_WORKSPACE_ROOT redirects it so the test suite can drive the script
# against a scratch directory instead of the real build output.
workspace_root="${APPLE_WORKSPACE_ROOT:-${root}}"

free_gib() {
  # Anchored on the capacity column (the only field that always ends in "%")
  # so a wrapped device name — macOS `df` puts a long filesystem name on its
  # own line and shifts the numeric columns — cannot turn "Available" into
  # "Used".
  df -Pk "$1" | tail -n 1 | awk '{
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^[0-9]+%$/) {
        printf "%.1f", $(i - 1) / 1048576
        exit
      }
    }
  }'
}

prune_superseded_flutter_sdks() {
  local pinned current
  pinned="$(sed -nE 's/^[[:space:]]*flutter[[:space:]]*=[[:space:]]*"([^"]+)".*$/\1/p' "${root}/mise.toml" | head -n1)"
  if [ -z "${pinned}" ]; then
    log "Could not read the flutter pin from mise.toml; leaving the tool cache untouched."
    return 0
  fi
  local sdk
  for sdk in "${tool_cache}"/flutter-*-stable; do
    [ -d "${sdk}" ] || continue
    current="$(basename "${sdk}" | sed -E 's/^flutter-(.+)-stable$/\1/')"
    if [ "${current}" = "${pinned}" ]; then
      continue
    fi
    log "Removing superseded Flutter SDK ${sdk} (pinned: ${pinned})"
    rm -rf "${sdk}"
  done
}

prune_workspace_build_dirs() {
  local dir
  for dir in "${workspace_root}/build/ios" "${workspace_root}/build/macos"; do
    if [ -d "${dir}" ]; then
      log "Removing stale build tree ${dir}"
      rm -rf "${dir}"
    fi
  done
}

if [ "${mode}" = "prune" ]; then
  prune_superseded_flutter_sdks
  prune_workspace_build_dirs
fi

free="$(free_gib "${workspace_root}")"
log "Free space on the workspace volume: ${free} GiB (need ${required_gib} GiB)"

# awk exits 0 exactly when the free space is below the floor.
if awk "BEGIN{exit !(${free} < ${required_gib})}"; then
  log "Not enough disk headroom for an Apple build on this runner."
  log "Free: ${free} GiB, required: ${required_gib} GiB."
  log "Reclaim space on the runner host, or lower APPLE_DISK_HEADROOM_GIB if"
  log "that floor is simply too high for this volume."
  echo "::error::Apple build needs ${required_gib} GiB free but only ${free} GiB is available on the runner volume."
  exit 1
fi

log "Disk headroom OK (${free} GiB free, ${required_gib} GiB required)."
