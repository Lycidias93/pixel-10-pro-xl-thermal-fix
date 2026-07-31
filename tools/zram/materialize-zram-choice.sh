#!/system/bin/sh
# Idempotent ZRAM fstab materializer shared by install, Action and helpers.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-/data/adb/modules/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-/data/adb/$ID/config.env}"
ACTIVE_DIR="${ZRAM_ACTIVE_DIR:-$MODDIR/system/vendor/etc}"
SRC="${ZRAM_FSTAB_SRC:-$MODDIR/tools/zram/fstab.zram.100p}"
DST="$ACTIVE_DIR/fstab.zram.100p"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
MODE="${1:-status}"
TMP=""

cleanup_tmp() {
  [ -n "$TMP" ] && rm -f "$TMP" 2>/dev/null || true
}
trap cleanup_tmp EXIT HUP INT TERM

files_equal() {
  left="$1"
  right="$2"
  [ -s "$left" ] && [ -s "$right" ] || return 1
  if command -v cmp >/dev/null 2>&1; then
    cmp -s "$left" "$right" 2>/dev/null
    return $?
  fi
  left_sha="$(sha256sum "$left" 2>/dev/null | awk '{print $1}')"
  right_sha="$(sha256sum "$right" 2>/dev/null | awk '{print $1}')"
  [ -n "$left_sha" ] && [ "$left_sha" = "$right_sha" ]
}

layout_fail() {
  reason="$1"
  code="$2"
  printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=$MODE reason=$reason source=$SRC path=$DST"
  exit "$code"
}

case "$MODE" in
  enable)
    [ -s "$SRC" ] || layout_fail template_missing 2
    mkdir -p "$ACTIVE_DIR" || layout_fail active_dir_create_failed 3

    if files_equal "$SRC" "$DST"; then
      chmod 0644 "$DST" 2>/dev/null || true
      printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=enable materialized=yes action=kept_existing path=$DST"
      exit 0
    fi

    TMP="$ACTIVE_DIR/.fstab.zram.100p.new.$$"
    rm -f "$TMP" 2>/dev/null || true
    cp -f "$SRC" "$TMP" || layout_fail temporary_copy_failed 4
    chmod 0644 "$TMP" 2>/dev/null || true
    files_equal "$SRC" "$TMP" || layout_fail temporary_verify_failed 5

    if [ -e "$DST" ]; then
      rm -f "$DST" || layout_fail destination_remove_failed 6
    fi
    mv -f "$TMP" "$DST" || layout_fail destination_move_failed 7
    TMP=""
    files_equal "$SRC" "$DST" || layout_fail destination_verify_failed 8
    printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=enable materialized=yes action=materialized path=$DST"
  ;;
  disable)
    rm -f "$DST" || layout_fail destination_remove_failed 9
    if [ -r "$EH_CONTROL" ]; then
      MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
    fi
    [ ! -e "$DST" ] || layout_fail destination_present 10
    printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=disable materialized=no action=removed path=$DST"
  ;;
  status)
    if [ -s "$DST" ]; then
      printf '%s\n' "RESULT: ZRAM_LAYOUT_STATUS materialized=yes path=$DST"
    else
      printf '%s\n' "RESULT: ZRAM_LAYOUT_STATUS materialized=no path=$DST"
    fi
  ;;
  *)
    layout_fail invalid_mode 64
  ;;
esac
