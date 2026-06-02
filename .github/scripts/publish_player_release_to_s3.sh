#!/usr/bin/env bash
# Upload versioned artifacts + regenerate feeds on dl.enjoy.bot (S3-compatible: R2, AWS, etc.).
# Use --feeds-only to sign + write feeds under build/update-feeds/ without uploading.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

feed_args=()
upload_files=()
feeds_only=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feeds-only)
      feeds_only=true
      shift
      ;;
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

version="${VERSION:-$("${root}/.github/scripts/read_pubspec_version.sh")}"
public_base="${ENJOY_PLAYER_DL_BASE:-https://dl.enjoy.bot/player}"
if [[ "${feeds_only}" == true ]]; then
  public_base="${ENJOY_PLAYER_DL_BASE:-http://127.0.0.1:8787/player}"
fi
export ENJOY_PLAYER_DL_BASE="${public_base}"

has_s3=false
if [[ -n "${S3_ACCESS_KEY_ID:-}" && -n "${S3_SECRET_ACCESS_KEY:-}" ]]; then
  has_s3=true
fi

if [[ "${feeds_only}" != true && "${has_s3}" != true ]]; then
  if [[ "${RELEASE_REQUIRE_S3:-}" == "1" ]]; then
    echo "Publish failed: set S3_ACCESS_KEY_ID / S3_SECRET_ACCESS_KEY (see publish_env.local.ps1)" >&2
    exit 1
  fi
  echo "Skipping publish: S3_ACCESS_KEY_ID / S3_SECRET_ACCESS_KEY not configured."
  exit 0
fi

bucket="${S3_BUCKET:-enjoy-dl}"
prefix="${S3_PREFIX:-player}"
s3_base="s3://${bucket}/${prefix}/${version}"

if [[ "${has_s3}" == true ]]; then
  export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
  export AWS_DEFAULT_REGION="${S3_REGION:-auto}"

  if [[ -n "${S3_ENDPOINT:-}" ]]; then
    s3_endpoint=(--endpoint-url "${S3_ENDPOINT}")
  else
    s3_endpoint=()
  fi

  s3_acl=()
  if [[ ${#s3_endpoint[@]} -eq 0 ]]; then
    s3_acl=(--acl public-read)
  fi

  s3_cp() {
    aws s3 cp "$@" "${s3_endpoint[@]}" "${s3_acl[@]}"
  }
else
  s3_cp() {
    echo "skip s3 upload (feeds-only): $*" >&2
  }
fi

purge_feed_cache() {
  if [[ "${feeds_only}" == true ]]; then
    return 0
  fi
  if [[ -n "${CLOUDFLARE_API_TOKEN:-}" && -n "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    curl -fsS -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"files\":[\"${public_base}/latest.json\",\"${public_base}/appcast.xml\"]}" \
      >/dev/null
    echo "Purged Cloudflare cache for feed URLs."
    return 0
  fi
  if [[ -n "${CLOUDFRONT_DISTRIBUTION_ID:-}" ]]; then
    aws cloudfront create-invalidation \
      --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
      --paths "/${prefix}/latest.json" "/${prefix}/appcast.xml" >/dev/null
    echo "Invalidated CloudFront paths for feeds."
  fi
}

local_stage="${root}/build/release/${version}"
mkdir -p "${local_stage}"

for f in "${upload_files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "::error::Missing artifact: ${f}" >&2
    exit 1
  fi
  cp -f "${f}" "${local_stage}/$(basename "${f}")"
  if [[ "${feeds_only}" != true ]]; then
    s3_cp "${f}" "${s3_base}/$(basename "${f}")" \
      --content-type "$(file -b --mime-type "${f}" 2>/dev/null || echo application/octet-stream)"
    echo "Uploaded $(basename "${f}")"
  fi
done

for f in "${upload_files[@]}"; do
  case "$(basename "${f}")" in
    EnjoyPlayerSetup-v*.exe|*.exe)
      bash "${root}/.github/scripts/sign_sparkle_enclosure.sh" "${f}" || true
      ;;
    EnjoyPlayer-macOS-v*.zip|*.zip)
      bash "${root}/.github/scripts/sign_sparkle_enclosure.sh" "${f}" || true
      ;;
  esac
done

bash "${root}/.github/scripts/generate_update_feeds.sh" "${feed_args[@]}"

feed_dir="${FEED_OUT_DIR:-${root}/build/update-feeds}"
cp -f "${feed_dir}/latest.json" "${local_stage}/latest.json"
cp -f "${feed_dir}/appcast.xml" "${local_stage}/appcast.xml"

if [[ "${feeds_only}" == true ]]; then
  serve_root="${root}/build/release/serve"
  serve_player="${serve_root}/player"
  serve_version="${serve_player}/${version}"
  rm -rf "${serve_root}"
  mkdir -p "${serve_version}"
  for f in "${upload_files[@]}"; do
    cp -f "${f}" "${serve_version}/$(basename "${f}")"
  done
  cp -f "${feed_dir}/latest.json" "${serve_player}/latest.json"
  cp -f "${feed_dir}/appcast.xml" "${serve_player}/appcast.xml"
fi

if [[ "${feeds_only}" != true ]]; then
  s3_cp "${feed_dir}/latest.json" "s3://${bucket}/${prefix}/latest.json" \
    --content-type application/json \
    --cache-control "max-age=300, must-revalidate"
  s3_cp "${feed_dir}/appcast.xml" "s3://${bucket}/${prefix}/appcast.xml" \
    --content-type application/xml \
    --cache-control "max-age=300, must-revalidate"
  purge_feed_cache
  echo "Published ${version} to ${public_base}/${version}/"
else
  echo "Local release bundle: ${local_stage}/"
  echo "Local update server root: ${serve_root}/"
  echo "  player/latest.json  player/appcast.xml  player/${version}/"
  echo "Serve for update testing:"
  echo "  cd build/release/serve && python -m http.server 8787"
  echo "Feeds use base URL: ${public_base}"
fi
