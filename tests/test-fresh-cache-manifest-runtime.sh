#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
core="$repo_root/tools/core/patch-thermal-fix5-core.sh"
supported="$repo_root/tools/core/supported-build.sh"

bash -n "$core"
bash -n "$supported"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
mod="$work/module"
data="$work/data"
source_dir="$work/source"
mkdir -p "$mod/tools/core" "$mod/system/vendor" "$source_dir"
cp -fp "$core" "$supported" "$mod/tools/core/"

for file in thermal_info_config.json thermal_info_config_charge.json thermal_info_config_throttling.json; do
  printf '%s\n' '{"Sensors":[{"Name":"VIRTUAL-SKIN","PollingDelay":300000,"HotThreshold":["NAN",39.0]}]}' > "$source_dir/$file"
done

if ! THERMAL_SOURCE_DIR="$source_dir" \
  THERMAL_DATA_ROOT="$data" \
  THERMAL_DEVICE=blazer \
  THERMAL_BUILD_ID=CP2A.260805.005 \
    sh "$mod/tools/core/patch-thermal-fix5-core.sh" mod outdoor-safe "$mod" > "$work/run.log" 2>&1; then
  cat "$work/run.log"
  printf '%s\n' 'FAIL fresh_cache_dynamic_materialization'
  exit 1
fi

grep -Fq 'PATCH_THERMAL=pass' "$work/run.log"
grep -Fq 'PATCH_THERMAL_FILES=3' "$work/run.log"
grep -Fq 'PATCH_THERMAL_SOURCE_300000=3' "$work/run.log"
grep -Fq 'PATCH_THERMAL_REPLACEMENTS=3' "$work/run.log"
grep -Fq 'PATCH_THERMAL_OUTPUT_5000=3' "$work/run.log"

source_manifest="$data/originals/blazer/CP2A.260805.005/vendor/etc/source-manifest.tsv"
patch_manifest="$mod/guard/patch-manifest.tsv"
expected_source_header="$(printf 'file\tsha256\tbytes\tpolling_300000')"
expected_patch_header="$(printf 'file\tsource_sha256\toutput_sha256\tsource_polling_300000\treplacements\toutput_polling_300000\toutput_polling_5000\tallowed_diff')"

[[ "$(head -n 1 "$source_manifest")" == "$expected_source_header" ]]
[[ "$(head -n 1 "$patch_manifest")" == "$expected_patch_header" ]]
! grep -Fq 'file\tsha256\tbytes\tpolling_300000' "$source_manifest"
! grep -Fq 'file\tsource_sha256\toutput_sha256' "$patch_manifest"

printf '%s\n' 'PASS fresh_cache_source_manifest_has_real_tabs'
printf '%s\n' 'PASS fresh_cache_patch_manifest_has_real_tabs'
printf '%s\n' 'PASS fresh_cache_dynamic_materialization_completed'
printf '%s\n' 'RESULT: PIXEL_THERMAL_FRESH_CACHE_MANIFEST_RUNTIME_TEST_PASS'
