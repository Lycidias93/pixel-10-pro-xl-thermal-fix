#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_a="$(mktemp --suffix=.zip)"
out_b="$(mktemp --suffix=.zip)"
log_a="$(mktemp)"
log_b="$(mktemp)"
cleanup() {
  rm -f "$out_a" "$out_b" "$log_a" "$log_b"
}
trap cleanup EXIT HUP INT TERM

"$repo_root/dev_tools/build-release-module.sh" "$out_a" > "$log_a"
"$repo_root/dev_tools/build-release-module.sh" "$out_b" > "$log_b"
"$repo_root/dev_tools/verify-release-module.sh" "$out_a"
"$repo_root/dev_tools/verify-release-module.sh" "$out_b"

cmp -s "$out_a" "$out_b" || {
  printf '%s\n' 'FAIL repeated_release_builds_not_binary_identical'
  exit 1
}

grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_a"
grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_b"

printf 'reproducible_sha256=%s\n' "$(sha256sum "$out_a" | awk '{print $1}')"
printf '%s\n' 'PASS release_builder_and_verifier_contract'
printf '%s\n' 'PASS repeated_release_builds_binary_identical'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_PACKAGE_EXCLUSION_TEST_PASS'
