#!/system/bin/sh
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
choose_download() { for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do [ -d "$d" ] && [ -w "$d" ] && { echo "$d"; return 0; }; done; echo "$ALT_DOWNLOAD"; }
DL="$(choose_download)"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
dbg="$(grep -E '^(DEBUG_MODE|debug_mode)=' "$CONFIG_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2 | tr -d '\r')"
if [ "$dbg" = "1" ]; then
  LOG="$DL/pixel_thermal_zram_100p_disable_${TS}.txt"
else
  LOG="/dev/null"
fi

mkdir -p "$CONFIG_DIR" "$DL" 2>/dev/null || true
if [ -f "$CONFIG_FILE" ]; then
  grep -v -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK)=' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
fi
{
  echo 'ENABLE_ZRAM_100P=0'
  echo 'ZRAM_RESTART_MMD=0'
  echo 'ZRAM_RISK_ACK=disabled_by_user'
} >> "$CONFIG_FILE"
{
  echo "debug_type=pixel_thermal_zram_100p_disable"
  echo "time=$(date -Is 2>/dev/null || date)"
  echo "config=$CONFIG_FILE"
  echo "NOTE: config disabled. Reboot recommended to return to stock zram behavior."
  echo "NOTE: persistent props are not forcibly blanked to avoid unknown stock defaults."
  echo
  echo "== current props =="
  for k in mm.zram.maintenance.first_delay_seconds mm.zram.maintenance.periodic_delay_seconds mmd.zram.writeback.max_idle_seconds mmd.zram.comp_algorithm mmd.zram.enabled mmd.zram.size vendor.zram.size persist.device_config.vendor_system_native_boot.zram_size persist.vendor.boot.zram.size; do echo "$k=$(getprop "$k" 2>/dev/null || true)"; done
  echo "RESULT: PIXEL_THERMAL_ZRAM_100P_DISABLE_DONE"
} > "$LOG" 2>&1
cat "$LOG"
