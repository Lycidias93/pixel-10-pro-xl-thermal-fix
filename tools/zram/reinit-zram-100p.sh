#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - guarded manual ZRAM 100p reinit helper.
# Disabled by default. Requires explicit command argument and config ACK.
set -eu

ID="pixel-10-pro-xl-thermal-fix"
LOG="/sdcard/Download/pixel_thermal_zram_reinit_$(date +%Y%m%d_%H%M%S).txt"
CONFIG="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
ZRAM_DEV="/dev/block/zram0"
ZRAM_SYS="/sys/block/zram0"
BIGMAX="2147483647"

cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "${CONFIG%/*}" 2>/dev/null || true
  touch "$CONFIG" 2>/dev/null || true
  tmp="$CONFIG.tmp.$$"
  grep -v "^${key}=" "$CONFIG" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG"
}

main() {
  printf '%s\n' 'debug_type=pixel_thermal_zram_reinit'
  printf 'time=%s\n' "$(date -Iseconds 2>/dev/null || date)"
  printf 'config=%s\n\n' "$CONFIG"

  if [ "${1:-}" != --i-understand-risk ]; then
    printf '%s\n' 'REFUSED: missing command ack --i-understand-risk'
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED missing_command_ack'
    return 2
  fi

  [ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG" sh "$NORMALIZE" >/dev/null 2>&1 || true
  if [ -r "$CONFIG" ]; then
    . "$CONFIG"
  fi

  printf '%s\n' '== config =='
  printf 'ENABLE_ZRAM_100P=%s\n' "${ENABLE_ZRAM_100P:-unset}"
  printf 'ZRAM_REINIT_ACK=%s\n' "${ZRAM_REINIT_ACK:-unset}"
  printf 'ZRAM_REINIT_MAX_SWAP_USED_KB=%s\n' "${ZRAM_REINIT_MAX_SWAP_USED_KB:-524288}"
  printf 'ZRAM_REINIT_SIZE_KB=%s\n' "${ZRAM_REINIT_SIZE_KB:-MemTotal}"
  printf 'ZRAM_SWAPPINESS=%s\n' "${ZRAM_SWAPPINESS:-100}"
  printf 'ZRAM_THP_MODE=%s\n' "${ZRAM_THP_MODE:-stock}"
  printf 'ZRAM_EMERALD_OC=%s\n\n' "${ZRAM_EMERALD_OC:-0}"

  if [ "${ENABLE_ZRAM_100P:-0}" != 1 ]; then
    printf '%s\n' 'REFUSED: ENABLE_ZRAM_100P is not 1'
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED zram_100p_not_enabled'
    return 3
  fi
  if [ "${ZRAM_REINIT_ACK:-}" != I_UNDERSTAND_ZRAM_SWAPOFF_RISK ]; then
    printf 'REFUSED: set ZRAM_REINIT_ACK=I_UNDERSTAND_ZRAM_SWAPOFF_RISK in %s\n' "$CONFIG"
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED missing_config_ack'
    return 4
  fi
  if [ ! -b "$ZRAM_DEV" ]; then
    printf 'REFUSED: %s is not a block device\n' "$ZRAM_DEV"
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED zram_block_missing'
    return 5
  fi

  mem_total_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
  mem_available_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
  swap_total_kb="$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)"
  swap_free_kb="$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)"
  swap_used_kb=$((swap_total_kb - swap_free_kb))
  max_swap_used_kb="${ZRAM_REINIT_MAX_SWAP_USED_KB:-524288}"

  printf '%s\n' '== safety =='
  printf 'MemTotal_kB=%s\n' "$mem_total_kb"
  printf 'MemAvailable_kB=%s\n' "$mem_available_kb"
  printf 'SwapTotal_kB=%s\n' "$swap_total_kb"
  printf 'SwapFree_kB=%s\n' "$swap_free_kb"
  printf 'SwapUsed_kB=%s\n' "$swap_used_kb"
  printf 'MaxSwapUsed_kB=%s\n\n' "$max_swap_used_kb"

  if [ "$swap_used_kb" -gt "$max_swap_used_kb" ]; then
    printf '%s\n' 'REFUSED: SwapUsed_kB is above safety threshold'
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_REFUSED swap_used_too_high'
    return 6
  fi

  if [ -z "${ZRAM_REINIT_SIZE_KB:-}" ]; then
    target_kb="$mem_total_kb"
  else
    target_kb="$ZRAM_REINIT_SIZE_KB"
  fi
  case "$target_kb" in ''|*[!0-9]*) target_kb="$mem_total_kb" ;; esac
  target_bytes=$((target_kb * 1024))

  printf '%s\n' '== before =='
  cat /proc/swaps || true
  printf 'disksize=%s\n' "$(cat "$ZRAM_SYS/disksize" 2>/dev/null || echo unknown)"
  printf 'comp_algorithm=%s\n\n' "$(cat "$ZRAM_SYS/comp_algorithm" 2>/dev/null || echo unknown)"

  printf '%s\n' '== set props =='
  if [ -x "$MODDIR/tools/resetprop-rs" ]; then
    "$MODDIR/tools/resetprop-rs" -n mm.zram.maintenance.first_delay_seconds "$BIGMAX" || true
    "$MODDIR/tools/resetprop-rs" -n mm.zram.maintenance.periodic_delay_seconds "$BIGMAX" || true
    "$MODDIR/tools/resetprop-rs" -n mmd.zram.writeback.max_idle_seconds "$BIGMAX" || true
    "$MODDIR/tools/resetprop-rs" -n mmd.zram.comp_algorithm lz77eh || true
    "$MODDIR/tools/resetprop-rs" -n mmd.zram.enabled true || true
    "$MODDIR/tools/resetprop-rs" -n mmd.zram.size 100% || true
    "$MODDIR/tools/resetprop-rs" -n vendor.zram.size 100p || true
    "$MODDIR/tools/resetprop-rs" -n persist.device_config.vendor_system_native_boot.zram_size 100p || true
    "$MODDIR/tools/resetprop-rs" -n persist.vendor.boot.zram.size 100p || true
  else
    setprop mm.zram.maintenance.first_delay_seconds "$BIGMAX"
    setprop mm.zram.maintenance.periodic_delay_seconds "$BIGMAX"
    setprop mmd.zram.writeback.max_idle_seconds "$BIGMAX"
    setprop mmd.zram.comp_algorithm lz77eh
    setprop mmd.zram.enabled true
    setprop mmd.zram.size 100%
    setprop vendor.zram.size 100p
    setprop persist.device_config.vendor_system_native_boot.zram_size 100p
    setprop persist.vendor.boot.zram.size 100p
  fi
  printf '%s\n' 'lmk_swap_low_policy=stock_unmodified'

  swappiness="${ZRAM_SWAPPINESS:-100}"
  case "$swappiness" in ''|*[!0-9]*) swappiness=100 ;; *) [ "$swappiness" -le 200 ] 2>/dev/null || swappiness=100 ;; esac
  sysctl -w "vm.swappiness=$swappiness" 2>/dev/null || setprop vm.swappiness "$swappiness"

  thp_mode="${ZRAM_THP_MODE:-stock}"
  case "$thp_mode" in stock|always|madvise|never) ;; *) thp_mode=stock ;; esac
  if [ "$thp_mode" != stock ] && [ -d /sys/kernel/mm/transparent_hugepage ]; then
    printf '%s\n' "$thp_mode" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    printf '%s\n' "$thp_mode" > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true
  fi

  printf 'target_kB=%s\n' "$target_kb"
  printf 'target_bytes=%s\n\n' "$target_bytes"

  printf '%s\n' '== reinit =='
  printf '%s\n' 'stopping mmd'
  stop mmd 2>/dev/null || true
  sleep 1
  printf 'swapoff %s\n' "$ZRAM_DEV"
  if ! swapoff "$ZRAM_DEV"; then
    printf '%s\n' 'FAILED: swapoff failed; trying to restart mmd'
    start mmd 2>/dev/null || true
    printf '%s\n' 'RESULT: PIXEL_THERMAL_ZRAM_REINIT_FAILED swapoff_failed'
    return 7
  fi

  printf '1\n' > "$ZRAM_SYS/reset" 2>/dev/null || true
  printf 'lz77eh\n' > "$ZRAM_SYS/comp_algorithm" 2>/dev/null || true
  printf '%s\n' "$target_bytes" > "$ZRAM_SYS/disksize"
  mkswap "$ZRAM_DEV"
  swapon "$ZRAM_DEV"
  printf '%s\n' 'starting mmd'
  start mmd 2>/dev/null || true
  sleep 2

  eh_state=adaptive
  if [ -r "$EH_CONTROL" ] &&
     [ "${ZRAM_EMERALD_OC:-0}" = 1 ] &&
     [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] &&
     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] &&
     [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG" sh "$EH_CONTROL" apply; then
      eh_state=max_frequency_lock_active
    else
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set LAST_ZRAM_100P enabled_standard
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      eh_state=max_frequency_lock_failed_fallback_adaptive
    fi
  elif [ -r "$EH_CONTROL" ]; then
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  fi

  printf '\n%s\n' '== after =='
  cat /proc/swaps || true
  printf 'disksize=%s\n' "$(cat "$ZRAM_SYS/disksize" 2>/dev/null || echo unknown)"
  printf 'comp_algorithm=%s\n' "$(cat "$ZRAM_SYS/comp_algorithm" 2>/dev/null || echo unknown)"
  cat "$ZRAM_SYS/mm_stat" 2>/dev/null || true
  printf '\nRESULT: PIXEL_THERMAL_ZRAM_REINIT_DONE eh_state=%s swappiness=%s thp=%s\n' "$eh_state" "$swappiness" "$thp_mode"
}

main "$@" > "$LOG" 2>&1
rc="$?"
cat "$LOG"
exit "$rc"
