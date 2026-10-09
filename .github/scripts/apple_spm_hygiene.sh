#!/usr/bin/env bash
# Shared SwiftPM hygiene for Apple CI / release on self-hosted macOS.
#
# Flutter 3.44+ resolves google_sign_in (and friends) via SwiftPM. On a
# self-hosted Mac that also runs Cursor/VS Code Copilot, inherited
# GIT_CONFIG_*=safe.bareRepository=explicit breaks bare SPM caches and
# surfaces as opaque "xcodebuild encountered an error (74)". Concurrent
# Apple jobs on the same host can also race the shared SPM cache.
#
# Source this file; do not execute it directly.
# shellcheck shell=bash

apple_sanitize_git_env_for_spm() {
  # Env-injected git config outranks global; zero the count so SwiftPM can
  # use its bare repository caches (see flutter/flutter#187828).
  export GIT_CONFIG_COUNT=0
  local i=0
  while [[ $i -lt 32 ]]; do
    unset "GIT_CONFIG_KEY_${i}" "GIT_CONFIG_VALUE_${i}" 2>/dev/null || true
    i=$((i + 1))
  done
  # Keep git itself on HTTP/1.1: this host's route to github.com drops
  # HTTP/2 connections mid-transfer, which SPM surfaces as SSL_ERROR_SYSCALL
  # clone failures ("xcodebuild encountered an error (74)"). Unlike
  # safe.bareRepository, http.version is inert for bare-cache resolution.
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="http.version"
  export GIT_CONFIG_VALUE_0="HTTP/1.1"
}

apple_raise_swiftpm_macos_floors() {
  # Raise SwiftPM plugin macOS deployment floors to the app minimum.
  #
  # SwiftPM builds a plugin package at the platform declared in its own
  # Package.swift, so macos/Podfile's post_install bump to 12.0 does not
  # apply. flutter_inappwebview 6.2.0-beta.3 declares .macOS("10.14") while
  # conforming to the macOS 10.15+ ASWebAuthenticationPresentationContextProviding
  # ungated, which the macOS 26.x SDK rejects at target 10.14
  # ("protocol ... requires 'presentationAnchor(for:)'"), failing the build
  # with exit 65. Mirroring the Podfile post_install policy (any floor below
  # 12.0 becomes 12.0) keeps the SwiftPM path consistent with the CocoaPods
  # one; every plugin must already build at 12.0 because the app requires it.
  #
  # The .packages entries are symlinks into the shared pub cache, so the edit
  # is persistent on self-hosted runners but idempotent: it re-runs on every
  # build, and a plugin version bump changes the symlink target so the stale
  # patched copy is never reused. iOS floors are left alone; none are known
  # to be lower than the APIs their packages use.
  local root="${1:?apple_raise_swiftpm_macos_floors: repo root required}"
  local floor="${2:-12.0}"
  local packages_dir="${root}/macos/Flutter/ephemeral/Packages/.packages"
  [[ -d "${packages_dir}" ]] || return 0

  local link target manifest current
  for link in "${packages_dir}"/*; do
    [[ -L "${link}" ]] || continue
    target="$(readlink "${link}")"
    manifest="${target}/Package.swift"
    [[ -f "${manifest}" ]] || continue
    current="$(sed -nE 's/.*\.macOS\("([0-9.]+)"\).*/\1/p' "${manifest}" | head -n 1)"
    [[ -n "${current}" ]] || continue
    if awk "BEGIN{exit !(${current} < ${floor})}"; then
      sed -i '' -E "s/\.macOS\(\"[0-9.]+\"\)/.macOS(\"${floor}\")/g" "${manifest}"
      echo "Raised SwiftPM macOS floor of $(basename "${link}") from ${current} to ${floor}" >&2
    fi
  done
}

apple_clear_spm_caches() {
  local root="${1:-.}"
  rm -rf "${HOME}/Library/Caches/org.swift.swiftpm"
  rm -rf \
    "${root}/ios/Flutter/ephemeral/Packages/.build" \
    "${root}/macos/Flutter/ephemeral/Packages/.build" \
    "${root}/ios/SourcePackages" \
    "${root}/macos/SourcePackages" \
    "${root}/build/ios/SourcePackages" \
    "${root}/build/macos/SourcePackages"
}

apple_spm_failure_match() {
  # Reads log text on stdin; exit 0 if retryable SPM / error-74 failure.
  grep -qE \
    'Could not resolve package dependencies|Couldn.t fetch updates from remote repositories|INTERNAL ERROR: Uncaught exception|xcodebuild encountered an error \(74\)|safe\.bareRepository is .explicit.|skipping cache due to an error'
}

apple_spm_lock_dir() {
  echo "${TMPDIR:-/tmp}/enjoy-player-apple-spm.lockdir"
}

apple_spm_lock_acquire() {
  local lockdir
  lockdir="$(apple_spm_lock_dir)"
  local waited=0
  local max_wait_s="${APPLE_SPM_LOCK_TIMEOUT_S:-3600}"
  local stale_s="${APPLE_SPM_LOCK_STALE_S:-7200}"

  while ! mkdir "${lockdir}" 2>/dev/null; do
    if [[ -d "${lockdir}" ]]; then
      local age=0
      if stat_mtime="$(stat -f %m "${lockdir}" 2>/dev/null)"; then
        age=$(( $(date +%s) - stat_mtime ))
      fi
      if [[ "${age}" -ge "${stale_s}" ]]; then
        echo "Removing stale Apple SPM host lock (${lockdir}, age ${age}s)" >&2
        rmdir "${lockdir}" 2>/dev/null || rm -rf "${lockdir}"
        continue
      fi
    fi
    if [[ "${waited}" -ge "${max_wait_s}" ]]; then
      echo "Timed out after ${max_wait_s}s waiting for Apple SPM host lock (${lockdir})" >&2
      return 1
    fi
    if [[ $((waited % 60)) -eq 0 ]]; then
      echo "Waiting for Apple SPM host lock (${lockdir}); waited ${waited}s…" >&2
    fi
    sleep 5
    waited=$((waited + 5))
  done
}

apple_spm_lock_release() {
  rmdir "$(apple_spm_lock_dir)" 2>/dev/null || true
}

# Run command under the host SPM lock with sanitized git env.
apple_with_spm_host_lock() {
  apple_spm_lock_acquire || return 1
  apple_sanitize_git_env_for_spm
  local cmd_status=0
  "$@" || cmd_status=$?
  apple_spm_lock_release
  return "${cmd_status}"
}

# Retry a command up to 5 times with escalating backoff on SPM-shaped failures.
# Usage: apple_retry_spm_command <repo_root> <command> [args...]
apple_retry_spm_command() {
  local root="${1:?apple_retry_spm_command: repo root required}"
  shift
  if [[ "$#" -lt 1 ]]; then
    echo "apple_retry_spm_command: missing command" >&2
    return 2
  fi

  apple_sanitize_git_env_for_spm

  local attempt logfile cmd_status
  # Escalating backoff bridges multi-minute network brownouts on this host;
  # three 15s-apart attempts all landed inside one outage on 2026-08-28.
  local backoffs=(15 30 60 120)
  for attempt in 1 2 3 4 5; do
    logfile="$(mktemp -t enjoy-apple-spm.XXXXXX)"
    set +e
    "$@" 2>&1 | tee "${logfile}"
    cmd_status=${PIPESTATUS[0]}
    set -e
    if [[ "${cmd_status}" -eq 0 ]]; then
      rm -f "${logfile}"
      return 0
    fi
    if [[ "${attempt}" -lt 5 ]] && apple_spm_failure_match <"${logfile}"; then
      local delay="${backoffs[$((attempt - 1))]}"
      echo "Apple SPM-related failure (attempt ${attempt}/5); clearing caches and retrying in ${delay}s…" >&2
      rm -f "${logfile}"
      apple_clear_spm_caches "${root}"
      sleep "${delay}"
      continue
    fi
    rm -f "${logfile}"
    return "${cmd_status}"
  done
}
