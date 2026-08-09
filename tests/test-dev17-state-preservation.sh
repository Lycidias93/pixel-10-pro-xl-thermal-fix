#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
auto="$root/tools/core/auto-profile-switch.sh"
module_prop="$root/module.prop"

fail() { printf 'FAIL %s\n' "$*"; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

bash -n "$auto" || fail auto_profile_switch_syntax
pass dev17_shell_syntax

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mod="$tmp/mod"
data="$tmp/data"
state="$mod/install-state.txt"
mkdir -p "$mod/tools/core" "$mod/system/vendor/etc" "$mod/guard" "$data"
cp "$auto" "$mod/tools/core/auto-profile-switch.sh"
cp "$module_prop" "$mod/module.prop"

printf '%s\n' \
  'thermal_supported_check(){ return 0; }' \
  'thermal_build_evidence_state(){ printf "%s\\n" exact_verified; }' \
  > "$mod/tools/core/supported-build.sh"
chmod +x "$mod/tools/core/supported-build.sh"

printf '%s\n' \
  'THERMAL_DISABLED=0' \
  'THERMAL_POLLING_MODE=mod' \
  'THERMAL_POLLING_EFFECTIVE=mod' \
  'THERMAL_OUTDOOR_PROFILE=outdoor-extended' \
  'LAST_THERMAL_OUTDOOR_PROFILE=outdoor-extended' \
  'LAST_THERMAL_POLLING_MODE=mod' \
  'THERMAL_SETTINGS_MODE=fresh' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' \
  'ZRAM_EH_RISK_ACK=none' \
  'DEBUG_MODE=1' \
  'LAST_DEBUG_MODE=verbose' \
  'PTUNE_OVERRIDE_MENU=off' \
  'LAST_PTUNE_OVERRIDE=0' \
  > "$data/config.env"
printf '%s\n' not_present > "$mod/guard/ptune_risk_ack"

for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  printf '%s\n' validated > "$mod/system/vendor/etc/$file"
done
printf '%s\n' zram > "$mod/system/vendor/etc/fstab.zram.100p"

printf '%s\n' \
  'install_state_schema=pixel-thermal-install-state-v2' \
  'install_state_owner=install-finalize-preserved-by-auto-profile-switch' \
  'module_id=pixel-10-pro-xl-thermal-fix' \
  'module_version=2.0.0-alpha.3-dev.16' \
  'module_version_code=1016227' \
  'device=mustang' \
  'android=17' \
  'android_sdk=37' \
  'build_id=CP2A.260705.006' \
  'incremental=15641320' \
  'fingerprint=google/mustang/mustang:17/CP2A.260705.006/15641320:user/release-keys' \
  'profile=dynamic/mustang/android17' \
  'profile_state=dynamic_stock_validated_exact_verified' \
  'validation_report_sha256=preserve-me' \
  'ptune_risk_ack=not_present' \
  'zram_risk_ack=explicit_user_enable' \
  'zram_eh_risk_ack=none' \
  'debug_mode=1' \
  'last_debug_mode=verbose' \
  'thermal_outdoor_profile=outdoor-extended' \
  'thermal_polling_effective=mod' \
  'zram_fstab_materialized=yes' \
  'zram_enabled=1' \
  > "$state"

run_auto() {
  ID=pixel-10-pro-xl-thermal-fix \
  MODDIR="$mod" \
  THERMAL_DATA_ROOT="$data" \
  THERMAL_INSTALL_STATE_FILE="$state" \
  THERMAL_DEVICE=mustang \
  THERMAL_ANDROID=17 \
  THERMAL_SDK=37 \
  THERMAL_BUILD_ID=CP2A.260705.006 \
  THERMAL_INCREMENTAL=15641320 \
  THERMAL_FINGERPRINT='google/mustang/mustang:17/CP2A.260705.006/15641320:user/release-keys' \
  sh "$auto"
}

run_auto

grep -Fxq 'profile_state=dynamic_stock_validated_exact_verified' "$state"
grep -Fxq 'profile_state_contract=dynamic_stock_derived_validation_v2' "$state"
grep -Fxq 'runtime_profile_state=dynamic_local_validated' "$state"
grep -Fxq 'runtime_profile_state_contract=dynamic_local_validation_v1' "$state"
grep -Fxq 'thermal_outdoor_profile=outdoor-extended' "$state"
grep -Fxq 'thermal_settings_mode=fresh' "$state"
grep -Fxq 'zram_risk_ack=explicit_user_enable' "$state"
grep -Fxq 'zram_eh_risk_ack=none' "$state"
grep -Fxq 'ptune_risk_ack=not_present' "$state"
grep -Fxq 'debug_mode=1' "$state"
grep -Fxq 'last_debug_mode=verbose' "$state"
grep -Fxq 'validation_report_sha256=preserve-me' "$state"
pass install_evidence_preserved_and_runtime_state_merged

for key in profile_state profile_state_contract runtime_profile_state runtime_profile_state_contract thermal_outdoor_profile zram_risk_ack zram_eh_risk_ack debug_mode last_debug_mode; do
  [[ "$(grep -c "^${key}=" "$state")" -eq 1 ]] || fail "duplicate_key=$key"
done
pass state_keys_unique

first_sha="$(sha256sum "$state" | awk '{print $1}')"
run_auto
second_sha="$(sha256sum "$state" | awk '{print $1}')"
[[ "$first_sha" = "$second_sha" ]] || fail second_boot_rewrote_stable_state
grep -Fq 'state_refresh=0' "$mod/guard/auto-profile-switch.log"
pass second_boot_is_idempotent

module_version="$(sed -n 's/^version=//p' "$module_prop" | head -n 1)"
module_version_code="$(sed -n 's/^versionCode=//p' "$module_prop" | head -n 1)"
[[ "$(grep -c '^version=' "$module_prop")" -eq 1 ]] || fail module_version_count
[[ "$(grep -c '^versionCode=' "$module_prop")" -eq 1 ]] || fail module_version_code_count
[[ "$module_version" =~ ^[0-9]+[.][0-9]+[.][0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || fail module_version_format
[[ "$module_version_code" =~ ^[0-9]+$ ]] || fail module_version_code_format
pass stable_metadata_preserves_dev17_contract

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV17_STATE_PRESERVATION_PASS'
