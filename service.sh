#!/system/bin/sh
MODDIR=${0%/*}
ID="pixel-10-pro-xl-thermal-fix"
G="$MODDIR/guard"
L="$G/bootguard.log"
H="$MODDIR/health.log"
mkdir -p "$G"

echo "timestamp_start=$(date +%s 2>/dev/null || echo unknown)" > "$H"
echo "health_log_model=read_only_guard_first_plus_zram_100p_boot_early_v1413_test18" >> "$H"

# PIXEL_THERMAL_ZRAM_100P_SERVICE_START
CONFIG_FILE="/data/adb/$ID/config.env"
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE" 2>/dev/null || true
fi
if [ "${ENABLE_ZRAM_100P:-0}" = "1" ] && [ "${ZRAM_RISK_ACK:-}" = "explicit_user_enable" ]; then
  echo "$(date -Is 2>/dev/null || date) SERVICE_ZRAM action=apply mode=boot_early resetprop=required mmd_restart=skip" >> "$L"
  if [ -r "$MODDIR/tools/zram/apply-zram-100p.sh" ]; then
    sh "$MODDIR/tools/zram/apply-zram-100p.sh" boot_early >> "$H" 2>&1 || echo "SERVICE_ZRAM result=apply_failed_nonfatal" >> "$H"
  else
    echo "SERVICE_ZRAM result=apply_script_absent" >> "$H"
  fi
else
  echo "$(date -Is 2>/dev/null || date) SERVICE_ZRAM action=skip enabled=${ENABLE_ZRAM_100P:-0} ack=${ZRAM_RISK_ACK:-unset}" >> "$L"
fi
# PIXEL_THERMAL_ZRAM_100P_SERVICE_END

echo "$(date -Is 2>/dev/null || date) SERVICE_START action=read_only_health optional_zram_supported=true" >> "$L"
while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ]; do
  sleep 1
done
sleep 2

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
  grep -E "$ID|/vendor/etc/thermal_info_config|/vendor/etc/fstab.zram.100p" /proc/mounts 2>/dev/null || true
  echo health_log_complete=yes
} >> "$H" 2>&1

if [ -s "$MODDIR/tools/debug/status-lib.sh" ]; then
  sh "$MODDIR/tools/debug/status-lib.sh" update >> "$H" 2>&1 || true
fi

# BOOTGUARD_V2_SUCCESS_START
if [ -s "$MODDIR/tools/bootguard/bootguard-lib.sh" ]; then
  MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard/bootguard-lib.sh" success >> "$H" 2>&1 || true
fi
# BOOTGUARD_V2_SUCCESS_END

# Deep sleep Emerald Hill 1.066 GHz (max_freq) wakeup guard (screen-on, non-blocking 60s check)
if [ "${ENABLE_ZRAM_100P:-0}" = "1" ]; then
  (
    EH_LOG="$G/eh_reapply.log"
    echo "=== EH Reapply Log Start: $(date -Is 2>/dev/null || date) ===" > "$EH_LOG"
    count=0
    while :; do
      sleep 60
      # Only run check when screen is active (brightness > 0)
      bright=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1 || echo 1)
      if [ "${bright:-0}" -gt 0 ]; then
        for eh_dir in /sys/class/devfreq/*eh* /sys/devices/platform/*.eh/devfreq/*; do
          if [ -d "$eh_dir" ] && [ -w "$eh_dir/min_freq" ] && [ -r "$eh_dir/max_freq" ]; then
            max_f="$(cat "$eh_dir/max_freq" 2>/dev/null)"
            cur_min="$(cat "$eh_dir/min_freq" 2>/dev/null || echo 0)"
            if [ -n "$max_f" ] && [ "$cur_min" != "$max_f" ]; then
              echo "$max_f" > "$eh_dir/min_freq" 2>/dev/null || true
              count=$((count + 1))
              echo "$(date -Is 2>/dev/null || date) EH_REAPPLY count=$count prev_min=$cur_min restored_target=$max_f" >> "$EH_LOG"
            fi
          fi
        done
      fi
    done
  ) &
fi

exit 0
