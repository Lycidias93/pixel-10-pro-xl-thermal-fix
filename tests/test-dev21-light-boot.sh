#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
bootguard="$root/tools/bootguard/bootguard-lib.sh"
service="$root/service.sh"
post_fs="$root/post-fs-data.sh"
apply="$root/tools/zram/apply-zram-100p.sh"
module_prop="$root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mod="$tmp/mod"
state="$tmp/state"
mkdir -p "$mod/guard" "$mod/system/vendor/etc" "$state"
cp "$module_prop" "$mod/module.prop"
printf '%s\n' 'THERMAL_POLLING_MODE=mod' 'THERMAL_OUTDOOR_PROFILE=stock' 'THERMAL_DISABLED=0' > "$state/config.env"
printf '%s\n' '{}' > "$mod/validation_report.json"
printf '%s\n' x > "$mod/guard/patch-manifest.tsv"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config.json"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config_charge.json"
printf '%s\n' '{}' > "$mod/system/vendor/etc/thermal_info_config_throttling.json"

MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == full ]]
[[ -e "$mod/guard/pending_boot" ]]
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" success
[[ -s "$mod/guard/last_good.env" ]]
grep -Eq '^state_signature=[0-9a-f]{64}$' "$mod/guard/last_good.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == fast ]]
[[ ! -e "$mod/guard/pending_boot" ]]
printf '%s\n' 'transition_pending=yes' 'phase=prepared' 'reason=test_transition' > "$mod/guard/platform-transition.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == full ]]
[[ "$(sed -n 's/^reason=//p' "$mod/guard/verification-mode.env")" == platform_transition_pending ]]
rm -f "$mod/guard/platform-transition.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" success
printf '%s\n' 'THERMAL_POLLING_MODE=stock' 'THERMAL_OUTDOOR_PROFILE=stock' 'THERMAL_DISABLED=0' > "$state/config.env"
MODDIR="$mod" CONFIG_FILE="$state/config.env" GUARD_DIR="$mod/guard" sh "$bootguard" arm-if-needed
[[ "$(sed -n 's/^mode=//p' "$mod/guard/verification-mode.env")" == full ]]
[[ -e "$mod/guard/pending_boot" ]]

bash -n "$bootguard"
bash -n "$service"
bash -n "$post_fs"
bash -n "$apply"
grep -Fq 'arm-if-needed' "$post_fs"
grep -Fq 'BOOTGUARD_RUNTIME_VERIFICATION=fast_trusted_unchanged_state' "$service"
grep -Fq 'update_manager_badges_fast' "$service"
grep -Fq 'update_manager_badges_full' "$service"
grep -Fq 'LMKD_SYSTEM_RESETPROP_BIN' "$apply"
grep -Fq 'property_writer=magisk_resetprop' "$root/tests/test-dev19-lmkd-early-test.sh"
module_version="$(sed -n 's/^version=//p' "$module_prop" | head -n 1)"
module_version_code="$(sed -n 's/^versionCode=//p' "$module_prop" | head -n 1)"
[[ "$(grep -c '^version=' "$module_prop")" -eq 1 ]]
[[ "$(grep -c '^versionCode=' "$module_prop")" -eq 1 ]]
[[ "$module_version" =~ ^[0-9]+[.][0-9]+[.][0-9]+([.-][0-9A-Za-z.-]+)?$ ]]
[[ "$module_version_code" =~ ^[0-9]+$ ]]

printf '%s\n' 'PASS stable_first_or_changed_boot_requires_full_verification'
printf '%s\n' 'PASS stable_unchanged_boot_uses_fast_path_without_pending_boot'
printf '%s\n' 'PASS stable_platform_transition_forces_full_verification'
printf '%s\n' 'PASS stable_config_change_rearms_full_bootguard'
printf '%s\n' 'PASS stable_fast_badges_avoid_full_compat_scan'
printf '%s\n' 'PASS stable_magisk_resetprop_writer_is_evidenced'
printf 'PASS module_metadata_contract version=%s versionCode=%s\n' "$module_version" "$module_version_code"
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV21_LIGHT_BOOT_PASS'
