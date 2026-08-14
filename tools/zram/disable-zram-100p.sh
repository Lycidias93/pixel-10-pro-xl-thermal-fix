#!/system/bin/sh
set -eu

ID="pixel-10-pro-xl-thermal-fix"
CONFIG_DIR="${THERMAL_CONFIG_DIR:-/data/adb/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-$CONFIG_DIR/config.env}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
LAYOUT="$MODDIR/tools/zram/materialize-zram-choice.sh"

cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG_FILE"
}

[ -r "$LAYOUT" ] || { printf '%s\n' "RESULT: ZRAM_DISABLE_FAIL reason=layout_helper_missing"; exit 2; }
MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$LAYOUT" disable >/dev/null

cfg_set ENABLE_ZRAM_100P 0
cfg_set ZRAM_EMERALD_OC 0
cfg_set ZRAM_RESTART_MMD 0
cfg_set ZRAM_RISK_ACK disabled_by_user
cfg_set ZRAM_EH_RISK_ACK disabled_by_user
cfg_set LAST_ZRAM_100P disabled
cfg_set LMKD_SWAP_LOW_RELOAD 0
cfg_set LMKD_SWAP_LOW_RISK_ACK none
cfg_set LAST_LMKD_SWAP_LOW_RELOAD disabled

printf '%s\n' "ZRAM 100p disabled in config and module layout removed. Reboot restores stock ZRAM layout."
printf '%s\n' "RESULT: PIXEL_THERMAL_ZRAM_100P_DISABLE_DONE layout=removed eh=adaptive"
