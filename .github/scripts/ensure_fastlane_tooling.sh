#!/usr/bin/env bash
# Ensure Ruby + Bundler + the Gemfile.lock-pinned fastlane gems are installed
# into a repo-local path (no sudo, no system gem pollution). Idempotent.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v ruby >/dev/null 2>&1; then
  echo "::error::ruby 3.2+ is required for fastlane uploads (mise use ruby@3.4 / brew install ruby)" >&2
  exit 1
fi

ruby_version="$(ruby -e 'puts RUBY_VERSION')"
if [[ "$(printf '%s\n3.2\n' "${ruby_version}" | sort -V | head -1)" != "3.2" ]]; then
  echo "::error::fastlane needs ruby >= 3.2, found ${ruby_version}" >&2
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "::error::bundler is missing (gem install bundler)" >&2
  exit 1
fi

cd "${root}"
bundle config set --local path .github/scripts/.fastlane-bundle
if ! bundle check >/dev/null 2>&1; then
  echo ">>> Installing fastlane gems (pinned by Gemfile.lock)"
  bundle install
fi
