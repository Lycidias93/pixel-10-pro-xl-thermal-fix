#!/system/bin/sh
set -eu
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${CONFIG_FILE:-/data/adb/$ID/config.env}"
G="$MODDIR/guard"
CUR="$G/current_snapshot.env"
LAST="$G/last_good.env"
if [ ! -s "$MODDIR/tools/bootguard-lib.sh" ]; then echo "Bootguard library missing."; exit 1; fi
MODDIR="$MODDIR" CONFIG_FILE="$CONFIG_FILE" sh "$MODDIR/tools/bootguard-lib.sh" snapshot "$CUR" >/dev/null 2>&1 || true
echo "Last-good differential"
echo "last_good=$([ -s "$LAST" ] && echo present || echo absent)"
echo "current=$([ -s "$CUR" ] && echo present || echo absent)"
if [ ! -s "$LAST" ] || [ ! -s "$CUR" ]; then echo "DIFF unavailable"; echo "RESULT: LAST_GOOD_DIFF_DONE state=missing"; exit 0; fi
keys="build_id incremental module_version module_version_code config_sha256 profile overlay_sha256 ptune thermal_profile thermal_polling zram_enabled"
changes=0
for k in $keys; do
  old="$(grep -E "^${k}=" "$LAST" 2>/dev/null | tail -n 1 | sed "s/^${k}=//")"
  new="$(grep -E "^${k}=" "$CUR" 2>/dev/null | tail -n 1 | sed "s/^${k}=//")"
  [ -n "$old$new" ] || continue
  if [ "$old" = "$new" ]; then echo "SAME $k=$new"; else echo "CHANGED $k"; echo "  old=$old"; echo "  new=$new"; changes=$((changes + 1)); fi
done
echo "RESULT: LAST_GOOD_DIFF_DONE changes=$changes"
