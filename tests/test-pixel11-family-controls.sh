#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

. "$repo_root/tools/core/thermal-layout.sh"
[[ "$(thermal_device_family mustang)" = pixel10 ]]
[[ "$(thermal_device_family tokay)" = pixel10 ]]
for device in cubs grizzly kodiak yogi; do
  [[ "$(thermal_device_family "$device")" = pixel11 ]] || { echo "FAIL family_$device"; exit 2; }
done

menu="$repo_root/tools/menu/install-options-menu.sh"
grep -Fq 'HotHysteresis & MaxReleaseStep' "$menu"
grep -Fq 'Passive Polling' "$menu"
grep -Fq 'Stock 7s (test 1 default)' "$menu"
grep -Fq 'INSTALL_OPTION_FAMILY "$DEVICE_FAMILY"' "$menu"
grep -Fq 'THERMAL_POLLING_POLICY stock_classic_polling_disabled_pixel11' "$menu"
grep -Fq 'mc_cycle2 "Polling Mode" "Mod values" "Stock values"' "$menu"

make_module() {
  local dst="$1"
  mkdir -p "$dst/tools/core" "$dst/guard" "$dst/system/vendor/etc"
  for path in \
    tools/core/supported-build.sh \
    tools/core/outdoor-runtime-policy.sh \
    tools/core/thermal-layout.sh \
    tools/core/patch-g6-performance-controls.sh \
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

write_graph() {
  local src="$1"
  mkdir -p "$src"
  cat > "$src/thermal_info_config.json" <<'JSON'
{
  "Include": ["thermal_info_config_common.json", "thermal_info_config_charge.json"],
  "Sensors": [
    {"Name": "ROOT-STOCK", "HotThreshold": [40], "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_charge.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "HotThreshold": [34, 38, 43], "PassiveDelay": 7000, "PollingDelay": 300000}
  ]
}
JSON
  cat > "$src/thermal_info_config_common.json" <<'JSON'
{
  "Sensors": [
    {"Name": "VIRTUAL-SKIN", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.9, 1.9, 1.9, 1.4, 1.9, 1.9], "PassiveDelay": 7000, "PollingDelay": 300000},
    {"Name": "VIRTUAL-SKIN-HINT", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.9, 1.9, 1.9, 1.4, 1.9, 1.9], "PassiveDelay": 7000, "PollingDelay": 300000},
    {
      "Name": "VIRTUAL-SKIN-CPU-LIGHT-ODPM",
      "HotThreshold": [43], "HotHysteresis": [0, 0.0, 1.9, 0, 0, 0, 0], "PassiveDelay": 7000, "PollingDelay": 300000,
      "BindedCdevInfo": [
        {"CdevRequest": "cpufreq-cpu0", "MaxReleaseStep": 1},
        {"CdevRequest": "cpufreq-cpu2", "MaxReleaseStep": 1},
        {"CdevRequest": "cpufreq-cpu6", "MaxReleaseStep": 1}
      ],
      "Profile": [{"Mode": "game", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]}]
    },
    {
      "Name": "VIRTUAL-SKIN-CPU-MID",
      "HotThreshold": [43], "HotHysteresis": [0, 0.0, 1.9, 0, 0, 0, 0], "PassiveDelay": 7000, "PollingDelay": 300000,
      "Profile": [
        {"Mode": "game", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]},
        {"Mode": "camera", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]}
      ]
    },
    {
      "Name": "VIRTUAL-SKIN-CPU-ODPM",
      "HotThreshold": [43], "HotHysteresis": [0, 0.0, 1.9, 0, 0, 0, 0], "PassiveDelay": 7000, "PollingDelay": 300000,
      "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}],
      "Profile": [
        {"Mode": "game", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]},
        {"Mode": "camera", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]}
      ]
    },
    {
      "Name": "VIRTUAL-SKIN-CPU-HIGH",
      "HotThreshold": [43], "HotHysteresis": [0, 0.0, 1.9, 0, 0, 0, 0], "PassiveDelay": 7000, "PollingDelay": 300000,
      "Profile": [
        {"Mode": "game", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]},
        {"Mode": "camera", "BindedCdevInfo": [{"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}]}
      ]
    },
    {
      "Name": "VIRTUAL-SKIN-SOC",
      "HotThreshold": [43], "HotHysteresis": [0, 0.0, 1.9, 1.9, 1.9, 1.4, 1.9], "PassiveDelay": 7000, "PollingDelay": 300000,
      "BindedCdevInfo": [
        {"CdevRequest": "g3d", "MaxReleaseStep": 1},
        {"CdevRequest": "tpu", "MaxReleaseStep": 1},
        {"CdevRequest": "aurora", "MaxReleaseStep": 1},
        {"CdevRequest": "vpu", "MaxReleaseStep": 1},
        {"CdevRequest": "disp", "MaxReleaseStep": 1}
      ]
    },
    {
      "Name": "VIRTUAL-SKIN-SOC-EXTREME", "HotThreshold": [60], "HotHysteresis": [0, 0, 1.9, 1.9, 1.9, 1.9, 1.9], "PassiveDelay": 7000, "PollingDelay": 300000,
      "BindedCdevInfo": [
        {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}, {"MaxReleaseStep": 1}
      ]
    },
    {"Name": "VIRTUAL-SKIN-MODEM", "HotThreshold": [50], "PassiveDelay": 10000, "PollingDelay": 300000}
  ]
}
JSON
}

run_phase() {
  local phase="$1" passive="$2"
  local root="$tmp/$phase" mod="$tmp/$phase/mod" src="$tmp/$phase/source" data="$tmp/$phase/data"
  make_module "$mod"
  write_graph "$src"
  mkdir -p "$data"

  THERMAL_DEVICE=grizzly THERMAL_ANDROID=17 THERMAL_BUILD_ID=G6_FAMILY_TEST \
    THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" stock stock "$mod" mod "$passive" | tee "$root.log"

  grep -Fxq 'PATCH_THERMAL=pass' "$root.log"
  grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$root.log"
  grep -Fxq 'PATCH_THERMAL_REPLACEMENTS=0' "$root.log"
  grep -Fxq 'PATCH_THERMAL_OUTPUT_5000=0' "$root.log"
  grep -Fxq 'PATCH_THERMAL_PIXEL11_HYSTERESIS_CHANGES=15' "$root.log"
  grep -Fxq 'PATCH_THERMAL_PIXEL11_MRS_CHANGES=32' "$root.log"

  local common="$mod/system/vendor/etc/thermal_info_config_common.json"
  grep -Fq '"Name": "VIRTUAL-SKIN", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.0, 1.0, 1.0, 1.0, 1.9, 1.9]' "$common"
  grep -Fq '"Name": "VIRTUAL-SKIN-HINT", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.0, 1.0, 1.0, 1.0, 1.9, 1.9]' "$common"
  [[ "$(grep -Fo '"MaxReleaseStep": 2' "$common" | wc -l | tr -d ' ')" = 32 ]]
  [[ "$(grep -Fo '"MaxReleaseStep": 1' "$common" | wc -l | tr -d ' ')" = 5 ]]
  grep -Fq '"Name": "VIRTUAL-SKIN-SOC-EXTREME"' "$common"
  grep -Fq '"HotHysteresis": [0, 0, 1.9, 1.9, 1.9, 1.9, 1.9]' "$common"
  grep -Fq '"Name": "VIRTUAL-SKIN-MODEM", "HotThreshold": [50], "PassiveDelay": 10000' "$common"
  grep -Fq '"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "HotThreshold": [34, 38, 43], "PassiveDelay": 7000' "$mod/system/vendor/etc/thermal_info_config_charge.json"

  if [[ "$passive" = stock ]]; then
    grep -Fxq 'PATCH_THERMAL_PIXEL11_PASSIVE_CHANGES=0' "$root.log"
    [[ "$(grep -Fo '"PassiveDelay": 7000' "$common" | wc -l | tr -d ' ')" = 8 ]]
  else
    grep -Fxq 'PATCH_THERMAL_PIXEL11_PASSIVE_CHANGES=7' "$root.log"
    [[ "$(grep -Fo '"PassiveDelay": 5000' "$common" | wc -l | tr -d ' ')" = 7 ]]
    [[ "$(grep -Fo '"PassiveDelay": 7000' "$common" | wc -l | tr -d ' ')" = 1 ]]
  fi
}

run_phase test1 stock
run_phase test2 mod

bad="$tmp/bad"
write_graph "$bad"
sed -i '0,/"MaxReleaseStep": 1/s//"MaxReleaseStep": 3/' "$bad/thermal_info_config_common.json"
if sh "$repo_root/tools/core/patch-g6-performance-controls.sh"     "$bad/thermal_info_config_common.json" "$tmp/bad.out" mod stock "$tmp/bad.metrics" >/dev/null 2>&1; then
  echo 'FAIL malformed_g6_inventory_admitted'
  exit 30
fi

printf '%s\n' 'RESULT: PIXEL11_FAMILY_CONTROLS_TEST_PASS'
