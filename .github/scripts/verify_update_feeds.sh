#!/usr/bin/env bash
# Verify the direct-download update feed before it is published.
#
# latest.json and appcast.xml describe the same release from two sides: the
# manifest lists the artifacts a client can download, the Sparkle feed lists
# the enclosures an installed client can update to. A platform that appears
# in one but not the other cannot update - the manifest advertises a download
# the app will not offer, or the feed offers an enclosure Sparkle refuses.
#
# Usage:
#   bash .github/scripts/verify_update_feeds.sh <latest.json> <appcast.xml>
#
# Requires `jq` or `python3` on PATH.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: verify_update_feeds.sh <latest.json> <appcast.xml>" >&2
  exit 2
fi

latest="$1"
appcast="$2"

if [[ ! -f "${latest}" ]]; then
  echo "Missing update manifest: ${latest}" >&2
  exit 1
fi

if [[ ! -f "${appcast}" ]]; then
  echo "Missing appcast: ${appcast}" >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  manifest_tool=jq
elif command -v python3 >/dev/null 2>&1; then
  manifest_tool=python3
else
  echo "verify_update_feeds.sh requires jq or python3 on PATH" >&2
  exit 1
fi

# Sparkle verifies EdDSA on macOS and legacy DSA on Windows, so the
# signature scheme is not unified across platforms.
signature_scheme_for() {
  case "$1" in
    macos) echo "ed" ;;
    windows) echo "dsa" ;;
    *) echo "" ;;
  esac
}

errors=0
fail() {
  echo "FAIL: $*" >&2
  errors=$((errors + 1))
}

manifest_platforms() {
  if [[ "${manifest_tool}" == "jq" ]]; then
    jq -r '.assets | keys[]' "${latest}"
  else
    python3 -c '
import json, sys
with open(sys.argv[1]) as handle:
    for key in json.load(handle)["assets"]:
        print(key)
' "${latest}"
  fi
}

manifest_has_assets() {
  if [[ "${manifest_tool}" == "jq" ]]; then
    jq -e '.assets | type == "object"' "${latest}" >/dev/null 2>&1
  else
    python3 -c '
import json, sys
with open(sys.argv[1]) as handle:
    assets = json.load(handle).get("assets")
sys.exit(0 if isinstance(assets, dict) else 1)
' "${latest}" >/dev/null 2>&1
  fi
}

if ! manifest_has_assets; then
  echo "FAIL: ${latest} has no assets object." >&2
  echo "The update manifest is malformed; refusing to publish a broken feed." >&2
  exit 1
fi

if command -v xmllint >/dev/null 2>&1; then
  if ! xmllint --noout "${appcast}" >/dev/null 2>&1; then
    echo "FAIL: ${appcast} is not well-formed XML." >&2
    exit 1
  fi
elif command -v python3 >/dev/null 2>&1; then
  if ! python3 -c 'import sys, xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "${appcast}" >/dev/null 2>&1; then
    echo "FAIL: ${appcast} is not well-formed XML." >&2
    exit 1
  fi
fi

# One line per appcast item: the platform it targets and the signature
# scheme it carries (empty when the enclosure is unsigned).
appcast_items() {
  awk '
    {
      if (index($0, "<item>") > 0) {
        in_item = 1
        block = ""
      }
      if (in_item) block = block $0 "\n"
      if (index($0, "</item>") > 0) {
        in_item = 0
        os = ""
        scheme = ""
        if (match(block, /sparkle:os="[a-z]+"/)) {
          os = substr(block, RSTART, RLENGTH)
          gsub(/^sparkle:os="/, "", os)
          gsub(/"$/, "", os)
        }
        if (block ~ /sparkle:edSignature="[^"]*"/) {
          scheme = "ed"
        } else if (block ~ /sparkle:dsaSignature="[^"]*"/) {
          scheme = "dsa"
        }
        print os "\t" scheme
      }
    }
  ' "${appcast}"
}

manifest_platform_list="$(manifest_platforms || true)"
appcast_platform_list="$(appcast_items | cut -f1 | sort -u)"

while IFS= read -r platform; do
  [[ -n "${platform}" ]] || continue
  expected="$(signature_scheme_for "${platform}")"
  if [[ -z "${expected}" ]]; then
    continue
  fi
  if ! grep -q "^${platform}\$" <<<"${appcast_platform_list}"; then
    fail "The manifest offers a ${platform} asset but the appcast has no ${platform} item."
  fi
done <<<"${manifest_platform_list}"

while IFS=$'\t' read -r platform scheme; do
  [[ -n "${platform}" ]] || continue
  expected="$(signature_scheme_for "${platform}")"
  if [[ -z "${expected}" ]]; then
    fail "The appcast has an item for ${platform}, which no Sparkle platform drives."
    continue
  fi
  if [[ -z "${scheme}" ]]; then
    fail "The appcast ${platform} item is unsigned; Sparkle refuses an enclosure without a signature."
    continue
  fi
  if [[ "${scheme}" != "${expected}" ]]; then
    fail "The appcast ${platform} item carries a ${scheme} signature; ${platform} expects ${expected}."
    continue
  fi
  if ! grep -q "^${platform}\$" <<<"${manifest_platform_list}"; then
    fail "The appcast has a ${platform} item but the manifest offers no ${platform} asset."
  fi
done < <(appcast_items)

if [[ ${errors} -gt 0 ]]; then
  echo "${errors} update feed check(s) failed - see docs/packaging.md." >&2
  exit 1
fi

echo "Update feed checks passed."
