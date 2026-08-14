#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
helper="$repo_root/tools/zram/materialize-zram-choice.sh"
installer="$repo_root/tools/zram/install-zram.sh"
action="$repo_root/action.sh"
dashboard="$repo_root/tools/action-dashboard.sh"
zram_menu="$repo_root/tools/menu/zram-menu.sh"
disable_helper="$repo_root/tools/zram/disable-zram-100p.sh"
src="$repo_root/tools/zram/fstab.zram.100p"
id="pixel-10-pro-xl-thermal-fix"

tmp="$(mktemp -d)"
trap 'chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp"' EXIT
adb_root="$tmp/adb"
active_mod="$adb_root/modules/$id"
stage_mod="$adb_root/modules_update/$id"
active="$active_mod/system/vendor/etc"
stage="$stage_mod/system/vendor/etc"
config="$tmp/config.env"
mkdir -p "$active" "$stage"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' > "$config"
printf '%s\n' 'sentinel-live-layout' > "$active/fstab.zram.100p"
printf '%s\n' 'sentinel-stage-layout' > "$stage/fstab.zram.100p"

# Runtime Action/helper calls must always be config-only on the active module
# tree, regardless of stale inherited installer flags/tokens.
chmod 0555 "$active"
out="$(THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" disable)"
grep -Fq 'RESULT: ZRAM_LAYOUT_DONE mode=disable materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"
out="$(THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" enable)"
grep -Fq 'RESULT: ZRAM_LAYOUT_DONE mode=enable materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"

# Even the complete dangerous installer environment must not unlock mutation
# on /modules. Immediate materialization is additionally bound to modules_update.
out="$(THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 ZRAM_MATERIALIZE_CALLER=install-zram sh "$helper" disable)"
grep -Fq 'materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"

# Action entry still shadows stale installer variables before the dashboard.
test "$(grep -c 'ZRAM_MATERIALIZE_NOW=0 ZRAM_MATERIALIZE_CALLER=action-' "$action")" -eq 2
export ZRAM_MATERIALIZE_NOW=1
export ZRAM_MATERIALIZE_CALLER=install-zram
out="$(THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=0 ZRAM_MATERIALIZE_CALLER=action-dashboard sh "$helper" disable)"
unset ZRAM_MATERIALIZE_NOW ZRAM_MATERIALIZE_CALLER
grep -Fq 'materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fq 'caller=action-dashboard' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"

# The real Action/UI paths are config-first. Layout-helper failure must never
# abort saving the user's ZRAM choice; post-fs-data reconcile owns the layout.
grep -Fq 'sh "$ZRAM_LAYOUT" enable >/dev/null 2>&1 || true' "$dashboard"
grep -Fq 'sh "$ZRAM_LAYOUT" disable >/dev/null 2>&1 || true' "$dashboard"
! grep -Fq '! ZRAM layout materialization failed' "$dashboard"
! grep -Fq '! ZRAM layout removal failed' "$dashboard"
! grep -Fq '! Existing configuration kept' "$dashboard"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RELOAD 0' "$dashboard"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RISK_ACK none' "$dashboard"
grep -Fq 'cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled' "$dashboard"
grep -Fq 'sh "$LAYOUT" disable >/dev/null 2>&1 || true' "$zram_menu"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RELOAD 0' "$zram_menu"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RELOAD 0' "$disable_helper"
grep -Fq 'cfg_set LMKD_SWAP_LOW_RISK_ACK none' "$disable_helper"
grep -Fq 'cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled' "$disable_helper"

# Only install-time code on the real modules_update identity may request
# immediate layout mutation, and it still needs flag + installer caller token.
chmod 0755 "$stage"
THERMAL_ADB_ROOT="$adb_root" MODDIR="$stage_mod" ZRAM_ACTIVE_DIR="$stage" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 ZRAM_MATERIALIZE_CALLER=install-zram sh "$helper" disable >/dev/null
test ! -e "$stage/fstab.zram.100p"
THERMAL_ADB_ROOT="$adb_root" MODDIR="$stage_mod" ZRAM_ACTIVE_DIR="$stage" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 ZRAM_MATERIALIZE_CALLER=install-zram sh "$helper" enable >/dev/null
cmp -s "$src" "$stage/fstab.zram.100p"

# Wrong path identity must remain deferred even with both installer variables.
out="$(THERMAL_ADB_ROOT="$adb_root" MODDIR="$tmp/not-modules-update" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 ZRAM_MATERIALIZE_CALLER=install-zram sh "$helper" disable)"
grep -Fq 'materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"

test "$(grep -c 'ZRAM_MATERIALIZE_NOW=1' "$installer")" -eq 2
test "$(grep -c 'ZRAM_MATERIALIZE_CALLER=install-zram' "$installer")" -eq 2

# post-fs-data reconcile remains authoritative and is intentionally allowed on
# the active tree because it runs before module mounting and follows config.
chmod 0755 "$active"
printf '%s\n' 'ENABLE_ZRAM_100P=0' 'ZRAM_RISK_ACK=disabled_by_user' > "$config"
THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" reconcile >/dev/null
test ! -e "$active/fstab.zram.100p"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' > "$config"
THERMAL_ADB_ROOT="$adb_root" MODDIR="$active_mod" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" reconcile >/dev/null
cmp -s "$src" "$active/fstab.zram.100p"

printf '%s\n' 'PASS active_runtime_always_deferred'
printf '%s\n' 'PASS leaked_complete_installer_environment_cannot_mutate_active_tree'
printf '%s\n' 'PASS action_entry_shadows_stale_installer_environment'
printf '%s\n' 'PASS action_runtime_layout_failures_are_nonblocking_config_first'
printf '%s\n' 'PASS zram_disable_immediately_clears_memory_killer_selection'
printf '%s\n' 'PASS installer_immediate_mutation_requires_flag_caller_and_stage_identity'
printf '%s\n' 'PASS wrong_path_identity_remains_deferred'
printf '%s\n' 'PASS post_fs_data_reconcile_remains_authoritative'
printf '%s\n' 'RESULT: VNEXT_ALPHA3_ZRAM_DEFER_CONTRACT_PASS'
