#!/system/bin/sh
# Print the Action dashboard snapshot without re-running compat-check.
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
STATUS_FILE="$MODDIR/guard/manager-status.env"

get_status_kv() {
  [ -r "$STATUS_FILE" ] || return 0
  grep -E "^$1=" "$STATUS_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//"
}

if [ ! -s "$STATUS_FILE" ]; then
  printf '%s\n' 'Status'
  printf '%s\n' 'Status cache unavailable'
  exit 0
fi

printf '%s\n' "Status"
printf '%s\n' "Source:  $(get_status_kv SOURCE_ICON) $(get_status_kv SOURCE_STATE)"
printf '%s\n' "Polling: $(get_status_kv POLLING_ICON) $(get_status_kv POLLING_STATE)"
printf '%s\n' "Thermal: $(get_status_kv THERMAL_ICON) $(get_status_kv THERMAL_STATE)"
printf '%s\n' "ZRAM:    $(get_status_kv ZRAM_ICON) $(get_status_kv ZRAM_STATE)"
printf '%s\n' ""
printf '%s\n' "Source 300000: $(get_status_kv SOURCE_POLLING_300000)"
printf '%s\n' "Replacements:  $(get_status_kv REPLACEMENTS)"
printf '%s\n' "Overlay 5000:  $(get_status_kv OVERLAY_POLLING_5000)"
printf '%s\n' "Active 5000:   $(get_status_kv ACTIVE_POLLING_5000)"
printf '%s\n' "Materialized:  $(get_status_kv MATERIALIZATION_VALID)"
printf '%s\n' "Vendor match:  $(get_status_kv ACTIVE_VENDOR_MATCH)"
printf '%s\n' "Active values: $(get_status_kv ACTIVE_POLLING_VALID)"
printf '%s\n' "Reboot safe:   $(get_status_kv SAFE_TO_REBOOT)"
printf '%s\n' "Reason:        $(get_status_kv COMPAT_REASON)"
exit 0
