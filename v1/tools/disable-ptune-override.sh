#!/system/bin/sh
# Disable pTune override and restore strict safe skip_mount when pTune is installed.
set -eu
MODULE_ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-/data/adb/modules/$MODULE_ID}"
STAGEDIR="/data/adb/modules_update/$MODULE_ID"
CONFIG_DIR="/data/adb/$MODULE_ID"
CONFIG_FILE="$CONFIG_DIR/config.env"
mkdir -p "$CONFIG_DIR"
{
  echo "PTUNE_GUARD_MODE=strict"
  echo "ALLOW_THERMAL_WITH_PTUNE=0"
} > "$CONFIG_FILE"
chmod 0600 "$CONFIG_FILE" 2>/dev/null || true
ptune_present=0
for p in /data/adb/modules/ptune /data/adb/modules_update/ptune; do
  [ -f "$p/module.prop" ] || continue
  grep -q '^id=ptune$' "$p/module.prop" 2>/dev/null || continue
  [ -e "$p/remove" ] && continue
  ptune_present=1
done
for d in "$MODDIR" "$STAGEDIR"; do
  [ -d "$d" ] || continue
  rm -f "$d/disable" "$d/remove" 2>/dev/null || true
  mkdir -p "$d/guard"
  rm -f "$d/guard/guard_override" "$d/guard/guard_override_source" "$d/guard/risk_ack" "$d/guard/override_profile_materialized" 2>/dev/null || true
  if [ "$ptune_present" = 1 ]; then
    touch "$d/skip_mount"
    echo "conflict_ptune_installed" > "$d/guard/disabled_reason"
    echo "strict_presence_skip_mount" > "$d/guard/conflict_guard_mode"
    echo "/data/adb/modules/ptune" > "$d/guard/conflict_ptune_path"
  fi
done
echo "PTUNE_OVERRIDE_DISABLED=yes"
echo "PTUNE_PRESENT=$ptune_present"
echo "CONFIG_FILE=$CONFIG_FILE"
if [ -x "$MODDIR/tools/compat-check.sh" ]; then sh "$MODDIR/tools/compat-check.sh" || true; fi
echo "RESULT: DISABLE_PTUNE_OVERRIDE_DONE"
