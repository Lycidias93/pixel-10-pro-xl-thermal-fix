#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
install_menu="$root/tools/menu/install-options-menu.sh"
action="$root/tools/action-dashboard.sh"
cycle="$root/tools/menu/menu-cycle.sh"
layout="$root/tools/zram/materialize-zram-choice.sh"
disable_ptune="$root/tools/ptune/disable-ptune-override.sh"
reinit="$root/tools/zram/reinit-zram-100p.sh"
status_lib="$root/tools/debug/status-lib.sh"
status_cached="$root/tools/debug/status-cached-print.sh"
customize="$root/customize.sh"
module_prop="$root/module.prop"

fail() { printf 'FAIL %s\n' "$*"; exit 1; }
pass() { printf 'PASS %s\n' "$*"; }

for file in "$install_menu" "$action" "$cycle" "$layout" "$disable_ptune" "$reinit" "$status_lib" "$status_cached" "$customize"; do
  bash -n "$file" || fail "syntax file=$file"
done
pass menu_and_helper_syntax

grep -Fq 'current_polling=mod' "$install_menu"
grep -Fq 'polling_index=0' "$install_menu"
grep -Fq 'current_zram=1' "$install_menu"
grep -Fq 'zram_index=1' "$install_menu"
grep -Fq 'current_debug=1' "$install_menu"
grep -Fq 'debug_index=1' "$install_menu"
pass fresh_defaults_polling_mod_zram_enabled_verbose

for route in \
  'Remember Settings" "Use last" "Fresh choices"' \
  'Polling Mode" "Mod values" "Stock values"' \
  '"Stock" \' \
  '"$safe_label" \' \
  '"$plus_label" \' \
  '"$ext_label" \' \
  'ZRAM 100%" "Disabled" "Enabled"' \
  'Emerald Hill mode" "Adaptive (daily default)" "EXPERIMENTAL max lock (heat/battery)"' \
  'pTune Override" "Override ON" "Override OFF"' \
  'LMKD 1% reload" "Disabled (stock)" "EXPERIMENTAL 1%"' \
  'Debug Logging" "Silent" "Verbose"'; do
  grep -Fq "$route" "$install_menu" || fail "installer_route_missing=$route"
done
pass installer_route_matrix_complete

for fn in 'ui_menu3() {' 'ui_menu4() {' 'ui_menu5() {' 'ui_menu6() {'; do
  grep -Fq "$fn" "$action" || fail "ui_menu_fn_missing=$fn"
done
pass action_menu_functions_defined

for route in \
  'mc_cycle4 "Action" "Settings" "Debug" "Advanced" "Exit"' \
  'mc_cycle4 "Settings" "Polling Mode" "Thermal Profile" "ZRAM 100%" "Back"' \
  'ui_menu3 "Polling Mode" "Module values" "Stock values" "Back"' \
  'ui_menu5 "Thermal max+' \
  'ui_menu3 "ZRAM 100%" "Enable 100p (adaptive EH)" "Disable" "Back"' \
  'ui_menu3 "Emerald Hill mode" "Adaptive (daily default)" "EXPERIMENTAL max lock" "Back"' \
  'ui_menu6 "Debug" "Feature Status" "Support Snapshot (ZIP)" "EH Event Log" "Memory Killer Evidence" "Debug Logging" "Back"' \
  'ui_menu6 "Advanced" "Emerald Hill mode" "LMKD 1% reload" "pTune Status" "pTune Override" "Update Channel" "Back"' \
  'ui_menu3 "pTune Risk" "Keep OFF" "Enable risk" "Back"' \
  'ui_menu3 "Update Channel" "Use Stable" "Use Test" "Back"'; do
  grep -Fq "$route" "$action" || fail "action_route_missing=$route"
done
pass action_route_matrix_complete

grep -Fq '[ "$MC_REASON" = "timeout" ] && return 0' "$action"
grep -Fq '[ "$UI_REASON" = "timeout" ] && return 0' "$action"
grep -Fq '*) msg "Back."; return 0 ;;' "$action"
pass timeout_and_back_routes_non_destructive

grep -Fq 'sh "$ZRAM_LAYOUT" enable' "$action"
grep -Fq 'sh "$ZRAM_LAYOUT" disable' "$action"
grep -Fq 'action_cycle_pending_reboot' "$action"
grep -Fq 'Existing configuration kept' "$action"
pass action_zram_transaction_wiring

grep -Fq 'desc="description=Polling ' "$status_lib" || fail readable_manager_description_missing
if grep -Fq 'description=P:' "$status_lib"; then
  fail abbreviated_manager_badges_present
fi
grep -Fq 'Thermal $thermal_icon $thermal_display' "$status_lib" || fail thermal_full_label_missing
grep -Fq 'ZRAM $zram_icon $zram_display' "$status_lib" || fail zram_full_label_missing
grep -Fq 'Memory Killer $lmk_icon $memory_killer_display' "$status_lib" || fail memory_killer_full_label_missing
grep -Fq 'MEMORY_KILLER_DISPLAY=' "$status_lib" || fail memory_killer_display_state_missing
grep -Fq 'Feature Status' "$status_cached" || fail feature_status_heading_missing
grep -Fq 'Memory Killer:' "$status_cached" || fail memory_killer_cached_status_missing
grep -Fq 'Support Snapshot (ZIP)' "$action" || fail support_snapshot_action_missing
grep -Fq 'Feature Status: readable runtime overview' "$customize" || fail installer_feature_status_guidance_missing
grep -Fq 'Support Snapshot (ZIP): testing/support file' "$customize" || fail installer_support_snapshot_guidance_missing
pass readable_status_and_support_ux_contract

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools/zram" "$tmp/mod/system/vendor/etc" "$tmp/config"
cp "$layout" "$tmp/mod/tools/zram/materialize-zram-choice.sh"
printf '%s\n' template > "$tmp/mod/tools/zram/fstab.zram.100p"

# Reconcile enable creates fstab
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' > "$tmp/config/config.env"
MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" reconcile > "$tmp/layout-enable.log"
[[ -s "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail reconcile_enable_missing

# Live runtime disable is deferred
MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" disable > "$tmp/layout-disable.log"
grep -Fq 'action=pre_mount_reconcile_required' "$tmp/layout-disable.log" || fail live_disable_not_deferred
[[ -s "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail live_disable_mutated_mounted_tree

# Reconcile disable removes fstab
printf '%s\n' 'ENABLE_ZRAM_100P=0' 'ZRAM_RISK_ACK=disabled_by_user' > "$tmp/config/config.env"
MODDIR="$tmp/mod" ZRAM_CONFIG_FILE="$tmp/config/config.env" sh "$layout" reconcile > "$tmp/layout-reconcile-disable.log"
[[ ! -e "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]] || fail reconcile_disable_present
pass zram_layout_enable_disable_transaction

printf '%s\n' \
  'THERMAL_POLLING_MODE=mod' \
  'THERMAL_OUTDOOR_PROFILE=outdoor-extended' \
  'ENABLE_ZRAM_100P=1' \
  'DEBUG_MODE=1' \
  'ALLOW_THERMAL_WITH_PTUNE=1' > "$tmp/config/config.env"
mkdir -p "$tmp/active/guard" "$tmp/stage/guard"
MODDIR="$tmp/active" STAGEDIR="$tmp/stage" THERMAL_CONFIG_DIR="$tmp/config" PTUNE_MODULE_ROOTS="$tmp/no-ptune" \
  sh "$disable_ptune" > "$tmp/ptune-disable.log"
grep -Fxq 'THERMAL_POLLING_MODE=mod' "$tmp/config/config.env"
grep -Fxq 'THERMAL_OUTDOOR_PROFILE=outdoor-extended' "$tmp/config/config.env"
grep -Fxq 'ENABLE_ZRAM_100P=1' "$tmp/config/config.env"
grep -Fxq 'DEBUG_MODE=1' "$tmp/config/config.env"
grep -Fxq 'ALLOW_THERMAL_WITH_PTUNE=0' "$tmp/config/config.env"
pass ptune_disable_preserves_unrelated_config

if grep -Fq 'setprop ro.lmk.swap_free_low_percentage 1' "$reinit"; then
  fail reinit_lmk_override_present
fi
grep -Fq 'lmk_swap_low_policy=stock_unmodified' "$reinit"
grep -Fq 'enabled_max_lock' "$reinit"
grep -Fq 'ZRAM_EH_RISK_ACK' "$reinit"
pass reinit_uses_stock_lmk_and_current_eh_contract

if grep -Fq 'Emerald Hill OC' "$cycle" "$install_menu" "$action"; then
  fail stale_oc_menu_wording
fi
module_version="$(sed -n 's/^version=//p' "$module_prop" | head -n 1)"
module_version_code="$(sed -n 's/^versionCode=//p' "$module_prop" | head -n 1)"
[[ "$(grep -c '^version=' "$module_prop")" -eq 1 ]] || fail module_version_count
[[ "$(grep -c '^versionCode=' "$module_prop")" -eq 1 ]] || fail module_version_code_count
[[ "$module_version" =~ ^[0-9]+[.][0-9]+[.][0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || fail module_version_format
[[ "$module_version_code" =~ ^[0-9]+$ ]] || fail module_version_code_format
pass stable_metadata_and_current_wording

printf '%s\n' 'ROUTE installer: remember/use-last/fresh'
printf '%s\n' 'ROUTE installer: polling mod/stock'
printf '%s\n' 'ROUTE installer: thermal stock/safe/plus/extended'
printf '%s\n' 'ROUTE installer: zram disabled/adaptive/experimental-max-lock'
printf '%s\n' 'ROUTE installer: lmkd stock/experimental-reload'
printf '%s\n' 'ROUTE installer: ptune on/off'
printf '%s\n' 'ROUTE installer: debug silent/verbose'
printf '%s\n' 'ROUTE action: settings/debug/advanced/exit'
printf '%s\n' 'ROUTE action settings: polling/thermal/zram/back'
printf '%s\n' 'ROUTE action debug: feature-status/support-snapshot/eh-log/memory-killer-evidence/toggle/back'
printf '%s\n' 'ROUTE action advanced: eh-mode/lmkd-reload/ptune-status/ptune-override/update-channel/back'
printf '%s\n' 'ROUTE action leafs: back/timeout preserve state'
printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV15_MENU_MATRIX_PASS'
