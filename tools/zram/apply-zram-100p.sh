#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - ZRAM 100% apply helper.
# In-memory resetprop-rs -n props; mmd restart only outside boot_early.

CONFIG_FILE="/data/adb/pixel-10-pro-xl-thermal-fix/config.env"
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" 2>/dev/null || true

MODE="${1:-manual}"
MODDIR="${MODDIR:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
RESET="$MODDIR/tools/resetprop-rs"
DEBUG="${DEBUG_MODE:-${debug_mode:-0}}"
RESTART="${ZRAM_RESTART_MMD:-1}"
BIGMAX="2147483647"

log() { echo "$*"; }

log "=== Apply ZRAM Start ==="
log "time=$(date -Is 2>/dev/null || date)"
log "mode=$MODE"
log "debug=$DEBUG"
log "restart_mmd=$RESTART"

if [ ! -x "$RESET" ]; then
  log "RESULT: ZRAM_APPLY_FAIL reason=resetprop_rs_missing_or_not_executable path=$RESET"
  exit 2
fi

prop_set() {
  key="$1"
  val="$2"
  "$RESET" -n "$key" "$val" || {
    log "RESULT: ZRAM_APPLY_FAIL reason=resetprop_failed key=$key"
    exit 3
  }
  [ "$DEBUG" = "1" ] && log "set $key=$val"
}

prop_set mm.zram.maintenance.first_delay_seconds "$BIGMAX"
prop_set mm.zram.maintenance.periodic_delay_seconds "$BIGMAX"
prop_set mmd.zram.writeback.max_idle_seconds "$BIGMAX"
prop_set mmd.zram.comp_algorithm lz77eh
prop_set mmd.zram.enabled true
prop_set mmd.zram.size 100%
prop_set vendor.zram.size 100p
prop_set persist.device_config.vendor_system_native_boot.zram_size 100p
prop_set persist.vendor.boot.zram.size 100p
prop_set ro.lmk.swap_free_low_percentage 1

# Hardware-accelerated swappiness, THP, and Emerald Hill 1 GHz clock boost
sysctl -w vm.swappiness=100 2>/dev/null || prop_set vm.swappiness 100
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
  echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
  echo within_size > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true
fi

for eh_dir in /sys/class/devfreq/*eh* /sys/devices/platform/*.eh/devfreq/*; do
  if [ -d "$eh_dir" ] && [ -w "$eh_dir/min_freq" ] && [ -r "$eh_dir/max_freq" ]; then
    max_f="$(cat "$eh_dir/max_freq" 2>/dev/null)"
    if [ -n "$max_f" ]; then
      echo "$max_f" > "$eh_dir/min_freq" 2>/dev/null || true
      [ "$DEBUG" = "1" ] && log "set $eh_dir/min_freq=$max_f"
    fi
  fi
done

if [ "$RESTART" = "1" ] && [ "$MODE" != "boot_early" ]; then
  log "mmd_restart=requested"
  stop mmd 2>/dev/null || setprop ctl.stop mmd 2>/dev/null || true
  start mmd 2>/dev/null || setprop ctl.start mmd 2>/dev/null || true
else
  log "mmd_restart=skipped mode=$MODE"
fi

if [ "$DEBUG" = "1" ] || [ "$MODE" != "boot_early" ]; then
  log "== active swaps =="
  cat /proc/swaps 2>/dev/null || true
  log "== zram info =="
  for f in disksize comp_algorithm mm_stat; do
    [ -r "/sys/block/zram0/$f" ] && log "zram0/$f: $(cat "/sys/block/zram0/$f")"
  done
fi

log "RESULT: ZRAM_APPLY_DONE mode=$MODE restart_policy=outside_boot_early resetprop=resetprop-rs_-n backup_state=none"
exit 0
