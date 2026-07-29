#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
G="$MODDIR/guard"
L="$G/bootguard.log"
H="$MODDIR/health.log"
CONFIG_FILE="/data/adb/$ID/config.env"
mkdir -p "$G"

printf 'timestamp_start=%s\n' "$(date +%s 2>/dev/null || echo unknown)" > "$H"
printf '%s\n' 'health_log_model=verified_runtime_guard_plus_zram_100p_boot_early_v3' >> "$H"

if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi
if [ "${ENABLE_ZRAM_100P:-0}" = 1 ] && [ "${ZRAM_RISK_ACK:-}" = explicit_user_enable ]; then
  printf '%s SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip\n' "$(date -Is 2>/dev/null || date)" >> "$L"
  if [ -r "$MODDIR/tools/zram/apply-zram-100p.sh" ]; then
    sh "$MODDIR/tools/zram/apply-zram-100p.sh" boot_early >> "$H" 2>&1 ||
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

if [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  if MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success-verify >> "$H" 2>&1; then
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=pass' >> "$H"
  else
    printf '%s\n' 'BOOTGUARD_RUNTIME_VERIFICATION=deferred_pending_preserved' >> "$H"
  fi
fi

exit 0
