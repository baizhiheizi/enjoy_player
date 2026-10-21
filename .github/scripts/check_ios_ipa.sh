#!/usr/bin/env bash
# Verify the exported iOS IPA contains the files App Store Connect expects.
#
# Usage: check_ios_ipa.sh <path/to/app.ipa>
set -euo pipefail

ipa="${1:-}"
if [[ -z "${ipa}" || ! -f "${ipa}" ]]; then
  echo "usage: $0 <path/to/app.ipa>" >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/enjoy-player-ipa.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

unzip -q "${ipa}" -d "${tmp_dir}"
app="${tmp_dir}/Payload/Runner.app"
if [[ ! -d "${app}" ]]; then
  echo "::error::missing Payload/Runner.app in ${ipa}" >&2
  exit 1
fi

frameworks="${app}/Frameworks"
if [[ ! -f "${frameworks}/eSpeakNG.framework/eSpeakNG" ]]; then
  echo "::error::missing Payload/Runner.app/Frameworks/eSpeakNG.framework/eSpeakNG" >&2
  exit 1
fi

# Naked .dylibs in Frameworks/ are not supported on iOS (TN2435), except for
# the system Swift libraries Xcode itself provides. Xcode embeds
# libswiftCompatibilitySpan.dylib for apps that link Swift under a Swift 6
# toolchain; TN2435 exempts it, and App Store Connect accepts the upload
# (verified with `xcrun altool --validate-app`). Every other naked .dylib is
# a packaging bug (the eSpeak library was one) and trips TN2435 / ITMS-90171
# / ITMS-90426.
#
# The exemption is granted on the code-signing identifier, which Xcode keeps
# when it re-signs the shim with the app's own identity inside the bundle.
is_xcode_swift_runtime_dylib() {
  local path="$1" identifier
  identifier="$(
    codesign -dv --verbose=2 "${path}" 2>&1 |
      awk -F= '/^Identifier=/ { print $2; exit }'
  )"
  [[ "${identifier}" == "com.apple.dt.runtime.swiftCompatibilitySpan" ]]
}

naked_dylibs=()
while IFS= read -r dylib; do
  if is_xcode_swift_runtime_dylib "${dylib}"; then
    continue
  fi
  naked_dylibs+=("${dylib}")
done < <(find "${frameworks}" -maxdepth 1 -name '*.dylib' -type f | sort)

if [[ ${#naked_dylibs[@]} -gt 0 ]]; then
  echo "::error::standalone .dylib files in Frameworks/ are not allowed on iOS (TN2435 / ITMS-90426):" >&2
  printf '  %s\n' "${naked_dylibs[@]#"${tmp_dir}/"}" >&2
  exit 1
fi

minimum_os="$(
  plutil -extract MinimumOSVersion raw -o - "${app}/Info.plist"
)"
if [[ "${minimum_os}" != "15.0" ]]; then
  echo "::error::expected MinimumOSVersion 15.0, found ${minimum_os}" >&2
  exit 1
fi

codesign --verify --deep --strict "${app}"
echo "iOS IPA packaging ok: ${ipa} (MinimumOSVersion=${minimum_os})"
