#!/usr/bin/env bash
# Emit appcast.xml + latest.json for dl.enjoy.bot from versioned release artifacts.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

version="${VERSION:-$("${root}/.github/scripts/read_pubspec_version.sh")}"
build="${BUILD_NUMBER:-$(grep '^version:' pubspec.yaml | sed -E 's/.*\+([0-9]+).*/\1/')}"
base_url="${ENJOY_PLAYER_DL_BASE:-https://dl.enjoy.bot/player}"
min_supported="${MIN_SUPPORTED_VERSION:-${version}}"
notes="${RELEASE_NOTES:-}"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

declare -A assets=()

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
  assets["${key}"]="${name}|${url}|${sha}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --windows-installer)
      add_asset windows "$2"
      shift 2
      ;;
    --macos-zip)
      add_asset macos "$2"
      shift 2
      ;;
    --android-apk)
      add_asset "$2" "$3"
      shift 3
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

out_dir="${FEED_OUT_DIR:-${root}/build/update-feeds}"
mkdir -p "${out_dir}"

latest_json="${out_dir}/latest.json"
{
  echo '{'
  echo "  \"version\": \"${version}\","
  echo "  \"build\": ${build},"
  echo "  \"minSupportedVersion\": \"${min_supported}\","
  echo "  \"notes\": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "${notes}"),"
  echo '  "assets": {'
  first=true
  for key in "${!assets[@]}"; do
    IFS='|' read -r _file url sha <<< "${assets[$key]}"
    if [[ "${first}" == true ]]; then first=false; else echo ','; fi
    printf '    "%s": {"url": "%s", "sha256": "%s", "file": "%s"}' \
      "${key}" "${url}" "${sha}" "$(basename "${_file}")"
  done
  echo
  echo '  }'
  echo '}'
} > "${latest_json}"

appcast="${out_dir}/appcast.xml"
sparkle_mac_sig="${SPARKLE_ED_SIGNATURE_MACOS:-}"
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

  if [[ -n "${assets[macos]:-}" ]]; then
    IFS='|' read -r file url sha <<< "${assets[macos]}"
    mac_len=0
    if [[ -f "${file}" ]]; then
      mac_len="$(wc -c < "${file}" | tr -d ' ')"
    fi
    echo '    <item>'
    echo "      <title>Version ${version}</title>"
    echo "      <pubDate>${pub_date}</pubDate>"
    echo '      <sparkle:version>'"${build}"'</sparkle:version>'
    echo '      <sparkle:shortVersionString>'"${version}"'</sparkle:shortVersionString>'
    echo '      <enclosure url="'"${url}"'" sparkle:os="macos" type="application/octet-stream" length="'"${mac_len}"'"'
    if [[ -n "${sparkle_mac_sig}" ]]; then
      echo '        sparkle:edSignature="'"${sparkle_mac_sig}"'"'
    fi
    echo '      />'
    echo '    </item>'
  fi

  if [[ -n "${assets[windows]:-}" ]]; then
    IFS='|' read -r file url sha <<< "${assets[windows]}"
    win_len=0
    if [[ -f "${file}" ]]; then
      win_len="$(wc -c < "${file}" | tr -d ' ')"
    fi
    echo '    <item>'
    echo "      <title>Version ${version}</title>"
    echo "      <pubDate>${pub_date}</pubDate>"
    echo '      <sparkle:version>'"${build}"'</sparkle:version>'
    echo '      <sparkle:shortVersionString>'"${version}"'</sparkle:shortVersionString>'
    echo '      <enclosure url="'"${url}"'" sparkle:os="windows" type="application/octet-stream" length="'"${win_len}"'"'
    if [[ -n "${sparkle_win_sig}" ]]; then
      echo '        sparkle:dsaSignature="'"${sparkle_win_sig}"'"'
    fi
    echo '      />'
    echo '    </item>'
  fi

  echo '  </channel>'
  echo '</rss>'
} > "${appcast}"

echo "Wrote ${latest_json}"
echo "Wrote ${appcast}"
