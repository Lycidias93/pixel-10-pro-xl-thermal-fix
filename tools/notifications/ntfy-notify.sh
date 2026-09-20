#!/system/bin/sh
set -u

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
BINDIR=${0%/*}
MODDIR="${MODDIR:-${BINDIR%/tools/notifications}}"
CONFIG_FILE="${PIXEL_CONFIG_FILE:-${THERMAL_CONFIG_FILE:-/data/adb/$ID/config.env}}"
NTFY_LIB="$MODDIR/lib/ntfy.sh"

event="${1:-}"
component="${2:-module}"
detail="${3:-state_changed}"

case "$event" in start|success|fail|warn) ;; *) exit 0 ;; esac
case "$component" in ""|*[!A-Za-z0-9._-]*) component=module ;; esac
case "$detail" in ""|*[!A-Za-z0-9._-]*) detail=state_changed ;; esac
[ -r "$NTFY_LIB" ] || exit 0

NTFY_ENABLED=0
NTFY_URL=
NTFY_TOPIC=
NTFY_TOKEN_FILE=
NTFY_PRIORITY=default
NTFY_TAGS=package
. "$NTFY_LIB"
webui_ntfy_load_config_file "$CONFIG_FILE" >/dev/null 2>&1 || exit 0
webui_ntfy_truthy "${NTFY_ENABLED:-0}" || exit 0

case "$event" in
  start) level=INFO; priority=default ;;
  success) level=PASS; priority="${NTFY_PRIORITY:-default}" ;;
  warn) level=WARN; priority=high ;;
  fail) level=FAIL; priority=high ;;
esac
title="Pixel Thermal $event"
body="event=$event component=$component detail=$detail"
webui_ntfy_send "$level" "$title" "$body" "${NTFY_TAGS:-package}" "$priority" >/dev/null 2>&1 || true
exit 0
