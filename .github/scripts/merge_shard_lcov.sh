#!/usr/bin/env bash
# Union-merge per-shard lcov tracefiles into one exact tracefile.
#
# flutter test shards by test case, so every shard's tracefile records the
# same SF files — concatenating them would multiply LF by the shard count
# while LH only grows by the hits each shard adds, and the gate's LF/LH sum
# would report a diluted percentage. This merges DA lines per SF with
# max(hit) (union coverage), emits each SF once with its instrumentable line
# count (LF — identical across shards for the same commit) and LH recomputed
# from the merged hits, so check_coverage_gate.sh and the Codecov upload see
# true totals.
#
# usage: merge_shard_lcov.sh OUTPUT INPUT.tracefile [INPUT...]
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 OUTPUT INPUT.tracefile [INPUT...]" >&2
  exit 2
fi

out="$1"
shift

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# DA lines keyed by file: "SF<tab>line<tab>hit".
awk '
  /^SF:/ { sf = substr($0, 4) }
  /^DA:/ {
    split(substr($0, 4), da, ",")
    print sf "\t" da[1] "\t" da[2] + 0
  }
' "$@" | LC_ALL=C sort -t$'\t' -k1,1 -k2,2n -k3,3nr \
  | awk -F'\t' '!seen[$1 FS $2]++' > "$tmp/da.tsv"

# LF is per-file instrumentation, identical across shards: take it once.
awk '
  /^SF:/ { sf = substr($0, 4) }
  /^LF:/ { print sf "\t" substr($0, 4) }
' "$@" | LC_ALL=C sort -u > "$tmp/lf.tsv"

awk -F'\t' '
  NR == FNR { lf[$1] = $2; order[++n] = $1; next }
  { hits[$1] = hits[$1] $2 ":" $3 "\n" }
  END {
    for (i = 1; i <= n; i++) {
      f = order[i]
      if (!(f in hits)) continue
      printf "SF:%s\n", f
      m = split(hits[f], lines, "\n")
      lh = 0
      for (j = 1; j <= m; j++) {
        if (lines[j] == "") continue
        split(lines[j], p, ":")
        printf "DA:%s,%s\n", p[1], p[2]
        if (p[2] + 0 > 0) lh++
      }
      printf "LF:%d\nLH:%d\nend_of_record\n", lf[f], lh
    }
  }
' "$tmp/lf.tsv" "$tmp/da.tsv" > "$out"
