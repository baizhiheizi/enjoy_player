#!/usr/bin/env bash
# Preflight checks for local macOS direct-download releases.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

errors=0
warns=0

fail() { echo "FAIL: $*" >&2; errors=$((errors + 1)); }
warn() { echo "WARN: $*" >&2; warns=$((warns + 1)); }
ok() { echo "OK: $*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "macOS host required"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  fail "flutter not on PATH"
else
  ok "flutter $(flutter --version 2>/dev/null | awk '/Flutter/ {print $2; exit}')"
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  fail "xcodebuild not on PATH"
else
  ok "xcodebuild $(xcodebuild -version 2>/dev/null | head -1)"
fi

dev_id="$(
  security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Developer ID Application/ { print $2; exit }'
)"
if [[ -z "${dev_id}" ]]; then
  fail "Developer ID Application cert missing (team 46X685R747)"
else
  ok "Developer ID cert: ${dev_id}"
fi

dist_id="$(
  security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Apple Distribution/ { print $2; exit }'
)"
if [[ -z "${dist_id}" ]]; then
  warn "Apple Distribution cert missing — TestFlight / App Store IPA signing will fail"
else
  ok "Apple Distribution cert: ${dist_id}"
fi

if [[ -n "${dev_id}" ]]; then
  probe="$(mktemp -t enjoy-codesign-probe)"
  cp /bin/ls "${probe}"
  if codesign --force --sign "${dev_id}" "${probe}" >/dev/null 2>&1; then
    ok "Keychain allows codesign with Developer ID"
  else
    fail "codesign failed (keychain locked or private key inaccessible). Run: security unlock-keychain login.keychain-db"
  fi
  rm -f "${probe}"
fi

profile="${NOTARY_PROFILE:-enjoy-notary}"
if xcrun notarytool history --keychain-profile "${profile}" >/dev/null 2>&1; then
  ok "notary profile '${profile}' reachable"
else
  warn "notary profile '${profile}' not ready (store credentials before --notarize)"
fi

missing_brew=0
while read -r formula; do
  [[ -n "${formula}" ]] || continue
  if ! brew list "${formula}" >/dev/null 2>&1; then
    warn "Homebrew formula missing: ${formula}"
    missing_brew=1
  fi
done < <(grep -E '^brew ' "${root}/macos/Brewfile" | awk '{print $2}' | tr -d '"')

if [[ "${missing_brew}" -eq 0 ]]; then
  ok "Homebrew FFmpeg deps installed"
else
  warn "Run: brew bundle install --file=macos/Brewfile"
fi

if [[ -f "${root}/.github/scripts/publish_env.local.sh" ]]; then
  if command -v aws >/dev/null 2>&1; then
    ok "aws CLI $(aws --version 2>/dev/null | awk '{print $1}')"
  else
    warn "publish_env.local.sh present but aws CLI missing (brew install awscli)"
  fi
fi

if [[ "${errors}" -gt 0 ]]; then
  echo "${errors} check(s) failed, ${warns} warning(s)." >&2
  exit 1
fi

echo "macOS release preflight passed (${warns} warning(s))."
exit 0
