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

# mode "exact" picks the item for one os and version; mode "latest" picks the
# item with the highest sparkle:version (the build number) for one os.
# Item markers are matched anywhere in a line, and the closing line is cut
# at </item>: a feed written by an older merge glued "</item>  </channel>" or
# "</item>    <item>" onto one line, and both would otherwise be carried
# into the merged item and break the XML.
select_appcast_item() {
  local file="$1"
  local os_name="$2"
  local ver="$3"
  local mode="$4"
  awk -v target_os="${os_name}" -v target_ver="${ver}" -v mode="${mode}" '
    function block_version(b,   v) {
      if (match(b, /<sparkle:version>[0-9]+<\/sparkle:version>/) == 0) return 0
      v = substr(b, RSTART, RLENGTH)
      gsub(/[^0-9]/, "", v)
      return v + 0
    }
    function emit(b,   v) {
      if (mode == "exact") {
        if (b ~ ("sparkle:os=\"" target_os "\"") &&
            b ~ ("<sparkle:shortVersionString>" target_ver "</sparkle:shortVersionString>")) {
          printf "%s", b
          exit 0
        }
        return
      }
      if (b !~ ("sparkle:os=\"" target_os "\"")) return
      v = block_version(b)
      if (v > best) {
        best = v
        best_block = b
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
    END {
      if (mode != "exact" && best_block != "") printf "%s", best_block
    }
  ' "${file}"
}

pick_merged_item() {
  local os_name="$1"
  local item=""
  item="$(select_appcast_item "${new}" "${os_name}" "${version}" exact || true)"
  # The publish carries one platform at a time, so a platform this publish
  # does not ship must keep the item it had in the remote feed. Dropping it
  # would leave installed clients of that platform with an empty feed.
  if [[ -z "${item}" && -f "${remote}" ]]; then
    item="$(select_appcast_item "${remote}" "${os_name}" "" latest || true)"
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
