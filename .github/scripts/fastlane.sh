#!/usr/bin/env bash
# Run a fastlane lane with the repo's pinned toolchain.
#
# Usage:
#   bash .github/scripts/fastlane.sh android beta
#   bash .github/scripts/fastlane.sh ios beta
#   bash .github/scripts/fastlane.sh ios submit_review
#   bash .github/scripts/fastlane.sh ios review_status
set -euo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=ensure_fastlane_tooling.sh
source "${scripts}/ensure_fastlane_tooling.sh"

exec bundle exec fastlane "$@"
