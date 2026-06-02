#!/usr/bin/env bash
# Verify Sparkle / WinSparkle keys are wired for direct-download auto-update.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

errors=0

warn() { echo "WARN: $*" >&2; }
fail() { echo "FAIL: $*" >&2; errors=$((errors + 1)); }
ok() { echo "OK: $*"; }

# macOS public EdDSA key in Info.plist
if grep -q 'SUPublicEDKey' macos/Runner/Info.plist 2>/dev/null; then
  ok "macOS SUPublicEDKey present in Info.plist"
else
  fail "macOS SUPublicEDKey missing — run on Mac: dart run auto_updater:generate_keys"
fi

# Windows DSA public key embedded in Runner.rc
if grep -q 'DSAPub' windows/runner/Runner.rc 2>/dev/null; then
  ok "Windows DSAPub resource in Runner.rc"
else
  fail "Windows DSAPub missing — run on Windows: dart run auto_updater:generate_keys (needs OpenSSL)"
fi

if [[ -f "windows/dsa_pub.pem" ]]; then
  ok "windows/dsa_pub.pem exists"
else
  warn "windows/dsa_pub.pem not found (expected after generate_keys on Windows)"
fi

# Feed URLs reachable (optional — pass SKIP_FEED_CHECK=1 when dl.enjoy.bot is not live yet)
if [[ "${SKIP_FEED_CHECK:-}" != "1" ]]; then
  for url in \
    "https://dl.enjoy.bot/player/latest.json" \
    "https://dl.enjoy.bot/player/appcast.xml"; do
    code="$(curl -fsS -o /dev/null -w '%{http_code}' "${url}" 2>/dev/null || echo "000")"
    if [[ "${code}" == "200" ]]; then
      ok "feed reachable: ${url}"
    else
      warn "feed HTTP ${code}: ${url} (provision R2 + publish a release, or SKIP_FEED_CHECK=1)"
    fi
  done
fi

if [[ "${errors}" -gt 0 ]]; then
  echo "${errors} check(s) failed — see docs/packaging.md § Sparkle keys" >&2
  exit 1
fi

echo "Sparkle setup checks passed."
