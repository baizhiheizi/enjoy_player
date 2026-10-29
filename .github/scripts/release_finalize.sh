#!/usr/bin/env bash
# Promote a draft GitHub Release to published only when every expected
# platform artifact is attached to it.
#
# The four per-platform release workflows each upload their own assets and
# leave the release as a draft, so a partial release (Windows and Android
# failed, Apple and Linux shipped) looks exactly like a complete one until
# somebody publishes it. This gate refuses to publish a release that is
# missing an expected asset.
#
# Usage:
#   bash .github/scripts/release_finalize.sh --tag v0.10.3
#   bash .github/scripts/release_finalize.sh --tag v0.10.3 --check-only
#   bash .github/scripts/release_finalize.sh --tag v0.10.3 \
#     --require EnjoyPlayer-v0.10.3.ipa --allow-missing EnjoyPlayer-v0.10.3.aab
#
# Requires `gh` on PATH and a token in GH_TOKEN / GITHUB_TOKEN.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${root}"

usage() {
  cat <<'USAGE'
Usage: release_finalize.sh [--tag vX.Y.Z] [--check-only]
                            [--require ASSET]... [--allow-missing ASSET]...

  --tag TAG           Release tag to finalize (default: the pubspec version).
  --check-only        Report whether the release is complete; publish nothing.
  --require ASSET     Asset name that must also be attached.
  --allow-missing ASSET  Asset name that is intentionally absent.
USAGE
}

tag=""
check_only=false
extra_required=()
allowed_missing=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      tag="${2:-}"
      shift 2
      ;;
    --check-only)
      check_only=true
      shift
      ;;
    --require)
      extra_required+=("${2:-}")
      shift 2
      ;;
    --allow-missing)
      allowed_missing+=("${2:-}")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${tag}" ]]; then
  tag="v$(bash "${root}/.github/scripts/read_pubspec_version.sh")"
fi
version="${tag#v}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found on PATH." >&2
  exit 1
fi

if ! gh release view "${tag}" >/dev/null 2>&1; then
  echo "GitHub Release ${tag} does not exist." >&2
  echo "Create it by running a per-platform release workflow for ${tag}." >&2
  exit 1
fi

asset_list="$(gh release view "${tag}" --json assets --jq '.assets[].name')" || {
  echo "Could not list the assets of GitHub Release ${tag}." >&2
  exit 1
}

attached=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && attached+=("${line}")
done <<<"${asset_list}"

expected=(
  "EnjoyPlayerSetup-v${version}.exe"
  "EnjoyPlayer-macOS-v${version}.zip"
  "enjoy-player-${version}-x86_64.AppImage"
  "EnjoyPlayer-v${version}.aab"
)
expected+=("${extra_required[@]+"${extra_required[@]}"}")

is_listed() {
  local needle="$1"
  shift
  local candidate
  for candidate in ${@+"${@}"}; do
    [[ "${candidate}" == "${needle}" ]] && return 0
  done
  return 1
}

missing=()
for name in "${expected[@]+"${expected[@]}"}"; do
  if is_listed "${name}" ${allowed_missing[@]+"${allowed_missing[@]}"}; then
    continue
  fi
  if ! is_listed "${name}" ${attached[@]+"${attached[@]}"}; then
    missing+=("${name}")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "GitHub Release ${tag} is missing ${#missing[@]} expected asset(s):" >&2
  for name in "${missing[@]}"; do
    echo "  - ${name}" >&2
  done
  echo "" >&2
  echo "Each platform uploads its own assets; run the missing platform's release" >&2
  echo "workflow, or pass --allow-missing <asset> when that channel is skipped." >&2
  exit 1
fi

echo "GitHub Release ${tag} carries every expected asset."

if [[ "${check_only}" == true ]]; then
  exit 0
fi

gh release edit "${tag}" --draft=false
echo "Promoted ${tag} from draft to published."
