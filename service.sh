#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
G="$MODDIR/guard"
L="$G/bootguard.log"
H="$MODDIR/health.log"
CONFIG_FILE="/data/adb/$ID/config.env"
NORMALIZE="$MODDIR/tools/zram/config-normalize.sh"
ZRAM_APPLY="$MODDIR/tools/zram/apply-zram-100p.sh"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
mkdir -p "$G"

printf 'timestamp_start=%s\n' "$(date +%s 2>/dev/null || echo unknown)" > "$H"
printf '%s\n' 'health_log_model=verified_runtime_guard_plus_zram_100p_eh_lmkd_reload_v7' >> "$H"
printf '%s\n' 'lmk_swap_low_policy=resolved_after_config' >> "$H"

[ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >> "$H" 2>&1 || true
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi
if [ "${LMKD_SWAP_LOW_RELOAD:-0}" = 1 ] && [ "${LMKD_SWAP_LOW_RISK_ACK:-}" = explicit_user_reload ]; then
  printf "%s
" "lmk_swap_low_policy=experimental_reload_1pct" >> "$H"
else
  printf "%s
" "lmk_swap_low_policy=stock_unmodified" >> "$H"
fi

# Standard lz77eh ZRAM properties may be prepared early. The optional Emerald
# Hill maximum-frequency minimum lock is deferred until Bootguard verifies the
# completed Android boot and active Thermal runtime.
if [ "${ENABLE_ZRAM_100P:-0}" = 1 ] && [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip eh=deferred lmk=stock\n' "$(date -Is 2>/dev/null || date)" >> "$L"
  if [ -r "$ZRAM_APPLY" ]; then
    sh "$ZRAM_APPLY" boot_early >> "$H" 2>&1 ||
      printf '%s\n' 'SERVICE_ZRAM result=apply_failed_nonfatal' >> "$H"
  else
    printf '%s\n' 'SERVICE_ZRAM result=apply_script_absent' >> "$H"
  fi
else
  printf '%s SERVICE_ZRAM action=skip enabled=%s ack=%s\n' \
    "$(date -Is 2>/dev/null || date)" "${ENABLE_ZRAM_100P:-0}" "${ZRAM_RISK_ACK:-unset}" >> "$L"
fi

printf '%s SERVICE_START action=verified_runtime_health optional_zram_supported=true\n' "$(date -Is 2>/dev/null || date)" >> "$L"
while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ]; do
  sleep 1
done

sleep "${BOOTGUARD_SUCCESS_SETTLE_SECONDS:-30}"

{
  printf 'timestamp_complete=%s\n' "$(date +%s 2>/dev/null || echo unknown)"
  printf 'boot_completed=%s\n' "$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  printf 'boot_id=%s\n' "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
  printf '\n== flags ==\n'
  [ -e "$MODDIR/disable" ] && printf '%s\n' disable=present || printf '%s\n' disable=absent
  [ -e "$MODDIR/skip_mount" ] && printf '%s\n' skip_mount=present || printf '%s\n' skip_mount=absent
  [ -e "$MODDIR/remove" ] && printf '%s\n' remove=present || printf '%s\n' remove=absent
  printf '\n== mounts ==\n'
  grep -E "$ID|/vendor/etc/thermal_info_config|/vendor/etc/fstab.zram.100p" /proc/mounts 2>/dev/null || true
  printf '%s\n' health_log_complete=yes
} >> "$H" 2>&1

bootguard_verified=0
if [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  if MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success-verify >> "$H" 2>&1; then
    bootguard_verified=1
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=pass' >> "$H"
  else
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=deferred_pending_preserved' >> "$H"
  fi
fi


# Android may rewrite selected ZRAM properties after early service startup.
# Reapply exactly once after verified boot. This path never mutates the LMKD
# property; the optional experiment is restricted to post-fs-data.
if [ "$bootguard_verified" = 1 ] &&
   [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
   [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  if [ -r "$ZRAM_APPLY" ] && sh "$ZRAM_APPLY" boot_verified >> "$H" 2>&1; then
    printf '%s\n' "SERVICE_ZRAM_POST_BOOT result=zram_properties_reapplied_no_mmd_restart lmk_policy=${LMKD_SWAP_LOW_RELOAD:-0}" >> "$H"
  else
    printf '%s\n' 'SERVICE_ZRAM_POST_BOOT result=reapply_failed_nonfatal' >> "$H"
  fi
fi

# The lock is a post-verification enhancement, never a boot prerequisite.
# Any failure restores adaptive devfreq and remains nonfatal.
if [ -r "$EH_CONTROL" ]; then
  if [ "$bootguard_verified" = 1 ] &&
     [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
     [ "${ZRAM_EMERALD_OC:-0}" = 1 ] &&
     [ "${LAST_ZRAM_100P:-}" = enabled_max_lock ] &&
     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ] &&
     [ "${ZRAM_EH_RISK_ACK:-}" = explicit_user_enable_max_lock ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" apply >> "$H" 2>&1; then
      printf '%s\n' 'SERVICE_ZRAM_EH result=max_frequency_minimum_lock_active' >> "$H"
    else
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
      printf '%s\n' 'SERVICE_ZRAM_EH result=apply_failed_adaptive_fallback' >> "$H"
    fi
  else
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
    printf '%s\n' "SERVICE_ZRAM_EH result=adaptive bootguard_verified=$bootguard_verified requested=${ZRAM_EMERALD_OC:-0} eh_ack=${ZRAM_EH_RISK_ACK:-none}" >> "$H"
  fi
fi

update_manager_badges() {
  status_lib="$MODDIR/tools/debug/status-lib.sh"
  [ -s "$status_lib" ] || return 1
  attempt=1
  while [ "$attempt" -le 3 ]; do
    sh "$status_lib" update >> "$H" 2>&1 || true
    desc="$(sed -n 's/^description=//p' "$MODDIR/module.prop" 2>/dev/null | tail -n 1)"
    case "$desc" in
      P:*' | T:'*' | Z:'*' | L:'*)
        printf '%s
' "MANAGER_BADGES result=verified attempt=$attempt description=$desc" >> "$H"
        return 0
      ;;
    esac
    sleep 2
    attempt=$((attempt + 1))
  done
  printf '%s
' 'MANAGER_BADGES result=failed reason=dynamic_description_readback_missing' >> "$H"
  return 1
}

update_manager_badges || true
exit 0
