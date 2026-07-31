#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
normalize="$repo_root/tools/zram/config-normalize.sh"
control="$repo_root/tools/zram/emerald-hill-control.sh"
apply="$repo_root/tools/zram/apply-zram-100p.sh"
service="$repo_root/service.sh"
action="$repo_root/tools/action-dashboard.sh"
install_menu="$repo_root/tools/menu/install-options-menu.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/devfreq/17000000.eh" "$tmp/state" "$tmp/data"
printf '%s\n' 200000000 > "$tmp/devfreq/17000000.eh/min_freq"
printf '%s\n' 1066000000 > "$tmp/devfreq/17000000.eh/max_freq"
printf '%s\n' '200000000 400000000 800000000 1066000000' > "$tmp/devfreq/17000000.eh/available_frequencies"
printf '%s\n' emerald-hill > "$tmp/devfreq/17000000.eh/name"

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

bash -n "$normalize"
bash -n "$control"
bash -n "$apply"
bash -n "$service"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" \
sh "$control" apply > "$tmp/apply.log"

grep -Fq 'RESULT: ZRAM_EH_APPLY_DONE' "$tmp/apply.log"
[[ "$(cat "$tmp/devfreq/17000000.eh/min_freq")" = 1066000000 ]]
grep -Fq 'state=active' "$tmp/state/status.env"
grep -Fq $'\t200000000\t1066000000\t1066000000' "$tmp/state/baseline.tsv"

MODDIR="$repo_root" \
ZRAM_CONFIG_FILE="$config" \
ZRAM_EH_STATE_DIR="$tmp/state" \
ZRAM_EH_DEVFREQ_ROOTS="$tmp/devfreq/*" \
sh "$control" restore > "$tmp/restore.log"

grep -Fq 'RESULT: ZRAM_EH_RESTORE_DONE' "$tmp/restore.log"
[[ "$(cat "$tmp/devfreq/17000000.eh/min_freq")" = 200000000 ]]
grep -Fq 'state=adaptive' "$tmp/state/status.env"

# Missing dedicated menu choice must be downgraded even when a legacy OC bit is set.
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' 'LAST_ZRAM_100P=enabled_standard' 'ZRAM_EMERALD_OC=1' > "$config"
ZRAM_CONFIG_FILE="$config" sh "$normalize" > "$tmp/normalize.log"
grep -Fq 'ZRAM_EMERALD_OC=0' "$config"

if grep -R -Fq 'ZRAM_EMERALD_OC:-1' "$apply" "$service" "$control" "$normalize"; then
  printf '%s\n' 'FAIL unsafe_default_on_present'
  exit 1
fi
if grep -Fq 'while :; do' "$service"; then
  printf '%s\n' 'FAIL unbounded_eh_watcher_present'
  exit 1
fi
if grep -E '/sys/.*/min_freq' "$service" >/dev/null; then
  printf '%s\n' 'FAIL service_writes_devfreq_directly'
  exit 1
fi

grep -Fq 'success-verify' "$service"
grep -Fq 'bootguard_verified' "$service"
grep -Fq 'ZRAM_EMERALD_OC' "$action"
grep -Fq 'Emerald Hill mode' "$install_menu"
grep -Fq 'max_lock_failed_fallback_adaptive' "$apply"

printf '%s\n' 'PASS zram_eh_fake_devfreq_apply_restore'
printf '%s\n' 'PASS zram_eh_default_off_and_explicit_choice_gate'
printf '%s\n' 'PASS zram_eh_deferred_until_bootguard_verified'
printf '%s\n' 'PASS zram_eh_no_unbounded_service_watcher'
printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_EH_DEV12_TEST_PASS'
