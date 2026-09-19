#!/system/bin/sh
# Independent vNext validator for legacy three-file and bounded Include-graph layouts.
set -eu

POLLING_MODE="${1:-mod}"
OUTDOOR_PROFILE="${2:-stock}"
MODPATH="${3:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
PIXEL11_HYSTERESIS_MODE="${4:-stock}"
ID="pixel-10-pro-xl-thermal-fix"
DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$ID}"
PATCHER="$MODPATH/tools/core/patch-thermal.sh"
DELTA_HELPER="$MODPATH/tools/core/verify-outdoor-delta.sh"
STATE_HELPER="$MODPATH/tools/core/validation-state.sh"
LAYOUT_HELPER="$MODPATH/tools/core/thermal-layout.sh"
TARGET_DIR="$MODPATH/system/vendor/etc"
GUARD_DIR="$MODPATH/guard"
LAYOUT_ENV="$GUARD_DIR/thermal-layout.env"
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
case "$PIXEL11_HYSTERESIS_MODE" in
  stock|hysteresis|max-release-step|combined) ;;
  mod) PIXEL11_HYSTERESIS_MODE=combined ;;
  *) exit 22 ;;
esac
[ -s "$PATCHER" ] || exit 23
[ -s "$DELTA_HELPER" ] || exit 24
[ -s "$STATE_HELPER" ] || exit 25
[ -s "$LAYOUT_HELPER" ] || exit 26
. "$STATE_HELPER"
. "$LAYOUT_HELPER"
thermal_validation_init || exit 27
mkdir -p "$GUARD_DIR" "$BACKUP_DIR"

backup_path() { _p="$1"; _n="$2"; if [ -e "$_p" ] || [ -L "$_p" ]; then cp -fpR "$_p" "$BACKUP_DIR/$_n" 2>/dev/null || true; printf '%s\n' present; else printf '%s\n' absent; fi; }
restore_path() { _p="$1"; _n="$2"; _s="$3"; rm -rf "$_p" 2>/dev/null || true; if [ "$_s" = present ] && [ -e "$BACKUP_DIR/$_n" ]; then mkdir -p "${_p%/*}" 2>/dev/null || true; cp -fpR "$BACKUP_DIR/$_n" "$_p" 2>/dev/null || true; fi; }

target_state="$(backup_path "$TARGET_DIR" target)"
validation_state="$(backup_path "$THERMAL_VALIDATION_DIR" validation)"
report_module_state="$(backup_path "$LEGACY_REPORT_MODULE" report-module)"
report_data_state="$(backup_path "$LEGACY_REPORT_DATA" report-data)"
patch_state="$(backup_path "$LEGACY_PATCH_MANIFEST" patch)"
delta_module_state="$(backup_path "$LEGACY_DELTA_MODULE" delta-module)"
delta_data_state="$(backup_path "$LEGACY_DELTA_DATA" delta-data)"
layout_state="$(backup_path "$LAYOUT_ENV" layout)"

rollback_outputs() {
  restore_path "$TARGET_DIR" target "$target_state"
  restore_path "$THERMAL_VALIDATION_DIR" validation "$validation_state"
  restore_path "$LEGACY_REPORT_MODULE" report-module "$report_module_state"
  restore_path "$LEGACY_REPORT_DATA" report-data "$report_data_state"
  restore_path "$LEGACY_PATCH_MANIFEST" patch "$patch_state"
  restore_path "$LEGACY_DELTA_MODULE" delta-module "$delta_module_state"
  restore_path "$LEGACY_DELTA_DATA" delta-data "$delta_data_state"
  restore_path "$LAYOUT_ENV" layout "$layout_state"
}
cleanup() { _rc="$?"; if [ "$_rc" -ne 0 ] && [ "$VALIDATED" -ne 1 ]; then rollback_outputs; fi; rm -f "$RUN_LOG" "$DELTA_TMP" 2>/dev/null || true; rm -rf "$BACKUP_DIR" 2>/dev/null || true; return "$_rc"; }
trap cleanup EXIT HUP INT TERM

rm -f "$LEGACY_REPORT_MODULE" "$LEGACY_REPORT_DATA" "$LEGACY_PATCH_MANIFEST" "$LEGACY_DELTA_MODULE" "$LEGACY_DELTA_DATA" "$LAYOUT_ENV" 2>/dev/null || true
if sh "$PATCHER" "$POLLING_MODE" "$OUTDOOR_PROFILE" "$MODPATH" "$PIXEL11_HYSTERESIS_MODE" > "$RUN_LOG" 2>&1; then cat "$RUN_LOG"; else _rc="$?"; cat "$RUN_LOG"; exit "$_rc"; fi

MATERIALIZATION_MODE="$(sed -n 's/^PATCH_THERMAL_MATERIALIZATION=//p' "$RUN_LOG" | tail -n 1)"
OVERLAY_FILES_CSV="$(sed -n 's/^PATCH_THERMAL_OVERLAY_FILES=//p' "$RUN_LOG" | tail -n 1)"
OVERLAY_COUNT="$(sed -n 's/^PATCH_THERMAL_OVERLAY_COUNT=//p' "$RUN_LOG" | tail -n 1)"
PATCH_DEVICE="$(sed -n 's/^PATCH_THERMAL_DEVICE=//p' "$RUN_LOG" | tail -n 1)"
PATCH_DEVICE_FAMILY="$(thermal_device_family "$PATCH_DEVICE")"
[ -n "$OVERLAY_FILES_CSV" ] || OVERLAY_FILES_CSV=none
case "$OVERLAY_COUNT" in ''|*[!0-9]*) printf '%s\n' PATCH_THERMAL_DELTA_REASON=invalid_overlay_count; exit 58 ;; esac
STOCK_NO_OVERLAY_EXPECTED=0
if [ "$PATCH_DEVICE_FAMILY" = pixel11 ] && [ "$POLLING_MODE" = stock ] && [ "$OUTDOOR_PROFILE" = stock ] && [ "$PIXEL11_HYSTERESIS_MODE" = stock ]; then STOCK_NO_OVERLAY_EXPECTED=1; fi
case "$MATERIALIZATION_MODE" in
  stock-no-overlay) [ "$STOCK_NO_OVERLAY_EXPECTED" -eq 1 ] && [ "$OVERLAY_COUNT" -eq 0 ] && [ "$OVERLAY_FILES_CSV" = none ] || { printf '%s\n' PATCH_THERMAL_DELTA_REASON=invalid_stock_no_overlay_contract; exit 58; } ;;
  sparse-overlay) [ "$PATCH_DEVICE_FAMILY" = pixel11 ] && [ "$STOCK_NO_OVERLAY_EXPECTED" -eq 0 ] && [ "$OVERLAY_COUNT" -gt 0 ] && [ "$OVERLAY_FILES_CSV" != none ] || { printf '%s\n' PATCH_THERMAL_DELTA_REASON=invalid_sparse_overlay_contract; exit 58; } ;;
  overlay) [ "$PATCH_DEVICE_FAMILY" != pixel11 ] && [ "$OVERLAY_COUNT" -gt 0 ] && [ "$OVERLAY_FILES_CSV" != none ] || { printf '%s\n' PATCH_THERMAL_DELTA_REASON=invalid_full_overlay_contract; exit 58; } ;;
  *) printf '%s\n' PATCH_THERMAL_DELTA_REASON=invalid_materialization_mode; exit 58 ;;
esac
overlay_file_selected() { case ",$OVERLAY_FILES_CSV," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

thermal_layout_load_env "$LAYOUT_ENV" || { printf '%s\n' PATCH_THERMAL_DELTA_REASON=layout_state_missing_or_invalid; exit 59; }
DEVICE="${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}"
BUILD_ID="${THERMAL_BUILD_ID:-$(getprop ro.build.id 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE=unknown
[ -n "$BUILD_ID" ] || BUILD_ID=unknown
BUILD_SLUG="$(printf '%s' "$BUILD_ID" | tr -c 'A-Za-z0-9._-' '_')"
CACHE_DIR="$DATA_ROOT/originals/$DEVICE/$BUILD_SLUG/vendor/etc"
DELTA=0
case "$OUTDOOR_PROFILE" in outdoor-safe) DELTA=1 ;; outdoor-plus) DELTA=2 ;; outdoor-extended) DELTA=3 ;; esac

validated_files=0; target_zone_total=0; threshold_array_total=0; threshold_value_total=0; layout_checked_files=0
if [ "$MATERIALIZATION_MODE" = stock-no-overlay ]; then
  for output_file in "$TARGET_DIR"/thermal_info_config*.json; do
    if [ -e "$output_file" ] || [ -L "$output_file" ]; then
      printf '%s\n' "PATCH_THERMAL_DELTA_REASON=stock_overlay_present_${output_file##*/}"; exit 61
    fi
  done
  for file in $THERMAL_LAYOUT_FILES; do
    source_file="$CACHE_DIR/$file"
    [ -s "$source_file" ] || { printf '%s\n' "PATCH_THERMAL_DELTA_REASON=source_missing_$file"; exit 60; }
    layout_checked_files=$((layout_checked_files + 1))
  done
else
  overlay_seen=0
  for file in $THERMAL_LAYOUT_FILES; do
    source_file="$CACHE_DIR/$file"; output_file="$TARGET_DIR/$file"
    [ -s "$source_file" ] || { printf '%s\n' "PATCH_THERMAL_DELTA_REASON=source_missing_$file"; exit 60; }
    layout_checked_files=$((layout_checked_files + 1))
    if overlay_file_selected "$file"; then
      overlay_seen=$((overlay_seen + 1))
      [ -s "$output_file" ] || { printf '%s\n' "PATCH_THERMAL_DELTA_REASON=output_missing_$file"; exit 61; }
      if metrics="$(sh "$DELTA_HELPER" "$source_file" "$output_file" "$DELTA" "$DEVICE")"; then
        set -- $metrics; [ "$#" -eq 3 ] || exit 62; target_zones="$1"; threshold_arrays="$2"; threshold_values="$3"
      else
        printf '%s\n' "PATCH_THERMAL_DELTA_REASON=exact_delta_invalid_${file}_expected_${DELTA}"; exit 63
      fi
      validated_files=$((validated_files + 1)); target_zone_total=$((target_zone_total + target_zones)); threshold_array_total=$((threshold_array_total + threshold_arrays)); threshold_value_total=$((threshold_value_total + threshold_values))
    else
      [ ! -e "$output_file" ] || { printf '%s\n' "PATCH_THERMAL_DELTA_REASON=unchanged_overlay_present_$file"; exit 61; }
    fi
  done
  [ "$overlay_seen" -eq "$OVERLAY_COUNT" ] 2>/dev/null || exit 64
  [ "$validated_files" -eq "$OVERLAY_COUNT" ] 2>/dev/null || exit 64
  [ "$threshold_array_total" -eq "$target_zone_total" ] || exit 66
  if [ "$DELTA" -gt 0 ] 2>/dev/null; then
    [ "$target_zone_total" -gt 0 ] || exit 65
    [ "$threshold_value_total" -gt 0 ] || exit 67
  fi
fi
[ "$layout_checked_files" -eq "$THERMAL_LAYOUT_COUNT" ] 2>/dev/null || exit 64

{
  printf '%s\n' 'schema=pixel-thermal-outdoor-delta-validation-v3'
  printf '%s\n' "device=$DEVICE"
  printf '%s\n' "build_id=$BUILD_ID"
  printf '%s\n' "layout_family=$THERMAL_LAYOUT_FAMILY"
  printf '%s\n' "layout_files=$THERMAL_LAYOUT_FILES_CSV"
  printf '%s\n' "polling_mode=$POLLING_MODE"
  printf '%s\n' "pixel11_hysteresis_mode=$PIXEL11_HYSTERESIS_MODE"
  printf '%s\n' "outdoor_profile=$OUTDOOR_PROFILE"
  printf '%s\n' "materialization_mode=$MATERIALIZATION_MODE"
  printf '%s\n' "overlay_files=$OVERLAY_FILES_CSV"
  printf '%s\n' "overlay_file_count=$OVERLAY_COUNT"
  printf '%s\n' "expected_delta=$DELTA"
  printf '%s\n' "validated_files=$validated_files"
  printf '%s\n' "target_zone_count=$target_zone_total"
  printf '%s\n' "threshold_array_count=$threshold_array_total"
  printf '%s\n' "threshold_value_count=$threshold_value_total"
  printf '%s\n' 'validation=passed'
} > "$DELTA_TMP"

[ -s "$LEGACY_REPORT_MODULE" ] || exit 68
[ -s "$LEGACY_PATCH_MANIFEST" ] || exit 69
thermal_validation_publish "$LEGACY_REPORT_MODULE" "$THERMAL_VALIDATION_REPORT" 0644 || exit 70
thermal_validation_publish "$LEGACY_PATCH_MANIFEST" "$THERMAL_VALIDATION_PATCH_MANIFEST" 0644 || exit 71
thermal_validation_publish "$DELTA_TMP" "$THERMAL_VALIDATION_DELTA" 0644 || exit 72
thermal_validation_write_state "$DEVICE" "$BUILD_ID" "$POLLING_MODE" "$OUTDOOR_PROFILE" "$PIXEL11_HYSTERESIS_MODE" || exit 73
thermal_validation_refresh_legacy_links "$MODPATH" || exit 74
VALIDATED=1
rm -rf "$BACKUP_DIR"
printf '%s\n' PATCH_THERMAL_DELTA_VALIDATION=pass "PATCH_THERMAL_PIXEL11_HYSTERESIS_MODE=$PIXEL11_HYSTERESIS_MODE" "PATCH_THERMAL_MATERIALIZATION=$MATERIALIZATION_MODE" "PATCH_THERMAL_OVERLAY_FILES=$OVERLAY_FILES_CSV" "PATCH_THERMAL_OVERLAY_COUNT=$OVERLAY_COUNT" "PATCH_THERMAL_DELTA_EXPECTED=$DELTA" "PATCH_THERMAL_DELTA_FILES=$validated_files" "PATCH_THERMAL_DELTA_TARGET_ZONES=$target_zone_total" "PATCH_THERMAL_DELTA_THRESHOLD_ARRAYS=$threshold_array_total" "PATCH_THERMAL_DELTA_THRESHOLD_VALUES=$threshold_value_total" "PATCH_THERMAL_LAYOUT_FAMILY=$THERMAL_LAYOUT_FAMILY" "PATCH_THERMAL_LAYOUT_FILES=$THERMAL_LAYOUT_FILES_CSV" "PATCH_THERMAL_VALIDATION_DIR=$THERMAL_VALIDATION_DIR" "PATCH_THERMAL_DELTA_REPORT=$THERMAL_VALIDATION_DELTA"
trap - EXIT HUP INT TERM
rm -f "$RUN_LOG" "$DELTA_TMP"
exit 0
