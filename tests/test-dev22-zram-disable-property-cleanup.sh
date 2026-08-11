#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
apply="$root/tools/zram/apply-zram-100p.sh"
disable_helper="$root/tools/zram/disable-zram-100p.sh"
normalize="$root/tools/zram/config-normalize.sh"
service="$root/service.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mod/tools/zram" "$tmp/mod/guard" "$tmp/bin" "$tmp/state"

printf '%s\n' test-boot > "$tmp/boot_id"
printf '%s\n' '12.00 34.00' > "$tmp/uptime"

# Mock resetprop & resetprop-rs tracking deleted keys
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'case "${1:-}" in' '  -d) echo "deleted:$2" >> "$DELETED_LOG" ;;' '  -n) echo "set_in_mem:$2=$3" >> "$SET_LOG" ;;' '  *) exit 0 ;;' 'esac' > "$tmp/bin/resetprop"
chmod +x "$tmp/bin/resetprop"
cp "$tmp/bin/resetprop" "$tmp/mod/tools/resetprop-rs"

cp "$apply" "$tmp/mod/tools/zram/apply-zram-100p.sh"
cp "$disable_helper" "$tmp/mod/tools/zram/disable-zram-100p.sh"
cp "$normalize" "$tmp/mod/tools/zram/config-normalize.sh"
chmod +x "$tmp/mod/tools/zram/"*.sh

# Mock layout materializer
printf '%s\n' '#!/usr/bin/env bash' 'echo "layout_mode=$1" >> "$LAYOUT_LOG"' > "$tmp/mod/tools/zram/materialize-zram-choice.sh"
chmod +x "$tmp/mod/tools/zram/materialize-zram-choice.sh"

# Mock EH control
printf '%s\n' '#!/usr/bin/env bash' 'echo "eh_mode=$1" >> "$EH_LOG"' > "$tmp/mod/tools/zram/emerald-hill-control.sh"
chmod +x "$tmp/mod/tools/zram/emerald-hill-control.sh"

deleted_log="$tmp/deleted.log"
set_log="$tmp/set.log"
layout_log="$tmp/layout.log"
eh_log="$tmp/eh.log"
config="$tmp/config.env"
: > "$deleted_log"; : > "$set_log"; : > "$layout_log"; : > "$eh_log"

export MODDIR="$tmp/mod"
export THERMAL_CONFIG_DIR="$tmp"
export ZRAM_CONFIG_FILE="$config"
export DELETED_LOG="$deleted_log"
export SET_LOG="$set_log"
export EH_LOG="$eh_log"
export LAYOUT_LOG="$layout_log"
export LMKD_SYSTEM_RESETPROP_BIN="$tmp/bin/resetprop"

# Test 1: Run disable-zram-100p.sh and verify layout removal, EH reset, and LMKD reset
: > "$deleted_log"; : > "$set_log"; : > "$layout_log"; : > "$eh_log"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_EMERALD_OC=1' 'LMKD_SWAP_LOW_RELOAD=1' 'LMKD_SWAP_LOW_RISK_ACK=explicit_user_reload' > "$config"

sh "$tmp/mod/tools/zram/disable-zram-100p.sh" > "$tmp/disable.log"

grep -Fq 'layout_mode=disable' "$layout_log"
grep -Fxq 'ENABLE_ZRAM_100P=0' "$config"
grep -Fxq 'ZRAM_EMERALD_OC=0' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RELOAD=0' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RISK_ACK=none' "$config"
# Verify no property resets occurred
[ ! -s "$deleted_log" ]
grep -Fq 'RESULT: PIXEL_THERMAL_ZRAM_100P_DISABLE_DONE' "$tmp/disable.log"
printf '%s\n' 'PASS disable_zram_helper_disables_lmkd_and_removes_layout'

# Test 2: Verify config-normalize.sh normalizes LMKD to 0 and removes fstab overlay when ZRAM is disabled
mkdir -p "$tmp/mod/system/vendor/etc"
touch "$tmp/mod/system/vendor/etc/fstab.zram.100p"
printf '%s\n' 'ENABLE_ZRAM_100P=0' 'ZRAM_EMERALD_OC=1' 'ZRAM_EH_RISK_ACK=explicit_user_enable_max_lock' 'LMKD_SWAP_LOW_RELOAD=1' > "$config"
ZRAM_CONFIG_FILE="$config" sh "$tmp/mod/tools/zram/config-normalize.sh" > "$tmp/normalize.log"
grep -Fxq 'ZRAM_EMERALD_OC=0' "$config"
grep -Fxq 'ZRAM_EH_RISK_ACK=disabled_by_user' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RELOAD=0' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RISK_ACK=none' "$config"
[ ! -f "$tmp/mod/system/vendor/etc/fstab.zram.100p" ]
printf '%s\n' 'PASS normalize_zram_disabled_resets_eh_and_lmkd_and_removes_fstab'

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV22_ZRAM_DISABLE_PROPERTY_CLEANUP_PASS'
