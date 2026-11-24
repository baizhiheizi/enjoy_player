#!/usr/bin/env bash
# Re-run a command with bounded retries and escalating backoff.
#
# Why:
#   On the shared self-hosted pool a build can fail because the host was
#   starved, not because the code is broken — ADR-0105 records the pool's
#   "self-hosted runner lost communication with the server" shape and calls
#   for a retry before suspecting the suite. A release compile is the
#   expensive step in the Linux build, so it gets a second and third chance
#   before the job goes red.
#
# Usage:
#   bash .github/scripts/retry_command.sh <attempts> <delay_seconds> <command> [args...]
#
# The command's output is streamed to the job log on every attempt, and the
# exit status of the last attempt is the script's exit status.
set -euo pipefail

attempts="${1:?Usage: $0 <attempts> <delay_seconds> <command> [args...]}"
delay_seconds="${2:?Usage: $0 <attempts> <delay_seconds> <command> [args...]}"
shift 2

if ! [[ "${attempts}" =~ ^[0-9]+$ ]] || [ "${attempts}" -lt 1 ]; then
  echo "retry_command: attempts must be a positive integer, got '${attempts}'." >&2
  exit 2
fi
if ! [[ "${delay_seconds}" =~ ^[0-9]+$ ]]; then
  echo "retry_command: delay must be a non-negative integer, got '${delay_seconds}'." >&2
  exit 2
fi
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <attempts> <delay_seconds> <command> [args...]" >&2
  exit 2
fi

attempt=1
while true; do
  echo ">>> retry_command: attempt ${attempt}/${attempts}: $*"
  status=0
  "$@" || status=$?
  if [ "${status}" -eq 0 ]; then
    exit 0
  fi
  if [ "${attempt}" -ge "${attempts}" ]; then
    echo "retry_command: giving up after ${attempt} attempt(s); last exit status ${status}." >&2
    exit "${status}"
  fi
  wait_s=$((delay_seconds * attempt))
  echo ">>> retry_command: attempt ${attempt} failed (exit ${status}); retrying in ${wait_s}s." >&2
  sleep "${wait_s}"
  attempt=$((attempt + 1))
done
