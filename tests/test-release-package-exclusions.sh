#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_a="$(mktemp --suffix=.zip)"
out_b="$(mktemp --suffix=.zip)"
log_a="$(mktemp)"
log_b="$(mktemp)"
legacy_collector="$repo_root/tools/debug/collect-outdoor-boot-failure-online.sh"
prerelease_collector="$repo_root/tools/debug/collect-thermal-prerelease-online.sh"
install_debug="$repo_root/tools/debug/install-debug.sh"
cleanup() {
  rm -f "$out_a" "$out_b" "$log_a" "$log_b"
}
trap cleanup EXIT HUP INT TERM

sh -n "$legacy_collector"
grep -Fq 'schema=pixel-thermal-outdoor-boot-debug-v2' "$legacy_collector"
grep -Fq 'logcat -L -b all' "$legacy_collector"
grep -Fq '/sys/fs/pstore' "$legacy_collector"
grep -Fq 'magisk/mirror/vendor/etc' "$legacy_collector"
grep -Fq 'persistent_original_cache' "$legacy_collector"
grep -Fq 'stock-source' "$legacy_collector"
grep -Fq 'module_install_mode_reported' "$legacy_collector"
grep -Fq 'RESULT: PIXEL_THERMAL_OUTDOOR_BOOT_DEBUG_DONE outcome=success workflow_exit_code=0' "$legacy_collector"

sh -n "$prerelease_collector"
grep -Fq 'SCHEMA="pixel-thermal-prerelease-debug-v3"' "$prerelease_collector"
grep -Fq 'EXPECTED_VERSION="2.0.0-alpha.3-dev.6"' "$prerelease_collector"
grep -Fq 'EXPECTED_VERSION_CODE="1016217"' "$prerelease_collector"
grep -Fq 'EXPECTED_ASSET_SHA256="b6c7d14edc49ddded30094b984b66c0dac40d436360461bb55e5fd630148a0b9"' "$prerelease_collector"
grep -Fq 'action-switch' "$prerelease_collector"
grep -Fq 'previous_profile_reported' "$prerelease_collector"
grep -Fq 'tools/core/patch-thermal-fix5-core.sh' "$prerelease_collector"
grep -Fq 'pixel_thermal_install_*.txt' "$prerelease_collector"
grep -Fq '/data/adb/ksud.log' "$prerelease_collector"
grep -Fq 'logcat -L -b all' "$prerelease_collector"
grep -Fq 'RESULT: PIXEL_THERMAL_PRERELEASE_DEBUG_DONE outcome=success workflow_exit_code=0' "$prerelease_collector"

sh -n "$install_debug"
grep -Fq 'package_sha256=' "$install_debug"
grep -Fq 'package_bytes=' "$install_debug"
grep -Fq 'battery_level=' "$install_debug"
grep -Fq 'root_impl=' "$install_debug"
grep -Fq 'mount_backend_hint=' "$install_debug"
grep -Fq 'profile_state=' "$install_debug"
grep -Fq 'PTUNE_GUARD_MODE=' "$install_debug"
grep -Fq '== install-state ==' "$install_debug"
grep -Fq '== recent thermal logcat ==' "$install_debug"
grep -Fq 'thermal_collect_debug_on_fail' "$install_debug"

bash "$repo_root/tests/test-outdoor-runtime-evidence.sh"

"$repo_root/dev_tools/build-release-module.sh" "$out_a" > "$log_a"
"$repo_root/dev_tools/build-release-module.sh" "$out_b" > "$log_b"
"$repo_root/dev_tools/verify-release-module.sh" "$out_a"
"$repo_root/dev_tools/verify-release-module.sh" "$out_b"

cmp -s "$out_a" "$out_b" || {
  printf '%s\n' 'FAIL repeated_release_builds_not_binary_identical'
  exit 1
}

for path in \
  tools/debug/collect-outdoor-boot-failure-online.sh \
  tools/debug/collect-thermal-prerelease-online.sh; do
  if unzip -Z1 "$out_a" | grep -Fxq "$path"; then
    printf 'FAIL online_debug_collector_shipped_in_flashable_zip path=%s\n' "$path"
    exit 1
  fi
done

if unzip -Z1 "$out_a" | grep -Fxq 'tools/core/outdoor-runtime-evidence.tsv'; then
  printf '%s\n' 'FAIL outdoor_runtime_evidence_shipped_in_flashable_zip'
  exit 1
fi

unzip -Z1 "$out_a" | grep -Fxq 'tools/core/outdoor-runtime-policy.sh'
unzip -Z1 "$out_a" | grep -Fxq 'tools/debug/install-debug.sh'
unzip -p "$out_a" tools/core/patch-thermal.sh | grep -Fq 'outdoor_runtime_policy_missing'
unzip -p "$out_a" tools/action-dashboard.sh | grep -Fq 'patch-thermal-validated.sh'

if unzip -p "$out_a" tools/core/patch-thermal.sh | grep -Fq '%.*f'; then
  printf '%s\n' 'FAIL android_awk_unsupported_dynamic_precision_shipped'
  exit 1
fi

grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_a"
grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_b"

printf 'reproducible_sha256=%s\n' "$(sha256sum "$out_a" | awk '{print $1}')"
printf '%s\n' 'PASS online_outdoor_collector_syntax_and_contract'
printf '%s\n' 'PASS online_prerelease_collector_syntax_and_contract'
printf '%s\n' 'PASS installer_debug_evidence_contract'
printf '%s\n' 'PASS online_collectors_repo_only'
printf '%s\n' 'PASS runtime_policy_shipped_evidence_repo_only'
printf '%s\n' 'PASS android_awk_portable_patcher_shipped'
printf '%s\n' 'PASS release_builder_and_verifier_contract'
printf '%s\n' 'PASS repeated_release_builds_binary_identical'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_PACKAGE_EXCLUSION_TEST_PASS'
