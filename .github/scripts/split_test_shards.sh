#!/usr/bin/env bash
# Emit one shard's slice of the app test files, one path per line.
#
# flutter test's --total-shards/--shard-index split by test case inside every
# file, so each shard still compiles the whole suite; passing an explicit,
# disjoint file list is what actually partitions the compile and the run.
# Round-robin over the LC_ALL=C-sorted list keeps the perf-test clusters
# spread across shards.
#
# usage: split_test_shards.sh SHARD_INDEX TOTAL_SHARDS
set -euo pipefail

index="${1:?shard index}"
total="${2:?shard total}"

case "$index" in
  ''|*[!0-9]*) echo "shard index must be a number: $index" >&2; exit 2 ;;
esac
case "$total" in
  ''|*[!0-9]*) echo "shard total must be a number: $total" >&2; exit 2 ;;
esac
if [ "$index" -ge "$total" ]; then
  echo "shard index $index out of range for total $total" >&2
  exit 2
fi

find test -name '*_test.dart' | LC_ALL=C sort \
  | awk -v n="$total" -v i="$index" 'NR % n == i'
