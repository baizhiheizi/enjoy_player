#!/usr/bin/env bash
# Assert the iOS SDK App Store Connect requires for uploads (warning 90725):
# starting April 2027, iOS/iPadOS apps must be built with the iOS 27 SDK or
# later, included in Xcode 27 or later.
#
# Usage:
#   check_ios_sdk_requirement.sh                    host mode — the active Xcode's iOS SDK
#   check_ios_sdk_requirement.sh --macho <binary>   artifact mode — the build SDK recorded in a Mach-O
#   check_ios_sdk_requirement.sh --warn             report as a ::warning:: instead of failing
#
# Env:
#   IOS_SDK_MINIMUM                  required major version (default 27)
#   ALLOW_IOS_SDK_BELOW_MINIMUM=1    deliberate bypass: warn loudly and exit 0.
#                                    The upload still carries App Store Connect
#                                    warning 90725 today and is rejected outright
#                                    once the April 2027 requirement is enforced.
set -euo pipefail

usage() {
  sed -n '2,12p' "$0"
}

minimum="${IOS_SDK_MINIMUM:-27}"
mode="host"
macho_path=""
warn_only=false

while [ $# -gt 0 ]; do
  case "$1" in
    --macho)
      mode="macho"
      if [ $# -lt 2 ]; then
        echo "usage: $0 --macho <path/to/macho-binary>" >&2
        exit 1
      fi
      macho_path="$2"
      shift 2
      ;;
    --warn)
      warn_only=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

bypassed() {
  [ "${ALLOW_IOS_SDK_BELOW_MINIMUM:-}" = "1" ]
}

# Not enforcing when --warn was passed or the operator set the bypass env;
# the annotation is downgraded to ::warning:: and the caller is let through.
report_failure() {
  headline="$1"
  detail="${2:-}"
  if [ "${warn_only}" = true ] || bypassed; then
    echo "::warning::${headline}" >&2
    if [ -n "${detail}" ]; then
      printf '%s\n' "${detail}" >&2
    fi
    exit 0
  fi
  echo "::error::${headline}" >&2
  if [ -n "${detail}" ]; then
    printf '%s\n' "${detail}" >&2
  fi
  exit 1
}

sdk_major() {
  major="${1%%.*}"
  case "${major}" in
    '' | *[!0-9]*) echo "" ;;
    *) echo "${major}" ;;
  esac
}

upgrade_instructions() {
  cat <<EOF
Install Xcode 27 or later (https://developer.apple.com/download/applications/),
then on the runner Mac:
  sudo xcode-select -s /Applications/Xcode.app
  sudo xcodebuild -runFirstLaunch
  xcodebuild -downloadPlatform iOS
EOF
}

check_host_sdk() {
  version="$(xcrun --sdk iphoneos --show-sdk-version 2>/dev/null || true)"
  if [ -z "${version}" ]; then
    report_failure \
      "the active Xcode reports no iOS SDK (xcrun --sdk iphoneos --show-sdk-version returned nothing)." \
      "App Store Connect requires the iOS ${minimum} SDK or later (Xcode 27+) for iOS uploads from April 2027 (warning 90725).
$(upgrade_instructions)"
  fi
  major="$(sdk_major "${version}")"
  if [ -z "${major}" ]; then
    report_failure \
      "the active Xcode reports an unparseable iOS SDK version: '${version}'."
  fi
  if [ "${major}" -lt "${minimum}" ]; then
    report_failure \
      "the active Xcode builds with the iOS ${version} SDK, below the required minimum of iOS ${minimum} — App Store Connect warning 90725." \
      "From April 2027, iOS/iPadOS apps must be built with the iOS ${minimum} SDK or later (Xcode 27+) to upload to App Store Connect.
$(upgrade_instructions)"
  fi
  echo "iOS SDK ${version} meets the App Store upload minimum (${minimum}) — ok."
}

check_macho_sdk() {
  if [ ! -f "${macho_path}" ]; then
    echo "usage: $0 --macho <path/to/macho-binary> — no such file: ${macho_path}" >&2
    exit 1
  fi
  build_info="$(xcrun vtool -show-build "${macho_path}" 2>/dev/null || true)"
  if [ -z "${build_info}" ]; then
    report_failure \
      "vtool could not read the build version load commands of ${macho_path}."
  fi
  slices=0
  wrong_platforms=""
  old_sdks=""
  while read -r platform slice_sdk; do
    slices=$((slices + 1))
    if [ "${platform}" != "IOS" ]; then
      wrong_platforms="${wrong_platforms}${wrong_platforms:+; }${platform} slice (sdk ${slice_sdk})"
    fi
    major="$(sdk_major "${slice_sdk}")"
    if [ -z "${major}" ] || [ "${major}" -lt "${minimum}" ]; then
      old_sdks="${old_sdks}${old_sdks:+; }${platform} slice built with the SDK ${slice_sdk}"
    fi
  done < <(
    printf '%s\n' "${build_info}" \
      | awk '/platform / { platform=$2 } /^ *sdk / { print platform, $2 }'
  )
  if [ "${slices}" -eq 0 ]; then
    report_failure \
      "no LC_BUILD_VERSION load command in ${macho_path} — cannot prove which SDK built it."
  fi
  if [ -n "${wrong_platforms}" ]; then
    report_failure \
      "${macho_path} carries non-device slices: ${wrong_platforms} — a device IPA must contain iOS platform slices only." \
      "A simulator slice (IOSSIMULATOR) in the uploaded binary is a packaging bug."
  fi
  if [ -n "${old_sdks}" ]; then
    report_failure \
      "${macho_path} was built with an SDK below the required minimum of iOS ${minimum}: ${old_sdks} — App Store Connect warning 90725." \
      "The IPA on disk predates the runner's toolchain upgrade; rebuild it (flutter build ipa) and re-run, or drop --skip-build.
$(upgrade_instructions)"
  fi
  echo "Mach-O build SDK meets the App Store upload minimum (${minimum}) — ok: ${macho_path}"
}

if [ "${mode}" = "macho" ]; then
  check_macho_sdk
else
  check_host_sdk
fi
