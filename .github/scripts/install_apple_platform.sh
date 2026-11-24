#!/usr/bin/env bash
# Install the iOS platform for the active Xcode, forcing the asset download
# over TCP.
#
# Why:
#   `xcodebuild -downloadPlatform iOS` hands the fetch to mobileassetd, which
#   opens a QUIC (HTTP/3) connection to Apple's asset server. On this host's
#   route that connection is cancelled after ~30 s ("read-side closed" in the
#   daemon's log), so the download either stalls for minutes or — when the
#   daemon's own retry loses the race — never completes and the runner is
#   left without the iOS platform. The generic iOS device destination then
#   reports "iOS <version> is not installed" and the build fails with the
#   unrelated "No Xcode build settings have been found".
#
#   Blocking outbound UDP/443 makes mobileassetd fall back to TCP/HTTP2,
#   which survives the route. The block is temporary: it is removed as soon
#   as the download finishes, and the trap removes it even when the script
#   is interrupted.
#
# What:
#   1. Checks whether the platform is already installed and exits early —
#      most runs need nothing.
#   2. Adds a pf anchor with a single "block out proto udp to port 443" rule
#      and enables pf (macOS ships pf disabled).
#   3. Runs the download.
#   4. Removes the rule, the anchor, and restores pf to the state it was in.
#
# Requires sudo. Usage:
#   sudo bash .github/scripts/install_apple_platform.sh [--dry-run]
#   bash .github/scripts/install_apple_platform.sh --print-ruleset
#
# The dry run validates the ruleset with `pfctl -n` and reports what would
# change; it never enables pf or touches /etc/pf.conf. --print-ruleset just
# prints the ruleset and needs no privileges.
set -euo pipefail

anchor="enjoy_player"
rules_file="$(mktemp -t enjoy-pf-rules.XXXXXX)"
backup_file="$(mktemp -t enjoy-pf-conf.XXXXXX)"
dry_run=0
print_ruleset=0
pf_was_enabled=0

for arg in "$@"; do
  case "${arg}" in
    --dry-run) dry_run=1 ;;
    --print-ruleset) print_ruleset=1 ;;
    -h | --help)
      sed -n '2,34p' "$0"
      exit 0
      ;;
    *)
      echo "Usage: $0 [--dry-run] [--print-ruleset]" >&2
      exit 2
      ;;
  esac
done

log() {
  echo "[install_apple_platform] $*"
}

# pf is last-match-wins (pf.conf(5)): "the last matching rule decides what
# action is performed". The block has to come AFTER the pass rules, or the
# trailing `pass out all` overrides it and UDP/443 keeps flowing.
#
# The ruleset is self-contained on purpose: macOS's stock /etc/pf.conf has no
# top-level pass rules in the com.apple anchor, so relying on the default
# policy would be a gamble with the host's connectivity.
write_ruleset() {
  cat >"${rules_file}" <<'EOF'
pass out all
pass in all
block out proto udp to port 443
EOF
}

cleanup() {
  local status=$?
  if [ "${dry_run}" -eq 0 ] && [ "${print_ruleset}" -eq 0 ]; then
    log "Removing the temporary pf rule."
    pfctl -a "${anchor}" -F all 2>/dev/null || true
    pfctl -a "${anchor}" -X "${anchor}" 2>/dev/null || true
    if [ -f "${backup_file}" ]; then
      cp "${backup_file}" /etc/pf.conf 2>/dev/null || true
      pfctl -f /etc/pf.conf 2>/dev/null || true
      log "Restored /etc/pf.conf."
    fi
    if [ "${pf_was_enabled}" -eq 0 ]; then
      pfctl -d 2>/dev/null || true
      log "pf disabled again (it was disabled before)."
    fi
  fi
  rm -f "${rules_file}" "${backup_file}"
  exit "${status}"
}
trap cleanup EXIT INT TERM

if [ "${print_ruleset}" -eq 1 ]; then
  write_ruleset
  cat "${rules_file}"
  exit 0
fi

# Runs a command, kills it after the timeout, and echoes its output.
# `timeout` is not part of macOS, so the wait is done here.
run_with_timeout() {
  local timeout_s="$1"
  shift
  local logfile pid waited status
  logfile="$(mktemp -t enjoy-platform-timeout.XXXXXX)"
  "$@" >"${logfile}" 2>&1 &
  pid=$!
  waited=0
  while kill -0 "${pid}" 2>/dev/null; do
    if [ "${waited}" -ge "${timeout_s}" ]; then
      log "The command exceeded ${timeout_s}s; terminating it."
      kill -TERM "${pid}" 2>/dev/null || true
      sleep 2
      kill -KILL "${pid}" 2>/dev/null || true
      wait "${pid}" 2>/dev/null || true
      cat "${logfile}"
      rm -f "${logfile}"
      return 124
    fi
    sleep 1
    waited=$((waited + 1))
  done
  set +e
  wait "${pid}" 2>/dev/null
  status=$?
  set -e
  cat "${logfile}"
  rm -f "${logfile}"
  return "${status}"
}

if [ "$(id -u)" -ne 0 ]; then
  echo "install_apple_platform: needs sudo (it edits /etc/pf.conf and pf)." >&2
  exit 1
fi

log "Checking whether the iOS platform is already installed…"
# The output is captured before it is filtered: `grep -q` closes the pipe
# early, which SIGPIPEs xcodebuild, and `pipefail` would then report the
# platform as missing even when it is installed.
destinations="$(xcodebuild -showdestinations -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphoneos 2>&1 || true)"
if printf '%s\n' "${destinations}" \
  | grep -E "platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder" \
  | grep -qv "error:"; then
  log "The generic iOS device destination is available; nothing to install."
  exit 0
fi
log "The generic iOS device destination is not usable; the platform is missing."

write_ruleset

if [ "${dry_run}" -eq 1 ]; then
  log "Dry run: validating the ruleset without applying it."
  pfctl -n -f "${rules_file}" 2>&1 | sed 's/^/[pf] /'
  log "Would add 'anchor \"${anchor}\"' to /etc/pf.conf, enable pf, block UDP/443, download, then restore."
  exit 0
fi

log "Backing up /etc/pf.conf…"
cp /etc/pf.conf "${backup_file}"

if ! grep -q "^anchor \"${anchor}\"" /etc/pf.conf; then
  log "Adding the '${anchor}' anchor to /etc/pf.conf."
  printf '\nanchor "%s"\n' "${anchor}" >>/etc/pf.conf
fi

if pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
  pf_was_enabled=1
  log "pf was already enabled."
else
  log "Enabling pf (macOS ships it disabled)."
  pfctl -e
fi

log "Loading the UDP/443 block rule…"
# Reload the main ruleset: the running one has to reference the anchor, or the
# anchor's rules are never evaluated. `pfctl -a … -f` alone only fills the
# anchor's rule list — nothing points at it until /etc/pf.conf is reloaded.
pfctl -f /etc/pf.conf
pfctl -a "${anchor}" -f "${rules_file}" -v

log "Asserting the block is live…"
if ! pfctl -a "${anchor}" -sr -v 2>&1 | grep -q "block out proto udp to port 443"; then
  echo "install_apple_platform: the UDP/443 block is not in the running ruleset." >&2
  exit 1
fi
pfctl -a "${anchor}" -sr -v 2>&1 | sed 's/^/[pf] /'

log "Downloading the iOS platform over TCP…"
# The download is bounded: xcodebuild prints no progress while mobileassetd
# fetches the asset, so an unbounded call would hang forever — the exact
# failure this script exists to work around.
run_with_timeout "${INSTALL_APPLE_PLATFORM_TIMEOUT_S:-1800}" \
  xcodebuild -downloadPlatform iOS -architectureVariant universal || true
run_with_timeout "${INSTALL_APPLE_PLATFORM_TIMEOUT_S:-1800}" \
  xcodebuild -downloadPlatform iOS -architectureVariant arm64 || true

log "Verifying the generic iOS device destination…"
destinations="$(xcodebuild -showdestinations -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphoneos 2>&1 || true)"
if printf '%s\n' "${destinations}" \
  | grep -E "platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder" \
  | grep -qv "error:"; then
  log "The generic iOS device destination is available."
else
  log "The platform is still not usable; see the destination errors above." >&2
  exit 1
fi
