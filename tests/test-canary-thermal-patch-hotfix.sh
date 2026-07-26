#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
patcher="$repo_root/tools/core/patch-thermal.sh"
wrapper="$repo_root/tools/core/patch-thermal-validated.sh"
delta_helper="$repo_root/tools/core/verify-outdoor-delta.sh"
supported_helper="$repo_root/tools/core/supported-build.sh"
state_helper="$repo_root/tools/core/validation-state.sh"
policy_helper="$repo_root/tools/core/outdoor-runtime-policy.sh"

for file in "$patcher" "$wrapper" "$delta_helper" "$supported_helper" "$state_helper" "$policy_helper"; do
  [[ -s "$file" ]]
  bash -n "$file"
done

if grep -Fq '%.*f' "$patcher"; then
  printf '%s\n' 'FAIL android_awk_dynamic_precision_format_present'
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
source_dir="$work/source"
mkdir -p "$source_dir"

cat > "$source_dir/thermal_info_config.json" <<'JSON'
{
  "Sensors": [
    { "Name": "OTHER-CONFIG", "PollingDelay": 300000, "HotThreshold": [99.0] }
  ]
}
JSON

cat > "$source_dir/thermal_info_config_charge.json" <<'JSON'
{
  "Sensors": [
    { "Name": "OTHER-CHARGE", "PollingDelay": 300000, "HotThreshold": [88.0] }
  ]
}
JSON

cat > "$source_dir/thermal_info_config_throttling.json" <<'JSON'
{
  "Sensors": [
    {
      "Name": "VIRTUAL-SKIN",
      "PollingDelay": 300000,
      "HotThreshold": ["NAN", 39.0, 43.0, 45.0, 46.5, 52.0, 55.0]
    },
    {
      "Name": "VIRTUAL-SKIN-HINT",
      "PollingDelay": 300000,
      "HotThreshold": ["NAN", 37.0, 43.0, 45.0, 46.5, 52.0, 55.0]
    },
    {
      "Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER",
      "PollingDelay": 300000,
      "HotThreshold": [35.0, 40.0, 45.0, 50.0, 52.0, 54.0, 55.0]
    },
    {
      "Name": "VIRTUAL-SKIN-SOC",
      "PollingDelay": 300000,
      "HotThreshold": [40.0, 45.0, 50.0, 52.0, 53.0, 54.0, 55.0]
    }
  ]
}
JSON

prepare_case() {
  local name="$1"
  local case_dir="$work/$name"
  mkdir -p "$case_dir/module/tools/core" "$case_dir/data"
  cp -fp "$patcher" "$wrapper" "$delta_helper" "$supported_helper" "$state_helper" "$policy_helper" "$case_dir/module/tools/core/"
  printf '%s\n' "$case_dir"
}

canary_safe="$(prepare_case canary-safe)"
THERMAL_SOURCE_DIR="$source_dir" \
THERMAL_DATA_ROOT="$canary_safe/data" \
THERMAL_DEVICE=mustang \
THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=ZP11.260618.005 \
  sh "$canary_safe/module/tools/core/patch-thermal-validated.sh" \
    mod outdoor-safe "$canary_safe/module" > "$canary_safe/run.log" 2>&1

canary_output="$canary_safe/module/system/vendor/etc/thermal_info_config_throttling.json"
canary_report="$canary_safe/data/validation/outdoor-delta-validation.env"
grep -Fq '"HotThreshold": ["NAN", 40.0, 44.0, 46.0, 47.5, 53.0, 55.0]' "$canary_output"
grep -Fq '"HotThreshold": ["NAN", 38.0, 44.0, 46.0, 47.5, 53.0, 55.0]' "$canary_output"
grep -Fq '"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER"' "$canary_output"
grep -Fq '"HotThreshold": [35.0, 40.0, 45.0, 50.0, 52.0, 54.0, 55.0]' "$canary_output"
grep -Fxq 'expected_delta=1' "$canary_report"
grep -Fxq 'target_zone_count=2' "$canary_report"
grep -Fxq 'threshold_array_count=2' "$canary_report"
grep -Fxq 'threshold_value_count=14' "$canary_report"
grep -Fq 'PATCH_THERMAL_OUTDOOR_MAX_ADMITTED_DELTA=1' "$canary_safe/run.log"

canary_plus="$(prepare_case canary-plus)"
if THERMAL_SOURCE_DIR="$source_dir" \
   THERMAL_DATA_ROOT="$canary_plus/data" \
   THERMAL_DEVICE=mustang \
   THERMAL_ANDROID=17 \
   THERMAL_BUILD_ID=ZP11.260618.005 \
     sh "$canary_plus/module/tools/core/patch-thermal-validated.sh" \
       mod outdoor-plus "$canary_plus/module" > "$canary_plus/run.log" 2>&1; then
  printf '%s\n' 'FAIL canary_plus_unexpectedly_admitted'
  exit 1
fi
grep -Fq 'requested_2_max_1' "$canary_plus/run.log"
[[ ! -d "$canary_plus/module/system/vendor/etc" ]]

local_plus="$(prepare_case local-plus)"
THERMAL_SOURCE_DIR="$source_dir" \
THERMAL_DATA_ROOT="$local_plus/data" \
THERMAL_DEVICE=mustang \
THERMAL_ANDROID=17 \
THERMAL_BUILD_ID=CP2A.260705.006 \
  sh "$local_plus/module/tools/core/patch-thermal-validated.sh" \
    mod outdoor-plus "$local_plus/module" > "$local_plus/run.log" 2>&1

local_output="$local_plus/module/system/vendor/etc/thermal_info_config_throttling.json"
grep -Fq '"HotThreshold": ["NAN", 41.0, 45.0, 47.0, 48.5, 54.0, 55.0]' "$local_output"
grep -Fq '"HotThreshold": ["NAN", 39.0, 45.0, 47.0, 48.5, 54.0, 55.0]' "$local_output"
grep -Fq 'PATCH_THERMAL_OUTDOOR_MAX_ADMITTED_DELTA=3' "$local_plus/run.log"

printf '%s\n' 'PASS android_awk_portable_fixed_precision_formats'
printf '%s\n' 'PASS canary_safe_runtime_policy_admitted'
printf '%s\n' 'PASS canary_plus_runtime_policy_failed_closed'
printf '%s\n' 'PASS exact_target_names_and_emergency_index_preserved'
printf '%s\n' 'RESULT: PIXEL_THERMAL_CANARY_PATCH_HOTFIX_TEST_PASS'
