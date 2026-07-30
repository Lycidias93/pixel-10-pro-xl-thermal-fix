#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
control="$repo_root/tools/zram/emerald-hill-control.sh"
apply="$repo_root/tools/zram/apply-zram-100p.sh"
service="$repo_root/service.sh"
auto_switch="$repo_root/tools/core/auto-profile-switch.sh"
module_prop="$repo_root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/devfreq/eh_freq" "$tmp/devfreq/gpu_freq" "$tmp/state" "$tmp/data"

# Real mustang naming observed after reboot: /sys/class/devfreq/eh_freq.
printf '%s\n' 200000000 > "$tmp/devfreq/eh_freq/min_freq"
printf '%s\n' 1066000000 > "$tmp/devfreq/eh_freq/max_freq"
printf '%s\n' '200000000 400000000 800000000 1066000000' > "$tmp/devfreq/eh_freq/available_frequencies"

# Decoy proves the matcher is not broadened to arbitrary *_freq devfreq nodes.
printf '%s\n' 300000000 > "$tmp/devfreq/gpu_freq/min_freq"
printf '%s\n' 900000000 > "$tmp/devfreq/gpu_freq/max_freq"

config="$tmp/data/config.env"
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' \
  'LAST_ZRAM_100P=enabled' \
  'ZRAM_EMERALD_OC=1' \
  'ZRAM_EH_TARGET_FREQ=max' \
  'ZRAM_THP_MODE=stock' \
  'ZRAM_SWAPPINESS=100' > "$config"

bash -n "$control"
bash -n "$apply"
bash -n "$service"
bash -n "$auto_switch"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" \
sh "$control" apply > "$tmp/apply.log"

grep -Fq 'RESULT: ZRAM_EH_APPLY_DONE nodes=1 target=1066000000' "$tmp/apply.log"
[[ "$(cat "$tmp/devfreq/eh_freq/min_freq")" = 1066000000 ]]
[[ "$(cat "$tmp/devfreq/gpu_freq/min_freq")" = 300000000 ]]
grep -Fq $'eh_freq\t200000000\t1066000000\t1066000000' "$tmp/state/baseline.tsv"
if grep -Fq 'gpu_freq' "$tmp/state/baseline.tsv"; then
  printf '%s\n' 'FAIL dev13_eh_matcher_admitted_decoy'
  exit 1
fi

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" \
sh "$control" restore > "$tmp/restore.log"
[[ "$(cat "$tmp/devfreq/eh_freq/min_freq")" = 200000000 ]]

grep -Fq 'boot_verified' "$apply"
grep -Fq 'boot_verified' "$service"
grep -Fq 'mmd_restart=skipped mode=$MODE' "$apply"
grep -Fq 'deferred_to_service_post_bootguard' "$apply"
grep -Fq 'SERVICE_ZRAM_POST_BOOT result=properties_reapplied_no_mmd_restart' "$service"
grep -Fq 'ro.lmk.swap_free_low_percentage 1' "$apply"
grep -Fq 'ZRAM_LMK_SWAP_LOW result=readback_unavailable_nonfatal' "$apply"

success_line="$(grep -n -m1 'success-verify' "$service" | cut -d: -f1)"
late_line="$(grep -n -m1 'boot_verified >>' "$service" | cut -d: -f1)"
[[ "$late_line" -gt "$success_line" ]]

for field in \
  'profile_state_contract=dynamic_local_validation_v1' \
  'thermal_polling_effective=$state_polling' \
  'thermal_outdoor_profile=$state_outdoor' \
  'zram_fstab_materialized=$state_zram_materialized' \
  'runtime_selection_source=config.env'; do
  grep -Fq "$field" "$auto_switch"
done

grep -Fq 'AUTO_SWITCH_STATE_REFRESH reason=runtime_state_contract_drift' "$auto_switch"
grep -Fq 'state_refresh=$state_refresh' "$auto_switch"
grep -Fq 'getstate module_version' "$auto_switch"
grep -Fq 'getstate zram_fstab_materialized' "$auto_switch"

if grep -Fq 'dynamic_stock_validated_exact_verified' "$auto_switch"; then
  printf '%s\n' 'FAIL stale_exact_profile_state_reintroduced'
  exit 1
fi
if grep -Fq 'EXACT_BUILD_SUPPORTED' "$auto_switch"; then
  printf '%s\n' 'FAIL stale_exact_build_contract_reintroduced'
  exit 1
fi
if grep -Fq 'while :; do' "$service"; then
  printf '%s\n' 'FAIL unbounded_eh_watcher_present'
  exit 1
fi

grep -Fq 'version=2.0.0-alpha.3-dev.13' "$module_prop"
grep -Fq 'versionCode=1016224' "$module_prop"

printf '%s\n' 'PASS dev13_real_eh_freq_match_and_decoy_rejection'
printf '%s\n' 'PASS dev13_post_bootguard_property_reapply_without_mmd_restart'
printf '%s\n' 'PASS dev13_post_ota_state_observability'
printf '%s\n' 'PASS dev13_current_profile_state_refresh_is_conditional'
printf '%s\n' 'PASS dev13_no_stale_exact_build_contract'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV13_POSTBOOT_RUNTIME_TEST_PASS'
