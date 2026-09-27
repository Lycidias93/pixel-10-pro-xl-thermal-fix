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

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
source_dir="$work/source"
mkdir -p "$source_dir"

cat > "$source_dir/thermal_info_config.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "PollingDelay": 300000, "HotThreshold": ["NAN", 39.0, 43.0, 45.0, 46.5, 52.0, 55.0]}
  ]
}
JSON

cat > "$source_dir/thermal_info_config_charge.json" <<'JSON'
{
  "Sensors": [
    {"Name": "DISPLAY-SKIN", "HotThreshold": ["NAN", 40.0, 45.0, 50.0, 55.0, "NAN", "NAN"]}
  ]
}
JSON

cat > "$source_dir/thermal_info_config_throttling.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-HINT", "PollingDelay": 300000, "HotThreshold": ["NAN", 37.0, 43.0, 45.0, 46.5, 52.0, 55.0]}
  ]
}
JSON

prepare_case() {
  local name="$1"
  local case_dir="$work/$name"
  local cache_dir="$case_dir/data/originals/mustang/CP2A.260805.005/vendor/etc"
  mkdir -p "$case_dir/module/tools/core" "$case_dir/module/system/vendor" "$case_dir/data" "$cache_dir"
  cp -fp "$patcher" "$fix5_core" "$wrapper" "$verify" "$supported" "$state" "$policy" "$case_dir/module/tools/core/"
  cp -fp "$repo_root/supported_versions.json" "$case_dir/module/"
  cp -fp "$source_dir"/thermal_info_config*.json "$cache_dir/"

  printf 'file\tsha256\tbytes\tpolling_300000\n' > "$cache_dir/source-manifest.tsv"
  for f in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
    sha="$(sha256sum "$cache_dir/$f" | awk '{print $1}')"
    bytes="$(wc -c < "$cache_dir/$f" | tr -d ' ')"
    polling="$(grep -o '"PollingDelay"[[:space:]]*:[[:space:]]*300000' "$cache_dir/$f" 2>/dev/null | wc -l | tr -d ' ')"
    printf '%s\t%s\t%s\t%s\n' "$f" "$sha" "$bytes" "$polling" >> "$cache_dir/source-manifest.tsv"
  done
  printf '%s\n' "$case_dir"
}

run_case() {
  local name="$1"
  local polling="$2"
  local profile="$3"
  local case_dir
  case_dir="$(prepare_case "$name")"
  THERMAL_SOURCE_DIR="$source_dir" \
  THERMAL_DATA_ROOT="$case_dir/data" \
  THERMAL_DEVICE=mustang \
  THERMAL_ANDROID=17 \
  THERMAL_BUILD_ID=CP2A.260805.005 \
    sh "$case_dir/module/tools/core/patch-thermal-validated.sh" "$polling" "$profile" "$case_dir/module" > "$case_dir/run.log" 2>&1
  printf '%s\n' "$case_dir"
}

stock_case="$(run_case stock-stock stock stock)"
grep -Fq 'PATCH_THERMAL_MATERIALIZED_FILES=0' "$stock_case/run.log"
grep -Fq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$stock_case/run.log"
grep -Fq 'PATCH_THERMAL_DELTA_FILES=3' "$stock_case/run.log"
if find "$stock_case/module/system/vendor/etc" -maxdepth 1 -type f -name 'thermal_info_config*.json' | grep -q .; then
  printf '%s\n' 'FAIL stock_stock_materialized_thermal_json'
  exit 1
fi

mod_case="$(run_case mod-stock mod stock)"
grep -Fq 'PATCH_THERMAL_MATERIALIZED_FILES=2' "$mod_case/run.log"
test -s "$mod_case/module/system/vendor/etc/thermal_info_config.json"
test ! -e "$mod_case/module/system/vendor/etc/thermal_info_config_charge.json"
test -s "$mod_case/module/system/vendor/etc/thermal_info_config_throttling.json"
grep -Fq '"PollingDelay": 5000' "$mod_case/module/system/vendor/etc/thermal_info_config.json"
grep -Fq '"PollingDelay": 5000' "$mod_case/module/system/vendor/etc/thermal_info_config_throttling.json"

outdoor_case="$(run_case stock-outdoor-safe stock outdoor-safe)"
grep -Fq 'PATCH_THERMAL_MATERIALIZED_FILES=2' "$outdoor_case/run.log"
test -s "$outdoor_case/module/system/vendor/etc/thermal_info_config.json"
test ! -e "$outdoor_case/module/system/vendor/etc/thermal_info_config_charge.json"
test -s "$outdoor_case/module/system/vendor/etc/thermal_info_config_throttling.json"
grep -Fq 'PATCH_THERMAL_DELTA_EXPECTED=1' "$outdoor_case/run.log"
grep -Fq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$outdoor_case/run.log"

printf '%s\n' 'PASS stock_stock_zero_thermal_json_overlay'
printf '%s\n' 'PASS mod_stock_materializes_only_changed_files'
printf '%s\n' 'PASS outdoor_safe_materializes_only_changed_files'
printf '%s\n' 'RESULT: PIXEL_THERMAL_STOCK_SPARSE_OVERLAY_TEST_PASS'
