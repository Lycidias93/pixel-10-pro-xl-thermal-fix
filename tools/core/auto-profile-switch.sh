#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="$MODDIR/install-state.txt"
CFG="/data/adb/$ID/config.env"
RESOLVER="$MODDIR/tools/core/profile-resolver.sh"
SOURCE_VERIFY="$MODDIR/tools/core/profile-source-verify.sh"
mkdir -p "$G"
log(){ echo "$(date -Is 2>/dev/null || date) $*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
getstate(){ [ -r "$STATE" ] && grep -E "^$1=" "$STATE" 2>/dev/null | tail -n1 | sed "s/^$1=//" | tr -d '\r'; }
cfg_set(){ k="$1"; v="$2"; mkdir -p "$(dirname "$CFG")" 2>/dev/null || true; touch "$CFG" 2>/dev/null || true; t="$CFG.tmp.$$"; grep -v "^${k}=" "$CFG" 2>/dev/null > "$t" || true; printf '%s=%s\n' "$k" "$v" >> "$t"; mv "$t" "$CFG"; chmod 0600 "$CFG" 2>/dev/null || true; }
prop(){ getprop "$1" 2>/dev/null || true; }

AUTO="$(getcfg AUTO_PROFILE_SWITCH)"
[ -n "$AUTO" ] || AUTO=1
case "$AUTO" in 1|yes|true|on|enabled) ;; *) log "AUTO_SWITCH_SKIP reason=config_disabled value=$AUTO"; echo config_disabled > "$G/auto_profile_switch_state"; exit 0 ;; esac

DEVICE="$(prop ro.product.device)"
ANDROID="$(prop ro.build.version.release)"
SDK="$(prop ro.build.version.sdk)"
BUILD_ID="$(prop ro.build.id)"
INCREMENTAL="$(prop ro.build.version.incremental)"

if [ ! -r "$RESOLVER" ]; then
  log "AUTO_SWITCH_BLOCK reason=resolver_missing"
  echo resolver_missing > "$G/auto_profile_switch_state"
  touch "$MODDIR/skip_mount"
  exit 0
fi
. "$RESOLVER"
if ! thermal_resolve_profile "$MODDIR" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
  log "AUTO_SWITCH_BLOCK reason=$THERMAL_RESOLVER_REASON device=$DEVICE android=$ANDROID build=$BUILD_ID"
  echo "$THERMAL_RESOLVER_REASON" > "$G/auto_profile_switch_state"
  printf '%s\n' "PROFILE_STALE_AFTER_OTA=yes" > "$G/profile_stale_after_ota"
  printf '%s\n' "REINSTALL_REQUIRED=yes" > "$G/reinstall_required"
  touch "$MODDIR/skip_mount"
  exit 0
fi
if [ ! -x "$SOURCE_VERIFY" ] || ! "$SOURCE_VERIFY" "$MODDIR" "$DEVICE" "$ANDROID" "$BUILD_ID" >/dev/null; then
  log "AUTO_SWITCH_BLOCK reason=profile_source_verify_failed profile=$THERMAL_PROFILE_REL"
  echo profile_source_verify_failed > "$G/auto_profile_switch_state"
  touch "$MODDIR/skip_mount"
  exit 0
fi

PROFILE="$THERMAL_PROFILE_REL"
PROFILE_STATE="exact_git_profile"
BUILD_STATE="exact_${DEVICE}_${BUILD_ID}_${INCREMENTAL}"
THERMAL_OUTDOOR_PROFILE="$(getcfg THERMAL_OUTDOOR_PROFILE)"
[ -n "$THERMAL_OUTDOOR_PROFILE" ] || THERMAL_OUTDOOR_PROFILE="stock"
THERMAL_POLLING_MODE="$(getcfg THERMAL_POLLING_MODE)"
[ -n "$THERMAL_POLLING_MODE" ] || THERMAL_POLLING_MODE="mod"
ACTIVE_DIR="$MODDIR/system/vendor/etc"
OLD_PROFILE="$(getstate profile)"
OLD_ANDROID="$(getstate android)"
OLD_BUILD="$(getstate build_id)"
OLD_INC="$(getstate incremental)"

NEED=0
[ "$OLD_PROFILE" = "$PROFILE" ] || NEED=1
[ "$OLD_ANDROID" = "$ANDROID" ] || NEED=1
[ "$OLD_BUILD" = "$BUILD_ID" ] || NEED=1
[ "$OLD_INC" = "$INCREMENTAL" ] || NEED=1

EXPECTED=0
for source_file in "$THERMAL_PROFILE_ETC"/thermal_info_config*.json; do
  [ -f "$source_file" ] || continue
  EXPECTED=$(( EXPECTED + 1 ))
  file="${source_file##*/}"
  [ -s "$ACTIVE_DIR/$file" ] || NEED=1
done
[ "$EXPECTED" -eq "$THERMAL_PROFILE_JSON_COUNT" ] 2>/dev/null || NEED=1

if [ "$NEED" = 0 ]; then
  cfg_set THERMAL_DISABLED 0
  echo current_profile_valid > "$G/auto_profile_switch_state"
  echo "$PROFILE" > "$G/selected_profile"
  log "AUTO_SWITCH_PASS reason=current_profile_valid profile=$PROFILE device=$DEVICE android=$ANDROID build=$BUILD_ID incremental=$INCREMENTAL"
  exit 0
fi

log "AUTO_SWITCH_TRIGGER reason=ota_or_overlay_missing profile=$PROFILE device=$DEVICE build=$BUILD_ID"
if [ -s "$MODDIR/tools/core/patch-thermal.sh" ]; then
  chmod 0755 "$MODDIR/tools/core/patch-thermal.sh" 2>/dev/null || true
  sh "$MODDIR/tools/core/patch-thermal.sh" "$THERMAL_POLLING_MODE" "$THERMAL_OUTDOOR_PROFILE" "$MODDIR" "$DEVICE" "$ANDROID" "$BUILD_ID" || {
    log "AUTO_SWITCH_BLOCK reason=patching_failed"
    echo patching_failed > "$G/auto_profile_switch_state"
    touch "$MODDIR/skip_mount"
    exit 0
  }
else
  log "AUTO_SWITCH_BLOCK reason=patcher_script_missing"
  echo patcher_script_missing > "$G/auto_profile_switch_state"
  touch "$MODDIR/skip_mount"
  exit 0
fi

cfg_set THERMAL_DISABLED 0
rm -f "$MODDIR/skip_mount" "$G/disabled_reason" "$G/profile_stale_after_ota" "$G/reinstall_required" 2>/dev/null || true
{
  echo "module_id=$ID"
  echo "module_version=$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n1 | sed 's/^version=//')"
  echo "module_version_code=$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n1 | sed 's/^versionCode=//')"
  echo "device=$DEVICE"
  echo "android=$ANDROID"
  echo "android_sdk=$SDK"
  echo "build_id=$BUILD_ID"
  echo "incremental=$INCREMENTAL"
  echo "profile=$PROFILE"
  echo "profile_state=$PROFILE_STATE"
  echo "build_state=$BUILD_STATE"
  echo "build_guard_mode=exact_git_profile"
  echo "profile_source_build=$THERMAL_PROFILE_BUILD_ID"
  echo "profile_source_incremental=stock_factory_bundle"
  echo "profile_source_channel=$THERMAL_PROFILE_CHANNEL"
  echo "profile_bundle_sha256=$THERMAL_PROFILE_BUNDLE_SHA256"
  echo "auto_profile_switch=yes"
  echo "auto_profile_switch_state=materialized"
  echo "auto_profile_switch_at=$(date -Is 2>/dev/null || date)"
  echo "profile_materialized=yes"
  echo "expected_thermal_files=$THERMAL_PROFILE_JSON_COUNT"
} > "$STATE"

echo materialized > "$G/auto_profile_switch_state"
echo "$PROFILE" > "$G/selected_profile"
log "AUTO_SWITCH_DONE old_profile=${OLD_PROFILE:-none} new_profile=$PROFILE old_android=${OLD_ANDROID:-none} new_android=$ANDROID old_build=${OLD_BUILD:-none} new_build=$BUILD_ID old_incremental=${OLD_INC:-none} new_incremental=$INCREMENTAL"
exit 0
