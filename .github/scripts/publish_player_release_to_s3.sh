#!/usr/bin/env bash
# Upload versioned artifacts + regenerate feeds on dl.enjoy.bot (optional secrets).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Skipping S3 publish: AWS credentials not configured."
  exit 0
fi

bucket="${ENJOY_DL_S3_BUCKET:-enjoy-dl}"
prefix="${ENJOY_DL_S3_PREFIX:-player}"
version="${VERSION:-$("${root}/.github/scripts/read_pubspec_version.sh")}"
s3_base="s3://${bucket}/${prefix}/${version}"
public_base="${ENJOY_PLAYER_DL_BASE:-https://dl.enjoy.bot/player}"

feed_args=()
upload_files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --windows-installer)
      upload_files+=("$2")
      feed_args+=(--windows-installer "$2")
      shift 2
      ;;
    --macos-zip)
      upload_files+=("$2")
      feed_args+=(--macos-zip "$2")
      shift 2
      ;;
    --android-apk)
      upload_files+=("$3")
      feed_args+=(--android-apk "$2" "$3")
      shift 3
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ${#upload_files[@]} -eq 0 ]]; then
  echo "No artifacts to publish."
  exit 0
fi

for f in "${upload_files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "::error::Missing artifact: ${f}"
    exit 1
  fi
  aws s3 cp "${f}" "${s3_base}/$(basename "${f}")" \
    --acl public-read \
    --content-type "$(file -b --mime-type "${f}" 2>/dev/null || echo application/octet-stream)"
  echo "Uploaded $(basename "${f}")"
done

export ENJOY_PLAYER_DL_BASE="${public_base}"
bash "${root}/.github/scripts/generate_update_feeds.sh" "${feed_args[@]}"

feed_dir="${FEED_OUT_DIR:-${root}/build/update-feeds}"
aws s3 cp "${feed_dir}/latest.json" "s3://${bucket}/${prefix}/latest.json" \
  --acl public-read \
  --content-type application/json \
  --cache-control "max-age=300, must-revalidate"
aws s3 cp "${feed_dir}/appcast.xml" "s3://${bucket}/${prefix}/appcast.xml" \
  --acl public-read \
  --content-type application/xml \
  --cache-control "max-age=300, must-revalidate"

if [[ -n "${CLOUDFRONT_DISTRIBUTION_ID:-}" ]]; then
  aws cloudfront create-invalidation \
    --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
    --paths "/${prefix}/latest.json" "/${prefix}/appcast.xml" >/dev/null
  echo "Invalidated CloudFront paths for feeds."
fi

echo "Published ${version} to ${public_base}/${version}/"
