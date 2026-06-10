#!/usr/bin/env bash
# Upload versioned artifacts + regenerate feeds on dl.enjoy.bot (S3-compatible: R2, AWS, etc.).
# Use --feeds-only to sign + write feeds under build/update-feeds/ without uploading.
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

root="$(release_repo_root)"
cd "${root}"

feeds_only=false
artifact_argv=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --feeds-only)
      feeds_only=true
      shift
      ;;
    *)
      artifact_argv+=("$1")
      shift
      ;;
  esac
done

release_parse_artifact_args ${artifact_argv[@]+"${artifact_argv[@]}"}

upload_files=()
spec=""
for spec in ${RELEASE_ARTIFACT_SPECS[@]+"${RELEASE_ARTIFACT_SPECS[@]}"}; do
  upload_files+=("$(release_spec_path "${spec}")")
done

feed_args=()
release_artifact_argv feed_args

if [[ ${#upload_files[@]} -eq 0 ]]; then
  echo "No artifacts to publish."
  exit 0
fi

if [[ "${feeds_only}" != true ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "Publish failed: AWS CLI (aws) not found in PATH." >&2
    echo "Install on macOS: brew install awscli" >&2
    echo "Install on Windows: winget install Amazon.AWSCLI" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Publish failed: jq is required to merge latest.json across platforms." >&2
    echo "Install on macOS: brew install jq" >&2
    exit 1
  fi
fi

version="${VERSION:-$(release_version)}"
public_base="${ENJOY_PLAYER_DL_BASE:-https://dl.enjoy.bot/player}"
if [[ "${feeds_only}" == true ]]; then
  public_base="${ENJOY_PLAYER_DL_BASE:-http://127.0.0.1:8787/player}"
fi
export ENJOY_PLAYER_DL_BASE="${public_base}"

has_s3=false
if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  has_s3=true
fi

if [[ "${feeds_only}" != true && "${has_s3}" != true ]]; then
  if [[ "${RELEASE_REQUIRE_S3:-}" == "1" ]]; then
    echo "Publish failed: set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (see publish_env.local.ps1)" >&2
    exit 1
  fi
  echo "Skipping publish: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY not configured."
  exit 0
fi

bucket="${PUBLISH_BUCKET:-enjoy-dl}"
prefix="${PUBLISH_PREFIX:-player}"
s3_base="s3://${bucket}/${prefix}/${version}"

if [[ "${has_s3}" == true ]]; then
  export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-auto}"

  s3_endpoint=()
  s3_checksum=()
  if [[ -n "${AWS_ENDPOINT_URL_S3:-}" ]]; then
    s3_endpoint=(--endpoint-url "${AWS_ENDPOINT_URL_S3}")
    if [[ "${AWS_ENDPOINT_URL_S3}" == *r2.cloudflarestorage.com* ]]; then
      s3_checksum=(--checksum-algorithm CRC32)
      s3_aws_config="$(mktemp)"
      cat >"${s3_aws_config}" <<'EOF'
[default]
s3 =
    max_concurrent_requests = 1
    multipart_threshold = 128MB
    multipart_chunksize = 64MB
EOF
      export AWS_CONFIG_FILE="${s3_aws_config}"
      trap 'rm -f "${s3_aws_config:-}"' EXIT
    fi
  fi

  s3_acl=()
  if [[ ${#s3_endpoint[@]} -eq 0 ]]; then
    s3_acl=(--acl public-read)
  fi

  s3_cp() {
    aws s3 cp "$@" \
      ${s3_endpoint[@]+"${s3_endpoint[@]}"} \
      ${s3_checksum[@]+"${s3_checksum[@]}"} \
      ${s3_acl[@]+"${s3_acl[@]}"} \
      --cli-connect-timeout 300 \
      --cli-read-timeout 300
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

for f in ${upload_files[@]+"${upload_files[@]}"}; do
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

for f in ${upload_files[@]+"${upload_files[@]}"}; do
  case "$(basename "${f}")" in
    EnjoyPlayerSetup-v*.exe|*.exe)
      sign_out="$(bash "${root}/.github/scripts/sign_sparkle_enclosure.sh" "${f}" 2>&1)" || true
      echo "${sign_out}"
      release_apply_sparkle_sign_output "${sign_out}"
      ;;
    EnjoyPlayer-macOS-v*.zip|*.zip)
      sign_out="$(bash "${root}/.github/scripts/sign_sparkle_enclosure.sh" "${f}" 2>&1)" || true
      echo "${sign_out}"
      release_apply_sparkle_sign_output "${sign_out}"
      ;;
  esac
done

merge_feed_dir=""
if [[ "${feeds_only}" != true && "${has_s3}" == true ]]; then
  merge_feed_dir="$(mktemp -d)"
  if release_fetch_remote_feed_file \
      "${merge_feed_dir}/latest.json" \
      "${public_base}/latest.json" \
      "s3://${bucket}/${prefix}/latest.json"; then
    export MERGE_LATEST_JSON="${merge_feed_dir}/latest.json"
  else
    echo "WARN: no remote latest.json to merge; feed will only list artifacts from this publish." >&2
  fi
  if release_fetch_remote_feed_file \
      "${merge_feed_dir}/appcast.xml" \
      "${public_base}/appcast.xml" \
      "s3://${bucket}/${prefix}/appcast.xml"; then
    export MERGE_APPCAST_XML="${merge_feed_dir}/appcast.xml"
  else
    echo "WARN: no remote appcast.xml to merge; feed will only list artifacts from this publish." >&2
  fi
fi

bash "${root}/.github/scripts/generate_update_feeds.sh" ${feed_args[@]+"${feed_args[@]}"}
unset MERGE_LATEST_JSON MERGE_APPCAST_XML
if [[ -n "${merge_feed_dir}" ]]; then
  rm -rf "${merge_feed_dir}"
fi

feed_dir="${FEED_OUT_DIR:-${root}/build/update-feeds}"
cp -f "${feed_dir}/latest.json" "${local_stage}/latest.json"
cp -f "${feed_dir}/appcast.xml" "${local_stage}/appcast.xml"

if [[ "${feeds_only}" == true ]]; then
  serve_root="${root}/build/release/serve"
  serve_player="${serve_root}/player"
  serve_version="${serve_player}/${version}"
  rm -rf "${serve_root}"
  mkdir -p "${serve_version}"
  for f in ${upload_files[@]+"${upload_files[@]}"}; do
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
