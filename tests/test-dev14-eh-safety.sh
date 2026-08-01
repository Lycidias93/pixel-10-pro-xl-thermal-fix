#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
control="$repo_root/tools/zram/emerald-hill-control.sh"
apply="$repo_root/tools/zram/apply-zram-100p.sh"
normalize="$repo_root/tools/zram/config-normalize.sh"
service="$repo_root/service.sh"
install_menu="$repo_root/tools/menu/install-options-menu.sh"
action_dashboard="$repo_root/tools/action-dashboard.sh"
install_finalize="$repo_root/tools/install-finalize.sh"
module_prop="$repo_root/module.prop"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/physical/eh-device" "$tmp/class" "$tmp/platform/soc/devfreq" "$tmp/state" "$tmp/data"

printf '%s\n' 200000000 > "$tmp/physical/eh-device/min_freq"
printf '%s\n' 1066000000 > "$tmp/physical/eh-device/max_freq"
printf '%s\n' '200000000 400000000 800000000 1066000000' > "$tmp/physical/eh-device/available_frequencies"
ln -s ../physical/eh-device "$tmp/class/eh_freq"
ln -s ../../../physical/eh-device "$tmp/platform/soc/devfreq/eh_freq"

config="$tmp/data/config.env"
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' \
  'ZRAM_EH_RISK_ACK=explicit_user_enable_max_lock' \
  'LAST_ZRAM_100P=enabled_max_lock' \
  'ZRAM_EMERALD_OC=1' \
  'ZRAM_EH_TARGET_FREQ=max' \
  'ZRAM_THP_MODE=stock' \
  'ZRAM_SWAPPINESS=100' > "$config"

for file in "$control" "$apply" "$normalize" "$service" "$install_menu" "$action_dashboard" "$install_finalize"; do
  bash -n "$file"
done

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
sh "$control" apply > "$tmp/apply.log"

grep -Fq 'RESULT: ZRAM_EH_APPLY_DONE nodes=1 aliases_skipped=1 target=1066000000' "$tmp/apply.log"
[[ "$(cat "$tmp/physical/eh-device/min_freq")" = 1066000000 ]]
[[ "$(wc -l < "$tmp/state/baseline.tsv" | tr -d ' ')" = 2 ]]
grep -Fq 'schema=pixel-zram-eh-status-v2' "$tmp/state/status.env"
grep -Fq 'aliases_skipped=1' "$tmp/state/status.env"
grep -Fq 'apply_mode=one_shot_post_bootguard' "$tmp/state/status.env"

# Simulate the unsafe duplicate Dev.13 baseline: first row has the true 200 MHz
# original, while the alias row observed 1066 MHz after the first write.
printf '%s\n' \
  $'path\toriginal_min\tobserved_max\ttarget' \
  "$tmp/class/eh_freq"$'\t200000000\t1066000000\t1066000000' \
  "$tmp/platform/soc/devfreq/eh_freq"$'\t1066000000\t1066000000\t1066000000' \
  > "$tmp/state/baseline.tsv"
printf '%s\n' 1066000000 > "$tmp/physical/eh-device/min_freq"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
sh "$control" restore > "$tmp/restore.log"

grep -Fq 'RESULT: ZRAM_EH_RESTORE_DONE nodes=1 aliases_skipped=1' "$tmp/restore.log"
[[ "$(cat "$tmp/physical/eh-device/min_freq")" = 200000000 ]]

# A Dev.13 legacy lock choice must normalize to adaptive.
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' \
  'LAST_ZRAM_100P=enabled' \
  'ZRAM_EMERALD_OC=1' > "$config"
ZRAM_CONFIG_FILE="$config" sh "$normalize" > "$tmp/normalize.log"
grep -Fq 'migrated=legacy_enabled_to_adaptive' "$tmp/normalize.log"
grep -Fq 'ZRAM_EMERALD_OC=0' "$config"
grep -Fq 'LAST_ZRAM_100P=enabled_standard' "$config"
grep -Fq 'ZRAM_EH_RISK_ACK=none' "$config"

# Dev.20 may write the LMKD property only behind the explicit ZRAM-linked
# reload gate. Stock remains the default when either flag is absent.
grep -Fq 'LMKD_RELOAD="${LMKD_SWAP_LOW_RELOAD:-0}"' "$apply"
grep -Fq 'LMKD_ACK="${LMKD_SWAP_LOW_RISK_ACK:-none}"' "$apply"
grep -Fq 'if [ "$LMKD_RELOAD" != 1 ] || [ "$LMKD_ACK" != explicit_user_reload ]; then' "$apply"
grep -Fq 'ro.lmk.swap_free_low_percentage 1' "$apply"
grep -Fq 'lmkd.reinit' "$apply"
grep -Fq 'ctl.restart lmkd' "$apply"
grep -Fq 'lmk_swap_low_policy=stock_unmodified' "$service"

grep -Fq 'polling_index=0' "$install_menu"
grep -Fq 'current_profile=stock' "$install_menu"
grep -Fq 'zram_index=1' "$install_menu"
grep -Fq 'ptune_index=1' "$install_menu"
grep -Fq 'debug_index=1' "$install_menu"
grep -Fq 'EXPERIMENTAL max lock (heat/battery)' "$install_menu"
grep -Fq 'Adaptive (daily default)' "$action_dashboard"

grep -Fq 'ptune_risk_ack=' "$install_finalize"
grep -Fq 'zram_risk_ack=' "$install_finalize"
grep -Fq 'zram_eh_risk_ack=' "$install_finalize"
if grep -Fq '"risk_ack=' "$install_finalize"; then
  printf '%s\n' 'FAIL dev14_generic_risk_ack_reintroduced'
  exit 1
fi

if grep -Fq 'while :; do' "$service"; then
  printf '%s\n' 'FAIL dev14_unbounded_eh_watcher_present'
  exit 1
fi

grep -Fq 'version=2.0.0-alpha.3-dev.21' "$module_prop"
grep -Fq 'versionCode=1016232' "$module_prop"

printf '%s\n' 'PASS dev14_physical_eh_alias_deduplication'
printf '%s\n' 'PASS dev14_migration_safe_duplicate_baseline_restore'
printf '%s\n' 'PASS dev14_legacy_lock_migrates_to_adaptive'
printf '%s\n' 'PASS dev20_opt_in_lmk_reload_preserves_stock_default'
printf '%s\n' 'PASS dev15_daily_fresh_defaults'
printf '%s\n' 'PASS dev14_distinct_risk_observability'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV14_EH_SAFETY_TEST_PASS'
