#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
patcher="$repo_root/tools/core/patch-thermal.sh"
wrapper="$repo_root/tools/core/patch-thermal-validated.sh"
delta_helper="$repo_root/tools/core/verify-outdoor-delta.sh"
supported_helper="$repo_root/tools/core/supported-build.sh"
state_helper="$repo_root/tools/core/validation-state.sh"

for file in "$patcher" "$wrapper" "$delta_helper" "$supported_helper" "$state_helper"; do
  [[ -s "$file" ]]
  bash -n "$file"
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
source_dir="$work/source"
mkdir -p "$source_dir"

{
  printf '%s\n' '{'
  printf '%s\n' '  "Sensors": ['
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "OTHER-CONFIG",'
  printf '%s\n' '      "PollingDelay": 300000,'
  printf '%s\n' '      "HotThreshold": [99]'
  printf '%s\n' '    }'
  printf '%s\n' '  ]'
  printf '%s\n' '}'
} > "$source_dir/thermal_info_config.json"

{
  printf '%s\n' '{'
  printf '%s\n' '  "Sensors": ['
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "OTHER-CHARGE",'
  printf '%s\n' '      "PollingDelay": 300000,'
  printf '%s\n' '      "HotThreshold": [88]'
  printf '%s\n' '    }'
  printf '%s\n' '  ]'
  printf '%s\n' '}'
} > "$source_dir/thermal_info_config_charge.json"

{
  printf '%s\n' '{'
  printf '%s\n' '  "Sensors": ['
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "VIRTUAL-SKIN",'
  printf '%s\n' '      "PollingDelay": 300000,'
  printf '%s\n' '      "HotThreshold": ["NAN", 39, 43, 45, 46.5, 52, 55]'
  printf '%s\n' '    },'
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "VIRTUAL-SKIN-HINT",'
  printf '%s\n' '      "PollingDelay": 300000,'
  printf '%s\n' '      "HotThreshold": ["NAN", 37, 43, 45, 46.5, 52, 55]'
  printf '%s\n' '    },'
  printf '%s\n' '    {'
  printf '%s\n' '      "Name": "OTHER-THROTTLING",'
  printf '%s\n' '      "PollingDelay": 300000,'
  printf '%s\n' '      "HotThreshold": [77]'
  printf '%s\n' '    }'
  printf '%s\n' '  ]'
  printf '%s\n' '}'
} > "$source_dir/thermal_info_config_throttling.json"

run_case() {
  local polling="$1"
  local profile="$2"
  local expected_delta="$3"
  local case_dir="$work/${polling}-${profile}"
  local moddir="$case_dir/module"
  local datadir="$case_dir/data"
  local report="$datadir/validation/outdoor-delta-validation.env"
  local state="$datadir/validation/state.env"

  mkdir -p "$moddir/tools/core" "$datadir"
  cp -fp "$patcher" "$moddir/tools/core/patch-thermal.sh"
  cp -fp "$wrapper" "$moddir/tools/core/patch-thermal-validated.sh"
  cp -fp "$delta_helper" "$moddir/tools/core/verify-outdoor-delta.sh"
  cp -fp "$supported_helper" "$moddir/tools/core/supported-build.sh"
  cp -fp "$state_helper" "$moddir/tools/core/validation-state.sh"

  THERMAL_SOURCE_DIR="$source_dir" \
  THERMAL_DATA_ROOT="$datadir" \
  THERMAL_DEVICE=mustang \
  THERMAL_BUILD_ID=CP2A.260705.006 \
    sh "$moddir/tools/core/patch-thermal-validated.sh" \
      "$polling" "$profile" "$moddir" \
      > "$case_dir/run.log" 2>&1

  grep -Fq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$case_dir/run.log"
  grep -Fq 'PATCH_THERMAL_LEGACY_PATHS=symlinks_only' "$case_dir/run.log"
  grep -Fxq "expected_delta=$expected_delta" "$report"
  grep -Fxq 'validated_files=3' "$report"
  grep -Fxq 'target_zone_count=2' "$report"
  grep -Fxq 'threshold_array_count=2' "$report"
  grep -Fxq 'threshold_value_count=14' "$report"
  grep -Fxq 'validation=passed' "$report"
  grep -Fxq 'schema=pixel-thermal-validation-state-v1' "$state"
  grep -Fxq 'legacy_paths=symlinks_only' "$state"

  [[ -L "$moddir/validation_report.json" ]]
  [[ -L "$datadir/validation_report.json" ]]
  [[ -L "$moddir/guard/patch-manifest.tsv" ]]
  [[ -L "$moddir/guard/outdoor-delta-validation.env" ]]
  [[ -L "$datadir/outdoor-delta-validation.env" ]]

  [[ "$(readlink "$moddir/validation_report.json")" = "$datadir/validation/validation-report.json" ]]
  [[ "$(readlink "$moddir/guard/patch-manifest.tsv")" = "$datadir/validation/patch-manifest.tsv" ]]
  [[ "$(readlink "$moddir/guard/outdoor-delta-validation.env")" = "$datadir/validation/outdoor-delta-validation.env" ]]

  if [[ "$polling" = mod ]]; then
    grep -Fq 'PATCH_THERMAL_OUTPUT_5000=5' "$case_dir/run.log"
  else
    grep -Fq 'PATCH_THERMAL_OUTPUT_5000=0' "$case_dir/run.log"
  fi

  printf 'PASS runtime_fixture=%s/%s/delta%s\n' "$polling" "$profile" "$expected_delta"
}

run_case stock stock 0
run_case mod stock 0
run_case mod outdoor-safe 1
run_case mod outdoor-plus 2
run_case mod outdoor-extended 3

bad_source="$work/bad-source"
mkdir -p "$bad_source"
cp -fp "$source_dir"/*.json "$bad_source/"
sed -i '/"HotThreshold"/d' "$bad_source/thermal_info_config_throttling.json"

bad_dir="$work/bad-case"
mkdir -p "$bad_dir/module/tools/core" "$bad_dir/data"
cp -fp "$patcher" "$bad_dir/module/tools/core/patch-thermal.sh"
cp -fp "$wrapper" "$bad_dir/module/tools/core/patch-thermal-validated.sh"
cp -fp "$delta_helper" "$bad_dir/module/tools/core/verify-outdoor-delta.sh"
cp -fp "$supported_helper" "$bad_dir/module/tools/core/supported-build.sh"
cp -fp "$state_helper" "$bad_dir/module/tools/core/validation-state.sh"

if THERMAL_SOURCE_DIR="$bad_source" \
   THERMAL_DATA_ROOT="$bad_dir/data" \
   THERMAL_DEVICE=mustang \
   THERMAL_BUILD_ID=CP2A.260705.006 \
   sh "$bad_dir/module/tools/core/patch-thermal-validated.sh" \
     mod outdoor-safe "$bad_dir/module" \
     > "$bad_dir/run.log" 2>&1; then
  printf '%s\n' 'FAIL malformed_target_unexpectedly_passed'
  exit 1
fi

[[ ! -d "$bad_dir/module/system/vendor/etc" ]]
[[ ! -d "$bad_dir/data/validation" || ! -s "$bad_dir/data/validation/state.env" ]]
printf '%s\n' 'PASS malformed_target_failed_closed_and_rolled_back'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_DELTA_RUNTIME_TEST_PASS'
