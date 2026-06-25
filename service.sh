#!/system/bin/sh
MODDIR=${0%/*}
G="$MODDIR/guard"
L="$G/bootguard.log"
H="$MODDIR/health.log"
mkdir -p "$G"

echo "timestamp_start=$(date +%s 2>/dev/null || echo unknown)" > "$H"
echo "health_log_model=read_only_guard_first_plus_optional_zram_100p_service_early_v1412_test6" >> "$H"

# PIXEL_THERMAL_ZRAM_100P_SERVICE_START
# Run before boot_completed waiting so persist props and mmd hints are present as early as possible.
CONFIG_FILE="/data/adb/pixel-10-pro-xl-thermal-fix/config.env"
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi
if [ "${ENABLE_ZRAM_100P:-0}" = "1" ] && [ "${ZRAM_RISK_ACK:-}" = "explicit_user_enable" ]; then
  echo "$(date -Is 2>/dev/null || date) SERVICE_ZRAM action=apply mode=boot_early" >> "$L"
  if [ -r "$MODDIR/tools/apply-zram-100p.sh" ]; then
    sh "$MODDIR/tools/apply-zram-100p.sh" boot_early >> "$H" 2>&1 || echo "SERVICE_ZRAM result=apply_failed_nonfatal" >> "$H"
  else
    echo "SERVICE_ZRAM result=apply_script_absent" >> "$H"
  fi
else
  echo "$(date -Is 2>/dev/null || date) SERVICE_ZRAM action=skip enabled=${ENABLE_ZRAM_100P:-0} ack=${ZRAM_RISK_ACK:-unset}" >> "$L"
fi
# PIXEL_THERMAL_ZRAM_100P_SERVICE_END

echo "$(date -Is 2>/dev/null || date) SERVICE_START action=read_only_health optional_zram_supported=true" >> "$L"
waited=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ] && [ "$waited" -lt 120 ]; do
  sleep 2
  waited=$((waited+2))
done

# Give Magisk/KernelSU overlay mounts time to settle before health logging.
sleep 20

{
  echo "timestamp_complete=$(date +%s 2>/dev/null || echo unknown)"
  echo "boot_completed=$(getprop sys.boot_completed 2>/dev/null || echo unknown)"
  echo "boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
  echo
  echo "== flags =="
  [ -e "$MODDIR/disable" ] && echo disable=present || echo disable=absent
  [ -e "$MODDIR/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent
  [ -e "$MODDIR/remove" ] && echo remove=present || echo remove=absent
  echo
  echo "== mounts =="
  grep -E 'pixel-10-pro-xl-thermal-fix|/vendor/etc/thermal_info_config|/vendor/etc/fstab.zram.100p' /proc/mounts 2>/dev/null || true
  echo health_log_complete=yes
} >> "$H" 2>&1

exit 0
