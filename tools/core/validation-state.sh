#!/system/bin/sh
# Canonical persistent validation-state helpers.

THERMAL_VALIDATION_ID="${THERMAL_VALIDATION_ID:-pixel-10-pro-xl-thermal-fix}"
THERMAL_VALIDATION_DATA_ROOT="${THERMAL_DATA_ROOT:-/data/adb/$THERMAL_VALIDATION_ID}"
THERMAL_VALIDATION_DIR="${THERMAL_VALIDATION_DIR:-$THERMAL_VALIDATION_DATA_ROOT/validation}"
THERMAL_VALIDATION_REPORT="$THERMAL_VALIDATION_DIR/validation-report.json"
THERMAL_VALIDATION_DELTA="$THERMAL_VALIDATION_DIR/outdoor-delta-validation.env"
THERMAL_VALIDATION_PATCH_MANIFEST="$THERMAL_VALIDATION_DIR/patch-manifest.tsv"
THERMAL_VALIDATION_STATE="$THERMAL_VALIDATION_DIR/state.env"

thermal_validation_init() {
  mkdir -p "$THERMAL_VALIDATION_DIR" || return 1
  chmod 0700 "$THERMAL_VALIDATION_DIR" 2>/dev/null || true
}

thermal_validation_sha() {
  [ -s "$1" ] || return 0
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

thermal_validation_publish() {
  _source="$1"
  _target="$2"
  _mode="${3:-0644}"
  [ -s "$_source" ] || return 1
  thermal_validation_init || return 1
  _tmp="$THERMAL_VALIDATION_DIR/.publish.$$.${_target##*/}"
  cp -fp "$_source" "$_tmp" || return 1
  chmod "$_mode" "$_tmp" 2>/dev/null || true
  mv "$_tmp" "$_target"
}

thermal_validation_link() {
  _target="$1"
  _legacy="$2"
  mkdir -p "${_legacy%/*}" 2>/dev/null || true
  rm -f "$_legacy" 2>/dev/null || true
  ln -s "$_target" "$_legacy"
}

thermal_validation_refresh_legacy_links() {
  _modpath="$1"
  thermal_validation_init || return 1
  mkdir -p "$_modpath/guard" 2>/dev/null || true

  thermal_validation_link \
    "$THERMAL_VALIDATION_REPORT" \
    "$_modpath/validation_report.json" || return 1
  thermal_validation_link \
    "$THERMAL_VALIDATION_REPORT" \
    "$THERMAL_VALIDATION_DATA_ROOT/validation_report.json" || return 1
  thermal_validation_link \
    "$THERMAL_VALIDATION_PATCH_MANIFEST" \
    "$_modpath/guard/patch-manifest.tsv" || return 1
  thermal_validation_link \
    "$THERMAL_VALIDATION_DELTA" \
    "$_modpath/guard/outdoor-delta-validation.env" || return 1
  thermal_validation_link \
    "$THERMAL_VALIDATION_DELTA" \
    "$THERMAL_VALIDATION_DATA_ROOT/outdoor-delta-validation.env" || return 1
}

thermal_validation_write_state() {
  _device="$1"
  _build_id="$2"
  _polling="$3"
  _outdoor="$4"
  _pixel11_hysteresis="${5:-stock}"
  _pixel11_passive="${6:-stock}"
  thermal_validation_init || return 1

  _tmp="$THERMAL_VALIDATION_DIR/.state.env.$$"
  {
    printf '%s\n' 'schema=pixel-thermal-validation-state-v1'
    printf '%s\n' "device=$_device"
    printf '%s\n' "build_id=$_build_id"
    printf '%s\n' "polling_mode=$_polling"
    printf '%s\n' "pixel11_hysteresis_mode=$_pixel11_hysteresis"
    printf '%s\n' "pixel11_passive_mode=$_pixel11_passive"
    printf '%s\n' "outdoor_profile=$_outdoor"
    printf '%s\n' "validation_report=$THERMAL_VALIDATION_REPORT"
    printf '%s\n' "validation_report_sha256=$(thermal_validation_sha "$THERMAL_VALIDATION_REPORT")"
    printf '%s\n' "outdoor_delta_report=$THERMAL_VALIDATION_DELTA"
    printf '%s\n' "outdoor_delta_sha256=$(thermal_validation_sha "$THERMAL_VALIDATION_DELTA")"
    printf '%s\n' "patch_manifest=$THERMAL_VALIDATION_PATCH_MANIFEST"
    printf '%s\n' "patch_manifest_sha256=$(thermal_validation_sha "$THERMAL_VALIDATION_PATCH_MANIFEST")"
    printf '%s\n' 'legacy_paths=symlinks_only'
    printf '%s\n' 'validation=passed'
  } > "$_tmp"
  chmod 0600 "$_tmp" 2>/dev/null || true
  mv "$_tmp" "$THERMAL_VALIDATION_STATE"
}
