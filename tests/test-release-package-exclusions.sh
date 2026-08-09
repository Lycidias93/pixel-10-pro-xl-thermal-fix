#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_a="$(mktemp --suffix=.zip)"
out_b="$(mktemp --suffix=.zip)"
log_a="$(mktemp)"
log_b="$(mktemp)"
legacy_collector="$repo_root/tools/debug/collect-outdoor-boot-failure-online.sh"
prerelease_collector="$repo_root/tools/debug/collect-thermal-prerelease-online.sh"
prerelease_launcher="$repo_root/tools/debug/collect-thermal-prerelease-online-menu.sh"
packaged_entrypoint="$repo_root/tools/bootguard/collect-debug.sh"
packaged_collector="$repo_root/tools/bootguard/collect-debug-v3.sh"
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
grep -Fq 'SCHEMA="pixel-thermal-online-debug-v4"' "$prerelease_collector"
grep -Fq 'MODE="${1:-support}"' "$prerelease_collector"
grep -Fq 'support|runtime)' "$prerelease_collector"
grep -Fq 'privacy=support mode excludes logcat dmesg tombstone contents account lists and app lists' "$prerelease_collector"
grep -Fq 'decision_gate=compare_layout_delay_keys_targets_and_runtime_before_device_allowlist_or_module_family_change' "$prerelease_collector"
grep -Fq 'support_enabled_by_this_run=no' "$prerelease_collector"
grep -Fq 'magisk/mirror/vendor/etc' "$prerelease_collector"
grep -Fq '/data/adb/ksud.log' "$prerelease_collector"
grep -Fq '/sys/fs/pstore' "$prerelease_collector"
grep -Fq 'RESULT: PIXEL_THERMAL_ONLINE_DEBUG_DONE outcome=success workflow_exit_code=0' "$prerelease_collector"

sh -n "$prerelease_launcher"
grep -Fq 'ENGINE_COMMIT="1764b4324f1e1647bdc5242e6097ccb8b8aa8a64"' "$prerelease_launcher"
grep -Fq 'ENGINE_BLOB="6553a7fa78afc3c6a93e2df8ff6ff8b1e08210b0"' "$prerelease_launcher"
grep -Fq 'collect-thermal-online-v5.sh' "$prerelease_launcher"
grep -Fq "choose 'Collection mode' 1 support runtime" "$prerelease_launcher"
grep -Fq 'Support mode: privacy-reduced platform/layout inventory; no logcat or dmesg.' "$prerelease_launcher"
grep -Fq 'Runtime mode: adds filtered system/root logs for boot or runtime failures.' "$prerelease_launcher"
grep -Fq 'collector_integrity_mismatch' "$prerelease_launcher"
grep -Fq 'su -c' "$prerelease_launcher"
if grep -Fq '/dev/tty' "$prerelease_launcher"; then
  printf '%s\n' 'FAIL prerelease_launcher_forces_dev_tty'
  exit 1
fi

sh -n "$packaged_entrypoint"
sh -n "$packaged_collector"
grep -Fq 'collect-debug-v3.sh' "$packaged_entrypoint"
grep -Fq 'SCHEMA="pixel-thermal-packaged-debug-v3"' "$packaged_collector"
grep -Fq 'module-caller' "$packaged_collector"
grep -Fq 'module-active' "$packaged_collector"
grep -Fq 'module-staged' "$packaged_collector"
grep -Fq 'tools/core/patch-thermal-fix5-core.sh' "$packaged_collector"
grep -Fq 'pixel_thermal_install_*.txt' "$packaged_collector"
grep -Fq '/data/adb/ksud.log' "$packaged_collector"
grep -Fq 'logcat -L -b all' "$packaged_collector"
grep -Fq '/sys/fs/pstore' "$packaged_collector"
grep -Fq 'RESULT: PIXEL_THERMAL_PACKAGED_DEBUG_DONE outcome=success workflow_exit_code=0' "$packaged_collector"

sh -n "$install_debug"
grep -Fq 'package_sha256=' "$install_debug"
grep -Fq 'package_bytes=' "$install_debug"
grep -Fq 'battery_level=' "$install_debug"
grep -Fq 'root_impl=' "$install_debug"
grep -Fq 'mount_backend_hint=' "$install_debug"
grep -Fq 'profile_state=' "$install_debug"
grep -Fq 'build_evidence=' "$install_debug"
grep -Fq 'thermal_outdoor_profile=' "$install_debug"
grep -Fq '== validation summaries ==' "$install_debug"
grep -Fq 'PTUNE_GUARD_MODE=' "$install_debug"
grep -Fq '== install-state ==' "$install_debug"
grep -Fq '== recent thermal logcat ==' "$install_debug"
grep -Fq 'collect-debug-v3.sh' "$install_debug"
grep -Fq 'thermal_collect_debug_on_fail' "$install_debug"

sh -n "$repo_root/tools/zram/apply-zram-100p.sh"
grep -Fq 'setprop lmkd.reinit 1' "$repo_root/tools/zram/apply-zram-100p.sh" || grep -F '"$SETPROP_BIN" lmkd.reinit 1' "$repo_root/tools/zram/apply-zram-100p.sh"
grep -Fq 'ctl.restart lmkd' "$repo_root/tools/zram/apply-zram-100p.sh"

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
  tools/debug/collect-thermal-prerelease-online.sh \
  tools/debug/collect-thermal-prerelease-online-menu.sh; do
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
unzip -Z1 "$out_a" | grep -Fxq 'tools/bootguard/collect-debug.sh'
unzip -Z1 "$out_a" | grep -Fxq 'tools/bootguard/collect-debug-v3.sh'
unzip -p "$out_a" tools/bootguard/collect-debug.sh | grep -Fq 'collect-debug-v3.sh'
unzip -p "$out_a" tools/bootguard/collect-debug-v3.sh | grep -Fq 'pixel-thermal-packaged-debug-v3'
unzip -p "$out_a" tools/core/patch-thermal.sh | grep -Fq 'outdoor_runtime_policy_missing'
unzip -p "$out_a" tools/action-dashboard.sh | grep -Fq 'patch-thermal-validated.sh'
unzip -p "$out_a" tools/zram/apply-zram-100p.sh | grep -F 'ro.lmk.swap_free_low_percentage' >/dev/null
unzip -p "$out_a" tools/zram/apply-zram-100p.sh | grep -F 'lmkd.reinit' >/dev/null
unzip -p "$out_a" tools/zram/apply-zram-100p.sh | grep -F 'ctl.restart lmkd' >/dev/null

if unzip -p "$out_a" tools/core/patch-thermal.sh | grep -Fq '%.*f'; then
  printf '%s\n' 'FAIL android_awk_unsupported_dynamic_precision_shipped'
  exit 1
fi

grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_a"
grep -q 'RESULT: PIXEL_THERMAL_LEAN_PACKAGE_BUILD_PASS' "$log_b"

printf 'reproducible_sha256=%s\n' "$(sha256sum "$out_a" | awk '{print $1}')"
printf '%s\n' 'PASS online_outdoor_collector_syntax_and_contract'
printf '%s\n' 'PASS online_thermal_collector_v4_contract'
printf '%s\n' 'PASS online_thermal_launcher_v5_integrity_and_mode_contract'
printf '%s\n' 'PASS packaged_debug_collector_v3_contract'
printf '%s\n' 'PASS installer_debug_evidence_contract'
printf '%s\n' 'PASS online_collectors_repo_only'
printf '%s\n' 'PASS packaged_collector_shipped'
printf '%s\n' 'PASS runtime_policy_shipped_evidence_repo_only'
printf '%s\n' 'PASS lmkd_reload_consolidated_in_zram_script'
printf '%s\n' 'PASS android_awk_portable_patcher_shipped'
printf '%s\n' 'PASS release_builder_and_verifier_contract'
printf '%s\n' 'PASS repeated_release_builds_binary_identical'
printf '%s\n' 'RESULT: PIXEL_THERMAL_RELEASE_PACKAGE_EXCLUSION_TEST_PASS'
