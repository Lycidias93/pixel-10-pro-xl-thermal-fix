#!/system/bin/sh
MODDIR=${0%/*}; G="$MODDIR/guard"; L="$G/bootguard.log"; H="$MODDIR/health.log"; mkdir -p "$G"
echo "timestamp_start=$(date +%s 2>/dev/null || echo unknown)" > "$H"; echo "health_log_model=read_only_guard_first_no_marker_mutation" >> "$H"; echo "$(date -Is 2>/dev/null || date) SERVICE_START action=read_only_health no_marker_mutation=true" >> "$L"
waited=0; while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ] && [ "$waited" -lt 120 ]; do sleep 2; waited=$((waited+2)); done; sleep 20
{ echo "timestamp_complete=$(date +%s 2>/dev/null || echo unknown)"; echo "boot_completed=$(getprop sys.boot_completed 2>/dev/null || echo unknown)"; echo "boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"; echo; echo "== flags =="; [ -e "$MODDIR/disable" ] && echo disable=present || echo disable=absent; [ -e "$MODDIR/skip_mount" ] && echo skip_mount=present || echo skip_mount=absent; [ -e "$MODDIR/remove" ] && echo remove=present || echo remove=absent; echo; echo "== mounts =="; grep -E 'pixel-10-pro-xl-thermal-fix|/vendor/etc/thermal_info_config' /proc/mounts 2>/dev/null || true; echo health_log_complete=yes; } >> "$H" 2>&1
exit 0
