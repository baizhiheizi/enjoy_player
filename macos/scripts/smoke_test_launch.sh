#!/bin/bash
# Smoke-test a built macOS app by starting its executable with an isolated HOME.
#
# The failure this guards against is a bundle that cannot be loaded at all:
# dyld aborts before main(), so the app never renders a window and never
# reports the problem itself. The check fails only on a dynamic-linker
# signature; any other exit is reported and passed, because a runner without a
# window server makes the app quit for unrelated reasons.
#
# Usage: smoke_test_launch.sh <path/to/Enjoy Player.app>
set -eu

APP_BUNDLE="${1:-}"
if [ -z "${APP_BUNDLE}" ] || [ ! -d "${APP_BUNDLE}" ]; then
  echo "usage: $0 <path/to/Enjoy Player.app>" >&2
  exit 1
fi

TIMEOUT_SECONDS="${MACOS_LAUNCH_SMOKE_TIMEOUT:-20}"

EXECUTABLE="${APP_BUNDLE}/Contents/MacOS/$(basename "${APP_BUNDLE}" .app)"
if [ ! -x "${EXECUTABLE}" ]; then
  echo "smoke_test_launch: no executable at ${EXECUTABLE}" >&2
  exit 1
fi

SANDBOX_HOME="$(mktemp -d)"
LOG="$(mktemp)"
cleanup() {
  rm -rf "${SANDBOX_HOME}" "${LOG}"
}
trap cleanup EXIT

HOME="${SANDBOX_HOME}" "${EXECUTABLE}" >"${LOG}" 2>&1 &
app_pid=$!

waited=0
while [ "${waited}" -lt "${TIMEOUT_SECONDS}" ]; do
  if ! kill -0 "${app_pid}" 2>/dev/null; then
    break
  fi
  sleep 1
  waited=$((waited + 1))
done

if kill -0 "${app_pid}" 2>/dev/null; then
  kill -KILL "${app_pid}" 2>/dev/null || true
  wait "${app_pid}" 2>/dev/null || true
  echo "smoke_test_launch: the app started and stayed up for ${TIMEOUT_SECONDS}s"
  exit 0
fi

set +e
wait "${app_pid}"
status=$?
set -e

if grep -Eq 'Library not loaded|Namespace DYLD|dyld: |Symbol not found|Reason: tried:' "${LOG}"; then
  echo "smoke_test_launch: the app died with a dynamic-linker failure (exit ${status}):" >&2
  cat "${LOG}" >&2
  exit 1
fi

echo "smoke_test_launch: the app exited on its own (status ${status}); no dynamic-linker failure"
exit 0
