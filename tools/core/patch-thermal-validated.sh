#!/system/bin/sh
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
PATCHER="$MODPATH/tools/core/patch-thermal.sh"
DELTA_HELPER="$MODPATH/tools/core/verify-outdoor-delta.sh"
STATE_HELPER="$MODPATH/tools/core/validation-state.sh"
TARGET_DIR="$MODPATH/system/vendor/etc"
GUARD_DIR="$MODPATH/guard"

LEGACY_REPORT_MODULE="$MODPATH/validation_report.json"
LEGACY_REPORT_DATA="$DATA_ROOT/validation_report.json"
LEGACY_PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"
LEGACY_DELTA_MODULE="$GUARD_DIR/outdoor-delta-validation.env"
LEGACY_DELTA_DATA="$DATA_ROOT/outdoor-delta-validation.env"

RUN_LOG="$GUARD_DIR/.patch-validated-run.$$"
DELTA_TMP="$GUARD_DIR/.outdoor-delta-validation.env.$$"
BACKUP_DIR="$GUARD_DIR/.validation-backup.$$"
VALIDATED=0

case "$POLLING_MODE" in stock|mod) ;; *) exit 21 ;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) exit 22 ;; esac

[ -s "$PATCHER" ] || exit 23
[ -s "$DELTA_HELPER" ] || exit 24
[ -s "$STATE_HELPER" ] || exit 25

. "$STATE_HELPER"
thermal_validation_init || exit 26
mkdir -p "$GUARD_DIR" "$BACKUP_DIR"

backup_path() {
  _path="$1"
  _name="$2"
  if [ -e "$_path" ] || [ -L "$_path" ]; then
    cp -fpR "$_path" "$BACKUP_DIR/$_name" 2>/dev/null || true
    printf '%s\n' present
  else
    printf '%s\n' absent
  fi
}

restore_path() {
  _path="$1"
  _name="$2"
  _state="$3"
  rm -rf "$_path" 2>/dev/null || true
  if [ "$_state" = present ] && [ -e "$BACKUP_DIR/$_name" ]; then
    mkdir -p "${_path%/*}" 2>/dev/null || true
    cp -fpR "$BACKUP_DIR/$_name" "$_path" 2>/dev/null || true
  fi
}

target_state="$(backup_path "$TARGET_DIR" target)"
validation_state="$(backup_path "$THERMAL_VALIDATION_DIR" validation)"
legacy_report_module_state="$(backup_path "$LEGACY_REPORT_MODULE" legacy-report-module)"
legacy_report_data_state="$(backup_path "$LEGACY_REPORT_DATA" legacy-report-data)"
legacy_patch_state="$(backup_path "$LEGACY_PATCH_MANIFEST" legacy-patch)"
legacy_delta_module_state="$(backup_path "$LEGACY_DELTA_MODULE" legacy-delta-module)"
legacy_delta_data_state="$(backup_path "$LEGACY_DELTA_DATA" legacy-delta-data)"

rollback_outputs() {
  restore_path "$TARGET_DIR" target "$target_state"
  restore_path "$THERMAL_VALIDATION_DIR" validation "$validation_state"
  restore_path "$LEGACY_REPORT_MODULE" legacy-report-module "$legacy_report_module_state"
  restore_path "$LEGACY_REPORT_DATA" legacy-report-data "$legacy_report_data_state"
  restore_path "$LEGACY_PATCH_MANIFEST" legacy-patch "$legacy_patch_state"
  restore_path "$LEGACY_DELTA_MODULE" legacy-delta-module "$legacy_delta_module_state"
  restore_path "$LEGACY_DELTA_DATA" legacy-delta-data "$legacy_delta_data_state"
}

cleanup() {
  _rc="$?"
  if [ "$_rc" -ne 0 ] && [ "$VALIDATED" -ne 1 ]; then
    rollback_outputs
  fi
  rm -f "$RUN_LOG" "$DELTA_TMP" 2>/dev/null || true
  rm -rf "$BACKUP_DIR" 2>/dev/null || true
  return "$_rc"
}
trap cleanup EXIT HUP INT TERM

# The lower-level patcher still writes its historical output paths. Remove
# legacy symlinks before invoking it, then promote its outputs into one
# canonical persistent validation directory after all independent checks pass.
rm -f \
  "$LEGACY_REPORT_MODULE" \
  "$LEGACY_REPORT_DATA" \
  "$LEGACY_PATCH_MANIFEST" \
  "$LEGACY_DELTA_MODULE" \
  "$LEGACY_DELTA_DATA" 2>/dev/null || true

if sh "$PATCHER" "$POLLING_MODE" "$OUTDOOR_PROFILE" "$MODPATH" > "$RUN_LOG" 2>&1; then
  cat "$RUN_LOG"
else
  patch_rc="$?"
  cat "$RUN_LOG"
  exit "$patch_rc"
fi

DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"

DELTA=0
case "$OUTDOOR_PROFILE" in
  outdoor-safe) DELTA=1 ;;
  outdoor-plus) DELTA=2 ;;
  outdoor-extended) DELTA=3 ;;
esac

validated_files=0
target_zone_total=0
threshold_array_total=0
threshold_value_total=0

for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  source_file="$CACHE_DIR/$file"
  output_file="$TARGET_DIR/$file"

  [ -s "$source_file" ] || {
    printf '%s\n' "PATCH_THERMAL_DELTA_REASON=source_missing_$file"
    exit 60
  }
  [ -s "$output_file" ] || {
    printf '%s\n' "PATCH_THERMAL_DELTA_REASON=output_missing_$file"
    exit 61
  }

  if metrics="$(sh "$DELTA_HELPER" "$source_file" "$output_file" "$DELTA")"; then
    set -- $metrics
    [ "$#" -eq 3 ] || exit 62
    target_zones="$1"
    threshold_arrays="$2"
    threshold_values="$3"
  else
    printf '%s\n' "PATCH_THERMAL_DELTA_REASON=exact_delta_invalid_${file}_expected_${DELTA}"
    exit 63
  fi

  validated_files=$((validated_files + 1))
  target_zone_total=$((target_zone_total + target_zones))
  threshold_array_total=$((threshold_array_total + threshold_arrays))
  threshold_value_total=$((threshold_value_total + threshold_values))
done

[ "$validated_files" -eq 3 ] || exit 64
[ "$target_zone_total" -gt 0 ] || exit 65
[ "$threshold_array_total" -eq "$target_zone_total" ] || exit 66
[ "$threshold_value_total" -gt 0 ] || exit 67

{
  printf '%s\n' 'schema=pixel-thermal-outdoor-delta-validation-v1'
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "polling_mode=$POLLING_MODE"
  printf '%s\n' "outdoor_profile=$OUTDOOR_PROFILE"
  printf '%s\n' "expected_delta=$DELTA"
  printf '%s\n' "validated_files=$validated_files"
  printf '%s\n' "target_zone_count=$target_zone_total"
  printf '%s\n' "threshold_array_count=$threshold_array_total"
  printf '%s\n' "threshold_value_count=$threshold_value_total"
  printf '%s\n' 'validation=passed'
} > "$DELTA_TMP"

[ -s "$LEGACY_REPORT_MODULE" ] || exit 68
[ -s "$LEGACY_PATCH_MANIFEST" ] || exit 69

thermal_validation_publish \
  "$LEGACY_REPORT_MODULE" \
  "$THERMAL_VALIDATION_REPORT" \
  0644 || exit 70
thermal_validation_publish \
  "$LEGACY_PATCH_MANIFEST" \
  "$THERMAL_VALIDATION_PATCH_MANIFEST" \
  0644 || exit 71
thermal_validation_publish \
  "$DELTA_TMP" \
  "$THERMAL_VALIDATION_DELTA" \
  0644 || exit 72

thermal_validation_write_state \
  "$DEVICE" \
  "$BUILD_ID" \
  "$POLLING_MODE" \
  "$OUTDOOR_PROFILE" || exit 73

thermal_validation_refresh_legacy_links "$MODPATH" || exit 74

VALIDATED=1
rm -rf "$BACKUP_DIR"
printf '%s\n' 'PATCH_THERMAL_DELTA_VALIDATION=pass'
printf '%s\n' "PATCH_THERMAL_DELTA_EXPECTED=$DELTA"
printf '%s\n' "PATCH_THERMAL_DELTA_FILES=$validated_files"
printf '%s\n' "PATCH_THERMAL_DELTA_TARGET_ZONES=$target_zone_total"
printf '%s\n' "PATCH_THERMAL_DELTA_THRESHOLD_ARRAYS=$threshold_array_total"
printf '%s\n' "PATCH_THERMAL_DELTA_THRESHOLD_VALUES=$threshold_value_total"
printf '%s\n' "PATCH_THERMAL_VALIDATION_DIR=$THERMAL_VALIDATION_DIR"
printf '%s\n' "PATCH_THERMAL_DELTA_REPORT=$THERMAL_VALIDATION_DELTA"
printf '%s\n' 'PATCH_THERMAL_LEGACY_PATHS=symlinks_only'
trap - EXIT HUP INT TERM
rm -f "$RUN_LOG" "$DELTA_TMP"
exit 0
