#!/usr/bin/env bash
# Assert every compiled agentic workflow routes inference through a proxy host
# declared by a shared engine component (ADR-0028) and that its egress
# allow-list includes that host (GH_AW firewall).
set -euo pipefail

WORKFLOWS_DIR=".github/workflows"
errors=0

fail() {
  echo "::error::$1"
  errors=$((errors + 1))
}

base_url_hosts() {
  sed -nE 's|.*ANTHROPIC_BASE_URL:[[:space:]]*"?(https?://)([^/"[:space:]]+).*|\2|p' "$1"
}

# The sanctioned hosts are whatever the shared engine components declare, so an
# engine switch (ADR-0028 amendment) extends the set without editing this gate.
SANCTIONED_HOSTS="$(for engine_md in "${WORKFLOWS_DIR}"/shared/engine-*.md; do
  [[ -f "${engine_md}" ]] || continue
  base_url_hosts "${engine_md}"
done | sort -u)"

if [[ -z "${SANCTIONED_HOSTS}" ]]; then
  echo "::error::no shared engine component declares ANTHROPIC_BASE_URL (ADR-0028)."
  exit 1
fi

# A source workflow that configures inference inline bypasses the shared engine
# components the sanctioned set is derived from.
for md in "${WORKFLOWS_DIR}"/*.md; do
  [[ -f "${md}" ]] || continue
  if grep -q 'ANTHROPIC_BASE_URL' "${md}" && ! grep -qE 'shared/engine-[a-z0-9-]+\.md' "${md}"; then
    fail "${md}: inline engine config must move to a shared engine component (ADR-0028)."
  fi
done

for lock in "${WORKFLOWS_DIR}"/*.lock.yml; do
  [[ -f "${lock}" ]] || continue

  hosts="$(base_url_hosts "${lock}" | sort -u)"
  if [[ -z "${hosts}" ]]; then
    fail "${lock}: no ANTHROPIC_BASE_URL — every agentic lock routes inference through a shared engine's proxy (ADR-0028)."
    continue
  fi

  while IFS= read -r host; do
    if ! printf '%s\n' "${SANCTIONED_HOSTS}" | grep -Fxq "${host}"; then
      fail "${lock}: ANTHROPIC_BASE_URL host ${host} is not declared by any shared engine component (ADR-0028)."
    fi
    if ! grep -v 'ANTHROPIC_BASE_URL' "${lock}" | grep "${host}" > /dev/null; then
      fail "${lock}: egress allow-list must include ${host}."
    fi
  done <<< "${hosts}"
done

commands_yml="${WORKFLOWS_DIR}/agentic_commands.yml"
if [[ -f "${commands_yml}" ]]; then
  while IFS= read -r host; do
    if ! printf '%s\n' "${SANCTIONED_HOSTS}" | grep -Fxq "${host}"; then
      fail "${commands_yml}: must not route inference outside the shared engine proxies (ADR-0028: ${host})."
    fi
  done < <(base_url_hosts "${commands_yml}")
fi

if [[ "${errors}" -gt 0 ]]; then
  echo "Agentic egress verification failed (${errors} issue(s)). See ADR-0028."
  exit 1
fi

lock_count="$(find "${WORKFLOWS_DIR}" -name '*.lock.yml' | wc -l | tr -d ' ')"
echo "Agentic egress allow-list assertion passed (${lock_count} lock file(s); sanctioned hosts: $(echo "${SANCTIONED_HOSTS}" | tr '\n' ' '))"
