#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
patcher="$repo_root/tools/core/patch-thermal.sh"
fix5_core="$repo_root/tools/core/patch-thermal-fix5-core.sh"
wrapper="$repo_root/tools/core/patch-thermal-validated.sh"
verify="$repo_root/tools/core/verify-outdoor-delta.sh"
supported="$repo_root/tools/core/supported-build.sh"
state="$repo_root/tools/core/validation-state.sh"
policy="$repo_root/tools/core/outdoor-runtime-policy.sh"

for file in "$patcher" "$fix5_core" "$wrapper" "$verify" "$supported" "$state" "$policy"; do
  bash -n "$file"
done
if grep -Fq '%.*f' "$patcher"; then
  printf '%s\n' 'FAIL android_awk_dynamic_precision_format_present'
  exit 1
fi
grep -Fq 'cellular-emergency' "$fix5_core"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
source_dir="$work/source"
mkdir -p "$source_dir"
cat > "$source_dir/thermal_info_config.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-SPEAKER", "PollingDelay": 300000, "HotThreshold": ["NAN", 37.0, "NAN", "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "PollingDelay": 300000, "HotThreshold": ["NAN", 35.0, "NAN", "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "DISPLAY-SKIN", "PollingDelay": 300000, "HotThreshold": ["NAN", 40.0, 45.0, 50.0, 55.0, "NAN", "NAN"]}
  ]
}
JSON
cat > "$source_dir/thermal_info_config_charge.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-CHARGE-PERSIST", "PollingDelay": 300000, "HotThreshold": ["NaN", 37.0, 41.0, 45.0, 47.0, 51.0, 55.0]},
    {"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "PollingDelay": 300000, "HotThreshold": ["NAN", 34.0, 38.0, 41.0, 45.0, 47.0, 55.0]},
    {"Name": "cellular-emergency", "PollingDelay": 300000, "HotThreshold": ["NAN", 40.0, 45.0, 50.0, 52.0, 54.0, 55.0]}
  ]
}
JSON
cat > "$source_dir/thermal_info_config_throttling.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "PollingDelay": 300000, "HotThreshold": ["NAN", 39, 43, 45, 46.5, 52, 55.0]},
    {"Name": "VIRTUAL-SKIN-HINT", "PollingDelay": 300000, "HotThreshold": ["NAN", 37.0, 43.0, 45.0, 46.5, 52.0, 55.0]},
    {"Name": "VIRTUAL-SKIN-CPU-LIGHT-ODPM", "PollingDelay": 300000, "HotThreshold": ["NAN", 37.0, 39.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "VIRTUAL-SKIN-CPU-MID", "PollingDelay": 300000, "HotThreshold": ["NAN", 39.0, 41.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "VIRTUAL-SKIN-CPU-ODPM", "PollingDelay": 300000, "HotThreshold": ["NAN", 39.0, 41.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "VIRTUAL-SKIN-CPU-HIGH", "PollingDelay": 300000, "HotThreshold": ["NAN", 41.0, 43.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "VIRTUAL-SKIN-SOC", "PollingDelay": 300000, "HotThreshold": ["NAN", 37.0, 39.0, 41.0, 45.0, 46.5, 52.0]},
    {"Name": "VIRTUAL-SKIN-SOC-EXTREME", "PollingDelay": 300000, "HotThreshold": ["NAN", "NAN", "NAN", 45.0, 46.0, "NAN", "NAN"]}
  ]
}
JSON

prepare_case() {
  local name="$1"
  local case_dir="$work/$name"
  mkdir -p "$case_dir/module/tools/core" "$case_dir/module/system/vendor" "$case_dir/data"
  cp -fp "$patcher" "$fix5_core" "$wrapper" "$verify" "$supported" "$state" "$policy" "$case_dir/module/tools/core/"
  cp -fp "$repo_root/supported_versions.json" "$case_dir/module/"
  printf '%s\n' "$case_dir"
}

for profile in stock outdoor-safe outdoor-plus outdoor-extended; do
  case_dir="$(prepare_case "$profile")"
  THERMAL_SOURCE_DIR="$source_dir" \
  THERMAL_DATA_ROOT="$case_dir/data" \
  THERMAL_DEVICE=mustang \
  THERMAL_ANDROID=17 \
  THERMAL_BUILD_ID=ZP11.260618.005 \
    sh "$case_dir/module/tools/core/patch-thermal-validated.sh" mod "$profile" "$case_dir/module" > "$case_dir/run.log"

  grep -Fq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$case_dir/run.log"
  grep -Fq 'PATCH_THERMAL_DELTA_TARGET_ZONES=12' "$case_dir/run.log"
  grep -Fq 'PATCH_THERMAL_DELTA_THRESHOLD_ARRAYS=12' "$case_dir/run.log"
  grep -Fq 'PATCH_THERMAL_DELTA_THRESHOLD_VALUES=84' "$case_dir/run.log"
  grep -Fq '"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "PollingDelay": 5000, "HotThreshold": ["NAN", 35.0' "$case_dir/module/system/vendor/etc/thermal_info_config.json"
  grep -Fq '"Name": "DISPLAY-SKIN", "PollingDelay": 5000, "HotThreshold": ["NAN", 40.0, 45.0, 50.0, 55.0' "$case_dir/module/system/vendor/etc/thermal_info_config.json"
done

grep -Fq '"NAN", 42, 46, 48, 49.5, 55, 58.0' "$work/outdoor-extended/module/system/vendor/etc/thermal_info_config_throttling.json"
grep -Fq '"Name": "cellular-emergency", "PollingDelay": 5000, "HotThreshold": ["NAN", 43.0, 48.0, 53.0, 55.0, 57.0, 58.0]' "$work/outdoor-extended/module/system/vendor/etc/thermal_info_config_charge.json"

printf '%s\n' 'PASS fix5_dynamic_inventory_12_arrays_84_values'
printf '%s\n' 'PASS all_profiles_materialize_on_canary_fixture'
printf '%s\n' 'PASS downstream_virtual_skin_and_cellular_shift_in_lockstep'
printf '%s\n' 'PASS over_35c_trigger_and_non_targets_unchanged'
printf '%s\n' 'PASS android_awk_portable_decimal_scale'
printf '%s\n' 'RESULT: PIXEL_THERMAL_CANARY_FIX5_TEST_PASS'
