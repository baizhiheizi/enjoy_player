#!/usr/bin/env bash
# Merge Sparkle appcast items by sparkle:os for multi-platform releases.
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: merge_appcast_xml.sh <new_appcast.xml> <remote_appcast.xml> <output.xml> <version>" >&2
  exit 2
fi

new="$1"
remote="$2"
out="$3"
version="$4"

pick_appcast_item() {
  local file="$1"
  local os_name="$2"
  local ver="$3"
  # Item markers are matched anywhere in a line, and the closing line is cut
  # at </item>: a feed written by an older merge glued "</item>  </channel>" or
  # "</item>    <item>" onto one line, and both would otherwise be carried
  # into the merged item and break the XML.
  awk -v target_os="${os_name}" -v target_ver="${ver}" '
    function emit(b) {
      if (b ~ ("sparkle:os=\"" target_os "\"") &&
          b ~ ("<sparkle:shortVersionString>" target_ver "</sparkle:shortVersionString>")) {
        printf "%s", b
        exit 0
      }
    }
    {
      rest = $0
      while (rest != "") {
        if (!in_item) {
          s = index(rest, "<item>")
          if (s == 0) break
          block = substr(rest, 1, s + 5) ORS
          in_item = 1
          rest = substr(rest, s + 6)
        } else {
          s = index(rest, "</item>")
          if (s == 0) {
            block = block rest ORS
            break
          }
          block = block substr(rest, 1, s + 6) ORS
          emit(block)
          block = ""
          in_item = 0
          rest = substr(rest, s + 7)
        }
      }
    }
  ' "${file}"
}

pick_merged_item() {
  local os_name="$1"
  local item=""
  item="$(pick_appcast_item "${new}" "${os_name}" "${version}" || true)"
  if [[ -z "${item}" && -f "${remote}" ]]; then
    item="$(pick_appcast_item "${remote}" "${os_name}" "${version}" || true)"
  fi
  printf '%s' "${item}"
}

if ! grep -q '<channel>' "${new}"; then
  echo "Invalid appcast: missing channel in ${new}" >&2
  exit 1
fi

header="$(sed -n '1,/<language>en<\/language>/p' "${new}")"
footer=$'  </channel>\n</rss>'
mac_item="$(pick_merged_item macos)"
win_item="$(pick_merged_item windows)"

{
  printf '%s\n' "${header}"
  # Each item block loses its trailing newline to command substitution, so
  # print one back — otherwise "</item>" is glued to the next element and the
  # feed stops parsing.
  [[ -n "${mac_item}" ]] && printf '%s\n' "${mac_item}"
  [[ -n "${win_item}" ]] && printf '%s\n' "${win_item}"
  printf '%s\n' "${footer}"
} > "${out}"
