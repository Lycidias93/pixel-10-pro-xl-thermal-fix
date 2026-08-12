#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
helper="$repo_root/tools/zram/materialize-zram-choice.sh"
installer="$repo_root/tools/zram/install-zram.sh"
src="$repo_root/tools/zram/fstab.zram.100p"

tmp="$(mktemp -d)"
trap 'chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp"' EXIT
active="$tmp/active"
config="$tmp/config.env"
mkdir -p "$active"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' > "$config"
printf '%s\n' 'sentinel-live-layout' > "$active/fstab.zram.100p"

# Runtime Action/helper calls must be config-only even when path identity cannot
# distinguish an active mount from a staging tree. A read-only destination is a
# regression fixture for the real Action failure reported on Mustang.
chmod 0555 "$active"
out="$(MODDIR="$tmp/path-alias-not-live" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_LIVE_MODDIR="$tmp/different-live-view" sh "$helper" disable)"
grep -Fq 'RESULT: ZRAM_LAYOUT_DONE mode=disable materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"
out="$(MODDIR="$tmp/path-alias-not-live" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_LIVE_MODDIR="$tmp/different-live-view" sh "$helper" enable)"
grep -Fq 'RESULT: ZRAM_LAYOUT_DONE mode=enable materialized=deferred action=pre_mount_reconcile_required' <<<"$out"
grep -Fxq 'sentinel-live-layout' "$active/fstab.zram.100p"

# Only install-time code may request immediate layout mutation explicitly.
chmod 0755 "$active"
MODDIR="$tmp/stage" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 sh "$helper" disable >/dev/null
test ! -e "$active/fstab.zram.100p"
MODDIR="$tmp/stage" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" ZRAM_MATERIALIZE_NOW=1 sh "$helper" enable >/dev/null
cmp -s "$src" "$active/fstab.zram.100p"

test "$(grep -c 'ZRAM_MATERIALIZE_NOW=1' "$installer")" -eq 2

# post-fs-data reconcile remains authoritative and does not need the install flag.
printf '%s\n' 'ENABLE_ZRAM_100P=0' 'ZRAM_RISK_ACK=disabled_by_user' > "$config"
MODDIR="$tmp/stage" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" reconcile >/dev/null
test ! -e "$active/fstab.zram.100p"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_RISK_ACK=explicit_user_enable' > "$config"
MODDIR="$tmp/stage" ZRAM_ACTIVE_DIR="$active" ZRAM_FSTAB_SRC="$src" ZRAM_CONFIG_FILE="$config" sh "$helper" reconcile >/dev/null
cmp -s "$src" "$active/fstab.zram.100p"

printf '%s\n' 'PASS action_default_deferred_independent_of_path_identity'
printf '%s\n' 'PASS installer_immediate_mutation_requires_explicit_flag'
printf '%s\n' 'PASS post_fs_data_reconcile_remains_authoritative'
printf '%s\n' 'RESULT: VNEXT_ALPHA3_ZRAM_DEFER_CONTRACT_PASS'
