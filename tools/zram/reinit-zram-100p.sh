#!/system/bin/sh
# Pixel 10 Thermal Polling Fix - guarded manual ZRAM 100p reinit helper.
# Disabled by default. Requires explicit command argument and config ACK.

LOG="/sdcard/Download/pixel_thermal_zram_reinit_$(date +%Y%m%d_%H%M%S).txt"
CONFIG="/data/adb/pixel-10-pro-xl-thermal-fix/config.env"
ZRAM_DEV="/dev/block/zram0"
ZRAM_SYS="/sys/block/zram0"

main() {
  echo "debug_type=pixel_thermal_zram_reinit"
  echo "time=$(date -Iseconds 2>/dev/null || date)"
  echo "config=$CONFIG"
  echo

  if [ "${1:-}" != "--i-understand-risk" ]; then
    echo "REFUSED: missing command ack --i-understand-risk"
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED missing_command_ack"
    return 2
  fi

  if [ -r "$CONFIG" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG"
  fi

  echo "== config =="
  echo "ENABLE_ZRAM_100P=${ENABLE_ZRAM_100P:-unset}"
  echo "ZRAM_REINIT_ACK=${ZRAM_REINIT_ACK:-unset}"
  echo "ZRAM_REINIT_MAX_SWAP_USED_KB=${ZRAM_REINIT_MAX_SWAP_USED_KB:-524288}"
  echo "ZRAM_REINIT_SIZE_KB=${ZRAM_REINIT_SIZE_KB:-MemTotal}"
  echo

  if [ "${ENABLE_ZRAM_100P:-0}" != "1" ]; then
    echo "REFUSED: ENABLE_ZRAM_100P is not 1"
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED zram_100p_not_enabled"
    return 3
  fi
  if [ "${ZRAM_REINIT_ACK:-}" != "I_UNDERSTAND_ZRAM_SWAPOFF_RISK" ]; then
    echo "REFUSED: set ZRAM_REINIT_ACK=I_UNDERSTAND_ZRAM_SWAPOFF_RISK in $CONFIG"
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED missing_config_ack"
    return 4
  fi
  if [ ! -b "$ZRAM_DEV" ]; then
    echo "REFUSED: $ZRAM_DEV is not a block device"
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED zram_block_missing"
    return 5
  fi

  mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  mem_available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  swap_total_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
  swap_free_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
  swap_used_kb=$((swap_total_kb - swap_free_kb))
  max_swap_used_kb=${ZRAM_REINIT_MAX_SWAP_USED_KB:-524288}

  echo "== safety =="
  echo "MemTotal_kB=$mem_total_kb"
  echo "MemAvailable_kB=$mem_available_kb"
  echo "SwapTotal_kB=$swap_total_kb"
  echo "SwapFree_kB=$swap_free_kb"
  echo "SwapUsed_kB=$swap_used_kb"
  echo "MaxSwapUsed_kB=$max_swap_used_kb"
  echo

  if [ "$swap_used_kb" -gt "$max_swap_used_kb" ]; then
    echo "REFUSED: SwapUsed_kB is above safety threshold"
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED swap_used_too_high"
    return 6
  fi

  if [ "${ZRAM_REINIT_SIZE_KB:-}" = "" ]; then
    target_kb=$mem_total_kb
  else
    target_kb=${ZRAM_REINIT_SIZE_KB}
  fi
  target_bytes=$((target_kb * 1024))

  echo "== before =="
  cat /proc/swaps || true
  echo "disksize=$(cat "$ZRAM_SYS/disksize" 2>/dev/null || echo unknown)"
  echo "comp_algorithm=$(cat "$ZRAM_SYS/comp_algorithm" 2>/dev/null || echo unknown)"
  echo

  echo "== set props =="
  setprop mm.zram.maintenance.first_delay_seconds 2147483647
  setprop mm.zram.maintenance.periodic_delay_seconds 2147483647
  setprop mmd.zram.writeback.max_idle_seconds 2147483647
  setprop mmd.zram.comp_algorithm lz77eh
  setprop mmd.zram.enabled true
  setprop mmd.zram.size 100%
  setprop vendor.zram.size 100p
  setprop persist.device_config.vendor_system_native_boot.zram_size 100p
  setprop persist.vendor.boot.zram.size 100p
  echo "target_kB=$target_kb"
  echo "target_bytes=$target_bytes"
  echo

  echo "== reinit =="
  echo "stopping mmd"
  stop mmd 2>/dev/null || true
  sleep 1
  echo "swapoff $ZRAM_DEV"
  if ! swapoff "$ZRAM_DEV"; then
    echo "FAILED: swapoff failed; trying to restart mmd"
    start mmd 2>/dev/null || true
    echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_FAILED swapoff_failed"
    return 7
  fi
  echo 1 > "$ZRAM_SYS/reset" 2>/dev/null || true
  echo lz77eh > "$ZRAM_SYS/comp_algorithm" 2>/dev/null || true
  echo "$target_bytes" > "$ZRAM_SYS/disksize"
  mkswap "$ZRAM_DEV"
  swapon "$ZRAM_DEV"
  echo "starting mmd"
  start mmd 2>/dev/null || true
  sleep 2
  echo

  echo "== after =="
  cat /proc/swaps || true
  echo "disksize=$(cat "$ZRAM_SYS/disksize" 2>/dev/null || echo unknown)"
  echo "comp_algorithm=$(cat "$ZRAM_SYS/comp_algorithm" 2>/dev/null || echo unknown)"
  cat "$ZRAM_SYS/mm_stat" 2>/dev/null || true
  echo
  echo "RESULT: PIXEL_THERMAL_ZRAM_REINIT_DONE"
}

main "$@" > "$LOG" 2>&1
rc=$?
cat "$LOG"
exit "$rc"
