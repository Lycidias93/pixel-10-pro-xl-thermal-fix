#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
control="$repo_root/tools/zram/emerald-hill-control.sh"
dashboard="$repo_root/tools/action-dashboard.sh"
service="$repo_root/service.sh"
post_fs="$repo_root/post-fs-data.sh"
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
  'ZRAM_EH_TARGET_FREQ=max' > "$config"

bash -n "$control"
bash -n "$dashboard"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
ZRAM_EH_CALLER=dev18_test_apply \
sh "$control" apply > "$tmp/apply.log"

grep -Fq 'RESULT: ZRAM_EH_APPLY_DONE nodes=1 aliases_skipped=1 target=1066000000' "$tmp/apply.log"
grep -Fq 'caller=dev18_test_apply event=apply outcome=success' "$tmp/state/events.log"
grep -Fq 'original_min=200000000' "$tmp/state/events.log"
grep -Fq 'target=1066000000' "$tmp/state/events.log"
grep -Fq 'readback=1066000000' "$tmp/state/events.log"
grep -Fq 'apply_events=1' "$tmp/state/status.env"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/class/* $tmp/platform/*/devfreq/*" \
ZRAM_EH_CALLER=dev18_test_restore \
sh "$control" restore > "$tmp/restore.log"

grep -Fq 'RESULT: ZRAM_EH_RESTORE_DONE nodes=1 aliases_skipped=0' "$tmp/restore.log"
grep -Fq 'caller=dev18_test_restore event=restore outcome=success' "$tmp/state/events.log"
grep -Fq 'restore_events=1' "$tmp/state/status.env"
[[ "$(cat "$tmp/physical/eh-device/min_freq")" = 200000000 ]]

grep -Fq 'Experimental max lock is under Advanced' "$dashboard"
grep -Fq 'ui_menu6 "Advanced" "Emerald Hill mode"' "$dashboard"
grep -Fq 'ui_menu6 "Debug" "Status" "Collect ZIP" "EH Event Log"' "$dashboard"
grep -Fq 'EXPERIMENTAL max lock' "$dashboard"
grep -Fq 'Adaptive (daily default)' "$dashboard"

if grep -Fq 'while :; do' "$service"; then
  printf '%s\n' 'FAIL dev18_unbounded_service_watcher_present'
  exit 1
fi
grep -Fq 'LMKD_EARLY="$MODDIR/tools/lmkd/early-swap-low-test.sh"' "$post_fs"

grep -Fq 'version=2.0.0-alpha.3-dev.20' "$module_prop"
grep -Fq 'versionCode=1016231' "$module_prop"

printf '%s\n' 'PASS dev18_eh_apply_restore_event_log'
printf '%s\n' 'PASS dev18_eh_advanced_ux'
printf '%s\n' 'PASS dev18_no_unbounded_watcher'
printf '%s\n' 'PASS dev18_stock_default_preserved_by_explicit_lmk_gate'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV18_EH_OBSERVABILITY_TEST_PASS'
