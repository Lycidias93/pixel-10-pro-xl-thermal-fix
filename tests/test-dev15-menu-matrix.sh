#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
install_menu="$root/tools/menu/install-options-menu.sh"
action="$root/tools/action-dashboard.sh"
layout="$root/tools/zram/materialize-zram-choice.sh"
normalize="$root/tools/zram/config-normalize.sh"
apply="$root/tools/zram/apply-zram-100p.sh"
status_lib="$root/tools/debug/status-lib.sh"
status_cached="$root/tools/debug/status-cached-print.sh"
collector="$root/tools/debug/collect-thermal-online-v5.sh"
post_fs="$root/post-fs-data.sh"
service="$root/service.sh"
module_prop="$root/module.prop"

fail() { printf 'FAIL %s\n' "$*"; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

for file in "$install_menu" "$action" "$layout" "$normalize" "$apply" "$status_lib" "$status_cached" "$collector" "$post_fs" "$service"; do
  bash -n "$file" || fail "syntax file=$file"
done
pass alpha3_shell_syntax

# User-facing status/support wording must not regress to P/T/Z/L.
grep -Fq 'desc="description=Polling ' "$status_lib" || fail readable_manager_description_missing
! grep -Fq 'description=P:' "$status_lib" || fail abbreviated_status_lib_present
! grep -Fq 'write_manager_description "P:' "$service" || fail abbreviated_fast_status_present
grep -Fq 'Feature Status' "$status_cached" || fail feature_status_heading_missing
grep -Fq 'Support Snapshot (ZIP)' "$action" || fail support_snapshot_action_missing
grep -Fq 'Memory Killer Evidence' "$action" || fail memory_killer_evidence_missing
pass readable_status_support_contract

# ZRAM memory properties stay on resetprop-rs -n. setprop is allowed only for
# Android init/service trigger properties such as lmkd.reinit/ctl.*.
grep -Fq 'RESET="${ZRAM_RESETPROP_BIN:-$MODDIR/tools/resetprop-rs}"' "$apply" || fail resetprop_helper_missing
grep -Fq '"$RESET" -n "$key" "$value"' "$apply" || fail resetprop_n_write_missing
if grep -Eq 'setprop[[:space:]]+(vendor\.zram|mmd\.zram)' "$apply"; then
  fail zram_memory_setprop_present
fi
pass zram_memory_resetprop_only

# Installer dependency: Memory Killer is presented only in the ZRAM-enabled
# branch; disabling ZRAM also clears every LMKD opt-in key.
grep -Fq 'mc_cycle2 "Memory Killer" "Stock" "EXPERIMENTAL 1%"' "$install_menu" || fail memory_killer_menu_missing
python3 - "$install_menu" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
z=s.index('mc_cycle2 "ZRAM 100%"')
else_pos=s.index('\nelse\n', z)
mk=s.index('mc_cycle2 "Memory Killer"', else_pos)
end=s.index('\nfi\n', mk)
assert else_pos < mk < end
PY
grep -Fq 'cfg_set LMKD_SWAP_LOW_RELOAD 0' "$install_menu" || fail zram_disable_lmkd_clear_missing
pass installer_zram_lmkd_dependency

# Runtime normalization is a second invariant guard.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools/zram" "$tmp/mod/system/vendor/etc" "$tmp/config"
cp "$root/tools/zram/fstab.zram.100p" "$tmp/mod/tools/zram/fstab.zram.100p"
printf '%s\n' \
  'ENABLE_ZRAM_100P=0' \
  'ZRAM_RISK_ACK=disabled_by_user' \
  'LMKD_SWAP_LOW_RELOAD=1' \
  'LMKD_SWAP_LOW_RISK_ACK=explicit_user_reload' \
  'LAST_LMKD_SWAP_LOW_RELOAD=enabled' > "$tmp/config/config.env"
ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$normalize" > "$tmp/normalize.log"
grep -Fxq 'LMKD_SWAP_LOW_RELOAD=0' "$tmp/config/config.env" || fail normalize_lmkd_not_disabled
grep -Fxq 'LMKD_SWAP_LOW_RISK_ACK=none' "$tmp/config/config.env" || fail normalize_lmkd_ack_not_cleared
grep -Fxq 'LAST_LMKD_SWAP_LOW_RELOAD=disabled' "$tmp/config/config.env" || fail normalize_lmkd_last_not_disabled
pass runtime_zram_lmkd_invariant

# Live Action layout mutation is deferred; pre-mount reconcile performs the
# actual add/remove transaction.
printf '%s\n' \
  'ENABLE_ZRAM_100P=1' \
  'ZRAM_RISK_ACK=explicit_user_enable' > "$tmp/config/config.env"
MODDIR="$tmp/mod" ZRAM_LIVE_MODDIR="$tmp/not-live" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" reconcile > "$tmp/reconcile-enable.log"
[[ -s "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail reconcile_enable_missing
MODDIR="$tmp/mod" ZRAM_LIVE_MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" disable > "$tmp/live-disable.log"
grep -Fq 'action=pre_mount_reconcile_required' "$tmp/live-disable.log" || fail live_disable_not_deferred
[[ -s "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail live_disable_mutated_mounted_tree
printf '%s\n' \
  'ENABLE_ZRAM_100P=0' \
  'ZRAM_RISK_ACK=disabled_by_user' > "$tmp/config/config.env"
MODDIR="$tmp/mod" ZRAM_LIVE_MODDIR="$tmp/not-live" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" reconcile > "$tmp/reconcile-disable.log"
[[ ! -e "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail reconcile_disable_present
grep -Fq 'sh "$ZRAM_LAYOUT" reconcile' "$post_fs" || fail post_fs_reconcile_missing
pass zram_live_defer_pre_mount_reconcile

# The install-time Support Snapshot failure from alpha.2 was a parse error.
# Shell syntax plus the corrected JSON-key regexes are now guarded.
grep -Fq "grep -Eo '\"PollingDelay\"[[:space:]]*:[[:space:]]*[0-9]+'" "$collector" || fail collector_polling_regex_missing
if grep -Fq "'\"'\"'PollingDelay" "$collector"; then
  fail collector_broken_quote_pattern_present
fi
pass support_snapshot_parser_contract

module_version="$(sed -n 's/^version=//p' "$module_prop" | head -n 1)"
module_version_code="$(sed -n 's/^versionCode=//p' "$module_prop" | head -n 1)"
[[ "$module_version" =~ ^[0-9]+[.][0-9]+[.][0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || fail module_version_format
[[ "$module_version_code" =~ ^[0-9]+$ ]] || fail module_version_code_format
pass module_metadata_contract

printf '%s\n' 'ROUTE installer: zram disabled => memory-killer hidden/off'
printf '%s\n' 'ROUTE installer: zram enabled => adaptive/max-lock => memory-killer stock/experimental'
printf '%s\n' 'ROUTE action: live layout change deferred until reboot pre-mount reconcile'
printf '%s\n' 'ROUTE service: disabled ZRAM skips memory property apply'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV15_MENU_MATRIX_PASS'
