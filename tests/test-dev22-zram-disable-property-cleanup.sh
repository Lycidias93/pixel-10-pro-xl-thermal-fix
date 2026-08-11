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

# Test 1: Run apply-zram-100p.sh restore directly
sh "$tmp/mod/tools/zram/apply-zram-100p.sh" restore > "$tmp/apply_restore.log"

grep -Fq 'deleted:persist.vendor.boot.zram.size' "$deleted_log"
grep -Fq 'deleted:persist.device_config.vendor_system_native_boot.zram_size' "$deleted_log"
grep -Fq 'deleted:vendor.zram.size' "$deleted_log"
grep -Fq 'deleted:mmd.zram.size' "$deleted_log"
grep -Fq 'deleted:mmd.zram.comp_algorithm' "$deleted_log"
grep -Fq 'deleted:mmd.zram.enabled' "$deleted_log"
grep -Fq 'eh_mode=restore' "$eh_log"
grep -Fq 'RESULT: ZRAM_APPLY_DONE mode=restore properties_cleared=yes' "$tmp/apply_restore.log"
printf '%s\n' 'PASS apply_zram_restore_mode_clears_properties'

# Test 2: Run disable-zram-100p.sh and verify layout removal, property deletion, and LKD retention
: > "$deleted_log"; : > "$set_log"; : > "$layout_log"; : > "$eh_log"
printf '%s\n' 'ENABLE_ZRAM_100P=1' 'ZRAM_EMERALD_OC=1' 'LMKD_SWAP_LOW_RELOAD=1' 'LMKD_SWAP_LOW_RISK_ACK=explicit_user_reload' > "$config"

sh "$tmp/mod/tools/zram/disable-zram-100p.sh" > "$tmp/disable.log"

grep -Fq 'layout_mode=disable' "$layout_log"
grep -Fq 'deleted:persist.vendor.boot.zram.size' "$deleted_log"
grep -Fxq 'ENABLE_ZRAM_100P=0' "$config"
grep -Fxq 'ZRAM_EMERALD_OC=0' "$config"
# Verify LMKD mod policy is PRESERVED as user configured
grep -Fxq 'LMKD_SWAP_LOW_RELOAD=1' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RISK_ACK=explicit_user_reload' "$config"
grep -Fq 'RESULT: PIXEL_THERMAL_ZRAM_100P_DISABLE_DONE' "$tmp/disable.log"
printf '%s\n' 'PASS disable_zram_helper_clears_properties_and_preserves_lmkd'

# Test 3: Verify config-normalize.sh normalizes EH OC when ZRAM is disabled, but leaves LMKD untouched
printf '%s\n' 'ENABLE_ZRAM_100P=0' 'ZRAM_EMERALD_OC=1' 'ZRAM_EH_RISK_ACK=explicit_user_enable_max_lock' 'LMKD_SWAP_LOW_RELOAD=1' > "$config"
ZRAM_CONFIG_FILE="$config" sh "$tmp/mod/tools/zram/config-normalize.sh" > "$tmp/normalize.log"
grep -Fxq 'ZRAM_EMERALD_OC=0' "$config"
grep -Fxq 'ZRAM_EH_RISK_ACK=disabled_by_user' "$config"
grep -Fxq 'LMKD_SWAP_LOW_RELOAD=1' "$config"
printf '%s\n' 'PASS normalize_zram_disabled_resets_eh_preserves_lmkd'

printf '%s\n' 'RESULT: PIXEL_THERMAL_DEV22_ZRAM_DISABLE_PROPERTY_CLEANUP_PASS'
