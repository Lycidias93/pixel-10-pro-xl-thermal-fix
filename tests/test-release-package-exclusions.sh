#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_a="$(mktemp --suffix=.zip)"
out_b="$(mktemp --suffix=.zip)"
log_a="$(mktemp)"
log_b="$(mktemp)"
collector="$repo_root/tools/debug/collect-outdoor-boot-failure-online.sh"
cleanup() {
  rm -f "$out_a" "$out_b" "$log_a" "$log_b"
}
trap cleanup EXIT HUP INT TERM

sh -n "$collector"
grep -Fq 'schema=pixel-thermal-outdoor-boot-debug-v2' "$collector"
grep -Fq 'logcat -L -b all' "$collector"
grep -Fq '/sys/fs/pstore' "$collector"
grep -Fq 'magisk/mirror/vendor/etc' "$collector"
grep -Fq 'persistent_original_cache' "$collector"
grep -Fq 'stock-source' "$collector"
grep -Fq 'module_install_mode_reported' "$collector"
grep -Fq 'RESULT: PIXEL_THERMAL_OUTDOOR_BOOT_DEBUG_DONE outcome=success workflow_exit_code=0' "$collector"

"$repo_root/dev_tools/build-release-module.sh" "$out_a" > "$log_a"
"$repo_root/dev_tools/build-release-module.sh" "$out_b" > "$log_b"
"$repo_root/dev_tools/verify-release-module.sh" "$out_a"
"$repo_root/dev_tools/verify-release-module.sh" "$out_b"

cmp -s "$out_a" "$out_b" || {
  printf '%s\n' 'FAIL repeated_release_builds_not_binary_identical'
  exit 1
}

if unzip -Z1 "$out_a" | grep -Fxq 'tools/debug/collect-outdoor-boot-failure-online.sh'; then
  printf '%s\n' 'FAIL online_debug_collector_shipped_in_flashable_zip'
  exit 1
fi

if unzip -Z1 "$out_a" | grep -Fxq 'tools/core/outdoor-runtime-evidence.tsv'; then
  printf '%s\n' 'FAIL outdoor_runtime_evidence_shipped_in_flashable_zip'
  exit 1
fi

grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_a"
grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_b"

printf 'reproducible_sha256=%s\n' "$(sha256sum "$out_a" | awk '{print $1}')"
printf '%s\n' 'PASS online_outdoor_collector_syntax_and_contract'
printf '%s\n' 'PASS online_outdoor_collector_repo_only'
printf '%s\n' 'PASS release_builder_and_verifier_contract'
printf '%s\n' 'PASS repeated_release_builds_binary_identical'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_PACKAGE_EXCLUSION_TEST_PASS'
