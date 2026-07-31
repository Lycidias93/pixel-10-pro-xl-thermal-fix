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
grep -Fq 'version=2.0.0-alpha.3-dev.21' "$module_prop"
grep -Fq 'versionCode=1016232' "$module_prop"

printf '%s\n' 'PASS dev21_first_or_changed_boot_requires_full_verification'
printf '%s\n' 'PASS dev21_unchanged_boot_uses_fast_path_without_pending_boot'
printf '%s\n' 'PASS dev21_config_change_rearms_full_bootguard'
printf '%s\n' 'PASS dev21_fast_badges_avoid_full_compat_scan'
printf '%s\n' 'PASS dev21_magisk_resetprop_writer_is_evidenced'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV21_LIGHT_BOOT_PASS'
