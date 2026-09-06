#!/system/bin/sh
# Policy-gated entrypoint for the layout-aware vNext Thermal core.
set -eu

# Thermal JSON numbers always use a dot as the decimal separator. AWK sprintf()
# follows the caller's numeric locale on Linux (for example de_DE.UTF-8 on
# DietPi), so pin the entire patch/validation subprocess tree to the POSIX
# locale before any numeric transformation. Android already behaves this way;
# making it explicit keeps host CI byte-identical to device execution.
LC_ALL=C
export LC_ALL

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
PIXEL11_HYSTERESIS_MODE="${4:-stock}"
PIXEL11_PASSIVE_MODE="${5:-stock}"
POLICY_HELPER="$MODPATH/tools/core/outdoor-runtime-policy.sh"
VNEXT_CORE="$MODPATH/tools/core/patch-thermal-vnext-core.sh"

[ -r "$POLICY_HELPER" ] || {
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=outdoor_runtime_policy_missing'
  exit 20
}
[ -r "$VNEXT_CORE" ] || {
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=vnext_core_missing'
  exit 20
}
. "$POLICY_HELPER"

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
ANDROID="${THERMAL_ANDROID:-$(getprop ro.build.version.release 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown

case "$POLLING_MODE" in stock|mod) ;; *)
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=invalid_polling_mode'
  exit 21
;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *)
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=invalid_outdoor_profile'
  exit 22
;; esac
case "$PIXEL11_HYSTERESIS_MODE" in stock|mod) ;; *)
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=invalid_pixel11_hysteresis_mode'
  exit 22
;; esac
case "$PIXEL11_PASSIVE_MODE" in stock|mod) ;; *)
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=invalid_pixel11_passive_mode'
  exit 22
;; esac

if ! thermal_outdoor_profile_admitted "$OUTDOOR_PROFILE" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
  requested_delta="$(thermal_outdoor_profile_delta "$OUTDOOR_PROFILE" 2>/dev/null || printf '%s\n' unknown)"
  max_delta="$(thermal_outdoor_max_delta "$DEVICE" "$ANDROID" "$BUILD_ID" 2>/dev/null || printf '%s\n' 0)"
  evidence="$(thermal_outdoor_policy_evidence "$DEVICE" "$ANDROID" "$BUILD_ID" 2>/dev/null || printf '%s\n' unavailable)"
  printf '%s\n' 'PATCH_THERMAL=fail'
  printf '%s\n' 'PATCH_THERMAL_REASON=outdoor_profile_not_runtime_proven'
  printf '%s\n' "PATCH_THERMAL_OUTDOOR_REQUESTED_DELTA=$requested_delta"
  printf '%s\n' "PATCH_THERMAL_OUTDOOR_MAX_ADMITTED_DELTA=$max_delta"
  printf '%s\n' "PATCH_THERMAL_OUTDOOR_POLICY_EVIDENCE=$evidence"
  exit 23
fi

exec sh "$VNEXT_CORE" "$POLLING_MODE" "$OUTDOOR_PROFILE" "$MODPATH" "$PIXEL11_HYSTERESIS_MODE" "$PIXEL11_PASSIVE_MODE"
