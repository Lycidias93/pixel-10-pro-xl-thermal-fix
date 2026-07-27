#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
verify="$repo_root/tools/core/verify-outdoor-delta.sh"
bash -n "$verify"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
source="$work/source.json"
output="$work/output.json"
invalid="$work/invalid.json"

cat > "$source" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "HotThreshold": ["NAN", 39, 43, 45, 46.5, 52, 55.0]},
    {"Name": "VIRTUAL-SKIN-CPU-HIGH", "HotThreshold": ["NAN", 41.0, 43.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "cellular-emergency", "HotThreshold": ["NaN", 40.0, 45.0, 50.0, 52.0, 54.0, 55.0]},
    {"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "HotThreshold": ["NAN", 35.0, "NAN", "NAN", "NAN", "NAN", "NAN"]}
  ]
}
JSON
cat > "$output" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "HotThreshold": ["NAN", 41, 45, 47, 48.5, 54, 57.0]},
    {"Name": "VIRTUAL-SKIN-CPU-HIGH", "HotThreshold": ["NAN", 43.0, 45.0, "NAN", "NAN", "NAN", "NAN"]},
    {"Name": "cellular-emergency", "HotThreshold": ["NaN", 42.0, 47.0, 52.0, 54.0, 56.0, 57.0]},
    {"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "HotThreshold": ["NAN", 35.0, "NAN", "NAN", "NAN", "NAN", "NAN"]}
  ]
}
JSON
metrics="$(sh "$verify" "$source" "$output" 2)"
[[ "$metrics" = '3 3 21' ]]

cp "$output" "$invalid"
sed -i 's/"NAN", 43.0, 45.0/"NAN", 42.0, 45.0/' "$invalid"
if sh "$verify" "$source" "$invalid" 2 >/dev/null 2>&1; then
  printf '%s\n' 'FAIL mismatched_downstream_delta_accepted'
  exit 1
fi

printf '%s\n' 'PASS dynamic_target_inventory_3_arrays_21_values'
printf '%s\n' 'PASS over_35c_trigger_excluded_from_delta_contract'
printf '%s\n' 'PASS mismatched_downstream_delta_rejected'
printf '%s\n' 'RESULT: PIXEL_THERMAL_OUTDOOR_DELTA_RUNTIME_TEST_PASS'
