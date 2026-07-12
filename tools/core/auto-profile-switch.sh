#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="$MODDIR/install-state.txt"
CFG="/data/adb/$ID/config.env"
SUPPORTED_JSON="$MODDIR/supported_versions.json"
SUPPORTED_HELPER="$MODDIR/tools/core/supported-build.sh"
mkdir -p "$G"

log(){ echo "$(date -Is 2>/dev/null || date) $*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'; }
getstate(){ [ -r "$STATE" ] && grep -E "^$1=" "$STATE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'; }
cfg_set(){
  key="$1"
  value="$2"
  mkdir -p "$(dirname "$CFG")" 2>/dev/null || true
  touch "$CFG" 2>/dev/null || true
  tmp="$CFG.tmp.$$"
  grep -v "^${key}=" "$CFG" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$CFG"
  chmod 0600 "$CFG" 2>/dev/null || true
}
prop(){ getprop "$1" 2>/dev/null || true; }
remove_thermal_overlay(){ rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true; }

AUTO="$(getcfg AUTO_PROFILE_SWITCH)"
[ -n "$AUTO" ] || AUTO=1
case "$AUTO" in
  1|yes|true|on|enabled) ;;
  *) log "AUTO_SWITCH_SKIP reason=config_disabled value=$AUTO"; echo config_disabled > "$G/auto_profile_switch_state"; exit 0 ;;
esac

DEVICE="$(prop ro.product.device)"
ANDROID="$(prop ro.build.version.release)"
SDK="$(prop ro.build.version.sdk)"
BUILD_ID="$(prop ro.build.id)"
INCREMENTAL="$(prop ro.build.version.incremental)"

if [ ! -r "$SUPPORTED_HELPER" ]; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  echo supported_helper_missing > "$G/auto_profile_switch_state"
  log "AUTO_SWITCH_BLOCK reason=supported_helper_missing"
  exit 0
fi
. "$SUPPORTED_HELPER"

if ! thermal_supported_check "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  echo unsupported_exact_build > "$G/auto_profile_switch_state"
  printf '%s\n' "$BUILD_ID" > "$G/unsupported_build_id"
  log "AUTO_SWITCH_BLOCK reason=unsupported_exact_build device=$DEVICE android=$ANDROID build=$BUILD_ID action=thermal_only_disabled"
  exit 0
fi

PROFILE="dynamic/${DEVICE}/android${ANDROID}"
PROFILE_STATE="dynamic_verified"
BUILD_STATE="dynamic_${DEVICE}_${BUILD_ID}_${INCREMENTAL}"
POLLING="$(getcfg THERMAL_POLLING_MODE)"
OUTDOOR="$(getcfg THERMAL_OUTDOOR_PROFILE)"
[ -n "$POLLING" ] || POLLING=mod
[ -n "$OUTDOOR" ] || OUTDOOR=stock

NEED=0
[ "$(getstate profile)" = "$PROFILE" ] || NEED=1
[ "$(getstate android)" = "$ANDROID" ] || NEED=1
[ "$(getstate build_id)" = "$BUILD_ID" ] || NEED=1
[ "$(getstate incremental)" = "$INCREMENTAL" ] || NEED=1
[ "$(getcfg THERMAL_DISABLED)" = 0 ] || NEED=1
for required in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  [ -s "$MODDIR/system/vendor/etc/$required" ] || NEED=1
done

if [ "$NEED" -eq 0 ]; then
  echo current_profile_valid > "$G/auto_profile_switch_state"
  echo "$PROFILE" > "$G/selected_profile"
  log "AUTO_SWITCH_PASS reason=current_profile_valid profile=$PROFILE build=$BUILD_ID"
  exit 0
fi

log "AUTO_SWITCH_TRIGGER reason=ota_or_overlay_missing profile=$PROFILE build=$BUILD_ID"
if [ ! -s "$MODDIR/tools/core/patch-thermal.sh" ] ||
   ! sh "$MODDIR/tools/core/patch-thermal.sh" "$POLLING" "$OUTDOOR" "$MODDIR"; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  echo patching_failed > "$G/auto_profile_switch_state"
  log "AUTO_SWITCH_BLOCK reason=patching_failed action=thermal_only_disabled"
  exit 0
fi

cfg_set THERMAL_DISABLED 0
cfg_set CANARY_DIAGNOSTIC_MODE 0
rm -f "$G/disabled_reason" "$G/profile_stale_after_ota" "$G/reinstall_required" "$G/unsupported_build_id" 2>/dev/null || true
{
  printf '%s\n' "module_id=$ID"
  printf '%s\n' "module_version=$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//')"
  printf '%s\n' "module_version_code=$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//')"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "android=$ANDROID"
  printf '%s\n' "android_sdk=$SDK"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "incremental=$INCREMENTAL"
  printf '%s\n' "profile=$PROFILE"
  printf '%s\n' "profile_state=$PROFILE_STATE"
  printf '%s\n' "build_state=$BUILD_STATE"
  printf '%s\n' "build_guard_mode=exact_device_android_build"
  printf '%s\n' "profile_source_build=$BUILD_ID"
  printf '%s\n' "profile_source_incremental=$INCREMENTAL"
  printf '%s\n' "auto_profile_switch=yes"
  printf '%s\n' "auto_profile_switch_state=materialized"
  printf '%s\n' "auto_profile_switch_at=$(date -Is 2>/dev/null || date)"
  printf '%s\n' "profile_materialized=yes"
  printf '%s\n' "expected_thermal_files=dynamic_validated"
} > "$STATE"

echo materialized > "$G/auto_profile_switch_state"
echo "$PROFILE" > "$G/selected_profile"
log "AUTO_SWITCH_DONE profile=$PROFILE build=$BUILD_ID incremental=$INCREMENTAL"
exit 0
