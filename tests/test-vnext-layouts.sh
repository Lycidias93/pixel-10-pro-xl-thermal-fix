#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

for code in tokay caiman komodo comet tegu stallion cubs grizzly kodiak yogi; do
  grep -q "\"$code\"" "$repo_root/supported_versions.json" || { echo "FAIL missing_device_$code"; exit 2; }
done

. "$repo_root/tools/core/outdoor-runtime-policy.sh"
[[ "$(thermal_outdoor_max_delta mustang 17 TEST)" = 3 ]]
for code in tokay caiman komodo comet tegu stallion cubs grizzly kodiak yogi; do
  [[ "$(thermal_outdoor_max_delta "$code" 17 TEST)" = 1 ]] || { echo "FAIL outdoor_cap_$code"; exit 3; }
done

for code in cubs grizzly kodiak yogi; do
  grep -Fq "$code:17" "$repo_root/tools/ptune/ptune-guard.sh" || { echo "FAIL ptune_experimental_$code"; exit 3; }
  grep -Fq "$code:17" "$repo_root/tools/debug/vnext-readiness-summary.sh" || { echo "FAIL readiness_experimental_$code"; exit 3; }
done
grep -Fq 'classic_polling_stock_family_controls' "$repo_root/tools/core/install-thermal-overlay.sh" || { echo 'FAIL g6_family_polling_policy_missing'; exit 3; }

grep -Fqx 'LC_ALL=C' "$repo_root/tools/core/patch-thermal.sh" || { echo 'FAIL thermal_locale_pin_missing'; exit 4; }
grep -Fqx 'export LC_ALL' "$repo_root/tools/core/patch-thermal.sh" || { echo 'FAIL thermal_locale_export_missing'; exit 4; }

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
  local name="${2:-VIRTUAL-SKIN}"
  printf '%s\n' \
    '{' \
    '  "Sensors": [' \
    '    {' \
    "      \"Name\": \"$name\"," \
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
  local device="$1" build="$2" third="$3" profile="$4" expected_family="$5" extra_third="${6:-}"
  local root="$tmp/$device"
  local mod="$root/mod" src="$root/source" data="$root/data"
  mkdir -p "$src" "$data"
  make_module "$mod"
  write_fixture "$src/thermal_info_config.json"
  write_fixture "$src/thermal_info_config_charge.json"
  write_fixture "$src/$third"
  if [[ -n "$extra_third" ]]; then write_fixture "$src/$extra_third"; fi

  THERMAL_DEVICE="$device" THERMAL_ANDROID=17 THERMAL_BUILD_ID="$build" THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" mod "$profile" "$mod" | tee "$root/run.log"

  grep -q '^PATCH_THERMAL_DELTA_VALIDATION=pass$' "$root/run.log" || { echo "FAIL delta_validation_$device"; exit 10; }
  grep -q "^family=$expected_family$" "$mod/guard/thermal-layout.env" || { echo "FAIL layout_family_$device"; exit 11; }
  grep -q "^third=$third$" "$mod/guard/thermal-layout.env" || { echo "FAIL layout_third_$device"; exit 12; }
  [[ -s "$mod/system/vendor/etc/thermal_info_config.json" ]]
  [[ -s "$mod/system/vendor/etc/thermal_info_config_charge.json" ]]
  [[ -s "$mod/system/vendor/etc/$third" ]]
  if [[ -n "$extra_third" ]]; then [[ ! -e "$mod/system/vendor/etc/$extra_third" ]]; fi
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*5000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 3 ]]
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*300000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 0 ]]
}

write_g6_graph_fixture() {
  local src="$1"
  mkdir -p "$src"
  cat > "$src/thermal_info_config.json" <<'JSON'
{
  "Include": [
    "thermal_info_config_charge.json",
    "thermal_info_config_stats.json",
    "thermal_info_config_forecast.json",
    "thermal_info_config_earlywarnings.json",
    "thermal_info_config_ambient.json"
  ],
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "HotThreshold": ["NaN", 39, 43, 45], "PollingDelay": 300000},
    {"Name": "cellular-emergency", "HotThreshold": ["NaN", 50, 54], "PollingDelay": 300000},
    {"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "HotThreshold": [35], "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_charge.json" <<'JSON'
{
  "Include": ["thermal_info_config_common.json"],
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "HotThreshold": ["NaN", 34, 38, 43], "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_common.json" <<'JSON'
{
  "Include": [
    "/vendor/etc/thermal_info_config_vt.json",
    "thermal_info_config_aa_throttling.json",
    "thermal_info_config_bg_tasks_throttling.json"
  ],
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-MODEM", "HotThreshold": ["NaN", 43, 45, 46.5], "PollingDelay": 300000}
  ]
}
JSON
  for f in thermal_info_config_vt.json thermal_info_config_aa_throttling.json thermal_info_config_bg_tasks_throttling.json thermal_info_config_forecast.json thermal_info_config_earlywarnings.json thermal_info_config_ambient.json; do
    write_fixture "$src/$f" "AUX-${f%.json}"
  done
  cat > "$src/thermal_info_config_stats.json" <<'JSON'
{
  "Sensors": [
    {"Name": "STATS-SENSOR", "HotThreshold": [40], "PollingDelay": 300000},
  ]
}
JSON
}

run_g6_graph_case() {
  local root="$tmp/grizzly-graph"
  local mod="$root/mod" src="$root/source" data="$root/data"
  mkdir -p "$data"
  make_module "$mod"
  write_g6_graph_fixture "$src"

  THERMAL_DEVICE=grizzly THERMAL_ANDROID=17 THERMAL_BUILD_ID=HARISH_STATIC_LAYOUT THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" stock outdoor-safe "$mod" | tee "$root/run.log"

  grep -q '^PATCH_THERMAL_DELTA_VALIDATION=pass$' "$root/run.log"
  grep -q '^PATCH_THERMAL_LAYOUT_FAMILY=include_graph_g6$' "$root/run.log"
  grep -q '^count=10$' "$mod/guard/thermal-layout.env"
  grep -q '^PATCH_THERMAL_FILES=10$' "$root/run.log"
  grep -q '^PATCH_THERMAL_REPLACEMENTS=0$' "$root/run.log"
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*300000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 12 ]]
  [[ "$(grep -Rho '"PollingDelay"[[:space:]]*:[[:space:]]*5000' "$mod/system/vendor/etc" | wc -l | tr -d ' ')" = 0 ]]

  grep -Fq '"Name": "VIRTUAL-SKIN", "HotThreshold": ["NaN", 40, 44, 46]' "$mod/system/vendor/etc/thermal_info_config.json"
  grep -Fq '"Name": "cellular-emergency", "HotThreshold": ["NaN", 50, 54]' "$mod/system/vendor/etc/thermal_info_config.json"
  grep -Fq '"Name": "VIRTUAL-SKIN-OVER-35C-TRIGGER", "HotThreshold": [35]' "$mod/system/vendor/etc/thermal_info_config.json"
  grep -Fq '"Name": "VIRTUAL-SKIN-MODEM", "HotThreshold": ["NaN", 43, 45, 46.5]' "$mod/system/vendor/etc/thermal_info_config_common.json"
  grep -Fq '"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "HotThreshold": ["NaN", 34, 38, 43]' "$mod/system/vendor/etc/thermal_info_config_charge.json"

  if THERMAL_DEVICE=grizzly THERMAL_ANDROID=17 THERMAL_BUILD_ID=HARISH_STATIC_LAYOUT THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data-mod" \
      sh "$mod/tools/core/patch-thermal-validated.sh" mod stock "$mod" > "$root/mod-block.log" 2>&1; then
    echo 'FAIL g6_mod_polling_unexpectedly_admitted'; exit 20
  fi
  grep -q 'PATCH_THERMAL_REASON=polling_mode_not_admitted_for_platform' "$root/mod-block.log"
}

run_g6_graph_negative_cases() {
  local root="$tmp/g6-negative"
  local src="$root/source"
  mkdir -p "$src"
  cp "$repo_root/tools/core/thermal-layout.sh" "$root/thermal-layout.sh"
  . "$root/thermal-layout.sh"

  cat > "$src/thermal_info_config.json" <<'JSON'
{"Include": ["thermal_info_config_missing.json"], "Sensors": []}
JSON
  if thermal_layout_detect "$src" grizzly; then echo 'FAIL missing_include_admitted'; exit 21; fi

  rm -rf "$src"; mkdir -p "$src"
  cat > "$src/thermal_info_config.json" <<'JSON'
{"Include": ["thermal_info_config_common.json"], "Sensors": []}
JSON
  cat > "$src/thermal_info_config_common.json" <<'JSON'
{"Include": ["thermal_info_config.json"], "Sensors": []}
JSON
  if thermal_layout_detect "$src" grizzly; then echo 'FAIL include_cycle_admitted'; exit 22; fi
}

run_repo_stock_fixture() {
  local root="$tmp/mustang-repo-stock"
  local mod="$root/mod" data="$root/data"
  make_module "$mod"
  mkdir -p "$data"
  THERMAL_DEVICE=mustang THERMAL_ANDROID=17 THERMAL_BUILD_ID=REPO_STOCK_FIXTURE THERMAL_SOURCE_DIR="$repo_root/dev_tools/stock" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" mod outdoor-extended "$mod" | tee "$root/run.log"
  grep -q '^PATCH_THERMAL_SOURCE_300000=23$' "$root/run.log"
  grep -q '^PATCH_THERMAL_REPLACEMENTS=23$' "$root/run.log"
  grep -q '^PATCH_THERMAL_DELTA_TARGET_ZONES=13$' "$root/run.log"
  grep -q '^PATCH_THERMAL_DELTA_THRESHOLD_VALUES=91$' "$root/run.log"
  grep -q '^PATCH_THERMAL_LAYOUT_FAMILY=base_charge_throttling$' "$root/run.log"
}

run_case stallion ZP11.260717.006 thermal_info_config_lpm.json outdoor-safe base_charge_lpm
run_case mustang CP2A.260805.005 thermal_info_config_throttling.json outdoor-extended base_charge_throttling thermal_info_config_lpm.json
run_g6_graph_case
run_g6_graph_negative_cases
run_repo_stock_fixture

for script in \
  "$repo_root/customize.sh" "$repo_root/action.sh" "$repo_root/tools/core/thermal-layout.sh" \
  "$repo_root/tools/core/patch-thermal.sh" "$repo_root/tools/core/patch-thermal-vnext-core.sh" \
  "$repo_root/tools/core/patch-thermal-validated.sh" "$repo_root/tools/core/patch-thermal-validated-vnext.sh" \
  "$repo_root/tools/bootguard/compat-check.sh" "$repo_root/tools/bootguard/compat-check-vnext.sh" \
  "$repo_root/tools/menu/install-options-menu.sh" "$repo_root/tools/core/platform-transition.sh"; do
  sh -n "$script"
done

printf '%s\n' 'RESULT: VNEXT_LAYOUT_REGRESSION_PASS'
