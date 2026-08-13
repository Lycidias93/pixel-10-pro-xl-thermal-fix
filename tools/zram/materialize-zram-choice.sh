#!/system/bin/sh
# ZRAM fstab materializer. Active-module Action changes are config-only and
# reconciled from post-fs-data before the module system tree is mounted.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
ADB_ROOT="${THERMAL_ADB_ROOT:-/data/adb}"
MODDIR="${MODDIR:-$ADB_ROOT/modules/$ID}"
CONFIG_FILE="${ZRAM_CONFIG_FILE:-$ADB_ROOT/$ID/config.env}"
ACTIVE_DIR="${ZRAM_ACTIVE_DIR:-$MODDIR/system/vendor/etc}"
SRC="${ZRAM_FSTAB_SRC:-$MODDIR/tools/zram/fstab.zram.100p}"
DST="$ACTIVE_DIR/fstab.zram.100p"
EH_CONTROL="$MODDIR/tools/zram/emerald-hill-control.sh"
MODE="${1:-status}"
MATERIALIZE_NOW="${ZRAM_MATERIALIZE_NOW:-0}"
MATERIALIZE_CALLER="${ZRAM_MATERIALIZE_CALLER:-runtime}"
INSTALL_STAGE_ROOT="$ADB_ROOT/modules_update/$ID"
TMP=""

cleanup_tmp() {
  [ -n "$TMP" ] && rm -f "$TMP" 2>/dev/null || true
}
trap cleanup_tmp EXIT HUP INT TERM

cfg_get() {
  [ -r "$CONFIG_FILE" ] || return 0
  grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

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

install_stage_identity() {
  case "$MODDIR" in
    "$INSTALL_STAGE_ROOT"|"$INSTALL_STAGE_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

layout_fail() {
  reason="$1"
  code="$2"
  printf '%s\n' "RESULT: ZRAM_LAYOUT_FAIL mode=$MODE reason=$reason source=$SRC path=$DST caller=$MATERIALIZE_CALLER"
  exit "$code"
}

materialize_enable() {
  [ -s "$SRC" ] || layout_fail template_missing 2
  mkdir -p "$ACTIVE_DIR" || layout_fail active_dir_create_failed 3

  if files_equal "$SRC" "$DST"; then
    chmod 0644 "$DST" 2>/dev/null || true
    printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=$MODE materialized=yes action=kept_existing path=$DST caller=$MATERIALIZE_CALLER"
    return 0
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
  printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=$MODE materialized=yes action=materialized path=$DST caller=$MATERIALIZE_CALLER"
}

materialize_disable() {
  rm -f "$DST" || layout_fail destination_remove_failed 9
  if [ -r "$EH_CONTROL" ]; then
    MODDIR="$MODDIR" ZRAM_CONFIG_FILE="$CONFIG_FILE" sh "$EH_CONTROL" restore >/dev/null 2>&1 || true
  fi
  [ ! -e "$DST" ] || layout_fail destination_present 10
  printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=$MODE materialized=no action=removed path=$DST caller=$MATERIALIZE_CALLER"
}

case "$MODE" in
  enable|disable)
    # Runtime Action/helper calls are always config-only. Immediate layout
    # mutation is install-only and requires three independent gates: explicit
    # mutation flag, installer caller token, and the real modules_update path.
    if [ "$MATERIALIZE_NOW" != 1 ] || [ "$MATERIALIZE_CALLER" != install-zram ] || ! install_stage_identity; then
      printf '%s\n' "RESULT: ZRAM_LAYOUT_DONE mode=$MODE materialized=deferred action=pre_mount_reconcile_required path=$DST caller=$MATERIALIZE_CALLER"
      exit 0
    fi
    [ "$MODE" = enable ] && materialize_enable || materialize_disable
  ;;
  reconcile)
    enabled="$(cfg_get ENABLE_ZRAM_100P)"
    ack="$(cfg_get ZRAM_RISK_ACK)"
    if [ "$enabled" = 1 ] && [ "$ack" = explicit_user_enable ]; then
      materialize_enable
    else
      materialize_disable
    fi
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
