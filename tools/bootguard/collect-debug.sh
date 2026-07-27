#!/system/bin/sh
# Compatibility entrypoint for the packaged debug collector.
set -u

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
COLLECTOR="$MODDIR/tools/bootguard/collect-debug-v3.sh"

if [ ! -s "$COLLECTOR" ]; then
  printf '%s\n' "FAILED: packaged collector missing path=$COLLECTOR"
  exit 2
fi

chmod 0755 "$COLLECTOR" 2>/dev/null || true
exec sh "$COLLECTOR" "$@"
