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
. "$repo_root/tools/core/outdoor-runtime-policy.sh"
[[ "$(thermal_outdoor_max_delta grizzly 17 G6_FAMILY_TEST)" = 1 ]]
thermal_outdoor_profile_admitted outdoor-safe grizzly 17 G6_FAMILY_TEST
! thermal_outdoor_profile_admitted outdoor-plus grizzly 17 G6_FAMILY_TEST

menu="$repo_root/tools/menu/install-options-menu.sh"
grep -Fq 'HotHysteresis & MaxReleaseStep' "$menu"
grep -Fq 'INSTALL_OPTION_FAMILY "$DEVICE_FAMILY"' "$menu"
! grep -Fq 'Passive Polling' "$menu"
grep -Fq 'mc_cycle2 "Thermal Profile max+$POLICY_MAX_DELTA" "Stock" "Outdoor Safe +1C"' "$menu"
grep -Fq 'mc_cycle2 "ZRAM page-cluster" "Stock" "EXPERIMENTAL 0 (post-Bootguard)"' "$menu"
grep -Fq 'cfg_unset PIXEL11_PASSIVE_MODE' "$menu"
grep -Fq 'single_pass_v5_family_zram' "$menu"
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
  local phase="$1" recovery="$2"
  local root="$tmp/$phase" mod="$tmp/$phase/mod" src="$tmp/$phase/source" data="$tmp/$phase/data"
  make_module "$mod"
  write_graph "$src"
  mkdir -p "$data"

  THERMAL_DEVICE=grizzly THERMAL_ANDROID=17 THERMAL_BUILD_ID=G6_FAMILY_TEST \
    THERMAL_SOURCE_DIR="$src" THERMAL_DATA_ROOT="$data" \
    sh "$mod/tools/core/patch-thermal-validated.sh" stock stock "$mod" "$recovery" | tee "$root.log"

  grep -Fxq 'PATCH_THERMAL=pass' "$root.log"
  grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$root.log"
  grep -Fxq 'PATCH_THERMAL_REPLACEMENTS=0' "$root.log"
  grep -Fxq 'PATCH_THERMAL_OUTPUT_5000=0' "$root.log"
  ! grep -Fq 'PIXEL11_PASSIVE' "$root.log"

  local common="$mod/system/vendor/etc/thermal_info_config_common.json"
  [[ "$(grep -Fo '"PassiveDelay": 5000' "$common" | wc -l | tr -d ' ')" = 0 ]]
  [[ "$(grep -Fo '"PassiveDelay": 7000' "$common" | wc -l | tr -d ' ')" = 8 ]]
  grep -Fq '"Name": "VIRTUAL-SKIN-SOC-EXTREME"' "$common"
  grep -Fq '"Name": "VIRTUAL-SKIN-MODEM", "HotThreshold": [50], "PassiveDelay": 10000' "$common"
  grep -Fq '"Name": "VIRTUAL-SKIN-CHARGE-WIRED", "HotThreshold": [34, 38, 43], "PassiveDelay": 7000' "$mod/system/vendor/etc/thermal_info_config_charge.json"

  if [[ "$recovery" = mod ]]; then
    grep -Fxq 'PATCH_THERMAL_PIXEL11_HYSTERESIS_CHANGES=15' "$root.log"
    grep -Fxq 'PATCH_THERMAL_PIXEL11_MRS_CHANGES=32' "$root.log"
    [[ "$(grep -Fo '"MaxReleaseStep": 2' "$common" | wc -l | tr -d ' ')" = 32 ]]
    [[ "$(grep -Fo '"MaxReleaseStep": 1' "$common" | wc -l | tr -d ' ')" = 5 ]]
    grep -Fq '"Name": "VIRTUAL-SKIN", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.0, 1.0, 1.0, 1.0, 1.9, 1.9]' "$common"
  else
    [[ "$(grep -Fo '"MaxReleaseStep": 2' "$common" | wc -l | tr -d ' ')" = 0 ]]
    [[ "$(grep -Fo '"MaxReleaseStep": 1' "$common" | wc -l | tr -d ' ')" = 37 ]]
    grep -Fq '"Name": "VIRTUAL-SKIN", "HotThreshold": [39, 43, 45, 46.5, 52, 65], "HotHysteresis": [0, 1.9, 1.9, 1.9, 1.4, 1.9, 1.9]' "$common"
  fi
}

run_phase recovery_mod mod
run_phase recovery_stock stock

# Pixel 11 threshold admission is independent from recovery tuning: +1 C is
# allowed only on the exact master VIRTUAL-SKIN object while classic polling
# and PassiveDelay remain untouched. The real-layout object placement itself
# is covered by test-vnext-layouts.sh.
threshold_root="$tmp/threshold-safe"
threshold_mod="$threshold_root/mod"
threshold_src="$threshold_root/source"
threshold_data="$threshold_root/data"
make_module "$threshold_mod"
write_graph "$threshold_src"
mkdir -p "$threshold_data"
THERMAL_DEVICE=grizzly THERMAL_ANDROID=17 THERMAL_BUILD_ID=G6_FAMILY_TEST \
  THERMAL_SOURCE_DIR="$threshold_src" THERMAL_DATA_ROOT="$threshold_data" \
  sh "$threshold_mod/tools/core/patch-thermal-validated.sh" stock outdoor-safe "$threshold_mod" mod | tee "$threshold_root.log"
grep -Fxq 'PATCH_THERMAL=pass' "$threshold_root.log"
grep -Fxq 'PATCH_THERMAL_DELTA_VALIDATION=pass' "$threshold_root.log"
grep -Fxq 'PATCH_THERMAL_REPLACEMENTS=0' "$threshold_root.log"
threshold_common="$threshold_mod/system/vendor/etc/thermal_info_config_common.json"
sensor_threshold_matches() {
  local file="$1" sensor="$2" expected="$3"
  awk -v target="$sensor" -v expected="$expected" '
    function sensor_name(line, name) {
      if (!match(line, /"Name"[[:space:]]*:[[:space:]]*"[^"]+"/)) return ""
      name=substr(line,RSTART,RLENGTH)
      sub(/^.*:[[:space:]]*"/,"",name)
      sub(/"$/,"",name)
      return name
    }
    {
      name=sensor_name($0)
      if (name!="") current=name
      if (current==target && $0 ~ /"HotThreshold"[[:space:]]*:/) {
        line=$0
        gsub(/[[:space:]]/,"",line)
        needle="\"HotThreshold\":[" expected "]"
        if (index(line,needle)) found=1
      }
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}
grep -Eq '"Name"[[:space:]]*:[[:space:]]*"VIRTUAL-SKIN".*"HotThreshold"[[:space:]]*:[[:space:]]*\[[[:space:]]*40,[[:space:]]*44,[[:space:]]*46,[[:space:]]*47\.5,[[:space:]]*53,[[:space:]]*66[[:space:]]*\]' "$threshold_common" || {
  echo 'FAIL pixel11_threshold_virtual_skin_plus1'
  grep -F '"Name": "VIRTUAL-SKIN"' "$threshold_common" || true
  exit 31
}
sensor_threshold_matches "$threshold_common" VIRTUAL-SKIN-CPU-LIGHT-ODPM 43 || {
  echo 'FAIL pixel11_threshold_cpu_light_changed'
  exit 32
}
sensor_threshold_matches "$threshold_common" VIRTUAL-SKIN-SOC 43 || {
  echo 'FAIL pixel11_threshold_soc_changed'
  exit 33
}
if grep -R -Eq '"PassiveDelay"[[:space:]]*:[[:space:]]*5000' "$threshold_mod/system/vendor/etc"; then
  echo 'FAIL pixel11_threshold_materialized_passive_5000'
  exit 34
fi

bad="$tmp/bad"
write_graph "$bad"
sed -i '0,/"MaxReleaseStep": 1/s//"MaxReleaseStep": 3/' "$bad/thermal_info_config_common.json"
if sh "$repo_root/tools/core/patch-g6-performance-controls.sh"     "$bad/thermal_info_config_common.json" "$tmp/bad.out" mod "$tmp/bad.metrics" >/dev/null 2>&1; then
  echo 'FAIL malformed_g6_inventory_admitted'
  exit 30
fi

printf '%s\n' 'RESULT: PIXEL11_FAMILY_CONTROLS_TEST_PASS'
