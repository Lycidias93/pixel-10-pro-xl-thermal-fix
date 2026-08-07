#!/system/bin/sh
set -eu
MODDIR="${MODDIR:-${0%/*}/../..}"
VNEXT="$MODDIR/tools/bootguard/compat-check-vnext.sh"
[ -s "$VNEXT" ] || {
  printf '%s\n' 'SAFE_TO_REBOOT=no'
  printf '%s\n' 'REASON=vnext_compat_missing'
  exit 25
}
exec sh "$VNEXT" "$@"
