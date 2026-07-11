#!/system/bin/sh
MODDIR="${MODDIR:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
choose_download() { for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do [ -d "$d" ] && [ -w "$d" ] && { echo "$d"; return 0; }; done; echo "$ALT_DOWNLOAD"; }
DL="$(choose_download)"
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
OUT="$DL/pixel_thermal_zram_debug_${TS}.txt"
{
  echo "debug_type=pixel_thermal_zram_debug"
  echo "time=$(date -Is 2>/dev/null || date)"
  echo "module=$MODDIR"
  echo
  echo "== config =="
  cat "$CONFIG_FILE" 2>/dev/null || true
  echo
  echo "== props =="
  for k in mm.zram.maintenance.first_delay_seconds mm.zram.maintenance.periodic_delay_seconds mmd.zram.writeback.max_idle_seconds mmd.zram.comp_algorithm mmd.zram.enabled mmd.zram.size vendor.zram.size persist.device_config.vendor_system_native_boot.zram_size persist.vendor.boot.zram.size; do echo "$k=$(getprop "$k" 2>/dev/null || true)"; done
  echo
  echo "== fstab.zram.100p =="
  for f in "$MODDIR/system/vendor/etc/fstab.zram.100p" /vendor/etc/fstab.zram.100p; do echo "-- $f"; [ -r "$f" ] && { ls -l "$f"; cat "$f"; } || echo absent; done
  echo
  echo "== mmd =="
  pidof mmd 2>/dev/null || true
  ps -A 2>/dev/null | grep -E '(^| )mmd( |$)' || true
  echo
  echo "== swaps =="
  cat /proc/swaps 2>/dev/null || true
  echo
  echo "== zram sysfs =="
  for f in /sys/block/zram0/disksize /sys/block/zram0/comp_algorithm /sys/block/zram0/backing_dev /sys/block/zram0/mm_stat /sys/block/zram0/stat; do echo "-- $f"; cat "$f" 2>/dev/null || true; done
  echo
  echo "== recent mmd/zram logcat =="
  logcat -d -t 300 2>/dev/null | grep -i -E 'mmd|zram|mm.zram|vendor.zram|pixel-10-pro-xl-thermal-fix' || true
  echo "RESULT: PIXEL_THERMAL_ZRAM_DEBUG_DONE"
} > "$OUT" 2>&1
cat "$OUT"
