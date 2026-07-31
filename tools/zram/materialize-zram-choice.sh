#!/system/bin/sh
# Transactional ZRAM fstab materializer shared by install, Action and helpers.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
ACTIVE_DIR="${ZRAM_ACTIVE_DIR:-$MODDIR/system/vendor/etc}"
SRC="${ZRAM_FSTAB_SRC:-$MODDIR/tools/zram/fstab.zram.100p}"
DST="$ACTIVE_DIR/fstab.zram.100p"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
MODE="${1:-status}"

case "$MODE" in
  enable)
    [ -s "$SRC" ] || {
      printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=enable reason=template_missing path=$SRC"
      exit 2
    }
    mkdir -p "$ACTIVE_DIR"
    tmp="$DST.tmp.$$"
    cp -fp "$SRC" "$tmp"
    chmod 0644 "$tmp" 2>/dev/null || true
    mv "$tmp" "$DST"
    [ -s "$DST" ] || {
      printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=enable reason=destination_missing path=$DST"
      exit 3
    }
    printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=enable materialized=yes path=$DST"
  ;;
  disable)
    rm -f "$DST"
    if [ -r "$EH_CONTROL" ]; then
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
    fi
    [ ! -e "$DST" ] || {
      printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=disable reason=destination_present path=$DST"
      exit 4
    }
    printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=disable materialized=no path=$DST"
  ;;
  status)
    if [ -s "$DST" ]; then
      printf '%s\n' "RESULT: ZRAM_LAYOUT_STATUS materialized=yes path=$DST"
    else
      printf '%s\n' "RESULT: ZRAM_LAYOUT_STATUS materialized=no path=$DST"
    fi
  ;;
  *)
    printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=$MODE reason=invalid_mode"
    exit 64
  ;;
esac
