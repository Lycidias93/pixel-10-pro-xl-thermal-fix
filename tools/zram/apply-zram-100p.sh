#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - ZRAM 100% apply helper.
# lz77eh hardware acceleration remains independent from the optional
# Emerald Hill maximum-frequency minimum lock.
set -eu

ID="pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
MODE="${1:-manual}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
RESET="$MODDIR/tools/resetprop-rs"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
BIGMAX="2147483647"

[ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >/dev/null 2>&1 || true
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" 2>/dev/null || true

DEBUG="${DEBUG_MODE:-${debug_mode:-0}}"
RESTART="${ZRAM_RESTART_MMD:-1}"
SWAPPINESS="${ZRAM_SWAPPINESS:-100}"
THP_MODE="${ZRAM_THP_MODE:-stock}"

log() { printf '%s\n' "$*"; }

cfg_set() {
  key="$1"
  value="$2"
  mkdir -p "${CONFIG_FILE%/*}" 2>/dev/null || true
  touch "$CONFIG_FILE" 2>/dev/null || true
  tmp="$CONFIG_FILE.tmp.$$"
  grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CONFIG_FILE"
}

log "=== Apply ZRAM Start ==="
log "time=$(date -Is 2>/dev/null || date)"
log "mode=$MODE"
log "debug=$DEBUG"
log "restart_mmd=$RESTART"
log "swappiness=$SWAPPINESS"
log "thp_mode=$THP_MODE"

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
  [ "$DEBUG" = 1 ] && log "set $key=$val"
}

case "$SWAPPINESS" in
  ''|*[!0-9]*) SWAPPINESS=100 ;;
  *) [ "$SWAPPINESS" -le 200 ] 2>/dev/null || SWAPPINESS=100 ;;
esac
case "$THP_MODE" in stock|always|madvise|never) ;; *) THP_MODE=stock ;; esac

# Runtime-only ZRAM properties. LMKD policy remains owned by the platform because
# a late ro.lmk override is not proven to be consumed without an explicit LMKD
# property reload.
prop_set mm.zram.maintenance.first_delay_seconds "$BIGMAX"
prop_set mm.zram.maintenance.periodic_delay_seconds "$BIGMAX"
prop_set mmd.zram.writeback.max_idle_seconds "$BIGMAX"
prop_set mmd.zram.comp_algorithm lz77eh
prop_set mmd.zram.enabled true
prop_set mmd.zram.size 100%
prop_set vendor.zram.size 100p
prop_set persist.device_config.vendor_system_native_boot.zram_size 100p
prop_set persist.vendor.boot.zram.size 100p
lmk_swap_low_actual="$(getprop ro.lmk.swap_free_low_percentage 2>/dev/null || true)"
log "ZRAM_LMK_SWAP_LOW policy=stock_unmodified actual=${lmk_swap_low_actual:-unset}"

sysctl -w "vm.swappiness=$SWAPPINESS" >/dev/null 2>&1 || prop_set vm.swappiness "$SWAPPINESS"

if [ "$THP_MODE" != stock ] && [ -d /sys/kernel/mm/transparent_hugepage ]; then
  printf '%s\n' "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
  case "$THP_MODE" in
    always|madvise|never)
      printf '%s\n' "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true
    ;;
  esac
fi

if [ "$RESTART" = 1 ] && [ "$MODE" != boot_early ] && [ "$MODE" != boot_verified ]; then
  log 'mmd_restart=requested'
  stop mmd 2>/dev/null || setprop ctl.stop mmd 2>/dev/null || true
  start mmd 2>/dev/null || setprop ctl.start mmd 2>/dev/null || true
else
  log "mmd_restart=skipped mode=$MODE"
fi

eh_state=adaptive
if [ "$MODE" = boot_early ]; then
  eh_state=deferred_until_verified_boot
elif [ "$MODE" = boot_verified ]; then
  eh_state=deferred_to_service_post_bootguard
elif [ -r "$EH_CONTROL" ]; then
  if [ "${ZRAM_EMERALD_OC:-0}" = 1 ] &&
     [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] &&
     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] &&
     [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" apply; then
      eh_state=max_frequency_minimum_lock_active
    else
      cfg_set ZRAM_EMERALD_OC 0
      cfg_set ZRAM_EH_RISK_ACK none
      cfg_set LAST_ZRAM_100P enabled_standard
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
      eh_state=max_lock_failed_fallback_adaptive
      log 'ZRAM_EH_FALLBACK=adaptive'
    fi
  else
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  fi
else
  eh_state=helper_missing_adaptive
fi

if [ "$DEBUG" = 1 ] || [ "$MODE" != boot_early ]; then
  log '== active swaps =='
  cat /proc/swaps 2>/dev/null || true
  log '== zram info =='
  for f in disksize comp_algorithm mm_stat; do
    [ -r "/sys/block/zram0/$f" ] && log "zram0/$f: $(cat "/sys/block/zram0/$f")"
  done
fi

log "RESULT: ZRAM_APPLY_DONE mode=$MODE restart_policy=manual_only swappiness=$SWAPPINESS thp=$THP_MODE eh_state=$eh_state lmk_swap_low_policy=stock_unmodified lmk_swap_low_actual=${lmk_swap_low_actual:-unset} backup_state=runtime_only"
exit 0
