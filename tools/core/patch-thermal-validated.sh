#!/system/bin/sh
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
PATCHER="$MODPATH/tools/core/patch-thermal.sh"
DELTA_HELPER="$MODPATH/tools/core/verify-outdoor-delta.sh"
TARGET_DIR="$MODPATH/system/vendor/etc"
GUARD_DIR="$MODPATH/guard"
REPORT_MODULE="$MODPATH/validation_report.json"
REPORT_DATA="$DATA_ROOT/validation_report.json"
PATCH_MANIFEST="$GUARD_DIR/patch-manifest.tsv"
DELTA_REPORT="$GUARD_DIR/outdoor-delta-validation.env"
DELTA_REPORT_DATA="$DATA_ROOT/outdoor-delta-validation.env"
RUN_LOG="$GUARD_DIR/.patch-validated-run.$$"
REPORT_TMP="$GUARD_DIR/.outdoor-delta-validation.env.$$"
BACKUP_DIR="$GUARD_DIR/.outdoor-delta-backup.$$"
VALIDATED=0
HAD_TARGET=0
HAD_MANIFEST=0
HAD_REPORT_MODULE=0
HAD_REPORT_DATA=0
HAD_DELTA_REPORT=0
HAD_DELTA_REPORT_DATA=0

case "$POLLING_MODE" in stock|mod) ;; *) exit 21 ;; esac
case "$OUTDOOR_PROFILE" in stock|outdoor-safe|outdoor-plus|outdoor-extended) ;; *) exit 22 ;; esac

[ -s "$PATCHER" ] || exit 23
[ -s "$DELTA_HELPER" ] || exit 24
mkdir -p "$GUARD_DIR" "$DATA_ROOT" "$BACKUP_DIR"

backup_file() {
  source_path="$1"
  backup_name="$2"
  if [ -e "$source_path" ]; then
    cp -fp "$source_path" "$BACKUP_DIR/$backup_name"
    return 0
  fi
  return 1
}

restore_file() {
  target_path="$1"
  backup_name="$2"
  had_file="$3"
  if [ "$had_file" -eq 1 ]; then
    cp -fp "$BACKUP_DIR/$backup_name" "$target_path" 2>/dev/null || true
  else
    rm -f "$target_path" 2>/dev/null || true
  fi
}

rollback_runtime_outputs() {
  rm -rf "$TARGET_DIR" 2>/dev/null || true
  if [ "$HAD_TARGET" -eq 1 ] && [ -d "$BACKUP_DIR/target" ]; then
    mkdir -p "${TARGET_DIR%/*}"
    cp -fpR "$BACKUP_DIR/target" "$TARGET_DIR" 2>/dev/null || true
  fi
  restore_file "$PATCH_MANIFEST" patch-manifest.tsv "$HAD_MANIFEST"
  restore_file "$REPORT_MODULE" validation-report-module.json "$HAD_REPORT_MODULE"
  restore_file "$REPORT_DATA" validation-report-data.json "$HAD_REPORT_DATA"
  restore_file "$DELTA_REPORT" outdoor-delta-module.env "$HAD_DELTA_REPORT"
  restore_file "$DELTA_REPORT_DATA" outdoor-delta-data.env "$HAD_DELTA_REPORT_DATA"
}

cleanup() {
  rc="$?"
  if [ "$rc" -ne 0 ] && [ "$VALIDATED" -ne 1 ]; then
    rollback_runtime_outputs
  fi
  rm -f "$RUN_LOG" "$REPORT_TMP" 2>/dev/null || true
  rm -rf "$BACKUP_DIR" 2>/dev/null || true
  return "$rc"
}
trap cleanup EXIT HUP INT TERM

if [ -d "$TARGET_DIR" ]; then
  cp -fpR "$TARGET_DIR" "$BACKUP_DIR/target"
  HAD_TARGET=1
fi
backup_file "$PATCH_MANIFEST" patch-manifest.tsv && HAD_MANIFEST=1 || true
backup_file "$REPORT_MODULE" validation-report-module.json && HAD_REPORT_MODULE=1 || true
backup_file "$REPORT_DATA" validation-report-data.json && HAD_REPORT_DATA=1 || true
backup_file "$DELTA_REPORT" outdoor-delta-module.env && HAD_DELTA_REPORT=1 || true
backup_file "$DELTA_REPORT_DATA" outdoor-delta-data.env && HAD_DELTA_REPORT_DATA=1 || true

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
  validated_files=$(( validated_files + 1 ))
  target_zone_total=$(( target_zone_total + target_zones ))
  threshold_array_total=$(( threshold_array_total + threshold_arrays ))
  threshold_value_total=$(( threshold_value_total + threshold_values ))
done

[ "$validated_files" -eq 3 ] || exit 64
[ "$target_zone_total" -gt 0 ] || exit 65
[ "$threshold_array_total" -eq "$target_zone_total" ] || exit 66
[ "$threshold_value_total" -gt 0 ] || exit 67

{
  printf '%s\n' "schema=pixel-thermal-outdoor-delta-validation-v1"
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "polling_mode=$POLLING_MODE"
  printf '%s\n' "outdoor_profile=$OUTDOOR_PROFILE"
  printf '%s\n' "expected_delta=$DELTA"
  printf '%s\n' "validated_files=$validated_files"
  printf '%s\n' "target_zone_count=$target_zone_total"
  printf '%s\n' "threshold_array_count=$threshold_array_total"
  printf '%s\n' "threshold_value_count=$threshold_value_total"
  printf '%s\n' "validation=passed"
} > "$REPORT_TMP"

mv "$REPORT_TMP" "$DELTA_REPORT"
cp -fp "$DELTA_REPORT" "$DELTA_REPORT_DATA"
chmod 0644 "$DELTA_REPORT" "$DELTA_REPORT_DATA" 2>/dev/null || true

VALIDATED=1
rm -rf "$BACKUP_DIR"
printf '%s\n' "PATCH_THERMAL_DELTA_VALIDATION=pass"
printf '%s\n' "PATCH_THERMAL_DELTA_EXPECTED=$DELTA"
printf '%s\n' "PATCH_THERMAL_DELTA_FILES=$validated_files"
printf '%s\n' "PATCH_THERMAL_DELTA_TARGET_ZONES=$target_zone_total"
printf '%s\n' "PATCH_THERMAL_DELTA_THRESHOLD_ARRAYS=$threshold_array_total"
printf '%s\n' "PATCH_THERMAL_DELTA_THRESHOLD_VALUES=$threshold_value_total"
printf '%s\n' "PATCH_THERMAL_DELTA_REPORT=$DELTA_REPORT"
trap - EXIT HUP INT TERM
rm -f "$RUN_LOG"
exit 0
