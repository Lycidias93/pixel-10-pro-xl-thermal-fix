#!/system/bin/sh
# Pixel 10 Thermal & Memory Control - consolidated ZRAM 100% and optional LMKD reload helper.
# lz77eh hardware acceleration remains independent from the optional Emerald Hill lock.
set -eu

ID="pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
MODE="${1:-manual}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
RESET="$MODDIR/tools/resetprop-rs"
SYSTEM_RESETPROP="${LMKD_SYSTEM_RESETPROP_BIN:-resetprop}"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
BIGMAX="2147483647"
GETPROP_BIN="${LMKD_GETPROP_BIN:-getprop}"
SETPROP_BIN="${LMKD_SETPROP_BIN:-setprop}"
PIDOF_BIN="${LMKD_PIDOF_BIN:-pidof}"
STOP_BIN="${LMKD_STOP_BIN:-stop}"
START_BIN="${LMKD_START_BIN:-start}"
SLEEP_BIN="${LMKD_SLEEP_BIN:-sleep}"
STATE_DIR="${CONFIG_FILE%/*}"
LMKD_STATE_FILE="$STATE_DIR/lmkd-reload.env"
OLD_LMKD_EVIDENCE="$STATE_DIR/lmkd-test/early-swap-low.env"
BOOT_ID_FILE="${LMKD_BOOT_ID_FILE:-/proc/sys/kernel/random/boot_id}"
UPTIME_FILE="${LMKD_UPTIME_FILE:-/proc/uptime}"

[ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >/dev/null 2>&1 || true
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" 2>/dev/null || true

DEBUG="${DEBUG_MODE:-${debug_mode:-0}}"
RESTART="${ZRAM_RESTART_MMD:-1}"
SWAPPINESS="${ZRAM_SWAPPINESS:-100}"
THP_MODE="${ZRAM_THP_MODE:-stock}"
LMKD_RELOAD="${LMKD_SWAP_LOW_RELOAD:-0}"
LMKD_ACK="${LMKD_SWAP_LOW_RISK_ACK:-none}"
LMKD_PROPERTY_WRITER=none

log() { printf '%s\n' "$*"; }

cfg_get() {
  key="$1"
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

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

prop_get() { "$GETPROP_BIN" "$1" 2>/dev/null || true; }
lmkd_pid() { "$PIDOF_BIN" lmkd 2>/dev/null | awk '{print $1}' || true; }
lmkd_service() { prop_get init.svc.lmkd; }
boot_id() { cat "$BOOT_ID_FILE" 2>/dev/null || printf unknown; }
uptime_ms() { awk '{printf "%d\n", $1 * 1000}' "$UPTIME_FILE" 2>/dev/null || printf 0; }
kv_get() {
  key="$1"; file="$2"
  [ -r "$file" ] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n 1 | sed "s/^${key}=//" | tr -d '\r'
}

write_lmkd_state() {
  result="$1"; method="$2"; before="$3"; after="$4"; pid_before="$5"; pid_after="$6"; svc_before="$7"; svc_after="$8"; detail="$9"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  tmp="$LMKD_STATE_FILE.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-lmkd-reload-v2'
    printf 'boot_id=%s\n' "$(boot_id)"
    printf 'epoch=%s\n' "$(date +%s 2>/dev/null || printf unknown)"
    printf 'uptime_ms=%s\n' "$(uptime_ms)"
    printf 'mode=%s\n' "$MODE"
    printf '%s\n' 'requested_property=ro.lmk.swap_free_low_percentage'
    printf '%s\n' 'requested_value=1'
    printf 'config_enabled=%s\n' "$LMKD_RELOAD"
    printf 'risk_ack=%s\n' "$LMKD_ACK"
    printf 'property_before=%s\n' "${before:-unset}"
    printf 'property_after=%s\n' "${after:-unset}"
    printf 'property_writer=%s\n' "${LMKD_PROPERTY_WRITER:-none}"
    printf 'lmkd_pid_before=%s\n' "${pid_before:-none}"
    printf 'lmkd_pid_after=%s\n' "${pid_after:-none}"
    printf 'lmkd_service_before=%s\n' "${svc_before:-unknown}"
    printf 'lmkd_service_after=%s\n' "${svc_after:-unknown}"
    printf 'reload_method=%s\n' "$method"
    printf 'reload_result=%s\n' "$result"
    printf '%s\n' 'aosp_contract=update_props_on_reinit_or_process_start'
    printf '%s\n' 'direct_internal_value_probe=no'
    printf 'detail=%s\n' "$detail"
  } > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$LMKD_STATE_FILE"
}

remember_original_lmkd_value() {
  original="$(cfg_get LMKD_SWAP_LOW_ORIGINAL_VALUE)"
  if [ -n "$original" ]; then return 0; fi
  before="$1"
  old_before="$(kv_get property_before "$OLD_LMKD_EVIDENCE")"
  case "$old_before" in ''|unset|1) ;; *) original="$old_before" ;; esac
  if [ -z "${original:-}" ]; then
    case "$before" in '') original=__absent__ ;; 1) original=__unknown_reboot_required__ ;; *) original="$before" ;; esac
  fi
  cfg_set LMKD_SWAP_LOW_ORIGINAL_VALUE "$original"
}

wait_reinit_ack () {
  i=0
  while [ "$i" -lt 5 ]; do
    state="$(prop_get lmkd.reinit)"
    [ "$state" != 1 ] && [ "$(lmkd_service)" = running ] && return 0
    "$SLEEP_BIN" 1
    i=$((i + 1))
  done
  return 1
}

wait_restart() {
  old_pid="$1"
  i=0
  while [ "$i" -lt 10 ]; do
    new_pid="$(lmkd_pid)"
    if [ -n "$new_pid" ] && [ "$(lmkd_service)" = running ] && { [ -z "$old_pid" ] || [ "$new_pid" != "$old_pid" ]; }; then
      printf '%s\n' "$new_pid"
      return 0
    fi
    "$SLEEP_BIN" 1
    i=$((i + 1))
  done
  return 1
}

reload_lmkd() {
  before="$1"
  pid_before="$(lmkd_pid)"
  svc_before="$(lmkd_service)"
  method=aosp_reinit
  if "$SETPROP_BIN" lmkd.reinit 1 2>/dev/null && wait_reinit_ack; then
    pid_after="$(lmkd_pid)"
    svc_after="$(lmkd_service)"
    after="$(prop_get ro.lmk.swap_free_low_percentage)"
    write_lmkd_state success "$method" "$before" "$after" "$pid_before" "$pid_after" "$svc_before" "$svc_after" reinit_trigger_acknowledged
    log "LMKD_RELOAD result=success method=$method pid_before=${pid_before:-none} pid_after=${pid_after:-none} property_after=${after:-unset}"
    return 0
  fi

  log 'LMKD_RELOAD reinit=failed_or_unacknowledged fallback=ctl_restart'
  method=ctl_restart
  "$SETPROP_BIN" ctl.restart lmkd 2>/dev/null || {
    "$STOP_BIN" lmkd 2>/dev/null || "$SETPROP_BIN" ctl.stop lmkd 2>/dev/null || true
    "$START_BIN" lmkd 2>/dev/null || "$SETPROP_BIN" ctl.start lmkd 2>/dev/null || true
    method=stop_start_fallback
  }
  if pid_after="$(wait_restart "$pid_before")"; then
    svc_after="$(lmkd_service)"
    after="$(prop_get ro.lmk.swap_free_low_percentage)"
    write_lmkd_state success "$method" "$before" "$after" "$pid_before" "$pid_after" "$svc_before" "$svc_after" process_restarted_and_running
    log "LMKD_RELOAD result=success method=$method pid_before=${pid_before:-none} pid_after=$pid_after property_after=${after:-unset}"
    return 0
  fi

  pid_after="$(lmkd_pid)"
  svc_after="$(lmkd_service)"
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  write_lmkd_state failed "$method" "$before" "$after" "$pid_before" "$pid_after" "$svc_before" "$svc_after" daemon_reload_not_verified
  log "LMKD_RELOAD result=failed method=$method service_after=${svc_after:-unknown} pid_after=${pid_after:-none}"
  return 1
}

set_lmkd_property_1() {
  LMKD_PROPERTY_WRITER=none
  if command -v "$SYSTEM_RESETPROP" >/dev/null 2>&1; then
    "$SYSTEM_RESETPROP" ro.lmk.swap_free_low_percentage 1 >/dev/null 2>&1 || true
    if [ "$(prop_get ro.lmk.swap_free_low_percentage)" = 1 ]; then
      LMKD_PROPERTY_WRITER=magisk_resetprop
      return 0
    fi
  fi

  "$RESET" -n ro.lmk.swap_free_low_percentage 1 >/dev/null 2>&1 || true
  if [ "$(prop_get ro.lmk.swap_free_low_percentage)" = 1 ]; then
    LMKD_PROPERTY_WRITER=resetprop_rs_fallback
    return 0
  fi
  return 1
}

apply_lmkd_policy() {
  before="$(prop_get ro.lmk.swap_free_low_percentage)"
  if [ "$LMKD_RELOAD" != 1 ] || [ "$LMKD_ACK" != explicit_user_reload ]; then
    write_lmkd_state disabled none "$before" "$before" "$(lmkd_pid)" "$(lmkd_pid)" "$(lmkd_service)" "$(lmkd_service)" stock_policy_selected
    log "ZRAM_LMK_SWAP_LOW policy=stock_unmodified actual=${before:-unset} reload=disabled"
    return 0
  fi

  remember_original_lmkd_value "$before"
  if ! set_lmkd_property_1; then
    after="$(prop_get ro.lmk.swap_free_low_percentage)"
    write_lmkd_state failed property_readback "$before" "$after" "$(lmkd_pid)" "$(lmkd_pid)" "$(lmkd_service)" "$(lmkd_service)" both_property_writers_failed_readback
    return 1
  fi
  after="$(prop_get ro.lmk.swap_free_low_percentage)"
  log "LMKD_PROPERTY_WRITE result=success writer=$LMKD_PROPERTY_WRITER property_after=$after"

  if [ "$MODE" = boot_verified ] && [ "$(kv_get boot_id "$LMKD_STATE_FILE")" = "$(boot_id)" ] && [ "$(kv_get reload_result "$LMKD_STATE_FILE")" = success ]; then
    log 'LMKD_RELOAD result=skipped method=already_verified_this_boot mode=boot_verified'
    return 0
  fi
  reload_lmkd "$before"
}

restore_lmkd_policy() {
  before="$(prop_get ro.lmk.swap_free_low_percentage)"
  original="$(cfg_get LMKD_SWAP_LOW_ORIGINAL_VALUE)"
  case "$original" in
    ''|__unknown_reboot_required__)
      write_lmkd_state restore_deferred reboot "$before" "$before" "$(lmkd_pid)" "$(lmkd_pid)" "$(lmkd_service)" "$(lmkd_service)" original_unknown_reboot_restores_stock
      log 'LMKD_RESTORE result=reboot_required reason=original_unknown'
      return 0
    ;;
    __absent__)
      "$RESET" -d ro.lmk.swap_free_low_percentage || return 1
    ;;
    *)
      "$RESET" -n ro.lmk.swap_free_low_percentage "$original" || return 1
    ;;
  esac
  reload_lmkd "$before"
}

log "=== Apply ZRAM Start ==="
log "time=$(date -Is 2>/dev/null || date)"
log "mode=$MODE"
log "debug=$DEBUG"
log "restart_mmd=$RESTART"
log "swappiness=$SWAPPINESS"
log "thp_mode=$THP_MODE"
log "lmkd_reload=$LMKD_RELOAD"

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
  if [ "$DEBUG" = 1 ]; then log "set $key=$val"; fi
}

prop_del() {
  key="$1"
  if [ -x "$SYSTEM_RESETPROP" ] || command -v "$SYSTEM_RESETPROP" >/dev/null 2>&1; then
    "$SYSTEM_RESETPROP" -d "$key" >/dev/null 2>&1 || true
  fi
  if [ -x "$RESET" ]; then
    "$RESET" -d "$key" >/dev/null 2>&1 || true
  fi
  if [ "$DEBUG" = 1 ]; then log "del $key"; fi
}

restore_zram_properties() {
  prop_del mm.zram.maintenance.first_delay_seconds
  prop_del mm.zram.maintenance.periodic_delay_seconds
  prop_del mmd.zram.writeback.max_idle_seconds
  prop_del mmd.zram.comp_algorithm
  prop_del mmd.zram.enabled
  prop_del mmd.zram.size
  prop_del vendor.zram.size
  prop_del persist.device_config.vendor_system_native_boot.zram_size
  prop_del persist.vendor.boot.zram.size
  if [ -r "$EH_CONTROL" ]; then
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  fi
}

case "$SWAPPINESS" in
  ''|*[!0-9]*) SWAPPINESS=100 ;;
  *) [ "$SWAPPINESS" -le 200 ] 2>/dev/null || SWAPPINESS=100 ;;
esac
case "$THP_MODE" in stock|always|madvise|never) ;; *) THP_MODE=stock ;; esac

if [ "$MODE" = lmkd_restore ]; then
  restore_lmkd_policy
  log 'RESULT: ZRAM_APPLY_DONE mode=lmkd_restore backup_state=runtime_only'
  exit 0
fi

if [ "$MODE" = restore ] || [ "$MODE" = disable ]; then
  restore_zram_properties
  log 'RESULT: ZRAM_APPLY_DONE mode=restore properties_cleared=yes eh=adaptive'
  exit 0
fi

prop_set mm.zram.maintenance.first_delay_seconds "$BIGMAX"
prop_set mm.zram.maintenance.periodic_delay_seconds "$BIGMAX"
prop_set mmd.zram.writeback.max_idle_seconds "$BIGMAX"
prop_set mmd.zram.comp_algorithm lz77eh
prop_set mmd.zram.enabled true
prop_set mmd.zram.size 100%
prop_set vendor.zram.size 100p
prop_set persist.device_config.vendor_system_native_boot.zram_size 100p
prop_set persist.vendor.boot.zram.size 100p

lmkd_result=stock
if apply_lmkd_policy; then
  [ "$LMKD_RELOAD" = 1 ] && [ "$LMKD_ACK" = explicit_user_reload ] && lmkd_result=reload_verified || true
else
  lmkd_result=reload_failed_nonfatal
fi

sysctl -w "vm.swappiness=$SWAPPINESS" >/dev/null 2>&1 || prop_set vm.swappiness "$SWAPPINESS"

if [ "$THP_MODE" != stock ] && [ -d /sys/kernel/mm/transparent_hugepage ]; then
  printf '%s\n' "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
  case "$THP_MODE" in
    always|madvise|never) printf '%s\n' "$THP_MODE" > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true ;;
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
  if [ "${ZRAM_EMERALD_OC:-0}" = 1 ] && [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] && [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] && [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then
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

log "RESULT: ZRAM_APPLY_DONE mode=$MODE restart_policy=manual_only swappiness=$SWAPPINESS thp=$THP_MODE eh_state=$eh_state lmkd_result=$lmkd_result backup_state=runtime_only"
exit 0
