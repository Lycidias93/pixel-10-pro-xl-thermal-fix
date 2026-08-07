#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

for code in tokay caiman komodo comet tegu stallion; do
  grep -q "\"$code\"" "$repo_root/supported_versions.json" || { echo "FAIL missing_device_$code"; exit 2; }
done

. "$repo_root/tools/core/outdoor-runtime-policy.sh"
[[ "$(thermal_outdoor_max_delta mustang 17 TEST)" = 3 ]]
for code in tokay caiman komodo comet tegu stallion; do
  [[ "$(thermal_outdoor_max_delta "$code" 17 TEST)" = 1 ]] || { echo "FAIL outdoor_cap_$code"; exit 3; }
done

make_module() {
  local dst="$1"
  mkdir -p "$dst/tools/core" "$dst/tools/bootguard" "$dst/tools/debug" "$dst/guard" "$dst/system/vendor/etc"
  for path in \
    tools/core/supported-build.sh \
    tools/core/outdoor-runtime-policy.sh \
    tools/core/thermal-layout.sh \
    tools/core/patch-thermal-vnext-core.sh \
    tools/core/patch-thermal.sh \
    tools/core/verify-outdoor-delta.sh \
    tools/core/validation-state.sh \
    tools/core/patch-thermal-validated-vnext.sh \
    tools/core/patch-thermal-validated.sh; do
    cp "$repo_root/$path" "$dst/$path"
  done
  cp "$repo_root/supported_versions.json" "$dst/supported_versions.json"
}

write_fixture() {
  local path="$1"
  printf '%s\n' \
    '{' \
    '  "Sensors": [' \
    '    {' \
    '      "Name": "VIRTUAL-SKIN",' \
    '      "HotThreshold": [' \
    '        40,' \
    '        45,' \
    '        "NaN"' \
    '      ],' \
    '      "PollingDelay": 300000' \
    '    }' \
    '  ]' \
    '}' > "$path"
}

run_case() {
  local device="$1"
  local build="$2"
  local third="$3"
  local profile="$4"
  local expected_family="$5"
  local extra_third="${6:-}"
  local root="$tmp/$device"
  local mod="$root/mod"
  local src="$root/source"
  local data="$root/data"
  mkdir -p "$src" "$data"
  make_module "$mod"
  write_fixture "$src/thermal_info_config.json"
  write_fixture "$src/thermal_info_config_charge.json"
  write_fixture "$src/$third"
  if [[ -n "$extra_third" ]]; then write_fixture "$src/$extra_third"; fi

  THERMAL_DEVICE="$device" \
  THERMAL_ANDROID=17 \
  THERMAL_BUILD_ID="$build" \
  THERMAL_SOURCE_DIR="$src" \
  THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" mod "$profile" "$mod" > "$root/run.log"

  grep -q '^PATCH_THERMAL_DELTA_VALIDATION=pass$' "$root/run.log"
  grep -q "^family=$expected_family$" "$mod/guard/thermal-layout.env"
  grep -q "^third=$third$" "$mod/guard/thermal-layout.env"
  [[ -s "$mod/system/vendor/etc/thermal_info_config.json" ]]
  [[ -s "$mod/system/vendor/etc/thermal_info_config_charge.json" ]]
  [[ -s "$mod/system/vendor/etc/$third" ]]
  if [[ -n "$extra_third" ]]; then [[ ! -e "$mod/system/vendor/etc/$extra_third" ]]; fi
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*5000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 3 ]]
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*300000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 0 ]]
}

run_case stallion ZP11.260717.006 thermal_info_config_lpm.json outdoor-safe base_charge_lpm
run_case mustang CP2A.260805.005 thermal_info_config_throttling.json outdoor-extended base_charge_throttling thermal_info_config_lpm.json

for script in \
  "$repo_root/customize.sh" \
  "$repo_root/tools/core/thermal-layout.sh" \
  "$repo_root/tools/core/patch-thermal.sh" \
  "$repo_root/tools/core/patch-thermal-vnext-core.sh" \
  "$repo_root/tools/core/patch-thermal-validated.sh" \
  "$repo_root/tools/core/patch-thermal-validated-vnext.sh" \
  "$repo_root/tools/bootguard/compat-check.sh" \
  "$repo_root/tools/bootguard/compat-check-vnext.sh" \
  "$repo_root/tools/menu/install-options-menu.sh" \
  "$repo_root/tools/core/platform-transition.sh"; do
  sh -n "$script"
done

printf '%s\n' 'RESULT: VNEXT_LAYOUT_REGRESSION_PASS'
