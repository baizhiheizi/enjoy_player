#!/usr/bin/env bash
# Assert every compiled agentic workflow routes inference through the ADR-0028 proxy
# and declares api.minimaxi.com in its egress allow-list (GH_AW firewall).
set -euo pipefail

PROXY_HOST="api.minimaxi.com"
PROXY_BASE_URL="https://api.minimaxi.com/anthropic"
WORKFLOWS_DIR=".github/workflows"
errors=0

fail() {
  echo "::error::$1"
  errors=$((errors + 1))
}

# Source workflows that invoke the MiniMax proxy must import the shared engine component.
for md in "${WORKFLOWS_DIR}"/*.md; do
  [[ -f "${md}" ]] || continue
  base="$(basename "${md}")"
  [[ "${base}" == shared ]] && continue

  if grep -qE 'engine-minimax|ANTHROPIC_BASE_URL' "${md}" 2>/dev/null; then
    if ! grep -q 'shared/engine-minimax.md' "${md}"; then
      fail "${md}: agentic source must import shared/engine-minimax.md (ADR-0028)."
    fi
  fi
done

# Compiled lock files: proxy URL + allow-list must include the proxy host.
for lock in "${WORKFLOWS_DIR}"/*.lock.yml; do
  [[ -f "${lock}" ]] || continue
  base="$(basename "${lock}")"

  if ! grep -q "${PROXY_BASE_URL}" "${lock}"; then
    fail "${lock}: missing ANTHROPIC_BASE_URL=${PROXY_BASE_URL}."
  fi

  if ! grep -q "${PROXY_HOST}" "${lock}"; then
    fail "${lock}: egress allow-list must include ${PROXY_HOST}."
  fi
done

# agentic_commands.yml is a slash-command router (no inference); ensure it does not
# declare a direct Anthropic endpoint that would bypass the proxy.
commands_yml="${WORKFLOWS_DIR}/agentic_commands.yml"
if [[ -f "${commands_yml}" ]]; then
  if grep -q 'ANTHROPIC_BASE_URL' "${commands_yml}" && ! grep -q "${PROXY_HOST}" "${commands_yml}"; then
    fail "${commands_yml}: must not route inference outside ${PROXY_HOST}."
  fi
fi

if [[ "${errors}" -gt 0 ]]; then
  echo "Agentic egress verification failed (${errors} issue(s)). See ADR-0028."
  exit 1
fi

echo "Agentic egress allow-list assertion passed ($(find "${WORKFLOWS_DIR}" -name '*.lock.yml' | wc -l | tr -d ' ') lock file(s))."
