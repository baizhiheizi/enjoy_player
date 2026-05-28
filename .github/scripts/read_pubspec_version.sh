#!/usr/bin/env bash
# Print semver from pubspec.yaml (strip +build). Run from repo root.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
version_line="$(grep -m1 '^version:' "${root}/pubspec.yaml")"
if [[ -z "${version_line}" ]]; then
  echo "Could not parse version from pubspec.yaml" >&2
  exit 1
fi
echo "${version_line#version:}" | tr -d ' ' | cut -d'+' -f1
