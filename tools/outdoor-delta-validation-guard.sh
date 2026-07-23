#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
PATCHER="$ROOT/tools/core/patch-thermal.sh"
WRAPPER="$ROOT/tools/core/patch-thermal-validated.sh"
DELTA_HELPER="$ROOT/tools/core/verify-outdoor-delta.sh"
SUPPORTED_HELPER="$ROOT/tools/core/supported-build.sh"
INSTALL_HELPER="$ROOT/tools/core/install-thermal-overlay.sh"
ACTION="$ROOT/action.sh"
fail=0

pass() { printf 'PASS %s\n' "$*"; }
err() { printf 'FAIL %s\n' "$*"; fail=1; }

for file in "$PATCHER" "$WRAPPER" "$DELTA_HELPER" "$SUPPORTED_HELPER" "$INSTALL_HELPER" "$ACTION"; do
  [[ -s "$file" ]] && pass "file_present=${file#$ROOT/}" || err "file_missing=${file#$ROOT/}"
done

for script in "$PATCHER" "$WRAPPER" "$DELTA_HELPER" "$SUPPORTED_HELPER" "$INSTALL_HELPER" "$ACTION"; do
  bash -n "$script" && pass "syntax=${script#$ROOT/}" || err "syntax=${script#$ROOT/}"
done

if grep -Fq 'patch-thermal-validated.sh' "$INSTALL_HELPER" &&
   ! grep -Fq 'sh "$MODPATH/tools/core/patch-thermal.sh"' "$INSTALL_HELPER"; then
  pass install_uses_validated_wrapper
else
  err install_uses_validated_wrapper
fi

if grep -Fq 'patch-thermal-validated.sh' "$ACTION" &&
   ! grep -Fq 'sh "$MODDIR/tools/core/patch-thermal.sh"' "$ACTION"; then
  pass action_uses_validated_wrapper
else
  err action_uses_validated_wrapper
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/pixel-thermal-delta.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT HUP INT TERM

SOURCE="$TMP/source"
mkdir -p "$SOURCE"
for name in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  {
    printf '%s\n' '{'
    printf '%s\n' '  "Sensors": ['
    printf '%s\n' '    {'
    printf '%s\n' '      "Name": "VIRTUAL-SKIN",'
    printf '%s\n' '      "PollingDelay": 300000,'
    printf '%s\n' '      "HotThreshold": [40, 42, 44]'
    printf '%s\n' '    },'
    printf '%s\n' '    {'
    printf '%s\n' '      "Name": "VIRTUAL-SKIN-HINT",'
    printf '%s\n' '      "PollingDelay": 300000,'
    printf '%s\n' '      "HotThreshold": [45, 47]'
    printf '%s\n' '    },'
    printf '%s\n' '    {'
    printf '%s\n' '      "Name": "OTHER",'
    printf '%s\n' '      "PollingDelay": 300000,'
    printf '%s\n' '      "HotThreshold": [99]'
    printf '%s\n' '    }'
    printf '%s\n' '  ]'
    printf '%s\n' '}'
  } > "$SOURCE/$name"
done

run_case() {
  polling="$1"
  profile="$2"
  delta="$3"
  case_dir="$TMP/$polling-$profile"
  moddir="$case_dir/module"
  datadir="$case_dir/data"
  mkdir -p "$moddir/tools/core" "$datadir"
  cp -fp "$PATCHER" "$moddir/tools/core/patch-thermal.sh"
  cp -fp "$WRAPPER" "$moddir/tools/core/patch-thermal-validated.sh"
  cp -fp "$DELTA_HELPER" "$moddir/tools/core/verify-outdoor-delta.sh"
  cp -fp "$SUPPORTED_HELPER" "$moddir/tools/core/supported-build.sh"

  if THERMAL_SOURCE_DIR="$SOURCE" \
     THERMAL_DATA_ROOT="$datadir" \
     THERMAL_DEVICE=mustang \
     THERMAL_BUILD_ID=CP2A.260705.006 \
     sh "$moddir/tools/core/patch-thermal-validated.sh" "$polling" "$profile" "$moddir" \
       > "$case_dir/run.log" 2>&1; then
    :
  else
    cat "$case_dir/run.log"
    return 1
  fi

  report="$moddir/guard/outdoor-delta-validation.env"
  grep -Fxq "expected_delta=$delta" "$report"
  grep -Fxq 'validated_files=3' "$report"
  grep -Fxq 'target_zone_count=6' "$report"
  grep -Fxq 'threshold_array_count=6' "$report"
  grep -Fxq 'threshold_value_count=15' "$report"
  grep -Fxq 'validation=passed' "$report"
  grep -Fq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$case_dir/run.log"

  if [[ "$polling" == mod ]]; then
    grep -Fq 'PATCH_THERMAL_OUTPUT_5000=9' "$case_dir/run.log"
  else
    grep -Fq 'PATCH_THERMAL_OUTPUT_5000=0' "$case_dir/run.log"
  fi
}

for fixture in \
  'stock stock 0' \
  'mod stock 0' \
  'mod outdoor-safe 1' \
  'mod outdoor-plus 2' \
  'mod outdoor-extended 3'
do
  set -- $fixture
  if run_case "$1" "$2" "$3"; then
    pass "dynamic_fixture=$1/$2/delta$3"
  else
    err "dynamic_fixture=$1/$2/delta$3"
  fi
done

BAD_SOURCE="$TMP/bad-source"
mkdir -p "$BAD_SOURCE"
cp -fp "$SOURCE"/*.json "$BAD_SOURCE/"
{
  printf '%s\n' '{'
  printf '%s\n' '  "Sensors": ['
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "VIRTUAL-SKIN",'
  printf '%s\n' '      "PollingDelay": 300000'
  printf '%s\n' '    }'
  printf '%s\n' '  ]'
  printf '%s\n' '}'
} > "$BAD_SOURCE/thermal_info_config.json"

bad_dir="$TMP/bad-case"
mkdir -p "$bad_dir/module/tools/core" "$bad_dir/data"
cp -fp "$PATCHER" "$bad_dir/module/tools/core/patch-thermal.sh"
cp -fp "$WRAPPER" "$bad_dir/module/tools/core/patch-thermal-validated.sh"
cp -fp "$DELTA_HELPER" "$bad_dir/module/tools/core/verify-outdoor-delta.sh"
cp -fp "$SUPPORTED_HELPER" "$bad_dir/module/tools/core/supported-build.sh"

if THERMAL_SOURCE_DIR="$BAD_SOURCE" \
   THERMAL_DATA_ROOT="$bad_dir/data" \
   THERMAL_DEVICE=mustang \
   THERMAL_BUILD_ID=CP2A.260705.006 \
   sh "$bad_dir/module/tools/core/patch-thermal-validated.sh" mod outdoor-safe "$bad_dir/module" \
     > "$bad_dir/run.log" 2>&1; then
  err malformed_target_unexpectedly_passed
else
  if grep -Fq 'PATCH_THERMAL_DELTA_REASON=exact_delta_invalid_thermal_info_config.json_expected_1' "$bad_dir/run.log" &&
     [[ ! -d "$bad_dir/module/system/vendor/etc" ]]; then
    pass malformed_target_fail_closed_and_rolled_back
  else
    cat "$bad_dir/run.log"
    err malformed_target_wrong_failure
  fi
fi

if [[ "$fail" -eq 0 ]]; then
  printf 'RESULT: OUTDOOR_DELTA_VALIDATION_GUARD_PASS rc=0\n'
else
  printf 'RESULT: OUTDOOR_DELTA_VALIDATION_GUARD_FAIL rc=1\n'
  exit 1
fi
