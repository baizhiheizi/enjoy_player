#!/usr/bin/env bash
# Ensure Xcode components required for iOS compile-only CI on self-hosted macOS runners.
#
# Xcode 26.x smoke builds need the matching iOS platform/simulator runtime and an
# up-to-date CoreSimulator framework (installed via -runFirstLaunch). Without these,
# xcodebuild exits 70 with "CoreSimulator is out of date" or "iOS 26.x is not installed".
set -euo pipefail

log() {
  echo "[ensure_ios_ci_toolchain] $*"
}

run_first_launch() {
  log "Running xcodebuild -runFirstLaunch (CoreSimulator + required components)…"
  # Bounded for the same reason as the platform download: it is an
  # xcodebuild invocation that can sit without output.
  if run_with_timeout "${IOS_FIRST_LAUNCH_TIMEOUT_S:-240}" xcodebuild -runFirstLaunch; then
    return 0
  fi
  local status=$?
  log "xcodebuild -runFirstLaunch failed (exit ${status})."
  log "On the runner Mac, run once with admin rights: sudo xcodebuild -runFirstLaunch"
  return "${status}"
}

run_with_timeout() {
  # Runs a command, kills it after the timeout, and echoes its output.
  # `timeout` is not part of macOS, so the wait is done here.
  local timeout_s="$1"
  shift
  local logfile pid waited status
  logfile="$(mktemp -t enjoy-ios-platform.XXXXXX)"
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

download_ios_platform() {
  log "Downloading the iOS platform for the active Xcode…"
  local variant attempt output status
  # The per-attempt timeout is sized so the whole step fits inside the Apple
  # job's budget: two variants × three attempts × (timeout + 15 s backoff) is
  # ~25 min at the 240 s default, and the job allows 45 min for everything
  # including the two compiles. A per-attempt timeout the job budget cannot
  # accommodate would kill the job before the destination check ever runs,
  # which is exactly the opaque timeout failure the check exists to replace.
  local attempt_timeout="${IOS_PLATFORM_TIMEOUT_S:-240}"
  # `universal` first: the generic iOS device destination the build uses needs
  # the device platform, while the arm64 variant is only the simulator
  # runtime. Asking for arm64 alone reported "already present" on a runner
  # that had no device platform at all, and the build then failed much later
  # with "No Xcode build settings have been found".
  for variant in universal arm64; do
    # xcodebuild exits non-zero when there is nothing to download, so the
    # "already present" answer is success and needs its own flag.
    variant_ok=0
    for attempt in 1 2 3; do
      log "Requesting the iOS platform (variant ${variant}, attempt ${attempt}/3)…"
      set +e
      output="$(run_with_timeout "${attempt_timeout}" \
        xcodebuild -downloadPlatform iOS -architectureVariant "${variant}")"
      status=$?
      set -e
      log "${output}"
      if [ "${status}" -eq 0 ]; then
        variant_ok=1
        break
      fi
      if echo "${output}" | grep -qE 'already downloaded|No needed downloadables'; then
        log "iOS platform already present (${variant})."
        variant_ok=1
        break
      fi
      if [ "${status}" -eq 124 ]; then
        log "The ${variant} download did not finish in time; retrying."
      fi
      sleep 15
    done
    # The device platform is what the generic iOS destination needs, so its
    # failure is fatal. The arm64 simulator variant is best effort — the
    # destination check below is the real gate.
    if [ "${variant}" = "universal" ] && [ "${variant_ok}" -eq 0 ]; then
      log "The iOS device platform could not be downloaded." >&2
      return 1
    fi
  done
  return 0
}

restart_simulator_services() {
  # After -runFirstLaunch updates CoreSimulator, stale ibtoold/simctl daemons break storyboard compiles.
  log "Restarting CoreSimulator-related daemons after toolchain update…"
  killall ibtoold 2>/dev/null || true
  killall SimulatorTrampoline 2>/dev/null || true
  xcrun simctl shutdown all 2>/dev/null || true
}

assert_ios_destination() {
  log "Checking for a usable generic iOS device destination…"
  # The placeholder id also appears in the "Ineligible destinations" list, where
  # it carries an "error:" clause ("iOS 26.5 is not installed"), so matching
  # the id alone proves nothing — the check has to reject the ineligible line.
  local destinations
  destinations="$(xcodebuild -showdestinations -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphoneos 2>&1)" || true
  if printf '%s\n' "${destinations}" \
    | grep -E "platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder" \
    | grep -qv "error:"; then
    log "generic iOS device destination is available."
    return 0
  fi
  log "No usable generic iOS device destination." >&2
  printf '%s\n' "${destinations}" | grep -E "error:" | head -5 >&2 || true
  log "Install components in Xcode > Settings > Components," >&2
  log "or run: xcodebuild -downloadPlatform iOS && sudo xcodebuild -runFirstLaunch" >&2
  return 1
}

run_first_launch
download_ios_platform
restart_simulator_services
assert_ios_destination
