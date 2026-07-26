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
moddir="$work/module"
datadir="$work/data"
mkdir -p "$source_dir" "$moddir/tools/core" "$datadir"
cp -fp "$patcher" "$wrapper" "$delta_helper" "$supported_helper" "$state_helper" "$moddir/tools/core/"

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

THERMAL_SOURCE_DIR="$source_dir" \
THERMAL_DATA_ROOT="$datadir" \
THERMAL_DEVICE=mustang \
THERMAL_BUILD_ID=ZP11.260618.005 \
  sh "$moddir/tools/core/patch-thermal-validated.sh" \
    mod outdoor-plus "$moddir" > "$work/run.log" 2>&1

output="$moddir/system/vendor/etc/thermal_info_config_throttling.json"
report="$datadir/validation/outdoor-delta-validation.env"

grep -Fq '"HotThreshold": ["NAN", 41.0, 45.0, 47.0, 48.5, 54.0, 55.0]' "$output"
grep -Fq '"HotThreshold": ["NAN", 39.0, 45.0, 47.0, 48.5, 54.0, 55.0]' "$output"

grep -Fq '"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER"' "$output"
grep -Fq '"HotThreshold": [35.0, 40.0, 45.0, 50.0, 52.0, 54.0, 55.0]' "$output"
grep -Fq '"Name": "VIRTUAL-SKIN-SOC"' "$output"
grep -Fq '"HotThreshold": [40.0, 45.0, 50.0, 52.0, 53.0, 54.0, 55.0]' "$output"

grep -Fxq 'target_contract=exact_virtual_skin_pair_v2' "$report"
grep -Fxq 'emergency_index_policy=index6_stock_unchanged_max55' "$report"
grep -Fxq 'numeric_format_policy=preserve_decimal_scale' "$report"
grep -Fxq 'target_zone_count=2' "$report"
grep -Fxq 'threshold_array_count=2' "$report"
grep -Fxq 'threshold_value_count=14' "$report"
grep -Fq 'PATCH_THERMAL_TARGET_CONTRACT=exact_virtual_skin_pair_v2' "$work/run.log"
grep -Fq 'PATCH_THERMAL_EMERGENCY_INDEX=index6_stock_unchanged_max55' "$work/run.log"
grep -Fq 'PATCH_THERMAL_NUMERIC_FORMAT=preserve_decimal_scale' "$work/run.log"

tampered_emergency="$work/tampered-emergency.json"
cp -fp "$output" "$tampered_emergency"
sed -i '0,/54.0, 55.0/s//54.0, 57.0/' "$tampered_emergency"
if sh "$delta_helper" "$source_dir/thermal_info_config_throttling.json" "$tampered_emergency" 2; then
  printf '%s\n' 'FAIL emergency_index_shift_unexpectedly_passed'
  exit 1
fi

tampered_format="$work/tampered-format.json"
cp -fp "$output" "$tampered_format"
sed -i '0,/41.0/s//41/' "$tampered_format"
if sh "$delta_helper" "$source_dir/thermal_info_config_throttling.json" "$tampered_format" 2; then
  printf '%s\n' 'FAIL decimal_scale_loss_unexpectedly_passed'
  exit 1
fi

bad_source="$work/bad-source"
cp -a "$source_dir" "$bad_source"
sed -i 's/"VIRTUAL-SKIN-HINT"/"VIRTUAL-SKIN-HINT-NEW"/' "$bad_source/thermal_info_config_throttling.json"
bad_mod="$work/bad-module"
bad_data="$work/bad-data"
mkdir -p "$bad_mod/tools/core" "$bad_data"
cp -fp "$patcher" "$wrapper" "$delta_helper" "$supported_helper" "$state_helper" "$bad_mod/tools/core/"
if THERMAL_SOURCE_DIR="$bad_source" \
   THERMAL_DATA_ROOT="$bad_data" \
   THERMAL_DEVICE=mustang \
   THERMAL_BUILD_ID=ZP11.260618.005 \
     sh "$bad_mod/tools/core/patch-thermal-validated.sh" \
       mod outdoor-plus "$bad_mod" > "$work/bad.log" 2>&1; then
  printf '%s\n' 'FAIL missing_exact_target_unexpectedly_passed'
  exit 1
fi
[[ ! -d "$bad_mod/system/vendor/etc" ]]

printf '%s\n' 'PASS exact_target_names_only'
printf '%s\n' 'PASS emergency_index6_stock_unchanged'
printf '%s\n' 'PASS decimal_scale_preserved'
printf '%s\n' 'PASS canary_prefix_sensors_untouched'
printf '%s\n' 'PASS malformed_exact_target_pair_failed_closed'
printf '%s\n' 'RESULT: PIXEL_THERMAL_CANARY_PATCH_HOTFIX_TEST_PASS'
