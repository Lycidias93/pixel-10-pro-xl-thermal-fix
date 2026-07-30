#!/system/bin/sh
ID="pixel-10-pro-xl-thermal-fix"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="$MODDIR/install-state.txt"
CFG="/data/adb/$ID/config.env"
SUPPORTED_JSON="$MODDIR/supported_versions.json"
SUPPORTED_HELPER="$MODDIR/tools/core/supported-build.sh"
VALIDATED_PATCHER="$MODDIR/tools/core/patch-thermal-validated.sh"
TRANSITION_HELPER="$MODDIR/tools/core/platform-transition.sh"
mkdir -p "$G"

log(){ printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "$*" >> "$L"; }
getcfg(){ [ -r "$CFG" ] && grep -E "^$1=" "$CFG" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'; }
getstate(){ [ -r "$STATE" ] && grep -E "^$1=" "$STATE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'; }
cfg_set(){
  key="$1"; value="$2"
  mkdir -p "$(dirname "$CFG")" 2>/dev/null || true
  touch "$CFG" 2>/dev/null || true
  tmp="$CFG.tmp.$$"
  grep -v "^${key}=" "$CFG" 2>/dev/null > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CFG"
}
prop(){ getprop "$1" 2>/dev/null || true; }
remove_thermal_overlay(){
  rm -f "$MODDIR/system/vendor/etc/thermal_info_config.json" \
        "$MODDIR/system/vendor/etc/thermal_info_config_charge.json" \
        "$MODDIR/system/vendor/etc/thermal_info_config_throttling.json" 2>/dev/null || true
}
transition_phase(){
  [ -s "$TRANSITION_HELPER" ] || return 0
  MODDIR="$MODDIR" CONFIG_FILE="$CFG" sh "$TRANSITION_HELPER" "$1" >> "$L" 2>&1 || true
}

AUTO="$(getcfg AUTO_PROFILE_SWITCH)"
[ -n "$AUTO" ] || AUTO=1
case "$AUTO" in
  1|yes|true|on|enabled) ;;
  *) log "AUTO_SWITCH_SKIP reason=config_disabled value=$AUTO"; printf '%s\n' config_disabled > "$G/auto_profile_switch_state"; exit 0 ;;
esac

DEVICE="${THERMAL_DEVICE:-$(prop ro.product.device)}"
ANDROID="${THERMAL_ANDROID:-$(prop ro.build.version.release)}"
SDK="${THERMAL_SDK:-$(prop ro.build.version.sdk)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(prop ro.build.id)}"
INCREMENTAL="${THERMAL_INCREMENTAL:-$(prop ro.build.version.incremental)}"
FINGERPRINT="${THERMAL_FINGERPRINT:-$(prop ro.build.fingerprint)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$SDK" ] || SDK=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
[ -n "$INCREMENTAL" ] || INCREMENTAL=unknown
[ -n "$FINGERPRINT" ] || FINGERPRINT=unknown

write_state(){
  profile="$1"
  profile_state="$2"
  platform_supported="$3"
  build_evidence="$4"
  state_polling="$(getcfg THERMAL_POLLING_MODE)"
  state_outdoor="$(getcfg THERMAL_OUTDOOR_PROFILE)"
  state_zram_enabled="$(getcfg ENABLE_ZRAM_100P)"
  [ -n "$state_polling" ] || state_polling=mod
  [ -n "$state_outdoor" ] || state_outdoor=stock
  [ -n "$state_zram_enabled" ] || state_zram_enabled=0
  state_zram_materialized=no
  if [ "$state_zram_enabled" = 1 ] && [ -s "$MODDIR/system/vendor/etc/fstab.zram.100p" ]; then
    state_zram_materialized=yes
  fi
  {
    printf '%s\n' "module_id=$ID"
    printf '%s\n' "module_version=$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//')"
    printf '%s\n' "module_version_code=$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//')"
    printf '%s\n' "device=$DEVICE"
    printf '%s\n' "android=$ANDROID"
    printf '%s\n' "android_sdk=$SDK"
    printf '%s\n' "build_id=$BUILD_ID"
    printf '%s\n' "incremental=$INCREMENTAL"
    printf '%s\n' "fingerprint=$FINGERPRINT"
    printf '%s\n' "profile=$profile"
    printf '%s\n' "profile_state=$profile_state"
    printf '%s\n' "profile_state_contract=dynamic_local_validation_v1"
    printf '%s\n' "platform_supported=$platform_supported"
    printf '%s\n' "build_evidence=$build_evidence"
    printf '%s\n' "build_state=dynamic_${DEVICE}_${BUILD_ID}_${INCREMENTAL}"
    printf '%s\n' "build_guard_mode=dynamic_local_validation"
    printf '%s\n' "profile_source_build=$BUILD_ID"
    printf '%s\n' "profile_source_incremental=$INCREMENTAL"
    printf '%s\n' "profile_source_fingerprint=$FINGERPRINT"
    printf '%s\n' "auto_profile_switch=yes"
    printf '%s\n' "auto_profile_switch_state=$profile_state"
    printf '%s\n' "auto_profile_switch_at=$(date -Is 2>/dev/null || date)"
    printf '%s\n' "profile_materialized=$([ "$profile_state" = dynamic_local_validated ] && printf yes || printf no)"
    printf '%s\n' "expected_thermal_files=$([ "$profile_state" = dynamic_local_validated ] && printf dynamic_validated || printf absent)"
    printf '%s\n' "thermal_polling_effective=$state_polling"
    printf '%s\n' "thermal_outdoor_profile=$state_outdoor"
    printf '%s\n' "zram_fstab_materialized=$state_zram_materialized"
    printf '%s\n' "zram_enabled=$state_zram_enabled"
    printf '%s\n' 'runtime_selection_source=config.env'
  } > "$STATE"
}

if [ ! -r "$SUPPORTED_HELPER" ]; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  printf '%s\n' supported_helper_missing > "$G/auto_profile_switch_state"
  printf '%s\n' 'REINSTALL_REQUIRED=yes' > "$G/reinstall_required"
  transition_phase failed
  log "AUTO_SWITCH_BLOCK reason=supported_helper_missing action=thermal_only_disabled"
  exit 1
fi
. "$SUPPORTED_HELPER"

if ! thermal_supported_check "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID"; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  write_state stock unsupported_platform_stock_only no unsupported_platform
  printf '%s\n' unsupported_platform > "$G/auto_profile_switch_state"
  printf '%s\n' "$BUILD_ID" > "$G/unverified_build_id"
  printf '%s\n' 'REINSTALL_REQUIRED=no' > "$G/reinstall_required"
  transition_phase safe-disabled
  log "AUTO_SWITCH_BLOCK reason=unsupported_platform device=$DEVICE android=$ANDROID build=$BUILD_ID action=stock_only"
  exit 0
fi

BUILD_EVIDENCE="$(thermal_build_evidence_state "$SUPPORTED_JSON" "$DEVICE" "$ANDROID" "$BUILD_ID")"
PROFILE="dynamic/${DEVICE}/android${ANDROID}"
POLLING="$(getcfg THERMAL_POLLING_MODE)"
OUTDOOR="$(getcfg THERMAL_OUTDOOR_PROFILE)"
[ -n "$POLLING" ] || POLLING=mod
[ -n "$OUTDOOR" ] || OUTDOOR=stock

same_tuple=yes
[ "$(getstate device)" = "$DEVICE" ] || same_tuple=no
[ "$(getstate android)" = "$ANDROID" ] || same_tuple=no
[ "$(getstate build_id)" = "$BUILD_ID" ] || same_tuple=no
[ "$(getstate incremental)" = "$INCREMENTAL" ] || same_tuple=no
[ "$(getstate fingerprint)" = "$FINGERPRINT" ] || same_tuple=no
if [ "$same_tuple" = yes ] &&
   [ "$(getstate profile_state)" = materialization_failed ] &&
   [ "$(getcfg THERMAL_DISABLED)" = 1 ]; then
  remove_thermal_overlay
  printf '%s\n' previous_materialization_failed > "$G/auto_profile_switch_state"
  printf '%s\n' 'REINSTALL_REQUIRED=yes' > "$G/reinstall_required"
  transition_phase safe-disabled
  log "AUTO_SWITCH_SKIP reason=previous_materialization_failed action=remain_stock_only"
  exit 0
fi

NEED=0
[ "$(getstate profile)" = "$PROFILE" ] || NEED=1
[ "$(getstate android)" = "$ANDROID" ] || NEED=1
[ "$(getstate build_id)" = "$BUILD_ID" ] || NEED=1
[ "$(getstate incremental)" = "$INCREMENTAL" ] || NEED=1
[ "$(getstate fingerprint)" = "$FINGERPRINT" ] || NEED=1
[ "$(getcfg THERMAL_DISABLED)" = 0 ] || NEED=1
for required in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  [ -s "$MODDIR/system/vendor/etc/$required" ] || NEED=1
done

if [ "$NEED" -eq 0 ]; then
  printf '%s\n' current_profile_valid > "$G/auto_profile_switch_state"
  printf '%s\n' "$PROFILE" > "$G/selected_profile"
  log "AUTO_SWITCH_PASS reason=current_profile_valid profile=$PROFILE build=$BUILD_ID evidence=$BUILD_EVIDENCE"
  exit 0
fi

log "AUTO_SWITCH_TRIGGER reason=platform_tuple_or_overlay_changed profile=$PROFILE build=$BUILD_ID incremental=$INCREMENTAL"
if [ ! -s "$VALIDATED_PATCHER" ] ||
   ! sh "$VALIDATED_PATCHER" "$POLLING" "$OUTDOOR" "$MODDIR"; then
  remove_thermal_overlay
  cfg_set THERMAL_DISABLED 1
  write_state "$PROFILE" materialization_failed yes "$BUILD_EVIDENCE"
  printf '%s\n' validated_patching_failed > "$G/auto_profile_switch_state"
  printf '%s\n' 'REINSTALL_REQUIRED=yes' > "$G/reinstall_required"
  transition_phase failed
  log "AUTO_SWITCH_BLOCK reason=validated_patching_failed action=thermal_only_disabled"
  exit 1
fi

cfg_set THERMAL_DISABLED 0
cfg_set CANARY_DIAGNOSTIC_MODE 0
rm -f "$G/disabled_reason" "$G/profile_stale_after_ota" "$G/reinstall_required" "$G/unsupported_build_id" 2>/dev/null || true
write_state "$PROFILE" dynamic_local_validated yes "$BUILD_EVIDENCE"
printf '%s\n' materialized_validated > "$G/auto_profile_switch_state"
printf '%s\n' "$PROFILE" > "$G/selected_profile"
transition_phase materialized
log "AUTO_SWITCH_DONE profile=$PROFILE build=$BUILD_ID incremental=$INCREMENTAL evidence=$BUILD_EVIDENCE validation=independent"
exit 0
