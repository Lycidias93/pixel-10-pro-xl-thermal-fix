#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
transition="$repo_root/tools/core/platform-transition.sh"
auto_switch="$repo_root/tools/core/auto-profile-switch.sh"
bootguard="$repo_root/tools/bootguard/bootguard-lib.sh"
post_fs="$repo_root/post-fs-data.sh"
service="$repo_root/service.sh"
compat="$repo_root/tools/bootguard/compat-check.sh"
status_lib="$repo_root/tools/debug/status-lib.sh"

for file in "$transition" "$auto_switch" "$bootguard" "$post_fs" "$service" "$compat" "$status_lib"; do
  bash -n "$file"
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mod="$tmp/module"
data="$tmp/data"
cfg="$data/config.env"
guard="$mod/guard"
mkdir -p "$mod/system/vendor/etc" "$guard" "$data/originals/mustang/BUILD.OLD/vendor/etc"
printf '%s\n' 'version=2.0.0-alpha.3-dev.11' > "$mod/module.prop"
printf '%s\n' \
  'device=mustang' \
  'android=17' \
  'build_id=BUILD.NEW' \
  'incremental=100' \
  'fingerprint=google/mustang/old' \
  'profile=dynamic/mustang/android17' \
  'profile_state=dynamic_local_validated' > "$mod/install-state.txt"
printf '%s\n' 'THERMAL_DISABLED=0' > "$cfg"
for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  printf '%s\n' old-overlay > "$mod/system/vendor/etc/$file"
done
printf '%s\n' keep > "$mod/system/vendor/etc/unrelated.conf"
mkdir -p "$data/originals/mustang/BUILD.NEW_/vendor/etc"
printf '%s\n' current-cache > "$data/originals/mustang/BUILD.NEW_/vendor/etc/cache"
printf '%s\n' old-cache > "$data/originals/mustang/BUILD.OLD/vendor/etc/cache"
mkdir -p "$data/validation"
printf '%s\n' stale > "$data/validation/state.env"

MODDIR="$mod" THERMAL_DATA_ROOT="$data" CONFIG_FILE="$cfg" \
THERMAL_DEVICE=mustang THERMAL_ANDROID=17 THERMAL_BUILD_ID=BUILD.NEW \
THERMAL_INCREMENTAL=101 THERMAL_FINGERPRINT=google/mustang/new \
sh "$transition" prepare > "$tmp/transition.out"

grep -Fq 'PLATFORM_TRANSITION_REASON=incremental_changed' "$tmp/transition.out"
grep -Fq 'transition_pending=yes' "$guard/platform-transition.env"
grep -Fq 'phase=prepared' "$guard/platform-transition.env"
grep -Fq 'THERMAL_DISABLED=1' "$cfg"
[[ -f "$mod/system/vendor/etc/unrelated.conf" ]]
[[ ! -e "$mod/system/vendor/etc/thermal_info_config.json" ]]
[[ ! -e "$data/originals/mustang/BUILD.NEW_/vendor/etc/cache" ]]
[[ -e "$data/originals/mustang/BUILD.OLD/vendor/etc/cache" ]]
[[ ! -e "$data/validation" ]]

# An OTA transition gets a one-attempt threshold. The next boot disables before
# mounts if the prior current-build attempt never reached verified success.
printf '%s\n' 0 > "$guard/fail_count"
cp "$guard/platform-transition.env" "$guard/pending_boot"
if MODDIR="$mod" CONFIG_FILE="$cfg" sh "$bootguard" evaluate > "$tmp/evaluate.out" 2>&1; then
  printf '%s\n' 'FAIL ota_transition_pending_did_not_trip_one_attempt_threshold'
  exit 1
fi
[[ -e "$mod/disable" ]]
[[ -e "$mod/skip_mount" ]]
grep -Fq 'automatic_bootguard_fail_count_1' "$guard/disabled_reason"

rm -f "$mod/disable" "$mod/skip_mount" "$guard/disabled_reason"
printf '%s\n' 0 > "$guard/fail_count"
MODDIR="$mod" CONFIG_FILE="$cfg" sh "$bootguard" arm
[[ -e "$guard/pending_boot" ]]

fake_compat="$tmp/fake-compat.sh"
printf '%s\n' \
  '#!/system/bin/sh' \
  "printf '%s\\n' 'SAFE_TO_REBOOT=yes'" \
  "printf '%s\\n' 'THERMAL_EXPECTED=thermal_active_allowed'" \
  "printf '%s\\n' 'REASON=active_dynamic_overlay_verified'" > "$fake_compat"
chmod +x "$fake_compat"
MODDIR="$mod" CONFIG_FILE="$cfg" BOOTGUARD_COMPAT_HELPER="$fake_compat" \
BOOTGUARD_SKIP_THERMAL_SERVICE_CHECK=1 BOOTGUARD_SECOND_PROBE_DELAY_SECONDS=0 \
BOOTGUARD_BOOT_COMPLETED=1 THERMAL_DEVICE=mustang THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=BUILD.NEW THERMAL_INCREMENTAL=101 \
THERMAL_FINGERPRINT=google/mustang/new \
sh "$bootguard" success-verify > "$tmp/success.out"
grep -Fq 'BOOTGUARD_SUCCESS_VERIFY=pass' "$tmp/success.out"
[[ ! -e "$guard/pending_boot" ]]
[[ "$(cat "$guard/fail_count")" = 0 ]]
grep -Fq 'transition_pending=no' "$guard/platform-transition.env"
grep -Fq 'phase=runtime_verified' "$guard/platform-transition.env"

eval_line="$(grep -n 'sh "$BOOTGUARD" evaluate' "$post_fs" | head -n1 | cut -d: -f1)"
prepare_line="$(grep -n 'sh "$TRANSITION" prepare' "$post_fs" | head -n1 | cut -d: -f1)"
auto_line="$(grep -n 'sh "$AUTO_SWITCH"' "$post_fs" | head -n1 | cut -d: -f1)"
arm_line="$(grep -n 'sh "$BOOTGUARD" arm' "$post_fs" | head -n1 | cut -d: -f1)"
(( eval_line < prepare_line && prepare_line < auto_line && auto_line < arm_line ))

grep -Fq 'success-verify' "$service"
if grep -Eq 'bootguard-lib\.sh" success([[:space:]]|$)' "$service"; then
  printf '%s\n' 'FAIL service_clears_pending_without_runtime_verification'
  exit 1
fi

grep -Fq 'build_guard_mode=dynamic_local_validation' "$auto_switch"
grep -Fq 'unsupported_platform' "$auto_switch"
grep -Fq 'PLATFORM_SUPPORTED=' "$compat"
grep -Fq 'BUILD_EVIDENCE=' "$compat"
grep -Fq 'PLATFORM_SUPPORTED=' "$status_lib"
if grep -R -nE 'unsupported_exact_build|exact_device_android_build|EXACT_BUILD_SUPPORTED=' \
  "$auto_switch" "$compat" "$status_lib" "$post_fs"; then
  printf '%s\n' 'FAIL stale_exact_build_runtime_label_present'
  exit 1
fi

printf '%s\n' 'PASS same_build_incremental_change_detected'
printf '%s\n' 'PASS current_build_cache_invalidated_other_build_cache_preserved'
printf '%s\n' 'PASS only_controlled_module_overlays_quarantined'
printf '%s\n' 'PASS ota_transition_one_attempt_bootguard_threshold'
printf '%s\n' 'PASS bootguard_success_requires_verified_compat_and_thermalservice_contract'
printf '%s\n' 'PASS post_fs_order_evaluate_prepare_materialize_arm'
printf '%s\n' 'PASS stale_exact_build_runtime_labels_removed'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OTA_TRANSITION_BOOTGUARD_TEST_PASS'
