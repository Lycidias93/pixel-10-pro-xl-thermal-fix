#!/system/bin/sh
# Detect and quarantine device/Android/build transitions before module mounts.
set -eu

ID="${ID:-pixel-10-pro-xl-thermal-fix}"
MODDIR="${MODDIR:-${0%/*}/../..}"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
CFG="${CONFIG_FILE:-$DATA_ROOT/config.env}"
G="${GUARD_DIR:-$MODDIR/guard}"
STATE="${INSTALL_STATE:-$MODDIR/install-state.txt}"
TRANSITION="$G/platform-transition.env"
VALIDATION_DIR="$DATA_ROOT/validation"

prop() {
  _override="$1"
  _name="$2"
  eval "_value=\${$_override:-}"
  if [ -n "$_value" ]; then printf '%s\n' "$_value"; else getprop "$_name" 2>/dev/null || true; fi
}

state_get() {
  [ -r "$STATE" ] || return 0
  grep -E "^$1=" "$STATE" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

kv_get() {
  [ -r "$2" ] || return 0
  grep -E "^$1=" "$2" 2>/dev/null | tail -n 1 | sed "s/^$1=//" | tr -d '\r'
}

cfg_set() {
  _key="$1"; _value="$2"
  mkdir -p "${CFG%/*}" 2>/dev/null || true
  touch "$CFG"
  _tmp="$CFG.tmp.$$"
  grep -v "^${_key}=" "$CFG" 2>/dev/null > "$_tmp" || true
  printf '%s=%s\n' "$_key" "$_value" >> "$_tmp"
  chmod 0600 "$_tmp" 2>/dev/null || true
  mv "$_tmp" "$CFG"
}

transition_set() {
  _key="$1"; _value="$2"
  mkdir -p "$G"
  _tmp="$TRANSITION.tmp.$$"
  if [ -r "$TRANSITION" ]; then grep -v "^${_key}=" "$TRANSITION" > "$_tmp" 2>/dev/null || true; else printf '%s\n' 'schema=pixel-thermal-platform-transition-v1' > "$_tmp"; fi
  printf '%s=%s\n' "$_key" "$_value" >> "$_tmp"
  chmod 0600 "$_tmp" 2>/dev/null || true
  mv "$_tmp" "$TRANSITION"
}

DEVICE="$(prop THERMAL_DEVICE ro.product.device)"
ANDROID="$(prop THERMAL_ANDROID ro.build.version.release)"
BUILD_ID="$(prop THERMAL_BUILD_ID ro.build.id)"
INCREMENTAL="$(prop THERMAL_INCREMENTAL ro.build.version.incremental)"
FINGERPRINT="$(prop THERMAL_FINGERPRINT ro.build.fingerprint)"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$ANDROID" ] || ANDROID=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
[ -n "$INCREMENTAL" ] || INCREMENTAL=unknown
[ -n "$FINGERPRINT" ] || FINGERPRINT=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"

OLD_DEVICE="$(state_get device)"
OLD_ANDROID="$(state_get android)"
OLD_BUILD="$(state_get build_id)"
OLD_INCREMENTAL="$(state_get incremental)"
OLD_FINGERPRINT="$(state_get fingerprint)"

reason=none
if [ ! -s "$STATE" ]; then reason=install_state_missing
elif [ "${OLD_DEVICE:-unknown}" != "$DEVICE" ]; then reason=device_changed
elif [ "${OLD_ANDROID:-unknown}" != "$ANDROID" ]; then reason=android_changed
elif [ "${OLD_BUILD:-unknown}" != "$BUILD_ID" ]; then reason=build_changed
elif [ "${OLD_INCREMENTAL:-unknown}" != "$INCREMENTAL" ]; then reason=incremental_changed
elif [ "${OLD_FINGERPRINT:-unknown}" != "$FINGERPRINT" ]; then reason=fingerprint_changed
fi

write_observation() {
  mkdir -p "$G"
  _tmp="$TRANSITION.tmp.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-platform-transition-v1'
    printf '%s\n' "transition_pending=$1"
    printf '%s\n' "phase=$2"
    printf '%s\n' "reason=$reason"
    printf '%s\n' "old_device=${OLD_DEVICE:-unknown}"
    printf '%s\n' "old_android=${OLD_ANDROID:-unknown}"
    printf '%s\n' "old_build_id=${OLD_BUILD:-unknown}"
    printf '%s\n' "old_incremental=${OLD_INCREMENTAL:-unknown}"
    printf '%s\n' "old_fingerprint=${OLD_FINGERPRINT:-unknown}"
    printf '%s\n' "device=$DEVICE"
    printf '%s\n' "android=$ANDROID"
    printf '%s\n' "build_id=$BUILD_ID"
    printf '%s\n' "incremental=$INCREMENTAL"
    printf '%s\n' "fingerprint=$FINGERPRINT"
    printf '%s\n' "observed_at=$(date -Is 2>/dev/null || date)"
  } > "$_tmp"
  chmod 0600 "$_tmp" 2>/dev/null || true
  mv "$_tmp" "$TRANSITION"
}

prepare() {
  if [ "$reason" = none ]; then
    if [ ! -r "$TRANSITION" ]; then write_observation no current; fi
    printf '%s\n' 'PLATFORM_TRANSITION=none'
    return 0
  fi

  mkdir -p "$G" "$DATA_ROOT"
  write_observation yes prepared

  # Remove only this module's controlled Thermal overlays. The wildcard is
  # intentional because vNext admits either throttling.json or lpm.json as the
  # third controlled file depending on device family.
  rm -f "$MODDIR/system/vendor/etc"/thermal_info_config*.json 2>/dev/null || true

  rm -rf "$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG" 2>/dev/null || true
  rm -rf "$VALIDATION_DIR" 2>/dev/null || true
  rm -f "$MODDIR/validation_report.json" \
        "$DATA_ROOT/validation_report.json" \
        "$MODDIR/guard/patch-manifest.tsv" \
        "$MODDIR/guard/outdoor-delta-validation.env" \
        "$MODDIR/guard/thermal-layout.env" \
        "$DATA_ROOT/outdoor-delta-validation.env" 2>/dev/null || true

  cfg_set THERMAL_DISABLED 1
  printf '%s\n' 'PROFILE_STALE_AFTER_OTA=yes' > "$G/profile_stale_after_ota"
  if [ "$(kv_get VNEXT_EXPERIMENTAL_PLATFORM "$CFG")" = 1 ]; then
    printf '%s\n' 'REINSTALL_REQUIRED=yes' > "$G/reinstall_required"
    printf '%s\n' experimental_platform_reinstall_required > "$G/auto_profile_switch_reason"
  else
    printf '%s\n' 'REINSTALL_REQUIRED=no' > "$G/reinstall_required"
    printf '%s\n' "$reason" > "$G/auto_profile_switch_reason"
  fi

  printf '%s\n' 'PLATFORM_TRANSITION=prepared'
  printf '%s\n' "PLATFORM_TRANSITION_REASON=$reason"
}

mark_phase() {
  _phase="$1"
  [ -r "$TRANSITION" ] || write_observation yes "$_phase"
  transition_set phase "$_phase"
  transition_set transition_pending yes
  transition_set phase_at "$(date -Is 2>/dev/null || date)"
  printf '%s\n' "PLATFORM_TRANSITION_PHASE=$_phase"
}

complete() {
  [ -r "$TRANSITION" ] || write_observation no runtime_verified
  transition_set phase runtime_verified
  transition_set transition_pending no
  transition_set completed_at "$(date -Is 2>/dev/null || date)"
  rm -f "$G/profile_stale_after_ota" "$G/reinstall_required" 2>/dev/null || true
  printf '%s\n' 'PLATFORM_TRANSITION=runtime_verified'
}

status() {
  if [ -r "$TRANSITION" ]; then cat "$TRANSITION"; else printf '%s\n' 'schema=pixel-thermal-platform-transition-v1' 'transition_pending=no' 'phase=absent' 'reason=none'; fi
}

case "${1:-status}" in
  prepare) prepare ;;
  materialized) mark_phase materialized_validated ;;
  safe-disabled) mark_phase safe_disabled ;;
  failed) mark_phase materialization_failed ;;
  complete) complete ;;
  status) status ;;
  *) printf '%s\n' "PLATFORM_TRANSITION_ERROR=unknown_command_${1:-empty}"; exit 2 ;;
esac
