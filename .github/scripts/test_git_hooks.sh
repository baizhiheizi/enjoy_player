#!/usr/bin/env bash
# Regression tests for the pre-commit secret scanner.
#
# Each case runs in a throwaway git repository with core.hooksPath pointed at
# the .githooks directory under test, so a broken rule is caught without
# touching this checkout's staged files.
#
# Usage: bash .github/scripts/test_git_hooks.sh

set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
hook_dir="$root/.githooks"
HEX64="$(printf '0123456789abcdef%.0s' 1 2 3 4)"
HEX32="$(printf '0123456789abcdef%.0s' 1 2)"

passed=0
failed=0

new_repo() {
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/git-hook-test.XXXXXX")"
  git -C "$dir" init -q
  git -C "$dir" config core.hooksPath "$hook_dir"
  git -C "$dir" config user.name "hook test"
  git -C "$dir" config user.email "hook-test@example.invalid"
  printf 'init\n' > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m init
  printf '%s' "$dir"
}

setup_akia() {
  # Split the sample so this test file itself never carries a credential-shaped
  # literal that the scanner would block when this file is committed.
  printf 'const key = "AKIA%s";\n' "1234567890ABCDEF" > src.dart
  git add -A
}

setup_aws_secret() {
  printf 'export AWS_SECRET_ACCESS_KEY="%s"\n' "$HEX64" > env.sh
  git add -A
}

setup_aws_access_key_id() {
  printf 'export AWS_ACCESS_KEY_ID="%s"\n' "$HEX32" > env.sh
  git add -A
}

setup_r2_endpoint() {
  printf 'const url = "https://account.r2.cloudflarestorage.com/%s/bucket";\n' "$HEX32" > config.dart
  git add -A
}

setup_r2_secret() {
  printf 'R2_SECRET_ACCESS_KEY=%s\n' "$HEX64" > env.sh
  git add -A
}

setup_forbidden_file() {
  mkdir -p .github/scripts
  printf 'export AWS_SECRET_ACCESS_KEY="placeholder"\n' > .github/scripts/publish_env.local.sh
  git add -A
}

setup_bare_hex() {
  printf 'const h = "%s";\n' "$HEX64" > notes.md
  git add -A
}

setup_test_fixture() {
  mkdir -p test
  printf "const h = '%s';\n" "$HEX64" > test/ids_test.dart
  git add -A
}

setup_sha256_digest() {
  printf 'image: alpine@sha256:%s\n' "$HEX64" > pins.yaml
  git add -A
}

setup_checksum() {
  printf 'const checksum = "%s"; // sha256 checksum of the pinned tarball\n' "$HEX64" > pins.sh
  git add -A
}

setup_lock_metadata() {
  printf '{"frontmatter_hash":"%s","body_hash":"%s"}\n' "$HEX64" "$HEX64" > workflow.lock.yml
  git add -A
}

setup_delete_hex() {
  mkdir -p src
  printf 'const h = "%s";\n' "$HEX64" > src/hash.dart
  git add -A
  git commit -q --no-verify -m "seed a digest"
  printf 'const h = "removed";\n' > src/hash.dart
  git add -A
}

setup_ordinary_source() {
  printf 'final greeting = "hello hooks";\n' > src.dart
  git add -A
}

setup_example_template() {
  mkdir -p .github/scripts
  printf 'export AWS_SECRET_ACCESS_KEY="%s"\n' "$HEX64" > .github/scripts/publish_env.example.sh
  git add -A
}

setup_lockfile() {
  printf 'sha256: %s\n' "$HEX64" > pubspec.lock
  git add -A
}

setup_test_credential() {
  mkdir -p test
  printf 'const key = "AKIA%s";\n' "1234567890ABCDEF" > test/keys_test.dart
  git add -A
}

setup_test_secret_assignment() {
  mkdir -p test
  printf 'export AWS_SECRET_ACCESS_KEY="%s"\n' "$HEX64" > test/env_test.dart
  git add -A
}

setup_digest_and_secret() {
  printf 'const pin = "sha256:%s"; const secret = "%s";\n' "$HEX64" "$HEX64" > pins.dart
  git add -A
}

setup_hash_and_secret() {
  printf '{"frontmatter_hash":"%s","secret":"%s"}\n' "$HEX64" "$HEX64" > workflow.lock.yml
  git add -A
}

setup_fixture_secret() {
  printf 'const fixtureSecret = "%s";\n' "$HEX64" > notes.md
  git add -A
}

setup_computed_hash() {
  printf '{"computedHash": "%s"}\n' "$HEX64" > notes.json
  git add -A
}

setup_path_key_digest() {
  printf '{".specify/scripts/bash/check.sh": "%s"}\n' "$HEX64" > notes.json
  git add -A
}

setup_skills_lock() {
  printf '{"skills":{"demo":{"computedHash": "%s"}}}\n' "$HEX64" > skills-lock.json
  git add -A
}

setup_digest_manifest() {
  mkdir -p .specify/integrations
  printf '{"files":{"common.sh": "%s"}}\n' "$HEX64" > .specify/integrations/demo.manifest.json
  git add -A
}

run_case() {
  local label="$1" expect="$2" setup_fn="$3"
  local dir out actual
  dir="$(new_repo)"
  ( cd "$dir" && "$setup_fn" )
  if out="$(cd "$dir" && git commit -q -m "case: $label" 2>&1)"; then
    actual="pass"
  else
    actual="block"
  fi
  if [[ "$actual" == "$expect" ]]; then
    printf '[ok]   %s\n' "$label"
    passed=$((passed + 1))
  else
    printf '[FAIL] %s (expected %s, got %s)\n' "$label" "$expect" "$actual"
    printf '%s\n' "$out" | sed 's/^/       /'
    failed=$((failed + 1))
  fi
  rm -rf "$dir"
}

run_case "blocks an AKIA access key id" block setup_akia
run_case "blocks an AWS_SECRET_ACCESS_KEY assignment" block setup_aws_secret
run_case "blocks an AWS_ACCESS_KEY_ID assignment" block setup_aws_access_key_id
run_case "blocks an R2 endpoint token" block setup_r2_endpoint
run_case "blocks an R2_SECRET_ACCESS_KEY assignment" block setup_r2_secret
run_case "blocks a forbidden local credential file" block setup_forbidden_file
run_case "blocks a bare 64-hex value outside a digest context" block setup_bare_hex
run_case "allows a 64-hex test fixture" pass setup_test_fixture
run_case "allows a sha256: image digest" pass setup_sha256_digest
run_case "allows a sha256 checksum line" pass setup_checksum
run_case "allows gh-aw lock metadata hashes" pass setup_lock_metadata
run_case "allows deleting a line that held a 64-hex digest" pass setup_delete_hex
run_case "allows ordinary Dart source" pass setup_ordinary_source
run_case "allows the example credential template" pass setup_example_template
run_case "allows a lockfile content hash" pass setup_lockfile
run_case "blocks an AKIA key id inside test/" block setup_test_credential
run_case "blocks an AWS_SECRET_ACCESS_KEY inside test/" block setup_test_secret_assignment
run_case "blocks a bare secret sharing a line with a sha256 digest" block setup_digest_and_secret
run_case "blocks a bare secret sharing a line with a gh-aw hash" block setup_hash_and_secret
run_case "blocks a fixture-named variable holding a bare secret" block setup_fixture_secret
run_case "allows a computedHash JSON value" pass setup_computed_hash
run_case "allows a path-keyed JSON digest mapping" pass setup_path_key_digest
run_case "allows regenerated skills-lock.json hashes" pass setup_skills_lock
run_case "allows a regenerated integration manifest" pass setup_digest_manifest

run_pre_push_case() {
  local label="$1" changed_path="$2" expected_calls="$3"
  local dir base head out hook_status actual_calls
  dir="$(new_repo)"
  base="$(git -C "$dir" rev-parse HEAD)"
  mkdir -p "$dir/.github/scripts" "$dir/bin" "$dir/$(dirname "$changed_path")"
  : > "$dir/calls.log"
  printf '#!/usr/bin/env bash\nprintf "format\\n" >> "$CALLS"\n' \
    > "$dir/.github/scripts/check_dart_format.sh"
  printf '#!/usr/bin/env bash\nprintf "codegen\\n" >> "$CALLS"\n' \
    > "$dir/.github/scripts/check_codegen_drift.sh"
  printf '#!/usr/bin/env bash\nprintf "flutter\\n" >> "$CALLS"\n' \
    > "$dir/bin/flutter"
  chmod +x "$dir/bin/flutter"
  printf 'change\n' > "$dir/$changed_path"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "change $changed_path"
  head="$(git -C "$dir" rev-parse HEAD)"
  if out="$(printf '%s %s %s %s\n' refs/heads/main "$head" refs/heads/main "$base" \
    | ( cd "$dir" && CALLS="$dir/calls.log" PATH="$dir/bin:$PATH" \
        bash "$hook_dir/pre-push" ) 2>&1)"; then
    hook_status=0
  else
    hook_status=1
  fi
  actual_calls="$(sort "$dir/calls.log" | tr '\n' ',' | sed 's/,$//')"
  if [[ "$hook_status" -eq 0 && "$actual_calls" == "$expected_calls" ]]; then
    printf '[ok]   %s\n' "$label"
    passed=$((passed + 1))
  else
    printf '[FAIL] %s (expected calls [%s], got [%s], status %s)\n' \
      "$label" "$expected_calls" "$actual_calls" "$hook_status"
    printf '%s\n' "$out" | sed 's/^/       /'
    failed=$((failed + 1))
  fi
  rm -rf "$dir"
}

run_pre_push_case "pre-push runs only the format gate for Dart changes" \
  "lib/foo.dart" "format"
run_pre_push_case "pre-push skips all Dart gates for docs-only changes" \
  "docs/note.md" ""

check_ci_pattern() {
  local label="ci changes PATTERN matches hook-only and Dart paths"
  local pattern missing=0 detail=""
  pattern="$(sed -n "s/^[[:space:]]*PATTERN: '\(.*\)'[[:space:]]*$/\1/p" \
    "$root/.github/workflows/ci.yml" | head -1)"
  if [[ -z "$pattern" ]]; then
    printf '[FAIL] %s (could not read PATTERN from ci.yml)\n' "$label"
    failed=$((failed + 1))
    return
  fi
  for p in ".githooks/pre-commit" ".githooks/pre-push" "lib/foo.dart"; do
    if ! printf '%s\n' "$p" | grep -Eq "$pattern"; then
      missing=1
      detail="${detail} no-match:${p}"
    fi
  done
  if printf '%s\n' "docs/note.md" | grep -Eq "$pattern"; then
    missing=1
    detail="${detail} unexpected-match:docs/note.md"
  fi
  if [[ "$missing" -eq 0 ]]; then
    printf '[ok]   %s\n' "$label"
    passed=$((passed + 1))
  else
    printf '[FAIL] %s (%s)\n' "$label" "$detail"
    failed=$((failed + 1))
  fi
}

check_ci_pattern

printf '\n%s passed, %s failed\n' "$passed" "$failed"
if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
