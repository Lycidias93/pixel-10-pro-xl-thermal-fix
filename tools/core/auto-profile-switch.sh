#!/system/bin/sh
ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
G="$MODDIR/guard"
L="$G/auto-profile-switch.log"
STATE="${THERMAL_INSTALL_STATE_FILE:-$MODDIR/install-state.txt}"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
CFG="${THERMAL_CONFIG_FILE:-$DATA_ROOT/config.env}"
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

state_set(){
  aps_key="$1"
  aps_value="$2"
  mkdir -p "${STATE%/*}" 2>/dev/null || true
  touch "$STATE" 2>/dev/null || true
  aps_tmp="$STATE.tmp.$$"
  grep -v "^${aps_key}=" "$STATE" 2>/dev/null > "$aps_tmp" || true
  printf '%s=%s
' "$aps_key" "$aps_value" >> "$aps_tmp"
  chmod 0644 "$aps_tmp" 2>/dev/null || true
  mv "$aps_tmp" "$STATE"
}
state_profile_state_for_runtime(){
  aps_runtime="$1"
  aps_evidence="$2"
  case "$aps_runtime:$aps_evidence" in
    dynamic_local_validated:exact_verified) printf '%s
' dynamic_stock_validated_exact_verified ;;
    *) printf '%s
' "$aps_runtime" ;;
  esac
}
write_state(){
  aps_profile="$1"
  aps_runtime_state="$2"
  aps_platform_supported="$3"
  aps_build_evidence="$4"
  aps_polling="$(getcfg THERMAL_POLLING_MODE)"
  aps_outdoor="$(getcfg THERMAL_OUTDOOR_PROFILE)"
  aps_settings_mode="$(getcfg THERMAL_SETTINGS_MODE)"
  aps_last_outdoor="$(getcfg LAST_THERMAL_OUTDOOR_PROFILE)"
  aps_last_polling="$(getcfg LAST_THERMAL_POLLING_MODE)"
  aps_ptune_menu="$(getcfg PTUNE_OVERRIDE_MENU)"
  aps_last_ptune="$(getcfg LAST_PTUNE_OVERRIDE)"
  aps_zram_enabled="$(getcfg ENABLE_ZRAM_100P)"
  aps_zram_ack="$(getcfg ZRAM_RISK_ACK)"
  aps_zram_eh_ack="$(getcfg ZRAM_EH_RISK_ACK)"
  aps_debug_mode="$(getcfg DEBUG_MODE)"
  aps_last_debug="$(getcfg LAST_DEBUG_MODE)"
  aps_ptune_ack="$(cat "$G/ptune_risk_ack" 2>/dev/null || true)"
  [ -n "$aps_polling" ] || aps_polling=mod
  [ -n "$aps_outdoor" ] || aps_outdoor=stock
  [ -n "$aps_settings_mode" ] || aps_settings_mode=unknown
  [ -n "$aps_last_outdoor" ] || aps_last_outdoor="$aps_outdoor"
  [ -n "$aps_last_polling" ] || aps_last_polling="$aps_polling"
  [ -n "$aps_ptune_menu" ] || aps_ptune_menu=off
  [ -n "$aps_last_ptune" ] || aps_last_ptune=0
  [ -n "$aps_zram_enabled" ] || aps_zram_enabled=0
  [ -n "$aps_zram_ack" ] || aps_zram_ack=unset
  [ -n "$aps_zram_eh_ack" ] || aps_zram_eh_ack=unset
  [ -n "$aps_debug_mode" ] || aps_debug_mode=0
  [ -n "$aps_last_debug" ] || aps_last_debug=silent
  [ -n "$aps_ptune_ack" ] || aps_ptune_ack=not_present
  aps_zram_materialized=no
  if [ "$aps_zram_enabled" = 1 ] && [ -s "$MODDIR/system/vendor/etc/fstab.zram.100p" ]; then
    aps_zram_materialized=yes
  fi
  aps_profile_state="$(state_profile_state_for_runtime "$aps_runtime_state" "$aps_build_evidence")"

  state_set install_state_schema pixel-thermal-install-state-v2
  state_set install_state_owner install-finalize-preserved-by-auto-profile-switch
  state_set module_id "$ID"
  state_set module_version "$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//')"
  state_set module_version_code "$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//')"
  state_set device "$DEVICE"
  state_set android "$ANDROID"
  state_set android_sdk "$SDK"
  state_set build_id "$BUILD_ID"
  state_set incremental "$INCREMENTAL"
  state_set fingerprint "$FINGERPRINT"
  state_set profile "$aps_profile"
  state_set profile_state "$aps_profile_state"
  state_set profile_state_contract dynamic_stock_derived_validation_v2
  state_set runtime_profile_state "$aps_runtime_state"
  state_set runtime_profile_state_contract dynamic_local_validation_v1
  state_set platform_supported "$aps_platform_supported"
  state_set build_evidence "$aps_build_evidence"
  state_set build_state "dynamic_${DEVICE}_${BUILD_ID}_${INCREMENTAL}"
  state_set build_guard_mode dynamic_local_validation
  state_set profile_source_build "$BUILD_ID"
  state_set profile_source_incremental "$INCREMENTAL"
  state_set profile_source_fingerprint "$FINGERPRINT"
  state_set auto_profile_switch yes
  state_set auto_profile_switch_state "$aps_runtime_state"
  state_set auto_profile_switch_at "$(date -Is 2>/dev/null || date)"
  state_set profile_materialized "$([ "$aps_runtime_state" = dynamic_local_validated ] && printf yes || printf no)"
  state_set expected_thermal_files "$([ "$aps_runtime_state" = dynamic_local_validated ] && printf dynamic_validated || printf absent)"
  state_set thermal_polling_effective "$aps_polling"
  state_set thermal_outdoor_profile "$aps_outdoor"
  state_set thermal_settings_mode "$aps_settings_mode"
  state_set last_thermal_outdoor_profile "$aps_last_outdoor"
  state_set last_thermal_polling_mode "$aps_last_polling"
  state_set ptune_override_menu "$aps_ptune_menu"
  state_set last_ptune_override "$aps_last_ptune"
  state_set ptune_risk_ack "$aps_ptune_ack"
  state_set zram_fstab_materialized "$aps_zram_materialized"
  state_set zram_enabled "$aps_zram_enabled"
  state_set zram_risk_ack "$aps_zram_ack"
  state_set zram_eh_risk_ack "$aps_zram_eh_ack"
  state_set debug_mode "$aps_debug_mode"
  state_set last_debug_mode "$aps_last_debug"
  state_set runtime_selection_source config.env
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
ZRAM_ENABLED="$(getcfg ENABLE_ZRAM_100P)"
[ -n "$POLLING" ] || POLLING=mod
[ -n "$OUTDOOR" ] || OUTDOOR=stock
[ -n "$ZRAM_ENABLED" ] || ZRAM_ENABLED=0
ZRAM_MATERIALIZED=no
if [ "$ZRAM_ENABLED" = 1 ] && [ -s "$MODDIR/system/vendor/etc/fstab.zram.100p" ]; then
  ZRAM_MATERIALIZED=yes
fi
MODULE_VERSION="$(grep -E '^version=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^version=//')"
MODULE_VERSION_CODE="$(grep -E '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | head -n 1 | sed 's/^versionCode=//')"

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
  state_refresh=0
  [ "$(getstate module_version)" = "$MODULE_VERSION" ] || state_refresh=1
  [ "$(getstate module_version_code)" = "$MODULE_VERSION_CODE" ] || state_refresh=1
  expected_profile_state="$(state_profile_state_for_runtime dynamic_local_validated "$BUILD_EVIDENCE")"
  [ "$(getstate profile_state)" = "$expected_profile_state" ] || state_refresh=1
  [ "$(getstate profile_state_contract)" = dynamic_stock_derived_validation_v2 ] || state_refresh=1
  [ "$(getstate runtime_profile_state)" = dynamic_local_validated ] || state_refresh=1
  [ "$(getstate runtime_profile_state_contract)" = dynamic_local_validation_v1 ] || state_refresh=1
  [ "$(getstate platform_supported)" = yes ] || state_refresh=1
  [ "$(getstate build_evidence)" = "$BUILD_EVIDENCE" ] || state_refresh=1
  [ "$(getstate thermal_polling_effective)" = "$POLLING" ] || state_refresh=1
  [ "$(getstate thermal_outdoor_profile)" = "$OUTDOOR" ] || state_refresh=1
  [ "$(getstate thermal_settings_mode)" = "$(getcfg THERMAL_SETTINGS_MODE)" ] || state_refresh=1
  [ "$(getstate zram_enabled)" = "$ZRAM_ENABLED" ] || state_refresh=1
  [ "$(getstate zram_fstab_materialized)" = "$ZRAM_MATERIALIZED" ] || state_refresh=1
  [ "$(getstate zram_risk_ack)" = "$(getcfg ZRAM_RISK_ACK)" ] || state_refresh=1
  [ "$(getstate zram_eh_risk_ack)" = "$(getcfg ZRAM_EH_RISK_ACK)" ] || state_refresh=1
  [ "$(getstate debug_mode)" = "$(getcfg DEBUG_MODE)" ] || state_refresh=1
  [ "$(getstate last_debug_mode)" = "$(getcfg LAST_DEBUG_MODE)" ] || state_refresh=1
  [ "$(getstate runtime_selection_source)" = config.env ] || state_refresh=1
  if [ "$state_refresh" -eq 1 ]; then
    write_state "$PROFILE" dynamic_local_validated yes "$BUILD_EVIDENCE"
    log "AUTO_SWITCH_STATE_REFRESH reason=runtime_state_contract_drift profile=$PROFILE build=$BUILD_ID evidence=$BUILD_EVIDENCE"
  fi
  printf '%s\n' current_profile_valid > "$G/auto_profile_switch_state"
  printf '%s\n' "$PROFILE" > "$G/selected_profile"
  log "AUTO_SWITCH_PASS reason=current_profile_valid profile=$PROFILE build=$BUILD_ID evidence=$BUILD_EVIDENCE state_refresh=$state_refresh"
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
