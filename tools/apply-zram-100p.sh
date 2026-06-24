#!/system/bin/sh
MODDIR="${MODDIR:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
DOWNLOAD="/sdcard/Download"
ALT_DOWNLOAD="/storage/emulated/0/Download"
MODE="${1:-manual}"
BIGMAX="2147483647"

choose_download() {
  for d in "$DOWNLOAD" "$ALT_DOWNLOAD"; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return 0; fi
  done
  echo "$ALT_DOWNLOAD"
}

DL="$(choose_download)"
mkdir -p "$CONFIG_DIR" "$DL" 2>/dev/null || true
TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
STATE="$CONFIG_DIR/zram-100p.state"
BACKUP="$CONFIG_DIR/zram-100p-backup-$TS.txt"
LOG="$DL/pixel_thermal_zram_100p_${TS}.txt"

prop_get() { getprop "$1" 2>/dev/null || true; }
prop_set() {
  k="$1"; v="$2"
  if command -v resetprop >/dev/null 2>&1; then
    resetprop -n "$k" "$v" >/dev/null 2>&1 || setprop "$k" "$v" 2>/dev/null || true
  elif [ -x /data/adb/ksu/bin/resetprop ]; then
    /data/adb/ksu/bin/resetprop -n "$k" "$v" >/dev/null 2>&1 || setprop "$k" "$v" 2>/dev/null || true
  elif [ -x /data/adb/magisk/resetprop ]; then
    /data/adb/magisk/resetprop -n "$k" "$v" >/dev/null 2>&1 || setprop "$k" "$v" 2>/dev/null || true
  else
    setprop "$k" "$v" 2>/dev/null || true
  fi
}

keys='mm.zram.maintenance.first_delay_seconds mm.zram.maintenance.periodic_delay_seconds mmd.zram.writeback.max_idle_seconds mmd.zram.comp_algorithm mmd.zram.enabled mmd.zram.size vendor.zram.size persist.device_config.vendor_system_native_boot.zram_size persist.vendor.boot.zram.size'

{
  echo "debug_type=pixel_thermal_zram_100p_apply"
  echo "time=$(date -Is 2>/dev/null || date)"
  echo "mode=$MODE"
  echo "module=$MODDIR"
  echo "config=$CONFIG_FILE"
  echo
  echo "== before props =="
  for k in $keys; do echo "$k=$(prop_get "$k")"; done
  echo
  echo "== fstab presence =="
  for f in "$MODDIR/system/vendor/etc/fstab.zram.100p" /vendor/etc/fstab.zram.100p; do
    echo "-- $f"
    if [ -r "$f" ]; then ls -l "$f"; cat "$f"; else echo absent; fi
  done
  echo
  echo "== mmd before =="
  pidof mmd 2>/dev/null || true
  echo
  echo "== swaps before =="
  cat /proc/swaps 2>/dev/null || true
} > "$LOG" 2>&1

if [ ! -f "$STATE" ]; then
  {
    echo "backup_time=$(date -Is 2>/dev/null || date)"
    for k in $keys; do echo "$k=$(prop_get "$k")"; done
  } > "$BACKUP" 2>/dev/null || true
  echo "backup_file=$BACKUP" > "$STATE"
fi

prop_set mm.zram.maintenance.first_delay_seconds "$BIGMAX"
prop_set mm.zram.maintenance.periodic_delay_seconds "$BIGMAX"
prop_set mmd.zram.writeback.max_idle_seconds "$BIGMAX"
prop_set mmd.zram.comp_algorithm "lz77eh"
prop_set mmd.zram.enabled "true"
prop_set mmd.zram.size "100%"
prop_set vendor.zram.size "100p"
prop_set persist.device_config.vendor_system_native_boot.zram_size "100p"
prop_set persist.vendor.boot.zram.size "100p"

restart_requested="${ZRAM_RESTART_MMD:-1}"
if [ "$restart_requested" = "1" ]; then
  {
    echo
    echo "== mmd restart =="
    echo "restart_model=stop_then_start"
    if command -v stop >/dev/null 2>&1; then
      stop mmd 2>/dev/null || setprop ctl.stop mmd 2>/dev/null || true
    else
      setprop ctl.stop mmd 2>/dev/null || true
    fi
    sleep 1
    if command -v start >/dev/null 2>&1; then
      start mmd 2>/dev/null || setprop ctl.start mmd 2>/dev/null || true
    else
      setprop ctl.start mmd 2>/dev/null || true
    fi
    sleep 3
  } >> "$LOG" 2>&1
fi

{
  echo
  echo "== after props =="
  for k in $keys; do echo "$k=$(prop_get "$k")"; done
  echo
  echo "== mmd after =="
  pidof mmd 2>/dev/null || true
  echo
  echo "== swaps after =="
  cat /proc/swaps 2>/dev/null || true
  echo
  echo "== zram sysfs =="
  for f in /sys/block/zram0/disksize /sys/block/zram0/comp_algorithm /sys/block/zram0/backing_dev /sys/block/zram0/mm_stat; do
    echo "-- $f"
    cat "$f" 2>/dev/null || true
  done
  echo
  echo "RESULT: PIXEL_THERMAL_ZRAM_100P_APPLY_DONE"
} >> "$LOG" 2>&1

cat "$LOG"
