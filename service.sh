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
printf '%s\n' 'health_log_model=verified_runtime_guard_plus_zram_100p_eh_deferred_v5' >> "$H"

[ -r "$NORMALIZE" ] && ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$NORMALIZE" >> "$H" 2>&1 || true
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi

# Standard lz77eh ZRAM properties may be prepared early. The optional Emerald
# Hill max-frequency lock is deliberately deferred until Bootguard verifies the
# completed Android boot and the active Thermal runtime.
if [ "${ENABLE_ZRAM_100P:-0}" = 1 ] && [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip eh=deferred\n' "$(date -Is 2>/dev/null || date)" >> "$L"
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

# late_start is non-blocking. Give Android and the thermal service time to settle
# before clearing the boot attempt. Bootguard performs two thermalservice probes.
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

if [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
  sh "$MODDIR/tools/debug/status-lib.sh" update >> "$H" 2>&1 || true
fi

bootguard_verified=0
if [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  if MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success-verify >> "$H" 2>&1; then
    bootguard_verified=1
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=pass' >> "$H"
  else
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=deferred_pending_preserved' >> "$H"
  fi
fi

# Android may rewrite selected LMK/ZRAM properties after early service startup.
# Reapply the runtime-only property set exactly once after verified boot. This
# mode never restarts mmd and deliberately leaves EH activation to the guarded
# block below.
if [ "$bootguard_verified" = 1 ] &&
   [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
   [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  if [ -r "$ZRAM_APPLY" ] && sh "$ZRAM_APPLY" boot_verified >> "$H" 2>&1; then
    printf '%s\n' 'SERVICE_ZRAM_POST_BOOT result=properties_reapplied_no_mmd_restart' >> "$H"
  else
    printf '%s\n' 'SERVICE_ZRAM_POST_BOOT result=reapply_failed_nonfatal' >> "$H"
  fi
fi

# Performance locking is a post-verification enhancement, never a boot
# prerequisite. Any failure falls back to adaptive devfreq and remains nonfatal.
if [ -r "$EH_CONTROL" ]; then
  if [ "$bootguard_verified" = 1 ] &&
     [ "${ENABLE_ZRAM_100P:-0}" = 1 ] &&
     [ "${ZRAM_EMERALD_OC:-0}" = 1 ] &&
     [ "${LAST_ZRAM_100P:-}" = enabled ] &&
     [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
    if MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" apply >> "$H" 2>&1; then
      printf '%s\n' 'SERVICE_ZRAM_EH result=max_frequency_lock_active' >> "$H"
    else
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
      printf '%s\n' 'SERVICE_ZRAM_EH result=apply_failed_adaptive_fallback' >> "$H"
    fi
  else
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >> "$H" 2>&1 || true
    printf '%s\n' "SERVICE_ZRAM_EH result=adaptive bootguard_verified=$bootguard_verified requested=${ZRAM_EMERALD_OC:-0}" >> "$H"
  fi
fi

if [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
  sh "$MODDIR/tools/debug/status-lib.sh" update >> "$H" 2>&1 || true
fi

exit 0
