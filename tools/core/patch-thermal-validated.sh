#!/system/bin/sh
set -eu
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
VNEXT="$MODPATH/tools/core/patch-thermal-validated-vnext.sh"
[ -s "$VNEXT" ] || {
  printf '%s\n' 'PATCH_THERMAL_DELTA_VALIDATION=fail'
  printf '%s\n' 'PATCH_THERMAL_DELTA_REASON=vnext_validator_missing'
  exit 25
}
exec sh "$VNEXT" "$@"
