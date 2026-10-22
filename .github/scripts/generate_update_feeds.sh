#!/usr/bin/env bash
# Emit appcast.xml + latest.json for dl.enjoy.bot from versioned release artifacts.
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

root="$(release_repo_root)"
cd "${root}"

release_parse_artifact_args "$@"

version="${VERSION:-$(release_version)}"
build="${BUILD_NUMBER:-$(release_build_number)}"
base_url="${ENJOY_PLAYER_DL_BASE:-https://dl.enjoy.bot/player}"
min_supported="${MIN_SUPPORTED_VERSION:-${version}}"
notes="${RELEASE_NOTES:-}"

json_string() {
  local s="${1//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '"%s"' "${s}"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

declare -a ASSET_ENTRIES=()

add_asset() {
  local key="$1"
  local file="$2"
  if [[ ! -f "${file}" ]]; then
    echo "skip missing asset (${key}): ${file}" >&2
    return 0
  fi
  local name sha url
  name="$(basename "${file}")"
  sha="$(sha256_file "${file}")"
  url="${base_url}/${version}/${name}"
  ASSET_ENTRIES+=("${key}|${name}|${url}|${sha}|${file}")
}

asset_entry_for_key() {
  local want="$1"
  local entry key
  for entry in ${ASSET_ENTRIES[@]+"${ASSET_ENTRIES[@]}"}; do
    key="${entry%%|*}"
    if [[ "${key}" == "${want}" ]]; then
      echo "${entry}"
      return 0
    fi
  done
  return 1
}

# Emit one Sparkle appcast <item>. macOS and Windows share the element shape
# but not the signature scheme: macOS verifies EdDSA (sparkle:edSignature),
# Windows verifies legacy DSA (sparkle:dsaSignature) — so the attribute name
# travels with the platform, it is not unified.
emit_appcast_item() {
  local os_name="$1"
  local asset_key="$2"
  local sig="$3"
  local sig_attr="$4"
  local asset url path len=0
  local _key _name _sha
  asset="$(asset_entry_for_key "${asset_key}" || true)"
  if [[ -z "${asset}" ]]; then
    return 0
  fi
  IFS='|' read -r _key _name url _sha path <<< "${asset}"
  if [[ -f "${path}" ]]; then
    len="$(wc -c < "${path}" | tr -d ' ')"
  fi
  echo '    <item>'
  echo "      <title>Version ${version}</title>"
  echo "      <pubDate>${pub_date}</pubDate>"
  echo '      <sparkle:version>'"${build}"'</sparkle:version>'
  echo '      <sparkle:shortVersionString>'"${version}"'</sparkle:shortVersionString>'
  echo '      <enclosure url="'"${url}"'" sparkle:os="'"${os_name}"'" type="application/octet-stream" length="'"${len}"'"'
  if [[ -n "${sig}" ]]; then
    echo '        '"${sig_attr}"'="'"${sig}"'"'
  fi
  echo '      />'
  echo '    </item>'
}

spec=""
for spec in ${RELEASE_ARTIFACT_SPECS[@]+"${RELEASE_ARTIFACT_SPECS[@]}"}; do
  add_asset "$(release_spec_key "${spec}")" "$(release_spec_path "${spec}")"
done

out_dir="${FEED_OUT_DIR:-${root}/build/update-feeds}"
mkdir -p "${out_dir}"

latest_json="${out_dir}/latest.json"
{
  echo '{'
  echo "  \"version\": \"${version}\","
  echo "  \"build\": ${build},"
  echo "  \"minSupportedVersion\": \"${min_supported}\","
  echo "  \"notes\": $(json_string "${notes}"),"
  echo '  "assets": {'
  first=true
  entry=""
  for entry in ${ASSET_ENTRIES[@]+"${ASSET_ENTRIES[@]}"}; do
    IFS='|' read -r key _file url sha _path <<< "${entry}"
    if [[ "${first}" == true ]]; then first=false; else echo ','; fi
    printf '    "%s": {"url": "%s", "sha256": "%s", "file": "%s"}' \
      "${key}" "${url}" "${sha}" "${_file}"
  done
  echo
  echo '  }'
  echo '}'
} > "${latest_json}"

if [[ -n "${MERGE_LATEST_JSON:-}" && -f "${MERGE_LATEST_JSON}" ]]; then
  merged_json="${out_dir}/latest.merged.json"
  bash "${root}/.github/scripts/merge_latest_json.sh" \
    "${latest_json}" "${MERGE_LATEST_JSON}" "${merged_json}"
  mv -f "${merged_json}" "${latest_json}"
  echo "Merged remote latest.json assets for version ${version}."
fi

appcast="${out_dir}/appcast.xml"
sparkle_mac_sig="${SPARKLE_ED_SIGNATURE_MACOS:-}"
# SPARKLE_ED_SIGNATURE_WINDOWS carries a DSA signature (dsa_priv.pem) despite
# the EdDSA name — CI exports it that way, and the Windows item must emit it
# as sparkle:dsaSignature, never sparkle:edSignature.
sparkle_win_sig="${SPARKLE_ED_SIGNATURE_WINDOWS:-}"
pub_date="$(date -u +"%a, %d %b %Y %H:%M:%S +0000")"

{
  echo '<?xml version="1.0" encoding="utf-8"?>'
  echo '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">'
  echo '  <channel>'
  echo '    <title>Enjoy Player</title>'
  echo '    <link>https://enjoy.bot</link>'
  echo '    <description>Enjoy Player direct-download updates</description>'
  echo '    <language>en</language>'

  emit_appcast_item macos macos "${sparkle_mac_sig}" sparkle:edSignature
  emit_appcast_item windows windows "${sparkle_win_sig}" sparkle:dsaSignature

  echo '  </channel>'
  echo '</rss>'
} > "${appcast}"

if [[ -n "${MERGE_APPCAST_XML:-}" && -f "${MERGE_APPCAST_XML}" ]]; then
  merged_appcast="${out_dir}/appcast.merged.xml"
  bash "${root}/.github/scripts/merge_appcast_xml.sh" \
    "${appcast}" "${MERGE_APPCAST_XML}" "${merged_appcast}" "${version}"
  mv -f "${merged_appcast}" "${appcast}"
  echo "Merged remote appcast.xml items for version ${version}."
fi

echo "Wrote ${latest_json}"
echo "Wrote ${appcast}"
